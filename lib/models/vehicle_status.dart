import 'package:flutter/material.dart';

enum VehicleStatus {
  active('Active', Color(0xFF16A34A), Color(0xFFDCFCE7)),
  maintenance('Maintenance', Color(0xFFD97706), Color(0xFFFEF3C7)),
  inactive('Inactive', Color(0xFF64748B), Color(0xFFF1F5F9));

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  const VehicleStatus(this.label, this.foregroundColor, this.backgroundColor);
}

