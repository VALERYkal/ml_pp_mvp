import 'dart:ui';
import 'package:flutter/material.dart';

TextStyle withTabs(
  TextStyle? base, {
  double? size,
  FontWeight? weight,
  Color? color,
}) {
  final b = (base ?? const TextStyle());
  return b.copyWith(
    fontSize: size ?? b.fontSize,
    fontWeight: weight ?? b.fontWeight,
    color: color ?? b.color,
    fontFeatures: const [FontFeature.tabularFigures()], // chiffres alignés
    height: 1.15,
  );
}

