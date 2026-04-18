import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/worker_model.dart';

class WorkerProvider with ChangeNotifier {
  List<Worker> _workers = [];
  Map<String, dynamic>? _dashboardStats;
  bool _isLoading = false;
  String? _error;

  List<Worker> get workers => _workers;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final String baseUrl = "https://rvm-backend-oaot.onrender.com";
  // final String baseUrl = "http://localhost:5000"; // Test local

  // 1. Récupérer tous les travailleurs
  Future<void> fetchWorkers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await fetchDashboardStats(); // Charger les stats en même temps

    try {
      final response = await http.get(Uri.parse('$baseUrl/worker/all'));
      print("📡 DEBUG FETCH ALL WORKERS: Code ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _workers = data.map((item) {
          try {
            return Worker.fromJson(item);
          } catch (e) {
            print("❌ Erreur parsing worker: $e");
            return null;
          }
        }).whereType<Worker>().toList();
        
        print("✅ TOTAL WORKERS CHARGÉS: ${_workers.length}");
      } else {
        _error = "Erreur server: ${response.statusCode}";
      }
    } catch (e) {
      _error = "Erreur réseau: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Ajouter un travailleur (Create User)
  Future<bool> addWorker(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/worker/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchWorkers(); // Rafraîchir la liste
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['message'] ?? "Erreur d'ajout: ${response.statusCode}";
        return false;
      }
    } catch (e) {
      _error = "Erreur réseau: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. Supprimer un travailleur
  Future<bool> deleteWorker(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/worker/delete/$id'),
      );

      if (response.statusCode == 200) {
        _workers.removeWhere((w) => w.id == id);
        return true;
      } else {
        _error = "Erreur de suppression";
        return false;
      }
    } catch (e) {
      _error = "Erreur réseau";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // 4. Mettre à jour le statut
  Future<bool> updateStatus(String id, String status) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/worker/update-status/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"status": status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 5. Récupérer les statistiques du Dashboard
  Future<void> fetchDashboardStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/worker/stats/dashboard'));
      if (response.statusCode == 200) {
        _dashboardStats = json.decode(response.body);
      }
    } catch (e) {
      print("Erreur fetch dashboard stats: $e");
    }
  }

  // 6. Assigner des machines à un travailleur (Réel)
  Future<bool> assignMachine(String workerId, List<String> machineIds, {String taskType = "maintenance"}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/worker/assign'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "workerId": workerId,
          "machineIds": machineIds,
          "taskType": taskType,
        }),
      );

      print("📡 DEBUG ASSIGN Worker: Code ${response.statusCode}, Body: ${response.body}");
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Optionnel : recharger les données pour voir les changements
        await fetchWorkers();
        return true;
      }
      return false;
    } catch (e) {
      print("Erreur assignation: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // 7. Récupérer l'historique d'un travailleur (Réel)
  Future<Map<String, dynamic>?> fetchWorkerHistory(String workerId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/worker/history/$workerId'));
      print("📡 DEBUG FETCH WORKER HISTORY: Code ${response.statusCode}, Body: ${response.body}");
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print("Erreur fetch worker history: $e");
      return null;
    }
  }

  // 8. Récupérer le profil complet d'un travailleur (Réel)
  Future<Map<String, dynamic>?> fetchWorkerProfile(String workerId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/worker/profile/$workerId'));
      print("📡 DEBUG FETCH WORKER PROFILE: Code ${response.statusCode}, Body: ${response.body}");
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print("Erreur fetch worker profile: $e");
      return null;
    }
  }

  // 9. Mettre à jour le profil d'un travailleur
  Future<bool> updateWorkerProfile(String workerId, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/worker/update/$workerId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      print("📡 DEBUG UPDATE WORKER PROFILE: Code ${response.statusCode}, Body: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      print("Erreur update worker profile: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 10. Obtenir les travailleurs filtrés par rôle et qui sont "Actif"
  List<Worker> getAvailableWorkers(WorkerRole role) {
    return _workers
        .where((w) => w.role == role && w.status == WorkerStatus.available)
        .toList();
  }
}
