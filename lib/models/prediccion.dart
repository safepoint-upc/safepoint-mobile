class Prediccion {
  final int id;
  final DateTime fechaPrediccion;
  final String? franjaHoraria;
  final String? sector;
  final String? cuadrante;
  final double probabilidad;
  final int? nivelRiesgo;
  final double? latitud;
  final double? longitud;
  final DateTime creadoEn;

  Prediccion({
    required this.id,
    required this.fechaPrediccion,
    this.franjaHoraria,
    this.sector,
    this.cuadrante,
    required this.probabilidad,
    this.nivelRiesgo,
    this.latitud,
    this.longitud,
    required this.creadoEn,
  });

  factory Prediccion.fromJson(Map<String, dynamic> json) => Prediccion(
    id: json['id'] ?? 0,
    fechaPrediccion: json['fecha_prediccion'] != null
        ? (DateTime.tryParse(json['fecha_prediccion'].toString()) ?? DateTime.now())
        : DateTime.now(),
    franjaHoraria: json['franja_horaria']?.toString(),
    sector: json['sector']?.toString(),
    cuadrante: json['cuadrante']?.toString(),
    probabilidad: (json['probabilidad'] as num?)?.toDouble() ?? 0.0,
    nivelRiesgo: json['nivel_riesgo'] as int?,
    latitud: json['latitud'] != null ? (json['latitud'] as num).toDouble() : null,
    longitud: json['longitud'] != null ? (json['longitud'] as num).toDouble() : null,
    creadoEn: json['creado_en'] != null
        ? (DateTime.tryParse(json['creado_en'].toString()) ?? DateTime.now())
        : DateTime.now(),
  );

  String get nivelRiesgoTexto {
    switch (nivelRiesgo) {
      case 0: return 'BAJO';
      case 1: return 'MEDIO';
      case 2: return 'ALTO';
      default: return 'DESCONOCIDO';
    }
  }
}