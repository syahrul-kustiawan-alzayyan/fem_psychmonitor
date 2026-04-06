import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────
/// Particle Animation Widget - Modern floating particles
/// ─────────────────────────────────────────────────────────────
class ParticleAnimation extends StatefulWidget {
  final double width;
  final double height;
  final int particleCount;
  final Color? particleColor;

  const ParticleAnimation({
    super.key,
    required this.width,
    required this.height,
    this.particleCount = 20,
    this.particleColor,
  });

  @override
  State<ParticleAnimation> createState() => _ParticleAnimationState();
}

class _ParticleAnimationState extends State<ParticleAnimation>
    with TickerProviderStateMixin {
  late List<Particle> _particles;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(
      widget.particleCount,
      (i) => Particle(
        x: math.Random().nextDouble() * widget.width,
        y: math.Random().nextDouble() * widget.height,
        size: math.Random().nextDouble() * 3 + 1,
        speedX: (math.Random().nextDouble() - 0.5) * 0.5,
        speedY: (math.Random().nextDouble() - 0.5) * 0.5,
        opacity: math.Random().nextDouble() * 0.5 + 0.2,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.addListener(_updateParticles);
  }

  void _updateParticles() {
    setState(() {
      for (var particle in _particles) {
        particle.x += particle.speedX;
        particle.y += particle.speedY;

        // Wrap around edges
        if (particle.x < 0) particle.x = widget.width;
        if (particle.x > widget.width) particle.x = 0;
        if (particle.y < 0) particle.y = widget.height;
        if (particle.y > widget.height) particle.y = 0;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.particleColor ?? Theme.of(context).primaryColor;
    
    return CustomPaint(
      size: Size(widget.width, widget.height),
      painter: ParticlePainter(
        particles: _particles,
        color: color,
      ),
    );
  }
}

class Particle {
  double x, y, size, speedX, speedY, opacity;
  
  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

/// ─────────────────────────────────────────────────────────────
/// Animated Wave Bars - Modern audio visualization
/// ─────────────────────────────────────────────────────────────
class AnimatedWaveBars extends StatefulWidget {
  final double width;
  final double height;
  final int barCount;
  final bool isAnimating;
  final Gradient? gradient;

  const AnimatedWaveBars({
    super.key,
    required this.width,
    required this.height,
    this.barCount = 40,
    this.isAnimating = false,
    this.gradient,
  });

  @override
  State<AnimatedWaveBars> createState() => _AnimatedWaveBarsState();
}

class _AnimatedWaveBarsState extends State<AnimatedWaveBars>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.barCount,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300 + (i % 5) * 100),
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.1,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    if (widget.isAnimating) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimation() {
    for (var controller in _controllers) {
      controller.stop();
      controller.value = 0.1;
    }
  }

  @override
  void didUpdateWidget(AnimatedWaveBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating != oldWidget.isAnimating) {
      if (widget.isAnimating) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (context, child) {
              final height = widget.height * _animations[i].value;
              return Container(
                width: 3,
                height: height,
                decoration: BoxDecoration(
                  gradient: widget.gradient ??
                      LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withValues(alpha: 0.3),
                        ],
                      ),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// Morphing Shape - Animated shape transitions
/// ─────────────────────────────────────────────────────────────
class MorphingShape extends StatefulWidget {
  final double size;
  final Gradient gradient;
  final Duration duration;

  const MorphingShape({
    super.key,
    required this.size,
    required this.gradient,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<MorphingShape> createState() => _MorphingShapeState();
}

class _MorphingShapeState extends State<MorphingShape>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(
              widget.size * 0.5 * (1 - _animation.value * 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withValues(alpha: 0.3),
                blurRadius: 30 + (_animation.value * 20),
                spreadRadius: _animation.value * 5,
              ),
            ],
          ),
        );
      },
    );
  }
}
