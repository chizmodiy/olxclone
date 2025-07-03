import 'dart:convert';

class ExtraField {
  final String name;
  final String type;
  final List<String>? options;
  final dynamic defaultValue;
  final String? unit;

  ExtraField({
    required this.name,
    required this.type,
    this.options,
    this.defaultValue,
    this.unit,
  });

  factory ExtraField.fromJson(String name, dynamic value) {
    if (value is Map<String, dynamic>) {
      return ExtraField(
        name: name,
        type: value['type'] as String,
        defaultValue: value['default'],
        unit: value['unit'] as String?,
      );
    } else if (value is List) {
      return ExtraField(
        name: name,
        type: 'select',
        options: List<String>.from(value),
      );
    }
    throw FormatException('Invalid extra field format');
  }

  Map<String, dynamic> toJson() {
    if (type == 'select') {
      return {name: options};
    }
    return {
      name: {
        'type': type,
        if (defaultValue != null) 'default': defaultValue,
        if (unit != null) 'unit': unit,
      }
    };
  }
}

class Subcategory {
  final String id;
  final String name;
  final String categoryId;
  final List<ExtraField> extraFields;

  Subcategory({
    required this.id,
    required this.name,
    required this.categoryId,
    this.extraFields = const [],
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    List<ExtraField> extraFields = [];
    if (json['extra_fields'] != null) {
      final Map<String, dynamic> fields = json['extra_fields'];
      extraFields = fields.entries
          .map((entry) => ExtraField.fromJson(entry.key, entry.value))
          .toList();
    }

    return Subcategory(
      id: json['id'],
      name: json['name'],
      categoryId: json['category_id'],
      extraFields: extraFields,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> extraFieldsMap = {};
    for (var field in extraFields) {
      extraFieldsMap.addAll(field.toJson());
    }

    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      if (extraFields.isNotEmpty) 'extra_fields': extraFieldsMap,
    };
  }
} 