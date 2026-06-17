import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Premium-styled refresh indicator with custom animation.
class PremiumRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;

  const PremiumRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? SAMsTheme.primary,
      backgroundColor: backgroundColor ?? SAMsTheme.surface,
      strokeWidth: 2.5,
      displacement: 60,
      child: child,
    );
  }
}

/// Flip-style currency text with animation.
/// Displays an amount with currency symbol, animating digit changes.
class FlipCurrencyText extends StatefulWidget {
  final double amount;
  final String currencySymbol;
  final TextStyle? style;
  final Duration duration;

  const FlipCurrencyText({
    super.key,
    required this.amount,
    this.currencySymbol = 'RM',
    this.style,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<FlipCurrencyText> createState() => _FlipCurrencyTextState();
}

class _FlipCurrencyTextState extends State<FlipCurrencyText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;
  double _oldAmount = 0;
  double _displayAmount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _oldAmount = widget.amount;
    _displayAmount = widget.amount;
    _controller.addListener(() {
      setState(() {
        _displayAmount = _oldAmount + (widget.amount - _oldAmount) * _anim.value;
      });
    });
    _controller.forward();
  }

  @override
  void didUpdateWidget(FlipCurrencyText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      _oldAmount = _displayAmount;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatted = _displayAmount.toStringAsFixed(2);
    return Text(
      '${widget.currencySymbol} $formatted',
      style: widget.style,
    );
  }
}

/// Animated flip counter for integer values.
class AnimatedFlipCounter extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final String? prefix;
  final String? suffix;

  const AnimatedFlipCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.prefix,
    this.suffix,
  });

  @override
  State<AnimatedFlipCounter> createState() => _AnimatedFlipCounterState();
}

class _AnimatedFlipCounterState extends State<AnimatedFlipCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;
  double _oldValue = 0;
  double _displayValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _oldValue = widget.value.toDouble();
    _displayValue = widget.value.toDouble();
    _controller.addListener(() {
      setState(() {
        _displayValue = _oldValue + (widget.value - _oldValue) * _anim.value;
      });
    });
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedFlipCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = _displayValue;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${widget.prefix ?? ''}${_displayValue.round()}${widget.suffix ?? ''}',
      style: widget.style,
    );
  }
}
