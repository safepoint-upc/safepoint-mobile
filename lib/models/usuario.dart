class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String rol;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'] ?? 0,
    nombre: json['nombre'] ?? json['email']?.toString().split('@').first ?? 'Usuario',
    email: json['email'] ?? '',
    rol: json['rol'] ?? 'ciudadano',
  );

  bool get esAgente => rol == 'agente' || rol == 'coordinador';
  bool get esCiudadano => rol == 'ciudadano';
  bool get esCoordinador => rol == 'coordinador';
}