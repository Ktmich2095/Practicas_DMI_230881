import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../config/branding/brand_assets.dart';
import '../../../config/theme/season_style.dart';
import '../../../domain/entities/season.dart';
import 'toktik_logo.dart';

double phase(double t, double from, double to) =>
    ((t - from) / (to - from)).clamp(0.0, 1.0);

/// Four timelines, one small native animation controller. No video or fake progress.
class SeasonIntro extends StatefulWidget {
  final Season season;
  final VoidCallback onComplete;
  final Widget? footer;
  const SeasonIntro({
    super.key,
    required this.season,
    required this.onComplete,
    this.footer,
  });
  @override
  State<SeasonIntro> createState() => _SeasonIntroState();
}

class _SeasonIntroState extends State<SeasonIntro>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController controller;
  bool started = false, completed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller =
        AnimationController(
          vsync: this,
          duration: BrandAssets.duration(widget.season),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && !completed) {
            completed = true;
            widget.onComplete();
          }
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!started) {
      started = true;
      if (MediaQuery.disableAnimationsOf(context)) {
        controller.duration = const Duration(milliseconds: 180);
      }
      controller.forward();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !completed) {
      controller.forward();
    } else if (!completed) {
      controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final reduced = MediaQuery.disableAnimationsOf(context);
        final t = reduced ? 1.0 : controller.value;
        final style = SeasonStyle.of(widget.season);
        final opacity = switch (widget.season) {
          Season.normal => phase(t, .35, .60),
          Season.halloween => phase(t, .35, .58),
          Season.christmas => phase(t, .22, .50),
          Season.valentine => phase(t, .40, .60),
        };
        final pop = Curves.easeOutBack.transform(phase(t, .35, .70));
        final scale = widget.season == Season.valentine && t > .60
            ? 1 + .045 * math.sin((t - .60) * math.pi * 10)
            : .78 + .22 * pop;
        return LayoutBuilder(
          builder: (context, constraints) {
            final logoSize = math.min(
              220.0,
              math.min(constraints.maxWidth * .52, constraints.maxHeight * .31),
            );
            return Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: BrandAssets.background(widget.season),
                    ),
                  ),
                ),
                if (!reduced)
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _IntroPainter(widget.season, t, logoSize),
                    ),
                  ),
                Center(
                  child: Transform.translate(
                    offset: const Offset(0, -34),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: opacity,
                          child: Transform.scale(
                            scale: scale,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: style.primary.withValues(
                                      alpha: widget.season == Season.halloween
                                          ? opacity * .16
                                          : .08 * opacity,
                                    ),
                                    blurRadius: 60,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: TokTikLogo(
                                season: widget.season,
                                size: logoSize,
                                decorated:
                                    widget.season != Season.christmas ||
                                    reduced,
                              ),
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: phase(t, .63, .84),
                          child: const Text(
                            'TokTik',
                            style: TextStyle(
                              fontFamily: 'sans-serif',
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Opacity(
                          opacity: phase(t, .74, .94),
                          child: Text(
                            switch (widget.season) {
                              Season.normal => 'Historias en movimiento',
                              Season.halloween => 'Un poco de misterio',
                              Season.christmas => 'Comparte la magia',
                              Season.valentine => 'Momentos que conectan',
                            },
                            style: TextStyle(
                              fontSize: 13,
                              color: style.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!reduced && widget.season == Season.christmas)
                  IgnorePointer(
                    child: CustomPaint(painter: _HatPainter(t, logoSize)),
                  ),
                if (widget.footer != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                        child: Opacity(
                          opacity: reduced ? 1 : phase(t, .78, .94),
                          child: widget.footer,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    ),
  );
}

class _IntroPainter extends CustomPainter {
  final Season season;
  final double t, logoSize;
  _IntroPainter(this.season, this.t, this.logoSize);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 76);
    final style = SeasonStyle.of(season);
    if (season == Season.normal) {
      final join = Curves.easeInOut.transform(phase(t, .10, .42));
      final fade = phase(t, .02, .12) * (1 - phase(t, .43, .61));
      for (final side in [-1, 1]) {
        final p =
            center +
            Offset(
              side * size.width * .32 * (1 - join),
              side * 24 * (1 - join),
            );
        canvas.drawCircle(
          p,
          10,
          Paint()
            ..color = (side < 0 ? style.primary : style.accent).withValues(
              alpha: fade,
            )
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
        canvas.drawCircle(
          p,
          4,
          Paint()..color = Colors.white.withValues(alpha: fade),
        );
      }
    } else if (season == Season.halloween) {
      for (var i = 0; i < 3; i++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(
              size.width * (.25 + i * .25) + math.sin(t * 6 + i) * 20,
              size.height * .40,
            ),
            width: size.width * .7,
            height: 90,
          ),
          Paint()
            ..color = const Color(0xFF74449F)
                .withValues(alpha: .12 * phase(t, 0, .14))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35),
        );
      }
      for (var i = 0; i < 3; i++) {
        final flight = phase(t, .04 + i * .035, .43 + i * .03);
        if (flight > 0 && flight < 1) {
          _bat(
            canvas,
            Offset(
              -30 + (size.width + 60) * flight,
              size.height * (.24 + i * .045) + math.sin(flight * 12) * 12,
            ),
            14 + i * 3.0,
            t,
          );
        }
      }
      final pumpkinAlpha = phase(t, .18, .35) * (1 - phase(t, .62, .85));
      _pumpkin(
        canvas,
        center + const Offset(12, 0),
        logoSize * .49,
        pumpkinAlpha,
        phase(t, .42, .60),
      );
      _pumpkin(
        canvas,
        Offset(size.width * .16, size.height * .75),
        15,
        .35 * phase(t, .35, .65),
        .5,
      );
    } else if (season == Season.christmas) {
      for (var i = 0; i < 14; i++) {
        final x =
            ((i * .618 + .08) % 1) * size.width + math.sin(t * 5 + i) * 10;
        final y = ((t * (.5 + i * .025) + i * .17) % 1) * size.height;
        _spark(
          canvas,
          Offset(x, y),
          2 + (i % 3).toDouble(),
          Colors.white.withValues(alpha: .5 * phase(t, .03, .15)),
        );
      }
      for (var i = 0; i < 7; i++) {
        final x = size.width * (i + 1) / 8;
        canvas.drawCircle(
          Offset(x, 58 + math.sin(i * .8) * 8),
          3,
          Paint()
            ..color = (i.isEven ? style.primary : style.accent).withValues(
              alpha: phase(t, .57 + i * .025, .72 + i * .025),
            ),
        );
      }
      _spark(
        canvas,
        center + Offset(logoSize * .37, -logoSize * .27),
        8,
        style.primary.withValues(
          alpha: phase(t, .65, .76) * (1 - phase(t, .85, 1)),
        ),
      );
    } else {
      for (var i = 0; i < 10; i++) {
        final x = size.width * ((i * .618 + .12) % 1) + math.sin(t * 4 + i) * 8;
        final y = size.height * (1 - ((t * .6 + i * .13) % 1));
        _heart(
          canvas,
          Offset(x, y),
          4 + (i % 3) * 2.0,
          style.primary.withValues(alpha: .27 * phase(t, .04, .18)),
        );
      }
      final join = Curves.easeInOut.transform(phase(t, .10, .43));
      final alpha = phase(t, .04, .14) * (1 - phase(t, .43, .60));
      _heart(
        canvas,
        center + Offset(-size.width * .25 * (1 - join), 0),
        22,
        style.primary.withValues(alpha: alpha),
      );
      _heart(
        canvas,
        center + Offset(size.width * .25 * (1 - join), 0),
        22,
        style.accent.withValues(alpha: alpha),
      );
    }
    for (var i = 0; i < 9; i++) {
      final x = size.width * ((i * .618 + .07) % 1);
      final y = size.height * ((i * .273 + .12) % 1) + math.sin(t * 7 + i) * 6;
      _spark(
        canvas,
        Offset(x, y),
        1.5,
        style.primary.withValues(
          alpha: (.12 + .12 * math.sin(t * 8 + i)) * phase(t, .48, .78),
        ),
      );
    }
  }

  static void _spark(Canvas canvas, Offset p, double r, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    canvas.drawLine(p - Offset(r, 0), p + Offset(r, 0), paint);
    canvas.drawLine(p - Offset(0, r), p + Offset(0, r), paint);
  }

  static void _heart(Canvas canvas, Offset p, double r, Color color) {
    final path = Path()..moveTo(p.dx, p.dy + r);
    path.cubicTo(
      p.dx - r * 2,
      p.dy - r * .2,
      p.dx - r,
      p.dy - r * 1.7,
      p.dx,
      p.dy - r * .5,
    );
    path.cubicTo(
      p.dx + r,
      p.dy - r * 1.7,
      p.dx + r * 2,
      p.dy - r * .2,
      p.dx,
      p.dy + r,
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  static void _bat(Canvas canvas, Offset p, double r, double t) {
    final flap = math.sin(t * 65) * r * .25;
    final path = Path()
      ..moveTo(p.dx - r, p.dy - r * .4 - flap)
      ..lineTo(p.dx - r * .4, p.dy)
      ..lineTo(p.dx - r * .15, p.dy - r * .4)
      ..lineTo(p.dx, p.dy - r * .1)
      ..lineTo(p.dx + r * .15, p.dy - r * .4)
      ..lineTo(p.dx + r * .4, p.dy)
      ..lineTo(p.dx + r, p.dy - r * .4 - flap)
      ..lineTo(p.dx + r * .6, p.dy + r * .5)
      ..lineTo(p.dx, p.dy + r * .25)
      ..lineTo(p.dx - r * .6, p.dy + r * .5)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFFBD86FF).withValues(alpha: .7),
    );
  }

  static void _pumpkin(
    Canvas canvas,
    Offset p,
    double r,
    double opacity,
    double eyes,
  ) {
    canvas.drawOval(
      Rect.fromCenter(center: p, width: r * 2, height: r * 1.6),
      Paint()..color = const Color(0xFFFF852D).withValues(alpha: opacity),
    );
    final paint = Paint()
      ..color = const Color(0xFFFFE373).withValues(alpha: opacity * eyes);
    for (final side in [-1, 1]) {
      final eye = p + Offset(side * r * .4, -r * .15);
      canvas.drawPath(
        Path()
          ..moveTo(eye.dx - r * .16, eye.dy)
          ..lineTo(eye.dx + r * .16, eye.dy)
          ..lineTo(eye.dx, eye.dy + r * .2)
          ..close(),
        paint,
      );
    }
    canvas.drawLine(
      p - Offset(0, r * .76),
      p - Offset(-r * .08, r * 1.02),
      Paint()
        ..color = const Color(0xFF86BB6D).withValues(alpha: opacity)
        ..strokeWidth = r * .1,
    );
  }

  @override
  bool shouldRepaint(_IntroPainter old) =>
      old.t != t || old.season != season || old.logoSize != logoSize;
}

class _HatPainter extends CustomPainter {
  final double t, logoSize;
  _HatPainter(this.t, this.logoSize);
  @override
  void paint(Canvas canvas, Size size) {
    final drop = Curves.bounceOut.transform(phase(t, .46, .70));
    final s = logoSize / 256;
    final center = Offset(size.width / 2, size.height / 2 - 76);
    canvas.save();
    canvas.translate(
      center.dx - logoSize / 2,
      center.dy - logoSize / 2 - 130 * (1 - drop),
    );
    canvas.scale(s);
    final opacity = phase(t, .44, .49);
    canvas.drawPath(
      Path()
        ..moveTo(75, 69)
        ..lineTo(94, 34)
        ..lineTo(154, 67)
        ..close(),
      Paint()..color = const Color(0xFFEE4956).withValues(alpha: opacity),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(70, 65, 161, 78),
        const Radius.circular(6),
      ),
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    canvas.drawCircle(
      const Offset(97.5, 36.5),
      7.5,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HatPainter old) => t != old.t || logoSize != old.logoSize;
}
