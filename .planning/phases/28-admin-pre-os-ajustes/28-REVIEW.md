---
phase: 28-admin-pre-os-ajustes
reviewed: 2026-06-05T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - lib/core/widgets/sport_btn.dart
  - lib/features/admin/ui/settings_tab.dart
  - lib/features/admin/ui/pricing_tab.dart
findings:
  critical: 0
  warning: 3
  info: 3
  total: 6
status: issues_found
---

# Phase 28: Code Review Report

**Reviewed:** 2026-06-05
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Three files reviewed: the shared `SportBtn` widget and two admin panel tabs (`SettingsTab`, `PricingTab`). The Arena Esportivo visual identity is correctly applied — no `Card`/shadow widgets, all colors via `AppTheme` tokens, `AppTheme.display` (Anton) used appropriately, and `SportBtn` named constructors used correctly throughout. BLoC/Cubit wiring is sound. `mounted` guards are present in all async paths. Controllers are disposed in all `dispose()` overrides.

Three warnings found, all in `pricing_tab.dart`: a drag handle on the sports list that does nothing, a `_syncFromState` logic issue that can silently drop remote updates, and an unvalidated hour ordering in `_TierEditSheet` that allows saving an invalid tier. Three info-level items noted.

---

## Warnings

### WR-01: Drag-handle icon rendered but reorder is not wired up

**File:** `lib/features/admin/ui/settings_tab.dart:522-530`
**Issue:** Each sport row renders a `Icons.drag_handle` icon that implies drag-to-reorder, and `_reorder()` is defined and correct, but no `ReorderableListView` or `ReorderableListView.builder` is used — the list is a plain `for` loop inside a `Column`. Users cannot reorder, but the affordance suggests they can.
**Fix:** Either replace the sport list with `ReorderableListView` and connect `onReorder: _reorder`, or remove the drag handle icon if reorder is not intended for this release:

```dart
// Option A — remove the misleading handle:
// Delete the SizedBox(width:12) + Icon(Icons.drag_handle) block at lines 521-530.

// Option B — wire up ReorderableListView:
ReorderableListView(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  onReorder: _reorder,
  children: [
    for (final sport in _localSports)
      DecoratedBox(
        key: ValueKey(sport),
        // ... existing row content
      ),
  ],
)
```

---

### WR-02: `_syncFromState` silently drops remote updates while `_isDirty`

**File:** `lib/features/admin/ui/settings_tab.dart:376-383`
**Issue:** Once a user makes a local change (`_isDirty = true`), subsequent Firestore updates to the sports list are permanently ignored — even if a different admin saves new data from another session. The dirty guard has no timeout or conflict-resolution path. If the user then saves stale local data, they silently overwrite the newer remote state.

```dart
void _syncFromState(List<String> stateSports) {
  if (!_initialized) {
    _localSports = List<String>.from(stateSports);
    _initialized = true;
  } else if (!_isDirty) {          // ← remote updates dropped when dirty
    setState(() => _localSports = List<String>.from(stateSports));
  }
}
```

**Fix:** After a successful save, `_isDirty` is correctly reset to `false` (line 426), which re-opens the sync window. The real risk is the window between "user edits" and "user saves". For a single-admin panel this is acceptable, but the code should at minimum reset `_isDirty` on dispose if the widget is torn down without saving, to avoid stale data persisting in a rebuild. More robustly, show a conflict banner when remote state diverges from local dirty state:

```dart
} else if (!_isDirty) {
  setState(() => _localSports = List<String>.from(stateSports));
} else if (!_listEquals(_localSports, stateSports)) {
  // Optionally show a warning: "Remote list changed while you were editing."
}
```

---

### WR-03: `_TierEditSheet` saves without validating `fromHour < toHour`

**File:** `lib/features/admin/ui/pricing_tab.dart:561-568`
**Issue:** The "SALVAR" button in `_TierEditSheet` calls `widget.onSave(_draft.copyWith(...))` directly with no local validation. The parent `_PricingEditorState._validate()` does check `toHour <= fromHour`, but that check only runs when the user presses "SALVAR TABELA" — not when they confirm a tier in the sheet. A user can set `DE: 17` and `ATÉ: 08` in the sheet, tap SALVAR, see a visually broken row (e.g. "17:00 → 08:00"), and only get an error later when trying to save the whole table.

```dart
// Current — no pre-check:
onPressed: () => widget.onSave(_draft.copyWith(
  price: double.tryParse(...) ?? _draft.price,
)),
```

**Fix:** Validate before calling `onSave`:

```dart
onPressed: () {
  if (_draft.toHour <= _draft.fromHour) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Horário de fim deve ser maior que o de início.')),
    );
    return;
  }
  widget.onSave(_draft.copyWith(
    price: double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? _draft.price,
  ));
},
```

---

## Info

### IN-01: `Colors.red` and `Colors.transparent` used directly instead of AppTheme tokens

**File:** `lib/features/admin/ui/settings_tab.dart:22`, `lib/features/admin/ui/pricing_tab.dart:40`, `lib/features/admin/ui/pricing_tab.dart:538`
**Issue:** Error text uses `Colors.red` (hardcoded Material color, not the `AppTheme.orangeDk` error token). The day-of-week chip uses `Colors.transparent` for the unselected background — minor but inconsistent.
**Fix:**
```dart
// Error text — use theme error color:
style: const TextStyle(color: AppTheme.orangeDk)

// Unselected chip background — use AppTheme.sand or AppTheme.paper:
color: selected ? AppTheme.ink : AppTheme.sand,
```

---

### IN-02: `NumberFormat.currency` instantiated inside `build()` on every repaint

**File:** `lib/features/admin/ui/pricing_tab.dart:278`
**Issue:** `_TierDisplayRow.build()` creates a new `NumberFormat` instance on every call. This is not a correctness issue but is an unnecessary allocation for a frequently rebuilt widget.
**Fix:** Move to a module-level or class-level constant:
```dart
final _currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');
```

---

### IN-03: `_SportsSectionState._initialized` flag never reset on widget rebuild

**File:** `lib/features/admin/ui/settings_tab.dart:367`
**Issue:** `_initialized` is set to `true` in `_syncFromState` but never reset. If the widget is rebuilt from scratch (e.g. hot-reload, navigation back), it reinitializes from `initState` with an empty list (`const <String>[]`) and only syncs from state on the first BLoC emission — which is correct in practice. However, because `_SportsSection` is a `const _SportsSection()` child with no key, its state is preserved across rebuilds of the parent, which is the intended behavior. This is fine as-is but worth noting if `_SportsSection` ever gets a key or is conditionally rendered.
**Fix:** No immediate action required. Document the intent with a comment:
```dart
// _initialized ensures we only seed _localSports from the BLoC once;
// subsequent remote changes are only applied when !_isDirty.
bool _initialized = false;
```

---

_Reviewed: 2026-06-05_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
