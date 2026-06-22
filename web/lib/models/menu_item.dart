class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imagePath;
  final bool isSpicy;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imagePath,
    this.isSpicy = false,
  });
}
