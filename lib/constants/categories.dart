const List<String> defaultCategories = [
  'Food',
  'Social Life',
  'Self-development',
  'Transportation',
  'Culture',
  'Household',
  'Apparel',
  'Beauty',
  'Health',
  'Education',
  'Gift',
  'Other',
];

/// Default subcategories seeded for each default category.
/// Users can add/remove their own subcategories on top of these.
const Map<String, List<String>> defaultSubcategories = {
  'Food': ['Groceries', 'Restaurant', 'Snacks'],
  'Social Life': ['Movies', 'Outing', 'Gifts'],
  'Self-development': ['Books', 'Courses'],
  'Transportation': ['Fuel', 'Public Transport', 'Cab'],
  'Culture': ['Events', 'Museum'],
  'Household': ['Rent', 'Utilities', 'Maintenance'],
  'Apparel': ['Clothing', 'Footwear'],
  'Beauty': ['Salon', 'Cosmetics'],
  'Health': ['Medicine', 'Doctor'],
  'Education': ['Fees', 'Supplies'],
  'Gift': ['Birthday', 'Festival'],
  'Other': ['Miscellaneous'],
};

