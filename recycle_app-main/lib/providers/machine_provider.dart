import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MachineProvider with ChangeNotifier {
  List<Map<String, dynamic>> _machines = [];
  List<Map<String, dynamic>> _recycledProducts = [];
  Map<String, dynamic>? _analyticsData;
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get machines => _machines;
  List<Map<String, dynamic>> get recycledProducts => _recycledProducts;
  Map<String, dynamic>? get analyticsData => _analyticsData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // URL réelle du backend Render
  final String baseUrl = "https://rvm-backend-oaot.onrender.com";
  // final String baseUrl = "http://localhost:5000"; // Test local Windows Desktop

  // Initialisation à vide (les données viendront de l'API)
  void setInitialMachines(List<Map<String, dynamic>> initialMachines) {
    if (_machines.isEmpty) {
      _machines = List.from(initialMachines);
      notifyListeners();
    }
  }

  // --- MÉTHODES POUR API (Backend) ---

  // 1. Récupérer toutes les machines depuis le serveur
  Future<void> fetchMachines() async {
    _isLoading = true;
    _error = null;
    // On ne notifie pas ici pour éviter de "vider" l'écran avant le chargement
    // notifyListeners();

    try {
      final response = await http.get(Uri.parse('$baseUrl/machine/'));
      print("📡 DEBUG FETCH MACHINES: Code ${response.statusCode}, Body: ${response.body}");
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _machines = data.map((json) => json as Map<String, dynamic>).toList();
      } else {
        _error = "Erreur de chargement: ${response.statusCode}";
      }
    } catch (e) {
      _error = "Erreur réseau: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 1b. Récupérer l'historique des produits recyclés (pour Analytics)
  Future<void> fetchRecycledProducts() async {
    _isLoading = true;
    try {
      final response = await http.get(Uri.parse('$baseUrl/product/'));
      print("📡 DEBUG FETCH PRODUCTS: Code ${response.statusCode}, Body: ${response.body}");
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _recycledProducts = data.map((json) => json as Map<String, dynamic>).toList();
      }
    } catch (e) {
      print("Erreur fetch products: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Ajouter une machine sur le serveur (avec Debug Logs)
  Future<bool> addMachine(Map<String, dynamic> newMachine) async {
    _isLoading = true;
    notifyListeners();

    bool success = false;

    try {
      print("🚀 TENTATIVE D'AJOUT MACHINE: ${json.encode(newMachine)}");

      final response = await http.post(
        Uri.parse('$baseUrl/machine/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(newMachine),
      );

      print("📡 RÉPONSE SERVEUR (Code: ${response.statusCode}): ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Succès : Le serveur a confirmé la sauvegarde
        success = true;
      } else {
        _error = "Erreur d'ajout: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      _error = "Erreur réseau lors de l'ajout: $e";
      print("❌ ERREUR RÉSEAU: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return success;
  }

  // 3. Supprimer une machine sur le serveur
  Future<bool> deleteMachine(String machineId) async {
    bool success = false;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/machine/$machineId'),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _machines.removeWhere((m) => 
          (m['machine_id']?.toString() == machineId) || (m['id']?.toString() == machineId)
        );
        success = true;
      } else {
        _error = "Erreur de suppression: ${response.statusCode}";
      }
    } catch (e) {
      _error = "Erreur réseau: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return success;
  }

  // 4. Récupérer les détails d'une machine spécifique (GET /machine/{id})
  Future<Map<String, dynamic>?> fetchMachineDetails(String machineId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/machine/$machineId'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Erreur fetch machine details: $e");
    }
    return null;
  }

  // 5. Mettre à jour l'état d'une machine (PUT /machine/{id})
  Future<bool> updateMachineStatus(String machineId, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/machine/$machineId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"status": newStatus}),
      );
      if (response.statusCode == 200) {
        // Mettre à jour localement si nécessaire
        await fetchMachines();
        return true;
      }
    } catch (e) {
      print("Erreur update status: $e");
    }
    return false;
  }
  // 6. Récupérer les données Analytics complètes (avec Filtres)
  Future<void> fetchAnalytics({String? city, String? period}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Construction de l'URL avec paramètres si présents
      String url = '$baseUrl/analytics';
      List<String> params = [];
      
      if (city != null && city != 'All' && city != 'all') {
        params.add('city=${Uri.encodeComponent(city)}');
      }
      if (period != null) {
        params.add('period=$period');
      }
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      print("📡 DEBUG FETCH ANALYTICS URL: $url");
      final response = await http.get(Uri.parse(url));
      print("📡 DEBUG FETCH ANALYTICS: Code ${response.statusCode}, Body: ${response.body}");
      
      if (response.statusCode == 200) {
        _analyticsData = json.decode(response.body);
      } else {
        _error = "Erreur Analytics: ${response.statusCode}";
      }
    } catch (e) {
      _error = "Erreur réseau: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 7. Mettre à jour les bacs d'une machine (PUT /machine/bin/update)
  Future<bool> updateBin(String machineId, Map<String, dynamic> binData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/machine/bin/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "machine_id": machineId,
          ...binData
        }),
      );
      if (response.statusCode == 200) {
        await fetchMachines();
        return true;
      }
    } catch (e) {
      print("Erreur update bin: $e");
    }
    return false;
  }
}
