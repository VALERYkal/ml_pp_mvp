# Stock Adjustments — AXE B (UI Layer)

**Date** : 09/01/2026  
**Status** : ✅ **CLOS — VALIDÉ FONCTIONNELLEMENT**  
**Version** : 1.0

---

## 🎯 Scope

AXE B covers the user-facing layer of stock adjustments.

### Objectives
- Creation of stock adjustments from the UI.
- Immediate and real impact on all stock figures.
- Visual transparency and auditability.

---

## 🔑 Key Principles

### 1. Adjustments are real business events
- Adjustments are not UI overrides or temporary corrections.
- They are official business events recorded in the database.
- They trigger the same database mechanisms as receptions and sorties.

### 2. Single source of truth
- All stock figures derive from a single canonical database source (`v_stock_actuel`).
- No Flutter-side stock calculations.
- No divergence between screens.

### 3. Explicit communication
- Any stock that includes manual corrections is explicitly marked as such.
- Visual indicators (badge "Corrigé") appear wherever stock figures are used for decision-making.

---

## 📊 Visual Indicators

### Badge "Corrigé"

A `Corrigé` badge is displayed wherever stock figures are used for decision-making:

- **Tank stock** (cartes citernes)
- **Depot total stock** (stock total dépôt)
- **Stock by owner** (stock par propriétaire)
- **Stock KPIs** (KPI stock dashboard)

### Tooltip

A tooltip explains that the stock includes one or more manual adjustments:
> "Ce stock inclut un ou plusieurs ajustements manuels."

### Implementation

- **Component** : `StockCorrectedBadge` (standardized, single component)
- **Providers** : `hasDepotAdjustmentsProvider` / `hasCiterneAdjustmentsProvider`
- **Logic** : Checks for adjustments in the last 30 days
- **Consistency** : Same badge, same tooltip, same logic everywhere

---

## ⚠️ MVP Handling of Inconsistencies

### Negative Stock

- **Database level** : Negative stock values are allowed.
- **UI display** : Values are clamped to 0 for usability.
- **Visual warning** : ⚠️ icon with tooltip if real stock is negative.
- **Tooltip** : "Stock réel négatif suite à un ajustement. La valeur affichée est corrigée à 0 pour l'affichage."

### Capacity Overflow

- **Database level** : Stock exceeding capacity is allowed.
- **UI display** : Actual value is shown.
- **Visual warning** : ⚠️ icon with tooltip if stock exceeds capacity.
- **Tooltip** : "Stock supérieur à la capacité théorique de la citerne. Veuillez vérifier les ajustements."

### Principles

- ✅ **No automatic correction** : The database value is never modified automatically.
- ✅ **No blocking** : Adjustments are never rejected automatically.
- ✅ **No silent inconsistencies** : Visual warnings prevent silent issues.
- ✅ **Audit visibility** : Real database values are preserved for audit.

---

## 🔄 Immediate Visual Propagation

After creating an adjustment, all screens refresh automatically:

- **Stock by tank** (citernes)
- **Daily stock** (stock journalier)
- **KPI dashboard** (KPI dashboard)
- **All screens using current stock** (tous écrans utilisant le stock actuel)

### Implementation

- **Helper function** : `refreshAfterStockAdjustment(ref, depotId: depotId)`
- **Mechanism** : Targeted invalidation of Riverpod providers
- **Optimization** : Uses `depotId` when available for targeted invalidation
- **Fallback** : Global invalidation if `depotId` is not available

---

## 🧪 Testing Strategy

### Business Correctness

Business correctness is validated through:

- **Database behavior** : Adjustments are written to the database correctly.
- **Trigger execution** : Database triggers execute as expected.
- **Stock impact** : Stock figures are updated correctly across all views.
- **Real usage** : Manual testing in staging environment.

### Full-Stack E2E Tests

**Full-stack Flutter E2E tests with live Supabase are intentionally not required** due to:

- **Non-idle application behavior** : Streams, auth refresh, timers make E2E tests unreliable.
- **Technical limitation** : This is a technical constraint, not a business limitation.
- **No impact on production** : The module is fully functional and exploitable without E2E tests.

### Validation

- ✅ **Business logic validated** : All business rules are correctly implemented.
- ✅ **Database integrity validated** : All database constraints and triggers work correctly.
- ✅ **UI consistency validated** : All screens display consistent stock figures.
- ✅ **Visual indicators validated** : Badge "Corrigé" appears correctly everywhere.

---

## 📁 File Structure

### Core Components

- **Service** : `lib/features/stocks_adjustments/data/stocks_adjustments_service.dart`
- **Providers** : `lib/features/stocks_adjustments/providers/has_adjustments_provider.dart`
- **Widget** : `lib/features/stocks_adjustments/widgets/stock_corrige_badge.dart`
- **Refresh helper** : `lib/features/stocks_adjustments/utils/stocks_adjustments_refresh.dart`

### Integration Points

- **Creation UI** : `lib/features/stocks_adjustments/screens/stocks_adjustment_create_sheet.dart`
- **Stock screens** : `lib/features/stocks/screens/stocks_screen.dart`
- **Tank cards** : `lib/features/citernes/screens/citerne_list_screen.dart`
- **KPI dashboard** : `lib/features/dashboard/widgets/role_dashboard.dart`

---

## ✅ Validation Checklist

### Functional Requirements

- [x] Adjustments can be created from the UI (reception / sortie)
- [x] Adjustments are written to the database correctly
- [x] Database triggers execute correctly
- [x] Stock figures are updated correctly across all views
- [x] All screens display consistent stock figures

### Visual Requirements

- [x] Badge "Corrigé" appears on tank cards when adjustments exist
- [x] Badge "Corrigé" appears on depot total stock when adjustments exist
- [x] Badge "Corrigé" appears on stock by owner when adjustments exist
- [x] Badge "Corrigé" appears on KPI dashboard when adjustments exist
- [x] Tooltip is consistent everywhere
- [x] Visual warnings appear for negative stock or capacity overflow

### Technical Requirements

- [x] No database modifications (read-only from Flutter)
- [x] No Flutter-side stock calculations
- [x] Single source of truth (`v_stock_actuel`)
- [x] Immediate visual propagation after adjustment creation
- [x] No crashes or blocking errors

---

## 🏁 Conclusion

**AXE B is CLOSED and VALIDATED FUNCTIONALLY.**

The stock adjustments module is:
- ✅ **Functional** : Adjustments can be created from the UI
- ✅ **Visible** : Badge "Corrigé" appears everywhere
- ✅ **Consistent** : Single source of truth, no divergence
- ✅ **Auditable** : Complete logging and traceability

**The project can advance without functional debt on this scope.**

### Next Steps

- **AXE A** : ✅ Locked (DB)
- **AXE B** : ✅ Closed officially
- **Next logical step** : **AXE C** (RLS / sécurité / prod hardening)

---

## 📚 Related Documentation

- **AXE A** : Database layer (triggers, views, functions)
- **B4.1** : Immediate visual propagation
- **B4.2** : Badge "STOCK CORRIGÉ"
- **B4.3** : Visual warnings for inconsistencies
- **B4.4** : Centralization of "Stock corrected" signal

---

**Last updated** : 09/01/2026
