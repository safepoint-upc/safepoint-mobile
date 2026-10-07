class Alerta {
  final int id;
  final String sector;
  final String? cuadrante;
  final String franjaHoraria;
  final double probabilidad;
  final double latitud;
  final double longitud;
  final bool activa;
  final DateTime creadoEn;

  Alerta({
    required this.id,
    required this.sector,
    this.cuadrante,
    required this.franjaHoraria,
    required this.probabilidad,
    required this.latitud,
    required this.longitud,
    required this.activa,
    required this.creadoEn,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) => Alerta(
    id: json['id'],
    sector: json['sector'] ?? '',
    cuadrante: json['cuadrante'],
    franjaHoraria: json['franja_horaria'] ?? '',
    probabilidad: (json['probabilidad'] as num).toDouble(),
    latitud: (json['latitud'] as num).toDouble(),
    longitud: (json['longitud'] as num).toDouble(),
    activa: json['activa'] ?? true,
    creadoEn: DateTime.parse(json['creado_en']),
  );
}