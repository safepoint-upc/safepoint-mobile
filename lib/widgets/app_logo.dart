import 'package:flutter/material.dart';

/// Widget de Logo Heráldico idéntico al del Dashboard Web de SafePoint.
///
/// Dibuja mediante [CustomPainter] la estructura del escudo heráldico:
/// 1. Marco metálico externo con punta superior e inferior.
/// 2. Fondo biselado oscuro `#0f172a`.
/// 3. Escudo dividido en 4 cuadrantes (Superior-Izquierdo e Inferior-Derecho en Azul `#3B82F6`,
///    Superior-Derecho e Inferior-Izquierdo en Blanco `#F8FAFC`).
/// 4. Brillo curvo superior reflejo.
/// 5. Líneas divisorias en cruz.
class SafePointLogoHeader extends StatelessWidget {
  final double width;
  final double height;
  final bool showWordmark;
  final double fontSize;

  const SafePointLogoHeader({
    super.key,
    this.width = 44,
    this.height = 48,
    this.showWordmark = false,
    this.fontSize = 38,
  });

  @override
  Widget build(BuildContext context) {
    final logoWidget = Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(width, height),
        painter: _SafePointShieldPainter(),
      ),
    );

    if (!showWordmark) {
      return logoWidget;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoWidget,
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Safe',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF3B82F6),
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Point',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SafePointShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Escala basada en viewBox original (50x54)
    final double scaleX = w / 50.0;
    final double scaleY = h / 54.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // 1. Marco exterior metálico (spFrameMetal: #475569 -> #94a3b8 -> #334155)
    final Path framePath = Path();
    framePath.moveTo(25, 1);
    framePath.quadraticBezierTo(14, 6, 2, 6);
    framePath.cubicTo(2, 25, 8, 41, 25, 52);
    framePath.cubicTo(42, 41, 48, 25, 48, 6);
    framePath.quadraticBezierTo(36, 6, 25, 1);
    framePath.close();

    final Paint framePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF475569),
          Color(0xFF94A3B8),
          Color(0xFF334155),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(const Rect.fromLTWH(0, 0, 50, 54));

    canvas.drawPath(framePath, framePaint);

    // 2. Bisel interno de fondo oscuro (#0f172a)
    final Path bevelPath = Path();
    bevelPath.moveTo(25, 3.5);
    bevelPath.quadraticBezierTo(14.5, 7.8, 4, 7.8);
    bevelPath.cubicTo(4, 24, 9.5, 38.8, 25, 48.8);
    bevelPath.cubicTo(40.5, 38.8, 46, 24, 46, 7.8);
    bevelPath.quadraticBezierTo(35.5, 7.8, 25, 3.5);
    bevelPath.close();

    final Paint bevelPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawPath(bevelPath, bevelPaint);

    // 3. ClipPath para cuadrantes interiores
    final Path shieldClip = Path();
    shieldClip.moveTo(25, 5);
    shieldClip.quadraticBezierTo(15, 9, 6, 9);
    shieldClip.cubicTo(6, 23, 11, 36, 25, 46);
    shieldClip.cubicTo(39, 36, 44, 23, 44, 9);
    shieldClip.quadraticBezierTo(35, 9, 25, 5);
    shieldClip.close();

    canvas.save();
    canvas.clipPath(shieldClip);

    // Fondo blanco (#f8fafc)
    final Paint whitePaint = Paint()..color = const Color(0xFFF8FAFC);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 50, 54), whitePaint);

    // Cuadrante Superior Izquierdo (Azul #3b82f6)
    final Paint bluePaint = Paint()..color = const Color(0xFF3B82F6);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 25, 25), bluePaint);

    // Cuadrante Inferior Derecho (Azul #3b82f6)
    canvas.drawRect(const Rect.fromLTWH(25, 25, 25, 29), bluePaint);

    // Brillo superior en arco
    final Path glossPath = Path();
    glossPath.moveTo(6, 9);
    glossPath.quadraticBezierTo(15, 13, 25, 13);
    glossPath.quadraticBezierTo(35, 13, 44, 9);
    glossPath.cubicTo(44, 15, 37, 21, 25, 21);
    glossPath.cubicTo(13, 21, 6, 15, 6, 9);
    glossPath.close();

    final Paint glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25);
    canvas.drawPath(glossPath, glossPaint);

    // Líneas divisorias en cruz
    final Paint linePaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(const Offset(25, 0), const Offset(25, 54), linePaint);
    canvas.drawLine(const Offset(0, 25), const Offset(50, 25), linePaint);

    canvas.restore(); // Restaura clip
    canvas.restore(); // Restaura escala
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
