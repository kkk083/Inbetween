import 'package:flutter/material.dart';

class AppConstants {
  // Colors - Palette moderne pour une marketplace étudiante
  static const Color primaryColor = Color(0xFF6C63FF); // Violet moderne
  static const Color secondaryColor = Color(0xFFFF6584); // Rose/Corail
  static const Color accentColor = Color(0xFF4ECDC4); // Turquoise
  static const Color backgroundColor = Color(0xFFF7F7F7);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  
  // Categories pour les produits
  static const List<String> categories = [
    'Livres & Fournitures',
    'Électronique',
    'Vêtements',
    'Meubles',
    'Sports & Loisirs',
    'Autre',
  ];
  
  // Conditions des produits
  static const List<String> conditions = [
    'Comme neuf',
    'Très bon état',
    'Bon état',
    'État acceptable',
  ];
}