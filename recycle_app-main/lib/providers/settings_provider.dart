import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('fr'); // Par défaut en Français
  String _languageName = 'Français';

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  String get languageName => _languageName;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  SettingsProvider() {
    _loadSettings();
  }

  // Charger les paramètres depuis SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Charger le thème
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    // Charger la langue
    _languageName = prefs.getString('languageName') ?? 'Français';
    _updateLocale(_languageName);

    notifyListeners();
  }

  // Basculer le Dark Mode
  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  // Changer la langue
  Future<void> setLanguage(String lang) async {
    _languageName = lang;
    _updateLocale(lang);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageName', lang);
  }

  void _updateLocale(String lang) {
    if (lang == 'English') {
      _locale = const Locale('en');
    } else if (lang == 'العربية') {
      _locale = const Locale('ar');
    } else {
      _locale = const Locale('fr');
    }
  }

  // --- TRADUCTIONS SIMPLIFIÉES (MOCK) ---
  // Note: Idéalement utiliser easy_localization, mais on simule ici pour la démo
  String translate(String key) {
    final Map<String, Map<String, String>> translations = {
      'fr': {
        'settings': 'Paramètres',
        'dark_mode': 'Mode Sombre',
        'language': 'Langue',
        'change_password': 'Changer mot de passe',
        'security': 'Sécurité',
        'profile': 'Profil',
        'save': 'Enregistrer',
        'cancel': 'Annuler',
        'old_password': 'Ancien mot de passe',
        'new_password': 'Nouveau mot de passe',
        'confirm_password': 'Confirmer mot de passe',
        'success_password': 'Mot de passe modifié avec succès !',
        'error_old_password': 'L\'ancien mot de passe est incorrect.',
        'error_match': 'Les mots de passe ne correspondent pas.',
        // Dashboard
        'dashboard': 'Tableau de Bord',
        'machines': 'Machines',
        'clients': 'Travailleurs',
        'analytics': 'Analyses',
        'logout': 'Déconnexion',
        'total_machines': 'Total Machines',
        'plastic': 'Plastique',
        'aluminum': 'Aluminium',
        // Clients & Analytics
        'search': 'Rechercher...',
        'client_management': 'Gestion des Clients',
        'export': 'Exporter',
        'critical_alerts': 'Alertes Critiques',
        'detailed_inventory': 'Inventaire Détaillé',
        // Login
        'login': 'Connexion',
        'email_address': 'Adresse email',
        'password': 'Mot de passe',
        'forgot_password': 'Mot de passe oublié ?',
        'login_subtitle': 'Accédez à votre tableau de bord',
        'login_descriptor': 'Optimisez vos machines de recyclage avec notre plateforme de monitoring avancée',
        'intelligent_supervision': 'Supervision Intelligente',
        'real_time_monitoring': 'Surveillance en temps réel',
        'control_efficiency': 'Contrôlez l\'efficacité de vos équipements',
      },
      'en': {
        'settings': 'Settings',
        'dark_mode': 'Dark Mode',
        'language': 'Language',
        'change_password': 'Change Password',
        'security': 'Security',
        'profile': 'Profile',
        'save': 'Save',
        'cancel': 'Cancel',
        'old_password': 'Old Password',
        'new_password': 'New Password',
        'confirm_password': 'Confirm Password',
        'success_password': 'Password changed successfully!',
        'error_old_password': 'Old password is incorrect.',
        'error_match': 'Passwords do not match.',
        // Dashboard
        'dashboard': 'Dashboard',
        'machines': 'Machines',
        'clients': 'Workers',
        'analytics': 'Analytics',
        'logout': 'Logout',
        'total_machines': 'Total Machines',
        'plastic': 'Plastic',
        'aluminum': 'Aluminum',
        // Clients & Analytics
        'search': 'Search...',
        'client_management': 'Client Management',
        'export': 'Export',
        'critical_alerts': 'Critical Alerts',
        'detailed_inventory': 'Detailed Inventory',
        // Login
        'login': 'Login',
        'email_address': 'Email address',
        'password': 'Password',
        'forgot_password': 'Forgot password?',
        'login_subtitle': 'Access your dashboard',
        'login_descriptor': 'Optimize your recycling machines with our advanced monitoring platform',
        'intelligent_supervision': 'Intelligent Supervision',
        'real_time_monitoring': 'Real-time monitoring',
        'control_efficiency': 'Control your equipment efficiency',
      },
      'ar': {
        'settings': 'الإعدادات',
        'dark_mode': 'الوضع الليلي',
        'language': 'اللغة',
        'change_password': 'تغيير كلمة المرور',
        'security': 'الأمان',
        'profile': 'الملف الشخصي',
        'save': 'حفظ',
        'cancel': 'إلغاء',
        'old_password': 'كلمة المرور القديمة',
        'new_password': 'كلمة المرور الجديدة',
        'confirm_password': 'تأكيد كلمة المرور',
        'success_password': 'تم تغيير كلمة المرور بنجاح!',
        'error_old_password': 'كلمة المرور القديمة غير صحيحة.',
        'error_match': 'كلمات المرور غير متطابقة.',
        // Dashboard
        'dashboard': 'لوحة التحكم',
        'machines': 'الآلات',
        'clients': 'العمال',
        'analytics': 'تحليلات',
        'logout': 'تسجيل الخروج',
        'total_machines': 'إجمالي الآلات',
        'plastic': 'بلاستيك',
        'aluminum': 'ألومنيوم',
        // Clients & Analytics
        'search': 'بحث...',
        'client_management': 'إدارة العملاء',
        'export': 'تصدير',
        'critical_alerts': 'تنبيهات حرجة',
        'detailed_inventory': 'جرد مفصل',
        // Login
        'login': 'تسجيل الدخول',
        'email_address': 'البريد الإلكتروني',
        'password': 'كلمة المرور',
        'forgot_password': 'نسيت كلمة المرور؟',
        'login_subtitle': 'الوصول إلى لوحة التحكم الخاصة بك',
        'login_descriptor': 'قم بتحسين آلات إعادة التدوير الخاصة بك من خلال منصة المراقبة المتقدمة الخاصة بنا',
        'intelligent_supervision': 'إشراف ذكي',
        'real_time_monitoring': 'مراقبة في الوقت الحقيقي',
        'control_efficiency': 'التحكم في كفاءة المعدات الخاصة بك',
      },
    };

    return translations[_locale.languageCode]?[key] ?? key;
  }
}
