import 'dart:convert';
import 'package:abc_app/models/medicine_template_model.dart';
import 'package:flutter/services.dart';

class MedicineDataService {

  // Loads the list of medicines from your local JSON asset
  Future<List<MedicineTemplateModel>> loadMedicineDatabase() async {
    try {
      // 1. Load the string from the asset file
      final String jsonString = await rootBundle.loadString('assets/data/medicine_database.json');

      // 2. Decode the JSON string into a List
      final List<dynamic> jsonList = json.decode(jsonString) as List;

      // 3. Map the list into MedicineTemplateModel objects
      return jsonList.map((json) => MedicineTemplateModel.fromJson(json)).toList();

    } catch (e) {
      print("Error loading medicine database: $e");
      return [];
    }
  }
}