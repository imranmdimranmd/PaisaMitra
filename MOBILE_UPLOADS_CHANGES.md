# mobile-uploads branch — changes in this drop

## How to apply
```bash
git clone <your repo url>
cd paisa-mitra
git checkout tst
git checkout -b mobile-uploads
# unzip this archive's contents over the working tree, overwriting files
git add .
git commit -m "Add category/subcategory edit + chart drill-down to transactions"
git push -u origin mobile-uploads
```

## What changed

1. **Edit category / subcategory** (`lib/screens/categories_screen.dart`)
   - Each category and subcategory row now has an edit (pencil) icon next to
     the existing delete icon, opening a rename dialog.
   - The default "Other" category is excluded from edit/delete, since it's
     the hard-coded fallback used when adding a new transaction
     (`lib/screens/new_transaction.dart`).

2. **Cascading rename** (`lib/DBhelp/dbhelper.dart`, `lib/models/categories.dart`)
   - `DBHelper.updateCategory` / `updateSubcategory` rename the row in
     `categories`/`subcategories` **and** update every `transactions` row
     that referenced the old name, all inside one DB transaction.
   - `Categories.update` / `updateSubcategory` call these and refresh
     provider state; `categories_screen.dart` then calls
     `Transactions.fetchTransactions()` so the in-memory transaction list
     picks up the renamed text immediately.

3. **Tap a chart slice to see its transactions**
   (`lib/screens/statistics/pie_chart.dart`,
   `lib/widgets/pie_chart_widgets/indicators_widget.dart`,
   `lib/screens/transactions/category_transactions_screen.dart`)
   - `MyPieChart` now accepts `sourceTransactions` + `byCategory`. Tapping a
     slice (or its legend entry) opens a new `CategoryTransactionsScreen`
     listing every transaction in that category/subcategory, reusing the
     existing `GroupedTransactionList` (date-grouped, running total, delete
     support).
   - Wired into all four chart screens: `daily_spendings.dart`,
     `weekly_spendings.dart`, `monthly_spendings.dart`,
     `yearly_spendings.dart`.

## Not yet done
- No automated tests were added; `flutter analyze` / `flutter test` should
  be run locally before merging (no Flutter toolchain was available in the
  environment this patch was produced in).
