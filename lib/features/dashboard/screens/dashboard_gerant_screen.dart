// 📌 Module : Dashboard Feature - Gerant Screen
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-08-07
// 🧭 Description : Écran de dashboard pour le gérant

import 'package:flutter/material.dart';

class DashboardGerantScreen extends StatelessWidget {
  const DashboardGerantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Gérant'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.manage_accounts,
              size: 64,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            Text(
              'Dashboard Gérant',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Accès aux fonctionnalités de gestion',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
