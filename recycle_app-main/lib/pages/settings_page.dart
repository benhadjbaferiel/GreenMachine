import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          settings.translate('settings'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION PROFIL ---

            // --- SECTION APPARENCE ---
            _buildSectionHeader('APPARENCE'),
            _buildSettingsCard([
              _buildSettingTile(
                icon: isDark ? Icons.dark_mode : Icons.light_mode,
                title: settings.translate('dark_mode'),
                trailing: Switch(
                  value: settings.isDarkMode,
                  onChanged: (val) => settings.toggleTheme(val),
                  activeColor: Colors.green,
                ),
              ),
              _buildSettingTile(
                icon: Icons.language,
                title: settings.translate('language'),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: settings.languageName,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    items: ['Français', 'English', 'العربية']
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) settings.setLanguage(val);
                    },
                  ),
                ),
                isLast: true,
              ),
            ]),

            // --- SECTION SÉCURITÉ ---
            _buildSectionHeader(settings.translate('security')),
            _buildSettingsCard([
              _buildSettingTile(
                icon: Icons.lock_outline,
                title: settings.translate('change_password'),
                onTap: () => _showPasswordDialog(context, settings),
                isLast: true,
              ),
            ]),

            const SizedBox(height: 30),
            Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.green[700],
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.green),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: subtitle != null ? Text(subtitle) : null,
          trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
          onTap: onTap,
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 56,
            endIndent: 20,
            color: Colors.black12,
          ),
      ],
    );
  }

  // --- DIALOGUE CHANGER MOT DE PASSE (FONCTIONNEL & PREMIUM) ---
  void _showPasswordDialog(BuildContext context, SettingsProvider settings) {
    _oldPassController.clear();
    _newPassController.clear();
    _confirmPassController.clear();

    bool isOldPassCorrect = false;
    bool passwordsMatch = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void validate() {
            setModalState(() {
              // On vérifie simplement que le champ n'est pas vide.
              // La validation réelle se fera côté backend lors de la soumission.
              isOldPassCorrect = _oldPassController.text.isNotEmpty;
              passwordsMatch =
                  _newPassController.text.isNotEmpty &&
                  _newPassController.text == _confirmPassController.text;
            });
          }

          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: Colors.green,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  settings.translate('change_password'),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Sécurisez votre compte en mettant à jour votre mot de passe.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  _buildPasswordField(
                    controller: _oldPassController,
                    label: settings.translate('old_password'),
                    onChanged: (_) => validate(),
                    // Suppression de la coche verte ici pour éviter de mentir à l'utilisateur
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: _newPassController,
                    label: settings.translate('new_password'),
                    onChanged: (_) => validate(),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: _confirmPassController,
                    label: settings.translate('confirm_password'),
                    onChanged: (_) => validate(),
                    suffix:
                        passwordsMatch && _confirmPassController.text.isNotEmpty
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                  if (_confirmPassController.text.isNotEmpty && !passwordsMatch)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "Les mots de passe ne correspondent pas",
                        style: TextStyle(color: Colors.red, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  settings.translate('cancel'),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(100, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                onPressed: (isOldPassCorrect && passwordsMatch)
                    ? () => _handleChangePassword(context, settings)
                    : null,
                child: Text(
                  settings.translate('save'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required Function(String) onChanged,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  // LOGIQUE DE CHANGEMENT DE MOT DE PASSE (RÉELLE)
  Future<void> _handleChangePassword(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final oldPass = _oldPassController.text;
    final newPass = _newPassController.text;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.green)),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email') ?? "test@ttest.com";

      final response = await http.put(
        Uri.parse('https://rvm-backend-oaot.onrender.com/user/change-password'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email":
              email, // Retour à l'email comme identifiant (Confirmé par Postman)
          "oldPassword": oldPass,
          "newPassword": newPass,
        }),
      );

      if (mounted) Navigator.pop(context); // Fermer le loading

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context); // Fermer la dialogue
          _showSnackBar(
            context,
            settings.translate('success_password'),
            Colors.green,
          );
        }
      } else {
        final data = jsonDecode(response.body);
        _showSnackBar(
          context,
          data['message'] ?? "Erreur lors du changement de mot de passe",
          Colors.red,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Fermer le loading
      _showSnackBar(context, "Erreur réseau : $e", Colors.red);
    }
  }

  void _showSnackBar(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }
}
