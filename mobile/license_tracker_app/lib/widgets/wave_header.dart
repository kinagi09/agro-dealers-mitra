import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'wave_clippers.dart';

const _headerGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [AppColors.brightGreen, AppColors.midGreen],
);

/// Short wavy header bar: a leading control, a title, and an optional
/// trailing control, all in one row. Used on the home screen and on
/// category display/update screens (back arrow + title).
class WaveHeaderBar extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final double height;

  const WaveHeaderBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const HeaderWaveClipper(),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: const BoxDecoration(gradient: _headerGradient),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                leading ?? const SizedBox(width: 40),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                trailing ?? const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tall wavy hero header with a centered logo/title/subtitle stack, used
/// on the login and register screens.
class WaveHeaderHero extends StatelessWidget {
  final Widget child;
  final Widget? leading;
  final double height;

  const WaveHeaderHero({
    super.key,
    required this.child,
    this.leading,
    this.height = 320,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const HeaderWaveClipper(),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: const BoxDecoration(gradient: _headerGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (leading != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(children: [leading!]),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Center(child: child),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Decorative wavy band, used as a footer flourish at the bottom of
/// hero-style screens. Optionally holds a small piece of content (e.g. a
/// "Sign Up" link) centered near the bottom of the band.
class WaveFooter extends StatelessWidget {
  final double height;
  final Widget? child;

  const WaveFooter({super.key, this.height = 90, this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipPath(
            clipper: const FooterWaveClipper(),
            child: Container(
              height: height,
              width: double.infinity,
              color: AppColors.brightGreen,
            ),
          ),
          if (child != null)
            Padding(padding: const EdgeInsets.only(bottom: 16), child: child),
        ],
      ),
    );
  }
}

/// The brand leaf mark, tinted for use on green backgrounds.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon/app_icon_foreground.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

/// A circular button matching the sketch's back-arrow / menu chip style.
class WaveHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const WaveHeaderIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: Colors.black87),
        onPressed: onPressed,
      ),
    );
  }
}
