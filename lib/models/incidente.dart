class Incidente {
  final int id;
  final DateTime fecha;
  final String hora;
  final String franjaHoraria;
  final String sector;
  final String tipoDelito;
  final String avenida;
  final String cuadra;
  final String cuadrante;
  final double latitud;
  final double longitud;

  Incidente({
    required this.id,
    required this.fecha,
    required this.hora,
    required this.franjaHoraria,
    required this.sector,
    required this.tipoDelito,
    required this.avenida,
    required this.cuadra,
    required this.cuadrante,
    required this.latitud,
    required this.longitud,
  });

  factory Incidente.fromJson(Map<String, dynamic> json) => Incidente(
        id: json['id'],
        fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : DateTime.now(),
        hora: json['hora'] ?? '',
        franjaHoraria: json['franja_horaria'] ?? '',
        sector: json['sector'] ?? '',
        tipoDelito: json['tipo_delito'] ?? '',
        avenida: json['avenida'] ?? '',
        cuadra: json['cuadra'] ?? '',
        cuadrante: json['cuadrante'] ?? '',
        latitud: (json['latitud'] ?? 0).toDouble(),
        longitud: (json['longitud'] ?? 0).toDouble(),
      );
}
