package com.example.device_motorola

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.location.Criteria
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.util.Log
import com.google.android.gms.location.LocationServices
import androidx.core.app.NotificationCompat

class MockLocationService : Service() {
    private val mockProviders = listOf(
        LocationManager.GPS_PROVIDER,
        LocationManager.NETWORK_PROVIDER,
        "fused",
    )
    private val mockUpdateIntervalMs = 1_000L
    private val handler = Handler(Looper.getMainLooper())
    private val fusedClient by lazy { LocationServices.getFusedLocationProviderClient(this) }
    private var wakeLock: PowerManager.WakeLock? = null
    private var providersInitialized = false
    private var stopRequested = false
    private var lat = 0.0
    private var lng = 0.0
    private val updateRunnable = object : Runnable {
        override fun run() {
            try {
                pushMockLocation(lat, lng)
            } catch (_: Exception) {
                // Keep retrying; provider writes can intermittently fail on OEM ROMs.
            } finally {
                handler.postDelayed(this, mockUpdateIntervalMs)
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                try {
                    stopRequested = false
                    lat = intent.getDoubleExtra(EXTRA_LAT, 0.0)
                    lng = intent.getDoubleExtra(EXTRA_LNG, 0.0)
                    logEvent("ACTION_START lat=$lat lng=$lng")
                    saveMockPoint(lat, lng)
                    startForeground(NOTIFICATION_ID, buildNotification())
                    acquireWakeLock()
                    setMockActiveState(true)
                    handler.removeCallbacks(updateRunnable)
                    handler.post(updateRunnable)
                } catch (e: Exception) {
                    // Prevent process crash if foreground start is restricted by OS policy.
                    logEvent("ACTION_START failed: ${e.message}")
                    setMockActiveState(false)
                    stopSelf()
                }
            }

            ACTION_STOP -> {
                stopRequested = true
                setMockActiveState(false)
                logEvent("ACTION_STOP requested")
                stopSelf()
            }

            else -> {
                if (getMockActiveState()) {
                    val point = getSavedMockPoint()
                    lat = point.first
                    lng = point.second
                    try {
                        startForeground(NOTIFICATION_ID, buildNotification())
                        acquireWakeLock()
                        handler.removeCallbacks(updateRunnable)
                        handler.post(updateRunnable)
                        logEvent("Service resumed with saved point")
                    } catch (e: Exception) {
                        logEvent("Service resume failed: ${e.message}")
                        setMockActiveState(false)
                        stopSelf()
                    }
                }
            }
        }
        return START_REDELIVER_INTENT
    }

    override fun onDestroy() {
        handler.removeCallbacks(updateRunnable)
        releaseWakeLock()
        if (stopRequested) {
            clearMockProvider()
            setMockActiveState(false)
        }
        logEvent("Service destroyed stopRequested=$stopRequested")
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(): Notification {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Mock Location",
                NotificationManager.IMPORTANCE_LOW,
            )
            manager.createNotificationChannel(channel)
        }
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Hello Moto")
            .setContentText("Mock location is active")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .build()
    }

    private fun pushMockLocation(latitude: Double, longitude: Double) {
        val locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
        ensureProvidersInitialized(locationManager)
        var pushedProviderCount = 0
        for (provider in mockProviders) {
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
                // Try next provider.
            }
        }
        if (pushedProviderCount == 0) {
            providersInitialized = false
            ensureProvidersInitialized(locationManager)
            for (provider in mockProviders) {
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
                    // Ignore retry failures.
                }
            }
        }
        if (pushedProviderCount == 0) {
            throw SecurityException("Unable to inject mock location for any provider.")
        }
        logEvent("Provider push success count=$pushedProviderCount")

        // Also drive fused provider to prevent fallback to real location on some OEM builds.
        try {
            val fusedLocation = Location(LocationManager.GPS_PROVIDER).apply {
                this.latitude = latitude
                this.longitude = longitude
                this.altitude = 0.0
                this.time = System.currentTimeMillis()
                this.accuracy = 8f
                this.elapsedRealtimeNanos = SystemClock.elapsedRealtimeNanos()
                this.speed = 0f
                this.bearing = 0f
            }
            fusedClient.setMockMode(true)
            fusedClient.setMockLocation(fusedLocation)
            logEvent("Fused mock location pushed")
        } catch (e: Exception) {
            logEvent("Fused push failed: ${e.message}")
            // Keep service alive even if fused mock mode is unavailable.
        }
    }

    private fun ensureProvidersInitialized(locationManager: LocationManager) {
        if (providersInitialized) {
            return
        }
        for (provider in mockProviders) {
            try {
                locationManager.removeTestProvider(provider)
            } catch (_: Exception) {
                // Ignore if provider does not exist.
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
            } catch (_: Exception) {
                // Ignore provider add failures on unsupported providers.
            }
        }
        providersInitialized = true
    }

    private fun clearMockProvider() {
        val locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
        for (provider in mockProviders) {
            try {
                locationManager.setTestProviderEnabled(provider, false)
                locationManager.removeTestProvider(provider)
            } catch (_: Exception) {
                // Ignore.
            }
        }
        providersInitialized = false
        try {
            fusedClient.setMockMode(false)
            logEvent("Cleared test providers and fused mock mode")
        } catch (e: Exception) {
            logEvent("Clear fused mode failed: ${e.message}")
            // Ignore fused cleanup failures.
        }
    }

    private fun setMockActiveState(active: Boolean) {
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_ACTIVE, active)
            .apply()
    }

    private fun logEvent(message: String) {
        Log.d(TAG, message)
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_LAST_EVENT, message)
            .apply()
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) {
            return
        }
        try {
            val pm = getSystemService(POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "device_motorola:mock_location_lock",
            ).apply {
                setReferenceCounted(false)
                acquire()
            }
        } catch (_: Exception) {
            // Ignore wake lock failures; service will still attempt updates.
        }
    }

    private fun releaseWakeLock() {
        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                }
            }
        } catch (_: Exception) {
            // Ignore release failures.
        } finally {
            wakeLock = null
        }
    }

    private fun getMockActiveState(): Boolean {
        return getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getBoolean(KEY_ACTIVE, false)
    }

    private fun saveMockPoint(latitude: Double, longitude: Double) {
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_LAT, latitude.toString())
            .putString(KEY_LNG, longitude.toString())
            .apply()
    }

    private fun getSavedMockPoint(): Pair<Double, Double> {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val savedLat = prefs.getString(KEY_LAT, "0.0")?.toDoubleOrNull() ?: 0.0
        val savedLng = prefs.getString(KEY_LNG, "0.0")?.toDoubleOrNull() ?: 0.0
        return Pair(savedLat, savedLng)
    }

    companion object {
        const val ACTION_START = "com.example.device_motorola.action.START_MOCK"
        const val ACTION_STOP = "com.example.device_motorola.action.STOP_MOCK"
        const val EXTRA_LAT = "extra_lat"
        const val EXTRA_LNG = "extra_lng"
        const val PREFS_NAME = "mock_location_prefs"
        const val KEY_ACTIVE = "mock_active"
        const val KEY_LAST_EVENT = "mock_last_event"
        private const val KEY_LAT = "mock_lat"
        private const val KEY_LNG = "mock_lng"

        private const val TAG = "MockLocationService"
        private const val CHANNEL_ID = "mock_location_channel"
        private const val NOTIFICATION_ID = 4107
    }
}
