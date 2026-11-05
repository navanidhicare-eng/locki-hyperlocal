import 'package:flutter/material.dart';

class ServiceCategory {
  final String id;
  final String name;
  final String icon;
  final String? iconUrl;
  final Color color;
  final String description;
  final int servicesCount;
  final List<Map<String, dynamic>> subCategories;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.iconUrl,
    required this.color,
    required this.description,
    required this.servicesCount,
    this.subCategories = const [],
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    Color parsedColor = const Color(0xFF2563EB);
    if (json['color'] != null) {
      String hex = json['color'].toString().replaceAll('#', '');
      if (hex.length == 6) {
        parsedColor = Color(int.parse('0xFF$hex'));
      }
    }

    final rawSubs = json['subCategories'];
    List<Map<String, dynamic>> parsedSubs = [];
    if (rawSubs is List) {
      parsedSubs = rawSubs.map((s) => s as Map<String, dynamic>).toList();
    }

    return ServiceCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'grid',
      iconUrl: json['iconUrl'] ?? json['image'] ?? json['imageUrl'],
      color: parsedColor,
      description: json['description'] ?? '',
      servicesCount: json['servicesCount'] ?? 0,
      subCategories: parsedSubs,
    );
  }

  IconData getIconData() {
    switch (id) {
      case 'cat_plumbing':
        return Icons.plumbing;
      case 'cat_electrical':
        return Icons.bolt;
      case 'cat_delivery':
        return Icons.delivery_dining;
      case 'cat_mechanic':
        return Icons.build;
      case 'cat_shops':
        return Icons.storefront;
      case 'cat_cleaning':
        return Icons.cleaning_services;
      case 'cat_appliances':
        return Icons.tv;
      case 'cat_bd22116b':
        return Icons.router;
      case 'cat_ab5c5cd1':
        return Icons.apartment;
      default:
        if (icon == 'wifi' || name.toLowerCase().contains('cable')) {
          return Icons.router;
        }
        if (icon == 'apartment' || name.toLowerCase().contains('lease') || name.toLowerCase().contains('rent')) {
          return Icons.apartment;
        }
        return Icons.home_repair_service;
    }
  }
}
