import 'dart:io';
import 'package:flutter/widgets.dart';

ImageProvider safeImage(
  String? url, {
  String defaultAsset = 'assets/images/studentmale.png',
}) {
  final String s = (url ?? '').toString().trim();
  
  if (s.isEmpty || s.toLowerCase() == 'null') {
    return AssetImage(defaultAsset);
  }

  // Handle Network Images
  if (s.startsWith('http://') || s.startsWith('https://')) {
    try {
      return NetworkImage(s);
    } catch (_) {
      return AssetImage(defaultAsset);
    }
  }

  // Handle File Images (absolute paths from local storage)
  if (s.startsWith('/') || s.startsWith('file://') || s.contains('com.fahamni')) {
    try {
      return FileImage(File(s.replaceFirst('file://', '')));
    } catch (_) {
      return AssetImage(defaultAsset);
    }
  }

  // Handle Assets
  if (s.startsWith('assets/')) {
    return AssetImage(s);
  }
  
  // If it doesn't start with assets/ but looks like a path, try as asset
  if (s.contains('/')) {
    return AssetImage(s);
  }

  // Default fallback if no pattern matched
  return AssetImage(defaultAsset);
}
