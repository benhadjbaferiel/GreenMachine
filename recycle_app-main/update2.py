import re

file_path = r'c:\Users\Admin\Downloads\recycle_app-main (2)\recycle_app-main\lib\pages\machines_page.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

# Make backup
with open(file_path + '.bak2', 'w', encoding='utf-8') as f:
    f.write(code)

# Remove manual wilaya dropdown
code = re.sub(
    r'DropdownButtonFormField<String>\(\s*value: machineWilaya,.*?onChanged: \(val\) =>\s*setModalState\(\(\) => machineWilaya = val\),\s*\),\s*const SizedBox\(height: 15\),',
    '',
    code,
    flags=re.DOTALL
)

# Remove capacity field
code = re.sub(
    r'_buildField\(\s*capacityController,\s*"Capacité Totale \(kg\)",\s*Icons\.storage,\s*capacityError,\s*isNum: true,\s*\),',
    '',
    code
)

# Remove types checkboxes
code = re.sub(
    r'Text\(\s*"Types de matières :".*?\}\)\.toList\(\),\s*\),',
    '',
    code,
    flags=re.DOTALL
)

# Remove capacity validation
code = re.sub(
    r'capacityError =.*?capacityError == null &&',
    'capacityError == null &&',
    code,
    flags=re.DOTALL
)
code = re.sub(
    r'capacityError == null &&',
    '',
    code
)
code = re.sub(
    r'wilayaError == null &&',
    '',
    code
)
code = re.sub(
    r'typeError == null &&',
    '',
    code
)

code = re.sub(
    r'wilayaError = \(machineWilaya == null\) \? "Choisissez une Wilaya" : null;',
    '',
    code
)
code = re.sub(
    r'typeError = selectedTypes\.isEmpty \? "Cochez au moins un type" : null;',
    '',
    code
)

# Fix map object values
code = re.sub(
    r'"wilaya": machineWilaya,',
    '"wilaya": machineWilaya ?? "Inconnue",',
    code
)

code = re.sub(
    r'"capacity": capacityController\.text,',
    '',
    code
)
code = re.sub(
    r'"types": List\.from\(selectedTypes\),',
    '',
    code
)
code = re.sub(
    r'"bacsInfo": newBacs,',
    '',
    code
)



# Adjust height
code = code.replace(
    'maxHeight: MediaQuery.of(context).size.height * 0.85,',
    'maxHeight: MediaQuery.of(context).size.height * 0.70,'
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)

print("Updates applied to UI")
