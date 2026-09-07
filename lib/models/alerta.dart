class Alerta {
  final int id;
  final String tipoDelito;
  final String sector;
  final String franjaHoraria;
  final double probabilidad;
  final double latitud;
  final double longitud;
  final bool activa;
  final DateTime creadoEn;

  Alerta({
    required this.id,
    required this.tipoDelito,
    required this.sector,
    required this.franjaHoraria,
    required this.probabilidad,
    required this.latitud,
    required this.longitud,
    required this.activa,
    required this.creadoEn,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) => Alerta(
        id: json['id'],
        tipoDelito: json['tipo_delito'] ?? '',
        sector: json['sector'] ?? '',
        franjaHoraria: json['franja_horaria'] ?? '',
        probabilidad: (json['probabilidad'] ?? 0).toDouble(),
        latitud: (json['latitud'] ?? 0).toDouble(),
        longitud: (json['longitud'] ?? 0).toDouble(),
        activa: json['activa'] ?? true,
        creadoEn: json['creado_en'] != null ? DateTime.parse(json['creado_en']) : DateTime.now(),
      );

  String get nivelRiesgo {
    if (probabilidad >= 0.66) return 'ALTO';
    if (probabilidad >= 0.33) return 'MEDIO';
    return 'BAJO';
  }
}
