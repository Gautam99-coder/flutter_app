// This model is ONLY for the local JSON file
class MedicineTemplateModel {
  final String name;
  final String description;
  final String category;

  MedicineTemplateModel({
    required this.name,
    required this.description,
    required this.category,
  });

  factory MedicineTemplateModel.fromJson(Map<String, dynamic> json) {
    return MedicineTemplateModel(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
    );
  }
}