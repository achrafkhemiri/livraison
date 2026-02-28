import 'package:flutter/material.dart';

/// Utilitaire responsive basé sur MediaQuery.
/// 
/// Fournit des facteurs d'échelle et des helpers pour adapter
/// l'interface à toute taille d'écran (phone small, phone, tablet, desktop).
/// 
/// Usage:
/// ```dart
/// final r = Responsive(context);
/// Text('Hello', style: TextStyle(fontSize: r.fontSize(16)));
/// Padding(padding: r.paddingAll(16));
/// SizedBox(width: r.wp(50)); // 50% de la largeur
/// ```
class Responsive {
  final BuildContext context;
  late final MediaQueryData _mq;
  late final double _screenWidth;
  late final double _screenHeight;
  late final double _textScaleFactor;
  late final DeviceType _deviceType;

  // Design reference: 375 x 812 (iPhone X/11/12)
  static const double _designWidth = 375.0;
  static const double _designHeight = 812.0;

  Responsive(this.context) {
    _mq = MediaQuery.of(context);
    _screenWidth = _mq.size.width;
    _screenHeight = _mq.size.height;
    _textScaleFactor = _mq.textScaler.scale(1.0);
    _deviceType = _classifyDevice();
  }

  // ========== DEVICE CLASSIFICATION ==========

  DeviceType _classifyDevice() {
    if (_screenWidth < 360) return DeviceType.smallPhone;
    if (_screenWidth < 600) return DeviceType.phone;
    if (_screenWidth < 900) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  DeviceType get deviceType => _deviceType;
  bool get isSmallPhone => _deviceType == DeviceType.smallPhone;
  bool get isPhone => _deviceType == DeviceType.phone || _deviceType == DeviceType.smallPhone;
  bool get isTablet => _deviceType == DeviceType.tablet;
  bool get isDesktop => _deviceType == DeviceType.desktop;
  bool get isLargeScreen => _deviceType == DeviceType.tablet || _deviceType == DeviceType.desktop;

  double get screenWidth => _screenWidth;
  double get screenHeight => _screenHeight;
  Orientation get orientation => _mq.orientation;
  EdgeInsets get viewPadding => _mq.viewPadding;

  // ========== SCALE FACTORS ==========

  /// Facteur d'échelle horizontal basé sur la largeur de référence.
  double get scaleWidth => _screenWidth / _designWidth;

  /// Facteur d'échelle vertical basé sur la hauteur de référence.
  double get scaleHeight => _screenHeight / _designHeight;

  /// Facteur d'échelle global (moyenne pondérée, favorise la largeur).
  double get scaleFactor {
    final scale = (scaleWidth * 0.7 + scaleHeight * 0.3);
    // Clamp pour éviter des valeurs extrêmes
    return scale.clamp(0.7, 1.6);
  }

  // ========== DIMENSION HELPERS ==========

  /// Largeur en pourcentage de l'écran (0-100).
  double wp(double percent) => _screenWidth * percent / 100;

  /// Hauteur en pourcentage de l'écran (0-100).
  double hp(double percent) => _screenHeight * percent / 100;

  /// Mise à l'échelle proportionnelle d'une valeur.
  double scale(double value) => value * scaleFactor;

  /// Taille de police adaptative (tient compte du textScaleFactor).
  double fontSize(double size) {
    final scaled = size * scaleFactor;
    // Clamp pour lisibilité
    return scaled.clamp(size * 0.75, size * 1.5);
  }

  /// Taille d'icône adaptative.
  double iconSize(double size) => (size * scaleFactor).clamp(size * 0.75, size * 1.5);

  /// Rayon de bordure adaptatif.
  double radius(double value) => value * scaleFactor;

  // ========== SPACING HELPERS ==========

  /// Espacement adaptatif.
  double space(double value) => value * scaleFactor;

  SizedBox verticalSpace(double height) => SizedBox(height: space(height));
  SizedBox horizontalSpace(double width) => SizedBox(width: space(width));

  // ========== PADDING HELPERS ==========

  EdgeInsets paddingAll(double value) => EdgeInsets.all(scale(value));

  EdgeInsets paddingSymmetric({double horizontal = 0, double vertical = 0}) =>
      EdgeInsets.symmetric(
        horizontal: scale(horizontal),
        vertical: scale(vertical),
      );

  EdgeInsets paddingOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      EdgeInsets.only(
        left: scale(left),
        top: scale(top),
        right: scale(right),
        bottom: scale(bottom),
      );

  // ========== LAYOUT HELPERS ==========

  /// Nombre de colonnes adaptatif pour un GridView.
  int gridColumns({int phoneCols = 2, int tabletCols = 3, int desktopCols = 4}) {
    switch (_deviceType) {
      case DeviceType.smallPhone:
      case DeviceType.phone:
        return phoneCols;
      case DeviceType.tablet:
        return tabletCols;
      case DeviceType.desktop:
        return desktopCols;
    }
  }

  /// Largeur maximale du contenu (pour centrer sur grands écrans).
  double get maxContentWidth {
    switch (_deviceType) {
      case DeviceType.smallPhone:
      case DeviceType.phone:
        return _screenWidth;
      case DeviceType.tablet:
        return 700;
      case DeviceType.desktop:
        return 900;
    }
  }

  /// Ratio adaptatif pour les cartes de statistiques.
  double get cardAspectRatio {
    if (isSmallPhone) return 1.1;
    if (isPhone) return 1.25;
    if (isTablet) return 1.4;
    return 1.5;
  }

  /// Hauteur adaptative pour les boutons.
  double get buttonHeight => scale(50).clamp(44.0, 64.0);

  /// Taille adaptative pour les avatars / logos.
  double avatarSize(double baseSize) => (baseSize * scaleFactor).clamp(baseSize * 0.7, baseSize * 1.5);

  // ========== ADAPTIVE VALUE ==========

  /// Retourne une valeur différente selon le type de device.
  T adaptive<T>({
    required T phone,
    T? smallPhone,
    T? tablet,
    T? desktop,
  }) {
    switch (_deviceType) {
      case DeviceType.smallPhone:
        return smallPhone ?? phone;
      case DeviceType.phone:
        return phone;
      case DeviceType.tablet:
        return tablet ?? phone;
      case DeviceType.desktop:
        return desktop ?? tablet ?? phone;
    }
  }
}

enum DeviceType {
  smallPhone,
  phone,
  tablet,
  desktop,
}

/// Extension pour accéder facilement au Responsive depuis le context.
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
}
