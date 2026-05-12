import 'dart:convert';

import 'package:flutter/material.dart';

ImageProvider? profileImageProvider(String? value, String apiBaseUrl) {
  if (value == null || value.isEmpty) return null;
  if (value.startsWith('data:image/')) {
    final comma = value.indexOf(',');
    if (comma <= 0) return null;
    return MemoryImage(base64Decode(value.substring(comma + 1)));
  }
  if (value.startsWith('http')) return NetworkImage(value);
  final base = apiBaseUrl.replaceFirst(RegExp(r'/api$'), '');
  return NetworkImage('$base$value');
}
