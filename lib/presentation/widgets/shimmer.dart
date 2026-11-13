import 'package:flutter/material.dart';

/// Lightweight shimmer effect (no extra package). Everything painted inside
/// [child] becomes a "bone" that the moving highlight slides across.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = Color.alphaBlend(scheme.onSurface.withAlpha(22), scheme.surface);
    final highlight = Color.alphaBlend(scheme.onSurface.withAlpha(60), scheme.surface);

    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: [base, highlight, base],
          stops: const [0.35, 0.5, 0.65],
          transform: _SlideTransform(_c.value),
        ).createShader(bounds),
        child: child,
      ),
    );
  }
}

class _SlideTransform extends GradientTransform {
  const _SlideTransform(this.t);
  final double t;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (t * 2 - 1), 0, 0);
}

Widget _bone({double? width, double? height, double radius = 6}) => Container(
  width: width,
  height: height,
  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius)),
);

/// Full-size shimmering block, used as an image placeholder.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key});

  @override
  Widget build(BuildContext context) => Shimmer(child: Container(color: Colors.white));
}

/// Skeleton of [ProductCard] (list mode).
class SkeletonListCard extends StatelessWidget {
  const SkeletonListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          _bone(width: 110, height: double.infinity, radius: 0),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bone(width: 150, height: 14),
                  const SizedBox(height: 8),
                  _bone(width: 90, height: 10),
                  const SizedBox(height: 10),
                  _bone(height: 10),
                  const SizedBox(height: 6),
                  _bone(width: 120, height: 10),
                  const Spacer(),
                  _bone(width: 60, height: 14),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

/// Skeleton of [ProductGridCard] (grid mode).
class SkeletonGridCard extends StatelessWidget {
  const SkeletonGridCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _bone(width: double.infinity, radius: 0)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _bone(width: 110, height: 12),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _bone(width: 70, height: 10),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _bone(width: 50, height: 14),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
