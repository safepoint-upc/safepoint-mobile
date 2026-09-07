class Prediccion {
  final int id;
  final DateTime fechaPrediccion;
  final String franjaHoraria;
  final String sector;
  final String tipoDelito;
  final double probabilidad;
  final double latitud;
  final double longitud;
  final String? _nivelRiesgo;

  Prediccion({
    required this.id,
    required this.fechaPrediccion,
    required this.franjaHoraria,
    required this.sector,
    required this.tipoDelito,
    required this.probabilidad,
    required this.latitud,
    required this.longitud,
    String? nivelRiesgo,
  }) : _nivelRiesgo = nivelRiesgo;

  factory Prediccion.fromJson(Map<String, dynamic> json) => Prediccion(
        id: json['id'] ?? 0,
        fechaPrediccion: json['fecha_prediccion'] != null
            ? DateTime.parse(json['fecha_prediccion'])
            : DateTime.now(),
        franjaHoraria: json['franja_horaria'] ?? json['franja_critica'] ?? '',
        sector: json['sector'] ?? '',
        tipoDelito: json['tipo_delito'] ?? '',
        probabilidad: ((json['probabilidad'] ?? json['probabilidad_promedio'] ?? 0) as num).toDouble(),
        latitud: ((json['latitud'] ?? 0) as num).toDouble(),
        longitud: ((json['longitud'] ?? 0) as num).toDouble(),
        nivelRiesgo: json['nivel_riesgo'],
      );

  String get nivelRiesgo {
    if (probabilidad >= 0.66) return 'ALTO';
if (probabilidad >= 0.33) return 'MEDIO';
return 'BAJO';
  }
}
