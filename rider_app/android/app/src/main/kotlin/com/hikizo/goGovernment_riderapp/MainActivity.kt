package com.hikizo.goGovernment_riderapp

import android.app.ActivityManager
import android.app.ActivityOptions
import android.app.KeyguardManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.hikizo.goGovernment_riderapp/app_launcher"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        wakeAndUnlock()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        wakeAndUnlock()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        OrderOverlayManager.setChannel(methodChannel)

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "canDrawOverlays" -> {
                    result.success(OrderOverlayManager.canDrawOverlays(this))
                }
                "openOverlaySettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            android.net.Uri.parse("package:$packageName")
                        ).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                    }
                    result.success(true)
                }
                "showOrderOverlay" -> {
                    try {
                        val orderId = call.argument<String>("orderId") ?: ""
                        val storeName = call.argument<String>("storeName") ?: "Store"
                        val dropAddress = call.argument<String>("dropAddress") ?: "Customer Location"
                        val fee = call.argument<String>("fee") ?: "0"
                        val countdownSecs = call.argument<Int>("countdownSecs") ?: 30

                        OrderOverlayManager.showOrderOverlay(
                            applicationContext,
                            orderId,
                            storeName,
                            dropAddress,
                            fee,
                            countdownSecs
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OVERLAY_ERROR", e.message, null)
                    }
                }
                "dismissOrderOverlay" -> {
                    OrderOverlayManager.dismissOrderOverlay(this)
                    result.success(true)
                }
                "bringAppToFront" -> {
                    try {
                        wakeAndUnlock()
                        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                        val tasks = activityManager?.appTasks
                        if (tasks != null && tasks.isNotEmpty()) {
                            try {
                                tasks[0].moveToFront()
                            } catch (ignored: Exception) {}
                        }
                        val intent = Intent(applicationContext, MainActivity::class.java).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                            val options = ActivityOptions.makeBasic()
                            options.setPendingIntentBackgroundActivityStartMode(ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED)
                            val pendingIntent = PendingIntent.getActivity(
                                applicationContext,
                                1001,
                                intent,
                                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                            )
                            pendingIntent.send(applicationContext, 0, null, null, null, null, options.toBundle())
                        } else {
                            startActivity(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("LAUNCH_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun wakeAndUnlock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
            val wakeLock = powerManager?.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE,
                "GoGovernment:RiderWakeLock"
            )
            wakeLock?.acquire(5000L)
        } catch (ignored: Exception) {}

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
            keyguardManager?.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
}
