class Category {
  Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    required this.parentId,
  });

  final String id;
  final String name;
  final String slug;
  final String icon;
  final String? parentId;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      parentId: json['parentId']?.toString(),
    );
  }
}
