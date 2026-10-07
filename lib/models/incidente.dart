class Incidente {
  final int id;
  final DateTime fecha;
  final String hora;
  final String? franjaHoraria;
  final String? diaSemana;
  final String? mes;
  final int? anio;
  final String? avenida;
  final String? cuadra;
  final String? sector;
  final String? sectorGps;
  final String? cuadrante;
  final String? cuadranteGps;
  final String? tipoDelito;
  final String? subTipoDelito;
  final String? estado;
  final String? modalidad;
  final String? dependencia;
  final double? latitud;
  final double? longitud;

  Incidente({
    required this.id,
    required this.fecha,
    required this.hora,
    this.franjaHoraria,
    this.diaSemana,
    this.mes,
    this.anio,
    this.avenida,
    this.cuadra,
    this.sector,
    this.sectorGps,
    this.cuadrante,
    this.cuadranteGps,
    this.tipoDelito,
    this.subTipoDelito,
    this.estado,
    this.modalidad,
    this.dependencia,
    this.latitud,
    this.longitud,
  });

  factory Incidente.fromJson(Map<String, dynamic> json) => Incidente(
    id: json['id'],
    fecha: DateTime.parse(json['fecha']),
    hora: json['hora'] ?? '',
    franjaHoraria: json['franja_horaria'],
    diaSemana: json['dia_semana'],
    mes: json['mes'],
    anio: json['anio'],
    avenida: json['avenida'],
    cuadra: json['cuadra'],
    sector: json['sector'],
    sectorGps: json['sector_gps'],
    cuadrante: json['cuadrante'],
    cuadranteGps: json['cuadrante_gps'],
    tipoDelito: json['tipo_delito'],
    subTipoDelito: json['sub_tipo_delito'],
    estado: json['estado'],
    modalidad: json['modalidad'],
    dependencia: json['dependencia'],
    latitud: json['latitud'] != null ? (json['latitud'] as num).toDouble() : null,
    longitud: json['longitud'] != null ? (json['longitud'] as num).toDouble() : null,
  );
}