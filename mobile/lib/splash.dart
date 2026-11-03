import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'design.dart';

/// A single camera shutter animation shown while the app restores its session.
class CamPahSplash extends StatefulWidget {
  const CamPahSplash({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<CamPahSplash> createState() => _CamPahSplashState();
}

class _CamPahSplashState extends State<CamPahSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  bool started = false;
  bool completed = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => finish());
    } else if (!started) {
      started = true;
      controller.forward().whenCompleteOrCancel(finish);
    }
  }

  void finish() {
    if (!mounted || completed) return;
    completed = true;
    widget.onComplete();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: forest,
        body: Semantics(
          label: 'CamPah, menyiapkan aplikasi',
          child: ExcludeSemantics(
              child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final t = controller.value;
              final entrance =
                  Curves.easeOutCubic.transform((t / .35).clamp(0, 1));
              final shutter = t < .43 || t > .72
                  ? 0.0
                  : t < .56
                      ? (t - .43) / .13
                      : (.72 - t) / .16;
              final flash = t < .54 || t > .68
                  ? 0.0
                  : t < .59
                      ? (t - .54) / .05
                      : (.68 - t) / .09;
              final text =
                  Curves.easeOut.transform(((t - .2) / .38).clamp(0, 1));
              final scale = .88 + .12 * entrance - .025 * shutter;
              return Stack(fit: StackFit.expand, children: [
                const _SplashBackdrop(),
                Center(
                    child: SingleChildScrollView(
                        child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Opacity(
                        opacity: entrance,
                        child: Transform.scale(
                            scale: scale,
                            child: SizedBox(
                                width: 144,
                                height: 144,
                                child: Stack(children: [
                                  const CamPahMark(size: 144),
                                  Positioned(
                                      left: 49.5,
                                      top: 58.5,
                                      child: IgnorePointer(
                                          child: Opacity(
                                        opacity: shutter.clamp(0, 1),
                                        child: CustomPaint(
                                            size: const Size(45, 45),
                                            painter: _ShutterPainter(shutter)),
                                      ))),
                                ])))),
                    const SizedBox(height: 20),
                    Opacity(
                        opacity: text,
                        child: Transform.translate(
                            offset: Offset(0, 10 * (1 - text)),
                            child: const Column(children: [
                              Text('CamPah',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -.8)),
                              SizedBox(height: 8),
                              Text('SATU FOTO, LANGKAH BERARTI',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Color(0xFFBDDBC3),
                                      fontSize: 9,
                                      letterSpacing: 1.7,
                                      fontWeight: FontWeight.w800)),
                            ]))),
                  ]),
                ))),
                Positioned.fill(
                    child: IgnorePointer(
                        child: Opacity(
                  key: const ValueKey('splash-flash'),
                  opacity: (.16 * flash).clamp(0, 1),
                  child: const ColoredBox(color: Color(0xFFF2FFD8)),
                ))),
                const Positioned(
                    bottom: 42,
                    left: 20,
                    right: 20,
                    child: SafeArea(
                        top: false,
                        child: Text('BERSAMA JAGA LINGKUNGAN',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFF8DB29B),
                                fontSize: 9,
                                letterSpacing: 1.3,
                                fontWeight: FontWeight.w700)))),
              ]);
            },
          )),
        ),
      );
}

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();
  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned(top: -130, right: -110, child: _ring(280)),
        Positioned(bottom: -160, left: -100, child: _ring(320)),
        const Positioned(
            top: 115,
            left: 48,
            child: Icon(Icons.auto_awesome_rounded,
                size: 15, color: Color(0xFF537D62))),
        const Positioned(
            bottom: 155,
            right: 46,
            child:
                Icon(Icons.eco_outlined, size: 19, color: Color(0xFF537D62))),
      ]);

  Widget _ring(double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x1FCCE8C1))),
      child: Center(
          child: Container(
              width: size * .68,
              height: size * .68,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x1FCCE8C1))))));
}

class _ShutterPainter extends CustomPainter {
  _ShutterPainter(this.amount);
  final double amount;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.width * .48;
    final inner = outer * (1 - .9 * amount);
    final paint = Paint()..color = const Color(0xFF103D31);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      final b = (i + 1) * math.pi / 3;
      final path = Path()
        ..moveTo(
            center.dx + outer * math.cos(a), center.dy + outer * math.sin(a))
        ..lineTo(
            center.dx + outer * math.cos(b), center.dy + outer * math.sin(b))
        ..lineTo(center.dx + inner * math.cos(b + .38 * amount),
            center.dy + inner * math.sin(b + .38 * amount))
        ..lineTo(center.dx + inner * math.cos(a + .38 * amount),
            center.dy + inner * math.sin(a + .38 * amount))
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShutterPainter oldDelegate) =>
      oldDelegate.amount != amount;
}
