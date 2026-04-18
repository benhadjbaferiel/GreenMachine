import re

file_path = r'c:\Users\Admin\Downloads\recycle_app-main (2)\recycle_app-main\lib\pages\machines_page.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

# Remove the wilayas list completely
code = re.sub(r'\s*final List<String> wilayas = \[.*?\];\n', '', code, flags=re.DOTALL)

# Remove machineWilaya and addressDisplay from variables
code = re.sub(r'\s*String\? machineWilaya;\n', '\n', code)
code = re.sub(r'\s*String addressDisplay = "";\n', '\n', code)

# In _clearInputs, remove machineWilaya and addressDisplay
code = re.sub(r'\s*machineWilaya = null;\n', '\n', code)
code = re.sub(r'\s*addressDisplay = "";\n', '\n', code)

# Remove _getWilayaAndAddressFromLatLon
code = re.sub(r'\s*void _getWilayaAndAddressFromLatLon\(StateSetter setModalState\) async \{.*?\}\n\s*\}\n\s*\}\n', '\n', code, flags=re.DOTALL)

# Remove Deduced Addres button and display in _showAddMachineDialog
code = re.sub(r'\s*Align\(\s*alignment: Alignment\.centerRight.*?Déduire Adresse / Wilaya.*?\),.*?if \(addressDisplay\.isNotEmpty\)\s*Padding\(.*?📌 \$addressDisplay.*?,\s*\),\s*', '\n', code, flags=re.DOTALL)

# Remove "city": machineWilaya ?? "Inconnue", from newMachine in _handleSave
code = re.sub(r'\s*"city": machineWilaya \?\? "Inconnue",\n', '\n', code)

# Replace the subtitle to just show coords
code = re.sub(r'subtitle: Text\(\s*"📍 \$\{m\[\'city\'\] \?\? m\[\'wilaya\'\] \?\? \'Adresse inconnue\'\}",\s*\),', 
    'subtitle: Text("📍 Lat: ${m[\'latitude\']} | Lon: ${m[\'longitude\']}"),', code)
    
# Replace the subtitle in the modal dialog as well
code = re.sub(r'Text\(\s*"ID: \$\{machine\[\'machine_id\'\] \?\? machine\[\'id\'\]\} \| 📍 \$\{machine\[\'city\'\] \?\? machine\[\'wilaya\'\] \?\? \'Adresse inconnue\'\}",',
    'Text("ID: ${machine[\'machine_id\'] ?? machine[\'id\']} | 📍 Lat: ${machine[\'latitude\']} | Lon: ${machine[\'longitude\']}",', code)

# Replace search logic that used city
code = re.sub(r'final matchesSearch = \(m\[\'city\'\]\?\.toString\(\) \?\? m\[\'wilaya\'\]\?\.toString\(\) \?\? \'\'\)\.toLowerCase\(\)\.contains\(',
    'final matchesSearch = (m[\'name\']?.toString() ?? \'\').toLowerCase().contains(', code)


with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)

print("Removed city fields!")
