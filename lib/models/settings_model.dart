class SettingsModel {
  final bool pushNotifications;
  final bool darkMode;
  final bool locationServices;

  SettingsModel({
    required this.pushNotifications,
    required this.darkMode,
    required this.locationServices,
  });

  Map<String, dynamic> toMap() {
    return {
      'pushNotifications': pushNotifications,
      'darkMode': darkMode,
      'locationServices': locationServices,
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      pushNotifications: map['pushNotifications'] ?? true,
      darkMode: map['darkMode'] ?? false,
      locationServices: map['locationServices'] ?? true,
    );
  }

  SettingsModel copyWith({
    bool? pushNotifications,
    bool? darkMode,
    bool? locationServices,
  }) {
    return SettingsModel(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      darkMode: darkMode ?? this.darkMode,
      locationServices: locationServices ?? this.locationServices,
    );
  }
}