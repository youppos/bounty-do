import 'package:flutter/material.dart';

class AnimatedCoinCounter extends ImplicitlyAnimatedWidget {
  final int value;
  final TextStyle style;

  const AnimatedCoinCounter({
    super.key,
    required this.value,
    required this.style,
    Duration duration = const Duration(milliseconds: 1500),
    Curve curve = Curves.easeOutCubic,
  }) : super(duration: duration, curve: curve);

  @override
  ImplicitlyAnimatedWidgetState<AnimatedCoinCounter> createState() => _AnimatedCoinCounterState();
}

class _AnimatedCoinCounterState extends AnimatedWidgetBaseState<AnimatedCoinCounter> {
  IntTween? _counterTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _counterTween = visitor(
      _counterTween,
      widget.value,
      (dynamic value) => IntTween(begin: value as int),
    ) as IntTween?;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${_counterTween?.evaluate(animation) ?? widget.value}',
      style: widget.style,
    );
  }
}
