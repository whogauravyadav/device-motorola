package com.example.device_motorola

import android.app.AppOpsManager
import android.location.Criteria
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.SystemClock
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt
import kotlin.random.Random

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.device_motorola/mock_location"
    private val mockProvider = LocationManager.GPS_PROVIDER
    private var mockActive = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setMockLocation" -> {
                        val latitude = call.argument<Double>("latitude")
                        val longitude = call.argument<Double>("longitude")
                        val radiusMeters = call.argument<Double>("radiusMeters")

                        if (latitude == null || longitude == null || radiusMeters == null) {
                            result.error("invalid_args", "Missing latitude/longitude/radius", null)
                            return@setMethodCallHandler
                        }

                        try {
                            val randomized = randomPointWithinRadius(latitude, longitude, radiusMeters)
                            pushMockLocation(randomized.first, randomized.second)
                            mockActive = true
                            result.success(
                                mapOf(
                                    "latitude" to randomized.first,
                                    "longitude" to randomized.second,
                                ),
                            )
                        } catch (e: SecurityException) {
                            mockActive = false
                            result.error(
                                "mock_permission_denied",
                                "Set this app as the Mock Location App in Developer Options.",
                                null,
                            )
                        } catch (e: Exception) {
                            mockActive = false
                            result.error("mock_failed", e.message ?: "Failed to set mock location", null)
                        }
                    }

                    "clearMockLocation" -> {
                        try {
                            clearMockProvider()
                            mockActive = false
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("clear_mock_failed", e.message ?: "Failed to clear mock location", null)
                        }
                    }

                    "getMockStatus" -> {
                        result.success(
                            mapOf(
                                "isMockSetupReady" to isMockAppSelected(),
                                "isMockActive" to mockActive,
                            ),
                        )
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun pushMockLocation(latitude: Double, longitude: Double) {
        val locationManager = getSystemService(LOCATION_SERVICE) as LocationManager

        try {
            locationManager.removeTestProvider(mockProvider)
        } catch (_: Exception) {
            // Ignore if provider is not registered yet.
        }

        locationManager.addTestProvider(
            mockProvider,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            Criteria.POWER_LOW,
            Criteria.ACCURACY_FINE,
        )
        locationManager.setTestProviderEnabled(mockProvider, true)

        val mockLocation = Location(mockProvider).apply {
            this.latitude = latitude
            this.longitude = longitude
            this.altitude = 0.0
            this.time = System.currentTimeMillis()
            this.accuracy = 8f
            this.elapsedRealtimeNanos = SystemClock.elapsedRealtimeNanos()
            this.speed = 0f
            this.bearing = 0f
        }

        locationManager.setTestProviderLocation(mockProvider, mockLocation)
    }

    private fun clearMockProvider() {
        val locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
        try {
            locationManager.setTestProviderEnabled(mockProvider, false)
            locationManager.removeTestProvider(mockProvider)
        } catch (_: Exception) {
            // Ignore cleanup failures when provider was already removed.
        }
    }

    private fun isMockAppSelected(): Boolean {
        return try {
            val appOpsManager = getSystemService(APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOpsManager.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_MOCK_LOCATION,
                    android.os.Process.myUid(),
                    packageName,
                )
            } else {
                appOpsManager.checkOpNoThrow(
                    AppOpsManager.OPSTR_MOCK_LOCATION,
                    android.os.Process.myUid(),
                    packageName,
                )
            }
            mode == AppOpsManager.MODE_ALLOWED
        } catch (_: Exception) {
            false
        }
    }

    private fun randomPointWithinRadius(
        centerLat: Double,
        centerLng: Double,
        radiusMeters: Double,
    ): Pair<Double, Double> {
        val distance = sqrt(Random.nextDouble()) * radiusMeters
        val bearing = Random.nextDouble(0.0, 2 * PI)
        val earthRadius = 6_378_137.0

        val deltaLat = distance * cos(bearing) / earthRadius
        val deltaLng = distance * sin(bearing) / (earthRadius * cos(Math.toRadians(centerLat)))

        return Pair(
            centerLat + Math.toDegrees(deltaLat),
            centerLng + Math.toDegrees(deltaLng),
        )
    }
}
