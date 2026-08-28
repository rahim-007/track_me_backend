import 'package:flutter/material.dart';

/// Claymorphism corner radius tokens — larger, softer corners.
class AppRadius {
  AppRadius._();

  static const double small = 12.0;
  static const double medium = 20.0;
  static const double large = 28.0;
  static const double xl = 32.0;

  static BorderRadius get smallBorderRadius => BorderRadius.circular(small);
  static BorderRadius get mediumBorderRadius => BorderRadius.circular(medium);
  static BorderRadius get largeBorderRadius => BorderRadius.circular(large);
  static BorderRadius get xlBorderRadius => BorderRadius.circular(xl);
}

/// Consistent spacing tokens used throughout the application.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}
