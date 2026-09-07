# SafePoint Mobile

Aplicación móvil del sistema SafePoint para la predicción de incidentes de seguridad ciudadana en el distrito de Jesús María, Lima, Perú.

Desarrollado como parte de la tesis "Aplicación Móvil basada en Machine Learning y Geolocalización para la Predicción de Incidentes de Seguridad Ciudadana en el Distrito de Jesús María" - UPC 2026.

## Stack

- Flutter 3+
- Dart
- Provider (manejo de estado)
- Dio (HTTP)
- Flutter Map (mapas interactivos)
- FL Chart (gráficos)
- Flutter Secure Storage (almacenamiento seguro del token JWT)

## Roles

- **Ciudadano** — acceso público, visualiza mapa de riesgo y estadísticas del distrito
- **Agente / Coordinador** — acceso con login, visualiza alertas, predicciones e incidentes en tiempo real

## Instalación

1. Clona el repositorio:
```bash
git clone https://github.com/safepoint-upc/safepoint-mobile.git
cd safepoint-mobile
```

2. Instala las dependencias:
```bash
flutter pub get
```

3. Corre la app:
```bash
flutter run
```

## APK

La versión compilada está disponible en [GitHub Releases](https://github.com/safepoint-upc/safepoint-mobile/releases).

## Estructura

```
lib/
├── main.dart
├── config/
│   └── constants.dart       ← URL del backend y constantes del distrito
├── models/                  ← modelos de datos
├── providers/               ← manejo de estado (AuthProvider)
├── screens/
│   ├── agente/              ← pantallas para agentes y coordinadores
│   └── ciudadano/           ← pantallas para ciudadanos
├── services/                ← comunicación con el backend
├── theme/                   ← estilos y colores
└── widgets/                 ← componentes reutilizables
```