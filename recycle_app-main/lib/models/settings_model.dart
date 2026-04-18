class Settings {
  bool pushNotifications;
  bool emailNotifications;
  String language;
  String unit;
  bool darkMode;

  Settings({
    required this.pushNotifications,
    required this.emailNotifications,
    required this.language,
    required this.unit,
    required this.darkMode,
  });

  // Valeurs par défaut lors du premier lancement de l'app
  factory Settings.defaultSettings() {
    return Settings(
      pushNotifications: true,
      emailNotifications: false,
      language: 'Français (FR)',
      unit: 'Kilogrammes (kg)',
      darkMode: false,
    );
  }

  // Convertit un Map (JSON décodé) en objet Settings
  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      pushNotifications: map['pushNotifications'] ?? true,
      emailNotifications: map['emailNotifications'] ?? false,
      language: map['language'] ?? 'Français (FR)',
      unit: map['unit'] ?? 'Kilogrammes (kg)',
      darkMode: map['darkMode'] ?? false,
    );
  }

  // Convertit l'objet Settings en Map pour le sauvegarder en JSON
  Map<String, dynamic> toMap() {
    return {
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'language': language,
      'unit': unit,
      'darkMode': darkMode,
    };
  }
}