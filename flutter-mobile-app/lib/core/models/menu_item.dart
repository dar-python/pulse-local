class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.emoji,
    required this.category,
  });

  final int id;
  final String name;
  final String description;
  final int price;
  final String emoji;
  final String category;
}
