import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginModel extends ChangeNotifier {
  // Champs contrôleurs
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool showPassword = false;
  String? errorMessage;

  // Lien de production Render pour la connexion
  final String apiUrl = "https://rvm-backend-oaot.onrender.com/user/login";
  // final String apiUrl = "http://localhost:5000/user/login";

  void togglePassword() {
    showPassword = !showPassword;
    notifyListeners();
  }

  Future<bool> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      errorMessage = "Veuillez remplir tous les champs.";
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("DEBUG LOGIN RESPONSE: ${response.body}"); // AFFICHE LA RÉPONSE POUR DÉBOGUER

        final prefs = await SharedPreferences.getInstance();
        
        // Sauvegarde de l'email
        await prefs.setString('user_email', email);

        if (data != null) {
          // Récupération du rôle
          final role = data['role'] ?? (data['user'] != null ? data['user']['role'] : null);
          if (role != null) {
            await prefs.setString('user_role', role);
          }

          // Recherche de l'ID utilisateur (très robuste)
          dynamic userId = data['_id'] ?? data['id'] ?? data['userId'];
          if (userId == null && data['user'] != null) {
            userId = data['user']['_id'] ?? data['user']['id'] ?? data['user']['userId'];
          }

          if (userId != null) {
            print("USER ID TROUVÉ ET SAUVEGARDÉ: $userId");
            await prefs.setString('user_id', userId.toString());
          } else {
            print("ATTENTION: Aucun ID utilisateur trouvé dans la réponse JSON.");
          }
        }

        notifyListeners();
        return true;
      } else if (response.statusCode == 400) {
        // Identifiants ou email incorrects selon votre backend
        final data = jsonDecode(response.body);
        errorMessage = data['message'] ?? "Identifiants incorrects.";
        notifyListeners();
        return false;
      } else {
        errorMessage = "Une erreur est survenue (${response.statusCode}).";
        notifyListeners();
        return false;
      }
    } catch (e) {
      isLoading = false;
      errorMessage = "Erreur de connexion : $e";
      notifyListeners();
      return false;
    }
  }

  // --- NOUVEAU : MOT DE PASSE OUBLIÉ ---
  Future<bool> forgotPassword(String email) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(apiUrl.replaceAll("/login", "/forgot-password")),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      isLoading = false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        errorMessage = data['message'] ?? "Erreur lors de la demande.";
        notifyListeners();
        return false;
      }
    } catch (e) {
      isLoading = false;
      errorMessage = "Erreur réseau : $e";
      notifyListeners();
      return false;
    }
  }

  // Ajout d'une méthode pour se déconnecter
  Future<void> logout() async {
    try {
      // Appel HTTP optionnel pour dire au backend de supprimer la session
      await http.post(
        Uri.parse(apiUrl.replaceAll("/login", "/logout")),
        headers: {"Content-Type": "application/json"},
      );
    } catch (e) {
      // Si on n'a pas internet, on force quand même la déconnexion locale
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await prefs.remove('user_email');
    await prefs.remove('user_id');

    // On notifie l'application du changement
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
