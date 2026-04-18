import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardPageModel extends ChangeNotifier {
  /// ---------------- STATE FIELDS ----------------

  // Choice pour filtrer par type de machine ou objet
  String? selectedChoice;

  // Statistiques dynamiques (Backend)
  double totalAluminum = 0.0;
  double totalPlastic = 0.0;
  int totalMachines = 0;
  
  bool isLoading = false;
  String? error;

  // Statistiques dynamiques (Legacy/Simulé)
  int bouteillesRecyclees = 2847;
  int machinesActives = 24;
  int alertesEnCours = 3;

  final String statsUrl = "https://rvm-backend-oaot.onrender.com/machine/stats";

  // ... (rest of maintenance and transactions) ...
  
  // Transactions simulées
  List<Map<String, dynamic>> transactions = [
    {
      "name": "Marie Dubois",
      "desc": "5 bouteilles • +0.25€",
      "time": "14:32",
      "color": Colors.green,
    },
    {
      "name": "Jean Martin",
      "desc": "3 canettes • +0.15€",
      "time": "14:28",
      "color": Colors.blue,
    },
    {
      "name": "Sophie Leroy",
      "desc": "2 bouteilles verre • +0.20€",
      "time": "14:15",
      "color": Colors.orange,
    },
  ];

  // Maintenance simulée
  List<Map<String, dynamic>> maintenance = [
    {"machine": "Machine #1", "time": "Dans 1 heure", "color": Colors.green},
    {"machine": "Machine #2", "time": "Dans 30 min", "color": Colors.orange},
    {
      "machine": "Machine #3",
      "time": "Maintenance programmée",
      "color": Colors.blue,
    },
  ];

  /// ---------------- DONNÉES GRAPHIQUES ----------------

  // Bouteilles recyclées par jour de la semaine
  List<int> bouteillesParJour = [30, 45, 25, 50, 70, 40, 60];

  // Répartition des machines par type (ex: bouteilles, canettes, verre)
  List<int> machinesParType = [12, 8, 4];

  // Historique mensuel des transactions (pour line chart)
  List<int> transactionsParMois = [120, 150, 130, 170, 200, 180];

  /// ---------------- METHODS ----------------

  Future<void> fetchStats() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(statsUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Adaptation selon la structure réelle du backend
        totalMachines = data['machines']?['value'] ?? 0;
        totalPlastic = (data['plastique']?['value'] ?? 0).toDouble();
        totalAluminum = (data['aluminium']?['value'] ?? 0).toDouble();
        
        // Optionnel: Mettre à jour aussi les champs existants
        machinesActives = totalMachines;
      } else {
        error = "Erreur: ${response.statusCode}";
      }
    } catch (e) {
      error = "Erreur de connexion : $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void updateChoice(String choice) {
    selectedChoice = choice;
    notifyListeners();
  }

  void updateStats({int? bouteilles, int? machines, int? alertes}) {
    if (bouteilles != null) bouteillesRecyclees = bouteilles;
    if (machines != null) machinesActives = machines;
    if (alertes != null) alertesEnCours = alertes;
    notifyListeners();
  }

  void addTransaction(Map<String, dynamic> transaction) {
    transactions.insert(0, transaction);
    notifyListeners();
  }

  void addMaintenance(Map<String, dynamic> maint) {
    maintenance.add(maint);
    notifyListeners();
  }

  void updateGraphData({
    List<int>? bouteillesSemaine,
    List<int>? machinesTypes,
    List<int>? transactionsMois,
  }) {
    if (bouteillesSemaine != null) bouteillesParJour = bouteillesSemaine;
    if (machinesTypes != null) machinesParType = machinesTypes;
    if (transactionsMois != null) transactionsParMois = transactionsMois;
    notifyListeners();
  }
}
