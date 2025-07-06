import 'package:flutter/material.dart';
import 'dart:math' as math;

class CompassWidget extends StatelessWidget {
  final double azimuth;
  final String compassDirection;
  final double size;
  final bool showText;

  const CompassWidget({
    Key? key,
    required this.azimuth,
    required this.compassDirection,
    this.size = 120.0,
    this.showText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          child: CustomPaint(
            painter: CompassPainter(azimuth),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.navigation,
                    color: Colors.red,
                    size: size * 0.3,
                  ),
                  if (showText) ...[
                    SizedBox(height: 4),
                    Text(
                      '${azimuth.toStringAsFixed(0)}°',
                      style: TextStyle(
                        fontSize: size * 0.08,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(height: 8),
          Text(
            compassDirection,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getDirectionColor(compassDirection),
            ),
          ),
          SizedBox(height: 4),
          Text(
            _getDirectionInstructions(compassDirection),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Color _getDirectionColor(String direction) {
    switch (direction) {
      case 'North':
        return Colors.green;
      case 'NorthEast':
      case 'NorthWest':
        return Colors.lightGreen;
      default:
        return Colors.orange;
    }
  }

  String _getDirectionInstructions(String direction) {
    switch (direction) {
      case 'North':
        return '✅ Идеально! Смотрите на СЕВЕР';
      case 'NorthEast':
        return '↩️ Поверните чуть влево';
      case 'NorthWest':
        return '↪️ Поверните чуть вправо';
      case 'East':
        return '←  Поверните сильно влево';
      case 'West':
        return '→  Поверните сильно вправо';
      case 'South':
        return '🔄 Развернитесь на 180°';
      case 'SouthEast':
        return '↖️ Поверните влево и назад';
      case 'SouthWest':
        return '↗️ Поверните вправо и назад';
      default:
        return 'Калибровка компаса...';
    }
  }
}

class CompassPainter extends CustomPainter {
  final double azimuth;

  CompassPainter(this.azimuth);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Фон компаса
    final backgroundPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Внешнее кольцо
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius - 5, ringPaint);

    // Рисуем основные направления
    _drawDirections(canvas, center, radius);

    // Рисуем стрелку севера (красная)
    _drawNorthArrow(canvas, center, radius);

    // Рисуем текущее направление телефона (синяя стрелка)
    _drawPhoneDirection(canvas, center, radius);
  }

  void _drawDirections(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final directions = ['N', 'E', 'S', 'W'];
    final angles = [0, 90, 180, 270];

    for (int i = 0; i < directions.length; i++) {
      final angle = angles[i] * (math.pi / 180);
      final isNorth = directions[i] == 'N';
      
      // Позиция текста
      final textRadius = radius - 20;
      final x = center.dx + textRadius * math.sin(angle);
      final y = center.dy - textRadius * math.cos(angle);

      textPainter.text = TextSpan(
        text: directions[i],
        style: TextStyle(
          color: isNorth ? Colors.red : Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );

      // Метки на окружности
      final markRadius = radius - 10;
      final markStartX = center.dx + markRadius * math.sin(angle);
      final markStartY = center.dy - markRadius * math.cos(angle);
      final markEndX = center.dx + (markRadius - 10) * math.sin(angle);
      final markEndY = center.dy - (markRadius - 10) * math.cos(angle);

      final markPaint = Paint()
        ..color = isNorth ? Colors.red : Colors.white
        ..strokeWidth = isNorth ? 3 : 2;

      canvas.drawLine(
        Offset(markStartX, markStartY),
        Offset(markEndX, markEndY),
        markPaint,
      );
    }

    // Рисуем промежуточные метки
    for (int i = 0; i < 360; i += 30) {
      if (i % 90 != 0) { // Пропускаем основные направления
        final angle = i * (math.pi / 180);
        final markRadius = radius - 10;
        final markStartX = center.dx + markRadius * math.sin(angle);
        final markStartY = center.dy - markRadius * math.cos(angle);
        final markEndX = center.dx + (markRadius - 5) * math.sin(angle);
        final markEndY = center.dy - (markRadius - 5) * math.cos(angle);

        final markPaint = Paint()
          ..color = Colors.white54
          ..strokeWidth = 1;

        canvas.drawLine(
          Offset(markStartX, markStartY),
          Offset(markEndX, markEndY),
          markPaint,
        );
      }
    }
  }

  void _drawNorthArrow(Canvas canvas, Offset center, double radius) {
    // Стрелка севера (всегда указывает вверх)
    final northPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final northPath = Path();
    northPath.moveTo(center.dx, center.dy - radius * 0.3);
    northPath.lineTo(center.dx - 8, center.dy - radius * 0.1);
    northPath.lineTo(center.dx + 8, center.dy - radius * 0.1);
    northPath.close();

    canvas.drawPath(northPath, northPaint);

    // Заливка стрелки севера
    final northFillPaint = Paint()
      ..color = Colors.red.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawPath(northPath, northFillPaint);
  }

  void _drawPhoneDirection(Canvas canvas, Offset center, double radius) {
    // Текущее направление телефона
    final phoneAngle = azimuth * (math.pi / 180);
    
    final phonePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Стрелка направления телефона
    final phoneArrowLength = radius * 0.6;
    final phoneEndX = center.dx + phoneArrowLength * math.sin(phoneAngle);
    final phoneEndY = center.dy - phoneArrowLength * math.cos(phoneAngle);

    canvas.drawLine(center, Offset(phoneEndX, phoneEndY), phonePaint);

    // Наконечник стрелки
    final arrowPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final arrowPath = Path();
    final arrowLength = 12;
    final arrowAngle1 = phoneAngle + 2.8;
    final arrowAngle2 = phoneAngle - 2.8;

    arrowPath.moveTo(phoneEndX, phoneEndY);
    arrowPath.lineTo(
      phoneEndX - arrowLength * math.sin(arrowAngle1),
      phoneEndY + arrowLength * math.cos(arrowAngle1),
    );
    arrowPath.lineTo(
      phoneEndX - arrowLength * math.sin(arrowAngle2),
      phoneEndY + arrowLength * math.cos(arrowAngle2),
    );
    arrowPath.close();

    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
