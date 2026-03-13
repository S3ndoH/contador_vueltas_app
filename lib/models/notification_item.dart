import 'package:flutter/material.dart';

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final String iconColorHex;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.iconColorHex,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      iconName: map['icon_name'] as String,
      iconColorHex: map['icon_color_hex'] as String,
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Color get iconColor {
    try {
      final hexCode = iconColorHex.replaceAll('#', '');
      // Ensure hex is 8 chars (AARRGGBB), if 6 assume fully opaque
      if (hexCode.length == 6) {
        return Color(int.parse('FF$hexCode', radix: 16));
      } else if (hexCode.length == 8) {
        return Color(int.parse(hexCode, radix: 16));
      }
      return Colors.blue; 
    } catch (e) {
      return Colors.blue;
    }
  }
}
