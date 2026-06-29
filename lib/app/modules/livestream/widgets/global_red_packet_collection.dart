import 'package:flutter/material.dart';
import 'dart:async';

class GlobalRedPacketCollection extends StatefulWidget {
  final VoidCallback? onCollect;
  final VoidCallback? onSendRedPacket;
  final bool isVisible;
  final String? redPacketId;
  final double? amount;
  final String? senderName;
  final int? durationMinutes;

  const GlobalRedPacketCollection({
    super.key,
    this.onCollect,
    this.onSendRedPacket,
    this.isVisible = false,
    this.redPacketId,
    this.amount,
    this.senderName,
    this.durationMinutes,
  });

  @override
  State<GlobalRedPacketCollection> createState() => _GlobalRedPacketCollectionState();
}

class _GlobalRedPacketCollectionState extends State<GlobalRedPacketCollection>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _timerController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _timerAnimation;
  
  Timer? _autoHideTimer;
  bool _isCollected = false;
  int _remainingSeconds = 120; // Default 2 minutes
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _timerController = AnimationController(
      duration: Duration(minutes: widget.durationMinutes ?? 2), // Dynamic duration
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _timerAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _timerController,
      curve: Curves.linear,
    ));

    if (widget.isVisible) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _isCollected = false;
    _remainingSeconds = (widget.durationMinutes ?? 2) * 60; // Convert minutes to seconds
    
    _slideController.forward();
    _pulseController.repeat(reverse: true);
    _timerController.forward();
    
    // Start countdown timer
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
        
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _hideAnimation();
        }
      } else {
        timer.cancel();
      }
    });
    
    // Auto hide after dynamic duration
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(Duration(minutes: widget.durationMinutes ?? 2), () {
      if (mounted && !_isCollected) {
        _hideAnimation();
      }
    });
  }

  void _hideAnimation() {
    _slideController.reverse();
    _pulseController.stop();
    _timerController.stop();
    _countdownTimer?.cancel();
    _autoHideTimer?.cancel();
  }

  void _onCollectTap() {
    if (!_isCollected && widget.onCollect != null) {
      setState(() {
        _isCollected = true;
      });
      widget.onCollect!();
      
      // Show success animation then hide
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _hideAnimation();
        }
      });
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void didUpdateWidget(GlobalRedPacketCollection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _startAnimation();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _hideAnimation();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _timerController.dispose();
    _autoHideTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Red packet collection widget
        if (widget.isVisible)
          Positioned(
            top: 100,
            right: 16,
            child: SlideTransition(
              position: _slideAnimation,
              child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isCollected ? 0.8 : _pulseAnimation.value,
              child: GestureDetector(
                onTap: _onCollectTap,
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isCollected 
                        ? [Colors.green.shade400, Colors.green.shade600]
                        : [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (_isCollected ? Colors.green : Colors.red).withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Red packet icon
                      Icon(
                        _isCollected ? Icons.check_circle : Icons.card_giftcard,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      
                      // Amount or success message
                      Text(
                        _isCollected 
                          ? 'Collected!' 
                          : widget.amount != null 
                            ? '৳${widget.amount!.toStringAsFixed(0)}'
                            : 'Red Packet',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      if (!_isCollected) ...[
                        const SizedBox(height: 4),
                        
                        // Sender name
                        if (widget.senderName != null)
                          Text(
                            'From ${widget.senderName}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        
                        const SizedBox(height: 8),
                        
                        // Timer progress bar
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white30,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: AnimatedBuilder(
                            animation: _timerAnimation,
                            builder: (context, child) {
                              return FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _timerAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Countdown timer
                        Text(
                          _formatTime(_remainingSeconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Tap to collect text
                        const Text(
                          'Tap to Collect',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
        
        // Floating send button
        Positioned(
          top: 50,
          right: 16,
          child: GestureDetector(
            onTap: widget.onSendRedPacket,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
