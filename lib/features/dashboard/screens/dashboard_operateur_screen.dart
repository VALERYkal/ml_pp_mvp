// 📌 Module : Dashboard Feature - Operateur Screen
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-08-07
// 🧭 Description : Écran de dashboard pour l'opérateur

import 'package:flutter/material.dart';
import 'package:ml_pp_mvp/features/dashboard/widgets/kpi_tiles.dart';

class DashboardOperateurScreen extends StatelessWidget {
  const DashboardOperateurScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Opérateur'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          KpiTiles(),
          SizedBox(height: 16),
          Center(child: Text('Accès aux fonctionnalités opérationnelles')),
        ],
      ),
    );
  }
}
