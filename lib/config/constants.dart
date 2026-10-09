/// Constantes globales de la app SafePoint.
/// Centraliza URLs, coordenadas, franjas horarias y mapeos de cuadrantes/sectores.
class AppConstants {
  AppConstants._();

  // ── URL base del backend ────────────────────────────────────────────────────
  static const String baseUrl = 'https://safepoint-backend.onrender.com';
  static const String appName = 'SafePoint';
  static const String version = '1.0.0';

  // ── Centro geográfico de Jesús María (Lima) ─────────────────────────────────
  static const double jesusMariaLat = -12.0764;
  static const double jesusMariaLng = -77.0489;
  static const double defaultZoom = 14.5;

  // ── Franjas horarias en el formato EXACTO que usa el backend/BD ────────────
  // Formato: 'De HH:MM a HH:MM H.'  (con punto y H mayúscula)
  static const List<String> franjasHorarias = [
    'De 00:00 a 02:59 H.',
    'De 03:00 a 05:59 H.',
    'De 06:00 a 08:59 H.',
    'De 09:00 a 11:59 H.',
    'De 12:00 a 14:59 H.',
    'De 15:00 a 17:59 H.',
    'De 18:00 a 20:59 H.',
    'De 21:00 a 23:59 H.',
  ];

  // ── Nombres geográficos de cada sector (para mostrar en UI) ────────────────
  static const Map<String, String> nombresSectores = {
    '1': 'Club Lawn Tennis / Lima',
    '2': 'Campo de Marte / Av. Brasil',
    '3': 'Hospital Rebagliati / Círculo Militar',
    '4': 'Comisaría / Jr. Huáscar',
    '5': 'Colegio Arquitectos / Mello Franco',
    '6': 'IPD / Jr. Huamachuco',
    '7': 'Hospital Militar / Pueblo Libre',
    '8': 'Univ. del Pacífico / Derrama Magisterial',
    '9': 'Residencial San Felipe / Real Plaza Salaverry',
  };

  // ── Cuadrantes que pertenecen a cada sector ─────────────────────────────────
  // Coincide al 100% con zonificacion.js del dashboard web
  static const Map<String, List<String>> sectorCuadrantes = {
    '1': ['1A1', '1A2', '1B1', '1B2', '1C1', '1C2'],
    '2': ['2A1', '2A2', '2B1', '2B2', '2C1', '2C2'],
    '3': ['3A1', '3A2', '3B1', '3B2', '3C1', '3C2'],
    '4': ['4A1', '4A2', '4B1', '4B2', '4C1', '4C2'],
    '5': ['5A1', '5A2', '5B1', '5B2', '5C1', '5C2'],
    '6': ['6A1', '6A2', '6B1', '6B2', '6C1', '6C2'],
    '7': ['7A1', '7A2', '7B1', '7B2', '7C1', '7C2'],
    '8': ['8A1', '8A2', '8B1', '8B2', '8C1', '8C2'],
    '9': ['9A', '9B', '9C', '9D'],
  };

  // ── Coordenadas [lat, lng] del centroide de cada cuadrante ─────────────────
  // Extraídas de CUADRANTE_COORDS en inferencia.py del backend.
  // Se usan para colorear polígonos y mostrar etiquetas en el mapa.
  static const Map<String, List<double>> cuadranteCoordenadas = {
    // Sector 1
    '1A1': [-12.06822584, -77.03893624],
    '1A2': [-12.07038116, -77.03893624],
    '1B1': [-12.06822584, -77.04113772],
    '1B2': [-12.07038116, -77.04113772],
    '1C1': [-12.06822584, -77.04333920],
    '1C2': [-12.07038116, -77.04333920],
    // Sector 2
    '2A1': [-12.07253648, -77.03893624],
    '2A2': [-12.07469180, -77.03893624],
    '2B1': [-12.07253648, -77.04113772],
    '2B2': [-12.07469180, -77.04113772],
    '2C1': [-12.07253648, -77.04333920],
    '2C2': [-12.07469180, -77.04333920],
    // Sector 3
    '3A1': [-12.07684712, -77.03893624],
    '3A2': [-12.07900244, -77.03893624],
    '3B1': [-12.07684712, -77.04113772],
    '3B2': [-12.07900244, -77.04113772],
    '3C1': [-12.07684712, -77.04333920],
    '3C2': [-12.07900244, -77.04333920],
    // Sector 4
    '4A1': [-12.06822584, -77.04554068],
    '4A2': [-12.07038116, -77.04554068],
    '4B1': [-12.06822584, -77.04774216],
    '4B2': [-12.07038116, -77.04774216],
    '4C1': [-12.06822584, -77.04994364],
    '4C2': [-12.07038116, -77.04994364],
    // Sector 5
    '5A1': [-12.07253648, -77.04554068],
    '5A2': [-12.07469180, -77.04554068],
    '5B1': [-12.07253648, -77.04774216],
    '5B2': [-12.07469180, -77.04774216],
    '5C1': [-12.07253648, -77.04994364],
    '5C2': [-12.07469180, -77.04994364],
    // Sector 6
    '6A1': [-12.07684712, -77.04554068],
    '6A2': [-12.07900244, -77.04554068],
    '6B1': [-12.07684712, -77.04774216],
    '6B2': [-12.07900244, -77.04774216],
    '6C1': [-12.07684712, -77.04994364],
    '6C2': [-12.07900244, -77.04994364],
    // Sector 7
    '7A1': [-12.06822584, -77.05214512],
    '7A2': [-12.07038116, -77.05214512],
    '7B1': [-12.06822584, -77.05214512],
    '7B2': [-12.07038116, -77.05214512],
    '7C1': [-12.07253648, -77.05214512],
    '7C2': [-12.07469180, -77.05214512],
    '7A': [-12.06822584, -77.05214512],
    '7B': [-12.07038116, -77.05214512],
    '7C': [-12.07253648, -77.05214512],
    '7D': [-12.07469180, -77.05214512],
    // Sector 8
    '8A1': [-12.07684712, -77.05214512],
    '8A2': [-12.07900244, -77.05214512],
    '8B1': [-12.07684712, -77.05214512],
    '8B2': [-12.07900244, -77.05214512],
    '8C1': [-12.08115776, -77.05214512],
    '8C2': [-12.08331308, -77.05214512],
    '8A': [-12.07684712, -77.05214512],
    '8B': [-12.07900244, -77.05214512],
    '8C': [-12.08115776, -77.05214512],
    '8D': [-12.08331308, -77.05214512],
    // Sector 9
    '9A': [-12.08546840, -77.04554068],
    '9B': [-12.08762372, -77.04554068],
    '9C': [-12.08977904, -77.04554068],
    '9D': [-12.09060040, -77.05338523],
  };

  // ── Calcula el centroide (promedio lat/lng) de todos los cuadrantes de un sector ──
  // Útil para centrar la cámara del mapa en un sector específico.
  static List<double> centroideSector(String sector) {
    final cuadrantes = sectorCuadrantes[sector] ?? [];
    if (cuadrantes.isEmpty) return [jesusMariaLat, jesusMariaLng];

    double sumLat = 0;
    double sumLng = 0;
    int count = 0;

    for (final c in cuadrantes) {
      final coords = cuadranteCoordenadas[c];
      if (coords != null && coords.length >= 2) {
        sumLat += coords[0];
        sumLng += coords[1];
        count++;
      }
    }

    if (count == 0) return [jesusMariaLat, jesusMariaLng];
    return [sumLat / count, sumLng / count];
  }

  // ── Devuelve la franja horaria actual forzando la hora de Lima (UTC-5) ──────
  // Retorna la cadena en el formato exacto del backend ('De HH:MM a HH:MM H.')
  static String getFranjaActual() {
    // Obtenemos la hora UTC y restamos 5 horas (Lima no usa horario de verano)
    // Esto asegura que la franja siempre sea correcta sin importar la zona horaria del dispositivo
    final hora = DateTime.now().toUtc().subtract(const Duration(hours: 5)).hour;
    
    if (hora < 3)  return franjasHorarias[0]; // 00:00-02:59
    if (hora < 6)  return franjasHorarias[1]; // 03:00-05:59
    if (hora < 9)  return franjasHorarias[2]; // 06:00-08:59
    if (hora < 12) return franjasHorarias[3]; // 09:00-11:59
    if (hora < 15) return franjasHorarias[4]; // 12:00-14:59
    if (hora < 18) return franjasHorarias[5]; // 15:00-17:59
    if (hora < 21) return franjasHorarias[6]; // 18:00-20:59
    return franjasHorarias[7];                // 21:00-23:59
  }

  // ── Convierte franja horaria a índice (0-7) para listas ────────────────────
  static int getFranjaIndex(String franja) {
    return franjasHorarias.indexOf(franja).clamp(0, 7);
  }

  // ── Versión corta de la franja para mostrar en chips/badges ────────────────
  // Ej: 'De 09:00 a 11:59 H.' → '09:00-11:59'
  static String franjaCorta(String franja) {
    // Extrae horas de inicio y fin del formato 'De HH:MM a HH:MM H.'
    final regex = RegExp(r'De (\d{2}:\d{2}) a (\d{2}:\d{2}) H\.');
    final match = regex.firstMatch(franja);
    if (match != null) return '${match.group(1)}-${match.group(2)}';
    return franja;
  }
}