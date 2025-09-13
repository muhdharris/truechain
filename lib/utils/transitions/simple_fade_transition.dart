// lib/utils/transitions/simple_fade_transition.dart
import 'package:flutter/material.dart';

class SimpleFadeTransition extends PageRouteBuilder {
  final Widget page;
  final Duration duration;
  
  SimpleFadeTransition({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}