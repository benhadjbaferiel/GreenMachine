import os

file_path = r'c:\Users\Admin\Downloads\recycle_app-main (2)\recycle_app-main\lib\pages\machines_page.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

# Make backup
with open(file_path + '.bak', 'w', encoding='utf-8') as f:
    f.write(code)

code = code.replace(
    "import 'package:flutter/material.dart';\nimport 'package:google_fonts/google_fonts.dart';",
    "import 'package:flutter/material.dart';\nimport 'package:google_fonts/google_fonts.dart';\nimport 'package:provider/provider.dart';\nimport 'package:geocoding/geocoding.dart';\nimport '../providers/machine_provider.dart';"
)

code = code.replace(
'''  String? idError,
      nameError,
      typeError,
      wilayaError,
      capacityError,
      accuracyError;''',
'''  String? idError,
      nameError,
      typeError,
      wilayaError,
      capacityError,
      accuracyError,
      latError,
      lonError,
      locationError,
      sizeError;'''
)

code = code.replace(
'''  List<String> selectedTypes = [];
  String? machineWilaya;''',
'''  List<String> selectedTypes = [];
  String? machineWilaya;
  String? machineLocation;
  String? machineSize;
  String addressDisplay = "";

  final List<String> locationOptions = [
    "Institut",
    "Restaurant",
    "Centre commercial",
    "Espace public",
    "Usine",
  ];

  final List<String> sizeOptions = ["Petit", "Grand"];'''
)

code = code.replace(
'''  final TextEditingController accuracyController = TextEditingController();''',
'''  final TextEditingController accuracyController = TextEditingController();
  final TextEditingController latController = TextEditingController();
  final TextEditingController lonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MachineProvider>(context, listen: false)
          .setInitialMachines(machines);
    });
  }'''
)

code = code.replace(
'''  // --- DIALOGUE DE CONFIRMATION PERSONNALISÉ ---
  void _showDeleteDialog(int index) {''',
'''  // --- DIALOGUE DE CONFIRMATION PERSONNALISÉ ---
  void _showDeleteDialog(int index, String machineId, String machineName) {'''
)

code = code.replace(
'''Voulez-vous vraiment supprimer ${machines[index]['name']} ? Cette action est irréversible.''',
'''Voulez-vous vraiment supprimer $machineName ? Cette action est irréversible.'''
)

code = code.replace(
'''setState(() => machines.removeAt(index));''',
'''Provider.of<MachineProvider>(context, listen: false).deleteMachine(machineId);'''
)

code = code.replace(
'''  void _handleSave(StateSetter setModalState) {''',
'''  Future<void> _handleSave(StateSetter setModalState) async {'''
)

code = code.replace(
'''wilayaError = (machineWilaya == null) ? "Choisissez une Wilaya" : null;
      typeError = selectedTypes.isEmpty ? "Cochez au moins un type" : null;''',
'''wilayaError = (machineWilaya == null) ? "Choisissez une Wilaya" : null;
      typeError = selectedTypes.isEmpty ? "Cochez au moins un type" : null;
      latError = (latController.text.isEmpty || double.tryParse(latController.text) == null) ? "Latitude invalide" : null;
      lonError = (lonController.text.isEmpty || double.tryParse(lonController.text) == null) ? "Longitude invalide" : null;
      locationError = (machineLocation == null) ? "Choisissez l'emplacement" : null;
      sizeError = (machineSize == null) ? "Choisissez la taille" : null;'''
)

code = code.replace(
'''typeError == null) {''',
'''typeError == null &&
        latError == null &&
        lonError == null &&
        locationError == null &&
        sizeError == null) {'''
)

code = code.replace(
'''      setState(() {
        machines.add({
          "id": idController.text,
          "name": nameController.text,
          "wilaya": machineWilaya,
          "capacity": capacityController.text,
          "types": List.from(selectedTypes),
          "status": "online",
          "bacsInfo": newBacs,
          "modelAccuracy": acc,
        });
      });
      _clearInputs();
      Navigator.pop(context);''',
'''      final newMachine = {
        "id": idController.text,
        "name": nameController.text,
        "wilaya": machineWilaya,
        "address": addressDisplay.isNotEmpty ? addressDisplay : machineLocation,
        "latitude": double.parse(latController.text),
        "longitude": double.parse(lonController.text),
        "locationType": machineLocation,
        "machineSize": machineSize,
        "capacity": capacityController.text,
        "types": List.from(selectedTypes),
        "status": "online",
        "bacsInfo": newBacs,
        "modelAccuracy": acc,
      };

      bool success = await Provider.of<MachineProvider>(context, listen: false).addMachine(newMachine);
      
      if (success && mounted) {
        _clearInputs();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Machine ajoutée avec succès !"), backgroundColor: Colors.green),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'ajout de la machine"), backgroundColor: Colors.red),
        );
      }'''
)

code = code.replace(
'''machineWilaya = null;''',
'''machineWilaya = null;
    machineLocation = null;
    machineSize = null;
    latController.clear();
    lonController.clear();
    addressDisplay = "";'''
)

old_add_sheet = '''  void _showAddMachineSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Configuration Machine",
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 20),
                _buildField(
                  idController,
                  "ID Machine",
                  Icons.fingerprint,
                  idError,
                  isNum: true,
                ),
                _buildField(nameController, "Nom", Icons.settings, nameError),

                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () => _handleSave(setModalState),
                    child: const Text(
                      "ENREGISTRER",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }'''

new_add_dialog = '''  void _getWilayaAndAddressFromLatLon(StateSetter setModalState) async {
    if (latController.text.isNotEmpty && lonController.text.isNotEmpty) {
      try {
        double lat = double.parse(latController.text);
        double lon = double.parse(lonController.text);
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setModalState(() {
            addressDisplay = "${place.street}, ${place.locality}";
            // Fallback for Wilaya selection 
            String? matchedWilaya;
            for (String w in wilayas) {
              if (place.administrativeArea?.contains(w) ?? false) {
                matchedWilaya = w;
                break;
              }
            }
            if (matchedWilaya != null) {
              machineWilaya = matchedWilaya;
            }
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Adresse récupérée !"), backgroundColor: Colors.green));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de géolocalisation"), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _showAddMachineDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  "Ajouter une Machine",
                  style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold, color: darkGreen),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField(idController, "ID Machine", Icons.fingerprint, idError, isNum: true),
                        _buildField(nameController, "Nom", Icons.settings, nameError),
                        
                        // Coordonnées
                        Row(
                          children: [
                            Expanded(child: _buildField(latController, "Latitude", Icons.location_on, latError, isNum: true)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildField(lonController, "Longitude", Icons.location_on, lonError, isNum: true)),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _getWilayaAndAddressFromLatLon(setModalState),
                            icon: const Icon(Icons.my_location, size: 18),
                            label: const Text("Déduire Adresse / Wilaya", style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        if (addressDisplay.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Text("📌 $addressDisplay", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                          ),

                        DropdownButtonFormField<String>(
                          value: machineWilaya,
                          decoration: InputDecoration(
                            labelText: "Wilaya",
                            prefixIcon: const Icon(Icons.map),
                            errorText: wilayaError,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: wilayas.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                          onChanged: (val) => setModalState(() => machineWilaya = val),
                        ),
                        const SizedBox(height: 15),
                        
                        DropdownButtonFormField<String>(
                          value: machineSize,
                          decoration: InputDecoration(
                            labelText: "Type de Machine",
                            prefixIcon: const Icon(Icons.aspect_ratio),
                            errorText: sizeError,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: sizeOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) => setModalState(() => machineSize = val),
                        ),
                        const SizedBox(height: 15),

                        DropdownButtonFormField<String>(
                          value: machineLocation,
                          decoration: InputDecoration(
                            labelText: "Emplacement",
                            prefixIcon: const Icon(Icons.place),
                            errorText: locationError,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: locationOptions.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                          onChanged: (val) => setModalState(() => machineLocation = val),
                        ),
                        const SizedBox(height: 15),

                        _buildField(capacityController, "Capacité Totale (kg)", Icons.storage, capacityError, isNum: true),
                        _buildField(accuracyController, "Précision IA (%)", Icons.psychology, accuracyError, isNum: true),
                        
                        Text("Types de matières :", style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (typeError != null)
                          Text(typeError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        Wrap(
                          spacing: 8,
                          children: typeOptions.map((type) {
                            final isSelected = selectedTypes.contains(type);
                            return FilterChip(
                              label: Text(type),
                              selected: isSelected,
                              selectedColor: darkGreen.withOpacity(0.2),
                              checkmarkColor: darkGreen,
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) selectedTypes.add(type);
                                  else selectedTypes.remove(type);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () => _handleSave(setModalState),
                    child: const Text("ENREGISTRER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }'''

code = code.replace(old_add_sheet, new_add_dialog)

code = code.replace(
'''  @override
  Widget build(BuildContext context) {
    final filtered = machines.where((m) {''',
'''  @override
  Widget build(BuildContext context) {
    final providerMachines = Provider.of<MachineProvider>(context).machines;

    final filtered = providerMachines.where((m) {'''
)

code = code.replace(
'''// Status Filters
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _showAddMachineSheet,
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text(
                "AJOUTER UNE MACHINE",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),''',
'''// Status Filters
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ["Tous", "En ligne", "Hors ligne", "En panne"].map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: statusFilter == status,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => statusFilter = status);
                        }
                      },
                      selectedColor: darkGreen.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: statusFilter == status ? darkGreen : Colors.black87,
                        fontWeight: statusFilter == status ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _showAddMachineDialog,
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text(
                "AJOUTER UNE MACHINE",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),'''
)


code = code.replace(
'''"📍 ${m['wilaya']}\\n📊 ${m['capacity']} kg | ${m['types'].join(', ')}",''',
'''"📍 ${m['wilaya']} ${m['address'] != null ? '- ' + m['address'] : ''}\\n📊 ${m['capacity']} kg | ${m['types'].join(', ')}",'''
)

code = code.replace(
'''"Gérer",''',
'''"Consulter",'''
)

code = code.replace(
'''final realIndex = machines.indexOf(m);
                              if (realIndex != -1) _showDeleteDialog(realIndex);''',
'''final realIndex = providerMachines.indexOf(m);
                              if (realIndex != -1) _showDeleteDialog(realIndex, m['id'], m['name']);'''
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)

print("Update script finished.")
