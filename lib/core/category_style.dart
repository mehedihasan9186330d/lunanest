import 'package:flutter/material.dart';

class CategoryStyle {
  const CategoryStyle(this.icon, this.colors, this.accent);
  final IconData icon;
  final List<Color> colors; // card background gradient
  final Color accent; // slider / highlight color

  static CategoryStyle of(String categoryId) {
    switch (categoryId) {
      case 'rain':
        return const CategoryStyle(Icons.water_drop, [Color(0xFF2B3A8F), Color(0xFF121744)], Color(0xFF8FA8FF));
      case 'ocean':
        return const CategoryStyle(Icons.waves, [Color(0xFF1F5F9E), Color(0xFF0F2447)], Color(0xFF5FB4F0));
      case 'nature':
        return const CategoryStyle(Icons.park, [Color(0xFF2D6A5A), Color(0xFF11263A)], Color(0xFF7FD1AE));
      case 'noise':
        return const CategoryStyle(Icons.graphic_eq, [Color(0xFF5B3F9E), Color(0xFF1A1450)], Color(0xFFB8A9FF));
      case 'cozy':
        return const CategoryStyle(Icons.fireplace, [Color(0xFF9A4F6B), Color(0xFF2A1440)], Color(0xFFFFA06B));
      default:
        return const CategoryStyle(Icons.bedtime, [Color(0xFF3B3F9E), Color(0xFF14183F)], Color(0xFFB8A9FF));
    }
  }
}
