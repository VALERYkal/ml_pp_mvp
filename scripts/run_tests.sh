#!/bin/bash

# 📌 Script de test pour ML_PP MVP
# 🧑 Auteur : Valery Kalonga
# 📅 Date : 2025-08-07
# 🧭 Description : Génération des mocks et exécution des tests

echo "🔧 Génération des mocks avec build_runner..."
flutter packages pub run build_runner build --delete-conflicting-outputs

echo "🧪 Exécution des tests..."
flutter test

echo "✅ Tests terminés !"
