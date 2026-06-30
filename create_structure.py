import os

base_dir = r'C:\Users\fersa\Desktop\proyecto-tesis\safepoint-mobile\lib'

structure = {
    'config': ['constants.dart'],
    'models': ['usuario.dart', 'incidente.dart', 'alerta.dart', 'prediccion.dart'],
    'services': ['auth_service.dart', 'incidentes_service.dart', 'alertas_service.dart', 'predicciones_service.dart'],
    'providers': ['auth_provider.dart'],
    'screens': [
        'login_screen.dart', 
        'splash_screen.dart',
        'agente/home_screen.dart',
        'agente/mapa_screen.dart',
        'agente/alertas_screen.dart',
        'agente/incidentes_screen.dart',
        'ciudadano/home_screen.dart',
        'ciudadano/mapa_screen.dart',
        'ciudadano/estadisticas_screen.dart'
    ],
    'widgets': ['custom_button.dart', 'custom_text_field.dart', 'loading_overlay.dart', 'risk_badge.dart'],
    'theme': ['app_theme.dart']
}

def get_class_name(filename):
    name = os.path.basename(filename).replace('.dart', '')
    parts = name.split('_')
    return ''.join([p.capitalize() for p in parts])

for folder, files in structure.items():
    for f in files:
        filepath = os.path.join(base_dir, folder, f)
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        class_name = get_class_name(f)
        
        content = ''
        if folder == 'screens' or folder == 'widgets':
            content += 'import \'package:flutter/material.dart\';\n\n'
            content += f'class {class_name} extends StatelessWidget {{\n  const {class_name}({{super.key}});\n\n  @override\n  Widget build(BuildContext context) {{\n    return const Scaffold(\n      body: Center(child: Text(\'{class_name}\')),\n    );\n  }}\n}}\n'
        else:
            content += f'class {class_name} {{\n  // TODO: Implement {class_name}\n}}\n'
            
        with open(filepath, 'w', encoding='utf-8') as file:
            file.write(content)

print('Estructura creada exitosamente.')
