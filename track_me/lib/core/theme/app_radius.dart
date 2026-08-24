import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double small = 10.0;
  static const double medium = 16.0;
  static const double large = 22.0;
  static const double xl = 28.0;

  static BorderRadius get smallBorderRadius => BorderRadius.circular(small);
  static BorderRadius get mediumBorderRadius => BorderRadius.circular(medium);
  static BorderRadius get largeBorderRadius => BorderRadius.circular(large);
  static BorderRadius get xlBorderRadius => BorderRadius.circular(xl);
}
