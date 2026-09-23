package com.hikizo.goGovernment_riderapp

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.CountDownTimer
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import io.flutter.plugin.common.MethodChannel

object OrderOverlayManager {
    private const val TAG = "OrderOverlayManager"
    private var overlayView: View? = null
    private var countDownTimer: CountDownTimer? = null
    private var channel: MethodChannel? = null

    fun setChannel(methodChannel: MethodChannel) {
        channel = methodChannel
    }

    fun canDrawOverlays(context: Context): Boolean {
        val allowed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else {
            true
        }
        Log.d(TAG, "canDrawOverlays check: $allowed")
        return allowed
    }

    fun showOrderOverlay(
        context: Context,
        orderId: String,
        storeName: String,
        dropAddress: String,
        fee: String,
        countdownSecs: Int
    ) {
        val appContext = context.applicationContext
        val canDraw = canDrawOverlays(appContext)
        Log.d(TAG, "showOrderOverlay called for order: $orderId, canDraw: $canDraw")
        if (!canDraw) {
            Log.w(TAG, "SYSTEM_ALERT_WINDOW not granted! Cannot show overlay.")
            return
        }

        Handler(Looper.getMainLooper()).post {
            dismissOrderOverlay(appContext)

            val windowManager = appContext.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
            if (windowManager == null) {
                Log.e(TAG, "WindowManager is NULL!")
                return@post
            }

            val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                layoutType,
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                        WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
                y = 100
            }

            // Root Container
            val root = LinearLayout(appContext).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(32, 28, 32, 28)
                val bg = GradientDrawable().apply {
                    setColor(Color.parseColor("#1A202C")) // Deep dark slate
                    cornerRadius = 32f
                    setStroke(3, Color.parseColor("#10B981")) // Green accent border
                }
                background = bg
                elevation = 25f
            }

            // Margin wrapper for root
            val rootWrapper = LinearLayout(appContext).apply {
                setPadding(24, 0, 24, 0)
                addView(root, LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ))
            }

            // Header Row: Title & Live Countdown Timer
            val headerRow = LinearLayout(appContext).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
            }

            val titleText = TextView(appContext).apply {
                text = "🚨 NEW ORDER ALERT"
                setTextColor(Color.parseColor("#10B981"))
                textSize = 16f
                paint.isFakeBoldText = true
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            }

            val timerText = TextView(appContext).apply {
                text = "⏱️ ${countdownSecs}s"
                setTextColor(Color.parseColor("#EF4444")) // Red
                textSize = 15f
                paint.isFakeBoldText = true
                val badgeBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#374151"))
                    cornerRadius = 16f
                }
                background = badgeBg
                setPadding(16, 6, 16, 6)
            }

            headerRow.addView(titleText)
            headerRow.addView(timerText)
            root.addView(headerRow)

            // Divider
            val divider = View(appContext).apply {
                setBackgroundColor(Color.parseColor("#374151"))
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    2
                ).apply { setMargins(0, 16, 0, 16) }
            }
            root.addView(divider)

            // Store Info (Pickup)
            val pickupText = TextView(appContext).apply {
                text = "📍 Pickup: $storeName"
                setTextColor(Color.WHITE)
                textSize = 15f
                paint.isFakeBoldText = true
            }
            root.addView(pickupText)

            // Customer Dropoff
            val dropText = TextView(appContext).apply {
                text = "🏠 Drop: $dropAddress"
                setTextColor(Color.parseColor("#9CA3AF"))
                textSize = 13f
                setPadding(0, 6, 0, 12)
            }
            root.addView(dropText)

            // Earnings Badge
            val earningsRow = LinearLayout(appContext).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                val earnBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#064E3B")) // Dark green
                    cornerRadius = 12f
                }
                background = earnBg
                setPadding(20, 8, 20, 8)
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply { setMargins(0, 0, 0, 16) }
            }

            val earnText = TextView(appContext).apply {
                text = "Estimated Payout: ₹$fee"
                setTextColor(Color.parseColor("#34D399"))
                textSize = 14f
                paint.isFakeBoldText = true
            }
            earningsRow.addView(earnText)
            root.addView(earningsRow)

            // Button Row: Accept (large green) & Decline (grey)
            val buttonRow = LinearLayout(appContext).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
            }

            val declineBtn = Button(appContext).apply {
                text = "Decline"
                setTextColor(Color.parseColor("#9CA3AF"))
                textSize = 13f
                val decBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#374151"))
                    cornerRadius = 16f
                }
                background = decBg
                layoutParams = LinearLayout.LayoutParams(
                    0,
                    120,
                    0.35f
                ).apply { setMargins(0, 0, 12, 0) }
                setOnClickListener {
                    dismissOrderOverlay(appContext)
                    channel?.invokeMethod("onOrderDeclined", mapOf("orderId" to orderId))
                }
            }

            val acceptBtn = Button(appContext).apply {
                text = "ACCEPT ORDER"
                setTextColor(Color.WHITE)
                textSize = 15f
                paint.isFakeBoldText = true
                val accBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#10B981"))
                    cornerRadius = 16f
                }
                background = accBg
                layoutParams = LinearLayout.LayoutParams(
                    0,
                    120,
                    0.65f
                )
                setOnClickListener {
                    dismissOrderOverlay(appContext)
                    // 1. Bring app to front
                    val intent = Intent(appContext, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                        putExtra("acceptedOrderId", orderId)
                    }
                    appContext.startActivity(intent)

                    // 2. Notify Flutter
                    channel?.invokeMethod("onOrderAccepted", mapOf("orderId" to orderId))
                }
            }

            buttonRow.addView(declineBtn)
            buttonRow.addView(acceptBtn)
            root.addView(buttonRow)

            // Add to WindowManager
            try {
                Log.d(TAG, "Attempting windowManager.addView(rootWrapper, params)")
                windowManager.addView(rootWrapper, params)
                overlayView = rootWrapper
                Log.i(TAG, "Overlay successfully added to WindowManager!")

                // Start 30s countdown
                countDownTimer = object : CountDownTimer((countdownSecs * 1000).toLong(), 1000L) {
                    override fun onTick(millisUntilFinished: Long) {
                        val secs = millisUntilFinished / 1000
                        timerText.text = "⏱️ ${secs}s"
                    }

                    override fun onFinish() {
                        dismissOrderOverlay(appContext)
                        channel?.invokeMethod("onOrderTimedOut", mapOf("orderId" to orderId))
                    }
                }.start()
            } catch (e: Exception) {
                Log.e(TAG, "CRITICAL ERROR adding overlay: ${e.message}", e)
            }
        }
    }

    fun dismissOrderOverlay(context: Context) {
        val appContext = context.applicationContext
        Handler(Looper.getMainLooper()).post {
            try {
                countDownTimer?.cancel()
                countDownTimer = null
                if (overlayView != null) {
                    val windowManager = appContext.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
                    windowManager?.removeView(overlayView)
                    overlayView = null
                    Log.d(TAG, "Overlay dismissed successfully")
                }
            } catch (e: Exception) {
                overlayView = null
            }
        }
    }
}
