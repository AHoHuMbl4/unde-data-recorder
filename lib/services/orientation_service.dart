import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class OrientationService {
  double _currentAzimuth = 0.0;
  String _deviceOrientation = 'Portrait';
  String _compassDirection = 'North';

  /// Вычисляем азимут из магнитометра
  double calculateAzimuth(double mx, double my, double mz) {
    // Компенсируем наклон устройства
    double azimuth = atan2(my, mx) * (180 / pi);
    
    // Нормализуем к 0-360 градусов
    if (azimuth < 0) azimuth += 360;
    
    _currentAzimuth = azimuth;
    return azimuth;
  }

  /// Определяем направление компаса
  String getCompassDirection(double azimuth) {
    if (azimuth >= 337.5 || azimuth < 22.5) {
      _compassDirection = 'North';
    } else if (azimuth >= 22.5 && azimuth < 67.5) {
      _compassDirection = 'NorthEast';
    } else if (azimuth >= 67.5 && azimuth < 112.5) {
      _compassDirection = 'East';
    } else if (azimuth >= 112.5 && azimuth < 157.5) {
      _compassDirection = 'SouthEast';
    } else if (azimuth >= 157.5 && azimuth < 202.5) {
      _compassDirection = 'South';
    } else if (azimuth >= 202.5 && azimuth < 247.5) {
      _compassDirection = 'SouthWest';
    } else if (azimuth >= 247.5 && azimuth < 292.5) {
      _compassDirection = 'West';
    } else {
      _compassDirection = 'NorthWest';
    }
    
    return _compassDirection;
  }

  /// Определяем ориентацию устройства по акселерометру
  String getDeviceOrientation(double ax, double ay, double az) {
    final double absX = ax.abs();
    final double absY = ay.abs();
    final double absZ = az.abs();

    if (absZ > absX && absZ > absY) {
      if (az > 0) {
        _deviceOrientation = 'FaceUp';
      } else {
        _deviceOrientation = 'FaceDown';
      }
    } else if (absY > absX) {
      if (ay > 0) {
        _deviceOrientation = 'Portrait';
      } else {
        _deviceOrientation = 'PortraitUpsideDown';
      }
    } else {
      if (ax > 0) {
        _deviceOrientation = 'LandscapeRight';
      } else {
        _deviceOrientation = 'LandscapeLeft';
      }
    }

    return _deviceOrientation;
  }

  /// Компенсация магнитных показаний по ориентации
  Map<String, double> compensateMagneticField(double bx, double by, double bz, String orientation) {
    double correctedBx = bx;
    double correctedBy = by;
    double correctedBz = bz;

    // Компенсируем ориентацию устройства
    switch (orientation) {
      case 'LandscapeRight':
        correctedBx = by;
        correctedBy = -bx;
        break;
      case 'LandscapeLeft':
        correctedBx = -by;
        correctedBy = bx;
        break;
      case 'PortraitUpsideDown':
        correctedBx = -bx;
        correctedBy = -by;
        break;
      case 'FaceDown':
        correctedBz = -bz;
        break;
      // Portrait и FaceUp остаются без изменений
    }

    return {
      'bx_corrected': correctedBx,
      'by_corrected': correctedBy,
      'bz_corrected': correctedBz,
    };
  }

  /// Получить все данные ориентации
  Map<String, dynamic> getOrientationData(double bx, double by, double bz, double ax, double ay, double az) {
    final azimuth = calculateAzimuth(bx, by, bz);
    final compassDir = getCompassDirection(azimuth);
    final deviceOrient = getDeviceOrientation(ax, ay, az);
    final compensated = compensateMagneticField(bx, by, bz, deviceOrient);

    return {
      'azimuth': azimuth,
      'compass_direction': compassDir,
      'device_orientation': deviceOrient,
      'bx_corrected': compensated['bx_corrected'],
      'by_corrected': compensated['by_corrected'],
      'bz_corrected': compensated['bz_corrected'],
    };
  }
}
