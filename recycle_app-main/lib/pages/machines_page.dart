import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../providers/machine_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';

class MachinesPage extends StatefulWidget {
  const MachinesPage({super.key});

  @override
  State<MachinesPage> createState() => _MachinesPageState();
}

class _MachinesPageState extends State<MachinesPage> {
  final Color darkGreen = const Color(0xFF064E3B);

  String searchQuery = "";
  String statusFilter = "Tous";

  final TextEditingController idController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController latController = TextEditingController();
  final TextEditingController lonController = TextEditingController();
  String? machineType;
  String? machineLocation;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<String> typeOptions = ["Petit", "Grand"];
  final List<String> locationOptions = [
    "Institut",
    "Restaurant",
    "Centre commercial",
    "Espace public",
    "Usine",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MachineProvider>(context, listen: false).fetchMachines();
    });
  }

  String _mapUIToBackend(String uiStatus) {
    switch (uiStatus) {
      case "online":
        return "actif";
      case "offline":
        return "inactif";
      case "en panne":
        return "en_panne";
      default:
        return "actif";
    }
  }

  String _mapBackendToUI(String backendStatus) {
    switch (backendStatus.toLowerCase()) {
      case "actif":
        return "online";
      case "inactif":
        return "offline";
      case "en_panne":
        return "en panne";
      default:
        return "online";
    }
  }

  Widget _buildStatusFilters() {
    final filters = ["Tous", "En ligne", "Hors ligne", "En panne"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: filters.map((f) {
        bool isSelected = statusFilter == f;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(
              f,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey[700],
              ),
            ),
            selected: isSelected,
            onSelected: (val) => setState(() => statusFilter = f),
            selectedColor: const Color(0xFFD1FAE5),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isSelected ? Colors.transparent : Colors.grey[300]!,
              ),
            ),
            showCheckmark: isSelected,
          ),
        );
      }).toList(),
    );
  }

  void _showAddMachineDialog() {
    _clearInputs();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final provider = Provider.of<MachineProvider>(context);
          final isDark = Provider.of<SettingsProvider>(context).isDarkMode;
          final Color dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
          final Color textColor = isDark ? Colors.white : darkGreen;

          return Dialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              constraints: const BoxConstraints(maxWidth: 800),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Ajouter une Machine",
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildField(idController, "ID Machine", Icons.fingerprint, isDark,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return "Veuillez entrer l'ID Machine.";
                        if (int.tryParse(value.trim()) == null) return "L'ID doit être numérique.";
                        return null;
                      },
                    ),
                    _buildField(nameController, "Nom", Icons.settings, isDark,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return "Veuillez entrer le nom.";
                        return null;
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(latController, "Latitude (-90 à 90)", Icons.location_on, isDark,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return "Veuillez entrer la latitude.";
                              final lat = double.tryParse(value.trim());
                              if (lat == null) return "Valeur numérique requise.";
                              if (lat < -90 || lat > 90) return "Entre -90 et 90.";
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildField(lonController, "Longitude (-180 à 180)", Icons.location_on, isDark,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return "Veuillez entrer la longitude.";
                              final lng = double.tryParse(value.trim());
                              if (lng == null) return "Valeur numérique requise.";
                              if (lng < -180 || lng > 180) return "Entre -180 et 180.";
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    _buildDropdown(
                      "Type de Machine",
                      Icons.aspect_ratio,
                      machineType,
                      typeOptions,
                      (v) => setModalState(() => machineType = v),
                      isDark,
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Veuillez choisir un type.";
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildDropdown(
                      "Emplacement",
                      Icons.location_on,
                      machineLocation,
                      locationOptions,
                      (v) => setModalState(() => machineLocation = v),
                      isDark,
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Veuillez choisir un emplacement.";
                        return null;
                      },
                    ),
                    const SizedBox(height: 35),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        onPressed: provider.isLoading
                            ? null
                            : () => _handleSave(setModalState),
                        child: provider.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "ENREGISTRER",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    bool isDark, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.white60 : Colors.grey[700],
          ),
          prefixIcon: Icon(
            icon,
            color: isDark ? Colors.white60 : Colors.grey[700],
          ),
          filled: true,
          fillColor: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFF3F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    IconData icon,
    String? value,
    List<String> options,
    Function(String?) onChanged,
    bool isDark, {
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white60 : Colors.grey[700],
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white60 : Colors.grey[700],
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: options
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Future<Map<String, String>> _getLocationData(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String wilaya =
            place.administrativeArea ??
            place.subAdministrativeArea ??
            place.locality ??
            "";
        String street = place.street ?? "";
        String subLocality = place.subLocality ?? "";
        String locality = place.locality ?? "";
        String address = "$street $subLocality $locality".trim();
        if (wilaya.isNotEmpty && address.isNotEmpty) {
          return {"city": wilaya, "address": address};
        }
      }
    } catch (e) {
      print("DEBUG: Geocoding natif ignoré, passage au fallback Web.");
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&addressdetails=1&accept-language=fr',
        ),
        headers: {'User-Agent': 'RecycleApp/1.0'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addr = data['address'];
        if (addr != null) {
          String wilaya =
              addr['province'] ??
              addr['state'] ??
              addr['county'] ??
              addr['city'] ??
              "Inconnu";
          String displayName = data['display_name'] ?? "";
          String address = displayName;
          if (displayName.contains(",")) {
            List<String> parts = displayName.split(",");
            if (parts.length > 3) {
              address =
                  "${parts[0].trim()}, ${parts[1].trim()}, ${parts[2].trim()}";
            }
          }
          return {"city": wilaya, "address": address};
        }
      }
    } catch (e) {
      print("Erreur Fallback OSM: $e");
    }

    return {"city": "Inconnu", "address": "N/A"};
  }

  Future<void> _launchURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Impossible d'ouvrir le lien: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSave(StateSetter setModalState) async {
    // Valider tous les champs via le Form — chaque champ affiche son erreur
    if (!_formKey.currentState!.validate()) return;

    double lat = double.parse(latController.text.trim());
    double lng = double.parse(lonController.text.trim());

    Map<String, String> locationData = await _getLocationData(lat, lng);

    final String serverType = machineType!.toLowerCase();
    final String serverLocation = machineLocation!.toLowerCase();

    final newMachine = {
      "machine_id": idController.text.trim(),
      "name": nameController.text.trim(),
      "latitude": lat,
      "longitude": lng,
      "city": locationData['city'],
      "address": locationData['address'],
      "type": serverType,
      "location_type": serverLocation,
      "status": "actif",
    };

    bool ok = await Provider.of<MachineProvider>(
      context,
      listen: false,
    ).addMachine(newMachine);
    if (ok && mounted) {
      await Provider.of<MachineProvider>(
        context,
        listen: false,
      ).fetchMachines();
      Navigator.pop(context);
      _clearInputs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Machine ajoutée !"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _clearInputs() {
    idController.clear();
    nameController.clear();
    latController.clear();
    lonController.clear();
    machineType = null;
    machineLocation = null;
  }

  void _showMachineDetails(
    String machineId,
    Map<String, dynamic> initialData,
  ) async {
    final provider = Provider.of<MachineProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<Map<String, dynamic>?>(
        future: provider.fetchMachineDetails(machineId),
        builder: (context, snapshot) {
          final machine = snapshot.data ?? initialData;
          final bool loading =
              snapshot.connectionState == ConnectionState.waiting;
          final isDark = Provider.of<SettingsProvider>(
            context,
            listen: false,
          ).isDarkMode;
          String currentBackendStatus = (machine['status'] ?? 'actif')
              .toString()
              .toLowerCase();

          return StatefulBuilder(
            builder: (context, setModalState) => Dialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                machine['name'] ?? 'Machine',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : darkGreen,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              _buildStatusBadge(currentBackendStatus),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            size: 20,
                            color: isDark ? Colors.white60 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    if (loading) const LinearProgressIndicator(minHeight: 2),
                    const Divider(),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 380,
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          _detailItem(Icons.fingerprint, "ID Machine",
                              machine['machine_id'] ?? machine['id'] ?? 'S/N', isDark),
                          _detailItem(Icons.settings, "Nom",
                              machine['name'] ?? 'N/A', isDark),
                          _detailItem(Icons.location_on_outlined, "Latitude",
                              machine['latitude']?.toString() ?? '0.0', isDark),
                          _detailItem(Icons.location_on_outlined, "Longitude",
                              machine['longitude']?.toString() ?? '0.0', isDark),
                          _detailItem(Icons.aspect_ratio_outlined, "Type",
                              machine['type']?.toString().toUpperCase() ?? 'N/A', isDark),
                          _detailItem(
                            Icons.business_outlined,
                            "Lieu",
                            (machine['location_type']?.toString().replaceAll("_", " ") ?? 'N/A').toUpperCase(),
                            isDark,
                          ),
                          _detailItem(Icons.map_outlined, "Wilaya",
                              machine['city']?.toString() ?? 'Inconnu', isDark),
                          _detailItem(Icons.location_on_outlined, "Adresse",
                              machine['address']?.toString() ?? 'N/A', isDark),
                          _detailItem(Icons.inventory_2_outlined, "Remplissage",
                              "${machine['current_fill']?.toString() ?? '0'} kg", isDark),
                          _detailItem(Icons.info_outline, "Statut",
                              _mapBackendToUI(currentBackendStatus).toUpperCase(), isDark),
                          _detailPhotoLink(machine['photo_url']?.toString(), isDark),
                          _detailItem(
                            Icons.auto_awesome_outlined,
                            "Précision AI",
                            "${(double.tryParse(machine['ai_accuracy']?.toString() ?? '0') ?? 0).toStringAsFixed(1)}%",
                            isDark,
                          ),
                          _detailItem(Icons.calendar_today_outlined, "Créé le",
                              _formatDate(machine['created_at']), isDark),
                          _detailItem(Icons.history_outlined, "Modifié le",
                              _formatDate(machine['updated_at']), isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    Text(
                      "CHANGER LE STATUT",
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white60 : Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ["online", "offline", "en panne"].map((s) {
                        bool isSel = _mapBackendToUI(currentBackendStatus) == s;
                        Color sCol = s == "online"
                            ? Colors.green
                            : (s == "offline" ? Colors.orange : Colors.red);
                        return ChoiceChip(
                          label: Text(
                            s.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: isSel ? Colors.white : sCol,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: sCol,
                          backgroundColor: sCol.withOpacity(0.1),
                          side: BorderSide(color: sCol.withOpacity(0.5)),
                          onSelected: (val) async {
                            if (val) {
                              String backendStatus = _mapUIToBackend(s);
                              bool ok = await provider.updateMachineStatus(
                                machineId,
                                backendStatus,
                              );
                              if (ok && mounted) {
                                await provider.fetchMachines();
                                setModalState(
                                  () => currentBackendStatus = backendStatus,
                                );
                              }
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 📜 HISTORIQUE DES NOTIFICATIONS D'UNE MACHINE
  // ─────────────────────────────────────────────────────────────
  void _showMachineHistory(String machineMongoId, String machineName) {
    final notifProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    final isDark =
        Provider.of<SettingsProvider>(context, listen: false).isDarkMode;

    // Future lancé une seule fois pour éviter les re-calls lors de setState
    final historyFuture = notifProvider.fetchMachineHistory(machineMongoId);

    showDialog(
      context: context,
      builder: (dialogContext) {
        String typeFilter = "Tous";
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Dialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── HEADER ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Historique Alertes",
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : darkGreen,
                              ),
                            ),
                            Text(
                              machineName,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white54 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: Icon(
                            Icons.close,
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── FILTRES PAR TYPE ──
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ["Tous", "En panne", "Remplissage"].map((f) {
                          final bool sel = typeFilter == f;
                          final Color chipColor = f == "En panne"
                              ? Colors.red
                              : f == "Remplissage"
                                  ? Colors.orange
                                  : Colors.green;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                f,
                                style: TextStyle(
                                  color: sel ? Colors.white : chipColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              selected: sel,
                              selectedColor: chipColor,
                              backgroundColor: chipColor.withOpacity(0.1),
                              side: BorderSide(color: chipColor.withOpacity(0.4)),
                              showCheckmark: false,
                              onSelected: (_) =>
                                  setModalState(() => typeFilter = f),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(
                      height: 1,
                      color: isDark ? Colors.white12 : Colors.grey[300],
                    ),
                    const SizedBox(height: 8),

                    // ── LISTE NOTIFICATIONS ──
                    FutureBuilder<List<dynamic>>(
                      future: historyFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 30),
                            child: Center(
                              child: Text(
                                "Erreur de chargement",
                                style: TextStyle(color: Colors.red[400]),
                              ),
                            ),
                          );
                        }

                        final all = snapshot.data ?? [];
                        final filtered = all.where((n) {
                          if (typeFilter == "Tous") return true;
                          final t = (n['type'] ?? '').toString().toLowerCase();
                          if (typeFilter == "En panne") return t.contains('panne');
                          if (typeFilter == "Remplissage")
                            return t.contains('remplissage');
                          return true;
                        }).toList();

                        if (filtered.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 35),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.history_toggle_off,
                                      size: 44, color: Colors.grey[400]),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Aucun historique",
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 360),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: isDark ? Colors.white12 : Colors.grey[200],
                            ),
                            itemBuilder: (context, i) {
                              final n = filtered[i];
                              final String type =
                                  (n['type'] ?? 'info').toString();
                              final String msg = n['message'] ?? '';
                              final String status =
                                  (n['status'] ?? 'envoyée').toString();
                              final bool isRead = status == 'traitée';

                              IconData ico = Icons.notifications_outlined;
                              Color icoColor = Colors.blue;
                              if (type.contains('panne')) {
                                ico = Icons.error_outline;
                                icoColor = Colors.red;
                              } else if (type.contains('remplissage')) {
                                ico = Icons.battery_charging_full_outlined;
                                icoColor = Colors.orange;
                              }

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: icoColor.withOpacity(0.1),
                                      child: Icon(ico, color: icoColor, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                type.toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isRead
                                                      ? Colors.green
                                                          .withOpacity(0.12)
                                                      : Colors.orange
                                                          .withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  isRead ? "TRAITÉ" : "EN ATTENTE",
                                                  style: TextStyle(
                                                    color: isRead
                                                        ? Colors.green
                                                        : Colors.orange,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            msg,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black87,
                                            ),
                                          ),
                                          if (n['technician'] != null && n['technician'].toString().isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              "Technicien: ${n['technician']}",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.blue[300] : Colors.blue[700],
                                              ),
                                            ),
                                          ],
                                          if (n['collector'] != null && n['collector'].toString().isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              "Collecteur: ${n['collector']}",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.orange[300] : Colors.orange[800],
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time,
                                                  size: 10, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDate(n['created_at']),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.green;
    if (status == "inactif") color = Colors.orange;
    if (status == "en_panne") color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        _mapBackendToUI(status).toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark ? const Color(0xFF10B981) : darkGreen,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.blueGrey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailPhotoLink(String? url, bool isDark) {
    final String commonDriveLink =
        "https://drive.google.com/drive/folders/1JXPNgvA3AEIoSYj5CqVkeVlgIOkUv5s5?usp=drive_link";
    String finalUrl = (url != null && url.isNotEmpty) ? url : commonDriveLink;
    String displayUrl = "Ouvrir Drive";

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.folder_shared_outlined,
                size: 16,
                color: isDark ? const Color(0xFF10B981) : darkGreen,
              ),
              const SizedBox(width: 8),
              Text(
                "Archive Photos",
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.blueGrey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => _launchURL(finalUrl),
            child: Text(
              displayUrl,
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return "N/A";
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(date.toString()));
    } catch (e) {
      return date.toString();
    }
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Supprimer $name ?",
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("ANNULER"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        bool ok = await Provider.of<MachineProvider>(
                          context,
                          listen: false,
                        ).deleteMachine(id);
                        if (ok && mounted) Navigator.pop(context);
                      },
                      child: const Text(
                        "SUPPRIMER",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MachineProvider>(context);
    final isDark = Provider.of<SettingsProvider>(context).isDarkMode;

    final filtered = provider.machines.where((m) {
      final nameMatches = (m['name']?.toString() ?? '').toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      final idMatches =
          (m['machine_id']?.toString() ?? m['id']?.toString() ?? '')
              .toLowerCase()
              .contains(searchQuery.toLowerCase());
      bool statusMatches = true;
      if (statusFilter != "Tous") {
        String mStatus = (m['status'] ?? 'actif').toString().toLowerCase();
        if (statusFilter == "En ligne" && mStatus != "actif")
          statusMatches = false;
        if (statusFilter == "Hors ligne" && mStatus != "inactif")
          statusMatches = false;
        if (statusFilter == "En panne" && mStatus != "en_panne")
          statusMatches = false;
      }
      return (nameMatches || idMatches) && statusMatches;
    }).toList();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF111827)
          : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          "Parc Machines",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : darkGreen,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchMachines(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                onChanged: (v) => setState(() => searchQuery = v),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: "Rechercher...",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _buildStatusFilters(),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _showAddMachineDialog,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "AJOUTER UNE MACHINE",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final m = filtered[i];
                    final mId =
                        (m['machine_id'] ?? m['id'] ?? 'S/N').toString();
                    final mName = m['name'] ?? 'Inconnu';
                    final mStatus =
                        (m['status'] ?? 'actif').toString().toLowerCase();
                    return Card(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _getStatusColor(mStatus).withOpacity(0.1),
                          child: Icon(
                            Icons.precision_manufacturing,
                            color: _getStatusColor(mStatus),
                          ),
                        ),
                        title: Text(
                          mName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          "ID: $mId • ${m['city'] ?? 'Wilaya'}",
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => _showMachineDetails(mId, m),
                              child: const Text("Consulter"),
                            ),
                            // ── ICÔNE HISTORIQUE NOTIFICATIONS ──
                            IconButton(
                              icon: Icon(
                                Icons.history,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.blueGrey,
                                size: 22,
                              ),
                              tooltip: "Historique notifications",
                              onPressed: () => _showMachineHistory(
                                m['_id']?.toString() ?? mId,
                                mName,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _confirmDelete(mId, mName),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == "actif") return Colors.green;
    if (status == "inactif") return Colors.orange;
    if (status == "en_panne") return Colors.red;
    return Colors.grey;
  }
}
