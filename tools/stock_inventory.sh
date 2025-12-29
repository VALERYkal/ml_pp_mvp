#!/bin/bash
# Script d'inventaire des usages legacy stock
# Usage: ./tools/stock_inventory.sh

echo "🔍 Inventaire des usages legacy stock"
echo "======================================"
echo ""

echo "📊 Recherche des occurrences de .from('stock_actuel'):"
rg "\.from\(['\"]stock_actuel" lib/ || echo "Aucune occurrence"

echo ""
echo "📊 Recherche des occurrences de .from('v_citerne_stock_actuel'):"
rg "\.from\(['\"]v_citerne_stock_actuel" lib/ || echo "Aucune occurrence"

echo ""
echo "📊 Recherche des occurrences de .from('v_stock_actuel_owner_snapshot'):"
rg "\.from\(['\"]v_stock_actuel_owner_snapshot" lib/ || echo "Aucune occurrence"

echo ""
echo "📊 Recherche des occurrences de .from('v_kpi_stock_global'):"
rg "\.from\(['\"]v_kpi_stock_global" lib/ || echo "Aucune occurrence"

echo ""
echo "✅ Inventaire terminé"
echo ""
echo "📝 Pour mettre à jour l'inventaire complet, voir:"
echo "   docs/db/stock_migration_inventory.md"

