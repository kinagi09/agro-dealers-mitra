import 'package:flutter/material.dart';

/// Clips a rectangle so its bottom edge is a smooth asymmetric wave.
/// Used behind headers (the green area sits above the wave).
class HeaderWaveClipper extends CustomClipper<Path> {
  const HeaderWaveClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.82);
    final firstControlPoint = Offset(size.width * 0.28, size.height);
    final firstEndPoint = Offset(size.width * 0.55, size.height * 0.88);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    final secondControlPoint = Offset(size.width * 0.8, size.height * 0.76);
    final secondEndPoint = Offset(size.width, size.height * 0.86);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Clips a rectangle so its top edge is a smooth asymmetric wave, filled
/// down to the bottom. Used as a decorative footer band.
class FooterWaveClipper extends CustomClipper<Path> {
  const FooterWaveClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.45);
    final firstControlPoint = Offset(size.width * 0.25, size.height * 0.05);
    final firstEndPoint = Offset(size.width * 0.5, size.height * 0.4);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    final secondControlPoint = Offset(size.width * 0.75, size.height * 0.7);
    final secondEndPoint = Offset(size.width, size.height * 0.3);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
