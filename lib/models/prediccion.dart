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
    id: json['id'],
    fechaPrediccion: DateTime.parse(json['fecha_prediccion']),
    franjaHoraria: json['franja_horaria'],
    sector: json['sector'],
    cuadrante: json['cuadrante'],
    probabilidad: (json['probabilidad'] as num).toDouble(),
    nivelRiesgo: json['nivel_riesgo'],
    latitud: json['latitud'] != null ? (json['latitud'] as num).toDouble() : null,
    longitud: json['longitud'] != null ? (json['longitud'] as num).toDouble() : null,
    creadoEn: DateTime.parse(json['creado_en']),
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