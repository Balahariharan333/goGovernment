import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../model/delivery_order_model.dart';
import '../utils/app_colors.dart';
import '../utils/responsive_helper.dart';
import '../widget/custom_text.dart';

/// Full-screen dispatch alert shown when a new order is targeted at this rider.
/// Plays alert.wav, shows 30-second countdown ring, Accept / Decline buttons.
class OrderDispatchAlert extends StatefulWidget {
  final DeliveryOrder order;
  final double? distKm;
  final int countdownSecs;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const OrderDispatchAlert({
    super.key,
    required this.order,
    this.distKm,
    this.countdownSecs = 30,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<OrderDispatchAlert> createState() => _OrderDispatchAlertState();
}

class _OrderDispatchAlertState extends State<OrderDispatchAlert>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  late AnimationController _ringController;
  final AudioPlayer _audio = AudioPlayer();
  bool _responded = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.countdownSecs;

    // Countdown ring animation
    _ringController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.countdownSecs),
    )..forward();

    // Countdown ticker
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) _autoDecline();
    });

    // Play alert sound
    _playSound();
  }

  Future<void> _playSound() async {
    try {
      await _audio.setVolume(1.0);
      await _audio.setReleaseMode(ReleaseMode.loop);
      await _audio.play(AssetSource('sound/alert.wav'));
      debugPrint('🔔 [OrderDispatchAlert] Playing alert sound loop...');
    } catch (e) {
      debugPrint('⚠️ Alert sound error: $e');
      try {
        await _audio.play(AssetSource('assets/sound/alert.wav'));
      } catch (_) {}
    }
  }

  Future<void> _stopSound() async {
    try {
      await _audio.stop();
      await _audio.dispose();
    } catch (_) {}
  }

  void _autoDecline() {
    if (_responded) return;
    _responded = true;
    _cleanup();
    widget.onDecline();
  }

  void _handleAccept() {
    if (_responded) return;
    _responded = true;
    _cleanup();
    widget.onAccept();
  }

  void _handleDecline() {
    if (_responded) return;
    _responded = true;
    _cleanup();
    widget.onDecline();
  }

  void _cleanup() {
    _timer?.cancel();
    _ringController.stop();
    _stopSound();
  }

  @override
  void dispose() {
    _cleanup();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final progress = _remaining / widget.countdownSecs;
    final distText = widget.distKm != null
        ? '${widget.distKm!.toStringAsFixed(1)} km away'
        : 'Nearby';

    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: Responsive.w(20)),
            padding: EdgeInsets.all(Responsive.w(24)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Responsive.w(24)),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 30, offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(Responsive.w(10)),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delivery_dining_rounded,
                          color: AppColors.primary, size: 28),
                    ),
                    SizedBox(width: Responsive.w(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText.title('New Delivery Request!',
                              fontSize: Responsive.sp(16),
                              fontWeight: FontWeight.bold),
                          CustomText.caption(distText, color: AppColors.success),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(20)),

                // Countdown ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: AnimatedBuilder(
                        animation: _ringController,
                        builder: (_, __) => CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 7,
                          backgroundColor: AppColors.lightGray,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _remaining > 10 ? AppColors.primary : AppColors.error,
                          ),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '$_remaining',
                          style: TextStyle(
                            fontSize: Responsive.sp(26),
                            fontWeight: FontWeight.bold,
                            color: _remaining > 10 ? AppColors.black : AppColors.error,
                          ),
                        ),
                        CustomText.caption('secs', color: AppColors.grayFont),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(20)),

                // Order info card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Responsive.w(14)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(Responsive.w(12)),
                  ),
                  child: Column(
                    children: [
                      _infoRow(Icons.storefront_outlined, AppColors.primary,
                          'Pickup', widget.order.storeName),
                      Divider(height: Responsive.h(14), color: AppColors.border),
                      _infoRow(Icons.location_on_rounded, AppColors.error,
                          'Deliver', widget.order.dropAddress),
                      Divider(height: Responsive.h(14), color: AppColors.border),
                      _infoRow(Icons.account_balance_wallet_outlined,
                          AppColors.success, 'Payout',
                          '₹${widget.order.estimatedPayout.toStringAsFixed(0)}'),
                    ],
                  ),
                ),
                SizedBox(height: Responsive.h(22)),

                // Accept / Decline buttons
                Row(
                  children: [
                    // Decline
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _handleDecline,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: Responsive.h(14)),
                          side: const BorderSide(color: AppColors.error, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Responsive.w(12)),
                          ),
                        ),
                        child: Text(
                          'Decline',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.sp(15),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Responsive.w(12)),
                    // Accept
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _handleAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: EdgeInsets.symmetric(vertical: Responsive.h(14)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Responsive.w(12)),
                          ),
                        ),
                        child: Text(
                          'Accept Delivery',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.sp(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, Color color, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: Responsive.w(8)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText.caption(label, color: AppColors.grayFont, fontSize: Responsive.sp(11)),
              CustomText.title(value,
                  fontSize: Responsive.sp(13), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
