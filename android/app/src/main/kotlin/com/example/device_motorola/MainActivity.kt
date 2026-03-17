package com.example.device_motorola

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.location.Criteria
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.SystemClock
import android.provider.Settings
import android.util.Log
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
    private val tag = "MainActivityMock"
    private val mockProviders = listOf(
        LocationManager.GPS_PROVIDER,
        LocationManager.NETWORK_PROVIDER,
        "fused",
    )
    private var mockActive = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setMockLocation" -> {
                        val latitude = call.argument<Double>("latitude")
                        val longitude = call.argument<Double>("longitude")
                        val radiusMeters = call.argument<Double>("radiusMeters") ?: 15.0

                        if (latitude == null || longitude == null) {
                            result.error("invalid_args", "Missing latitude/longitude", null)
                            return@setMethodCallHandler
                        }

                        try {
                            val randomized = randomPointWithinRadius(latitude, longitude, radiusMeters)
                            pushMockLocation(randomized.first, randomized.second)
                            Log.d(tag, "setMockLocation push success lat=${randomized.first} lng=${randomized.second}")
                            mockActive = true
                            setMockActiveState(true)
                            // Keep mock location functional even if foreground service start is restricted.
                            try {
                                startMockService(randomized.first, randomized.second)
                            } catch (_: Exception) {
                                // Ignore service startup failures; immediate mock injection already succeeded.
                            }
                            result.success(
                                mapOf(
                                    "latitude" to randomized.first,
                                    "longitude" to randomized.second,
                                ),
                            )
                        } catch (e: SecurityException) {
                            Log.e(tag, "setMockLocation permission denied", e)
                            mockActive = false
                            setMockActiveState(false)
                            result.error(
                                "mock_permission_denied",
                                "Set this app as the Mock Location App in Developer Options.",
                                null,
                            )
                        } catch (e: Exception) {
                            Log.e(tag, "setMockLocation failed", e)
                            mockActive = false
                            setMockActiveState(false)
                            result.error("mock_failed", e.message ?: "Failed to set mock location", null)
                        }
                    }

                    "clearMockLocation" -> {
                        try {
                            stopMockService()
                            clearMockProvider()
                            mockActive = false
                            setMockActiveState(false)
                            Log.d(tag, "clearMockLocation success")
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(tag, "clearMockLocation failed", e)
                            result.error("clear_mock_failed", e.message ?: "Failed to clear mock location", null)
                        }
                    }

                    "getMockStatus" -> {
                        result.success(
                            mapOf(
                                "isMockSetupReady" to isMockAppSelected(),
                                "isMockActive" to (getMockActiveState() || mockActive),
                            ),
                        )
                    }

                    "openMockLocationSettings" -> {
                        result.success(openMockLocationSettings())
                    }

                    "getMockDebugInfo" -> {
                        val prefs = getSharedPreferences(MockLocationService.PREFS_NAME, Context.MODE_PRIVATE)
                        result.success(
                            mapOf(
                                "isMockSetupReady" to isMockAppSelected(),
                                "isMockActivePref" to getMockActiveState(),
                                "isMockActiveMem" to mockActive,
                                "lastEvent" to (prefs.getString(MockLocationService.KEY_LAST_EVENT, "") ?: ""),
                            ),
                        )
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun pushMockLocation(latitude: Double, longitude: Double) {
        val locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
        var pushedProviderCount = 0

        for (provider in mockProviders) {
            try {
                locationManager.removeTestProvider(provider)
            } catch (_: Exception) {
                // Ignore if provider is not registered yet.
            }

            try {
                locationManager.addTestProvider(
                    provider,
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
            } catch (_: IllegalArgumentException) {
                // Provider may already exist on some OEM builds.
            }

            try {
                locationManager.setTestProviderEnabled(provider, true)

                val mockLocation = Location(provider).apply {
                    this.latitude = latitude
                    this.longitude = longitude
                    this.altitude = 0.0
                    this.time = System.currentTimeMillis()
                    this.accuracy = 8f
                    this.elapsedRealtimeNanos = SystemClock.elapsedRealtimeNanos()
                    this.speed = 0f
                    this.bearing = 0f
                }

                locationManager.setTestProviderLocation(provider, mockLocation)
                pushedProviderCount += 1
            } catch (_: Exception) {
                // Try other providers; some providers can fail on specific devices.
            }
        }

        if (pushedProviderCount == 0) {
            throw SecurityException("Unable to inject mock location for any provider.")
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

    private fun clearMockProvider() {
        val locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
        for (provider in mockProviders) {
            try {
                locationManager.setTestProviderEnabled(provider, false)
                locationManager.removeTestProvider(provider)
            } catch (_: Exception) {
                // Ignore cleanup failures when provider was already removed.
            }
        }
    }

    private fun startMockService(latitude: Double, longitude: Double) {
        val intent = Intent(this, MockLocationService::class.java).apply {
            action = MockLocationService.ACTION_START
            putExtra(MockLocationService.EXTRA_LAT, latitude)
            putExtra(MockLocationService.EXTRA_LNG, longitude)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopMockService() {
        val intent = Intent(this, MockLocationService::class.java).apply {
            action = MockLocationService.ACTION_STOP
        }
        startService(intent)
        stopService(Intent(this, MockLocationService::class.java))
    }

    private fun setMockActiveState(active: Boolean) {
        getSharedPreferences(MockLocationService.PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(MockLocationService.KEY_ACTIVE, active)
            .apply()
    }

    private fun getMockActiveState(): Boolean {
        return getSharedPreferences(MockLocationService.PREFS_NAME, Context.MODE_PRIVATE)
            .getBoolean(MockLocationService.KEY_ACTIVE, false)
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

    private fun openMockLocationSettings(): Boolean {
        return try {
            startActivity(
                Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                },
            )
            true
        } catch (_: Exception) {
            try {
                startActivity(
                    Intent(Settings.ACTION_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    },
                )
                true
            } catch (_: Exception) {
                false
            }
        }
    }

}
