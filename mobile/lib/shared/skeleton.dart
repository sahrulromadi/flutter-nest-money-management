import 'package:flutter/material.dart';

/// Skeleton loading — kotak shimmer yang bentuknya niru konten asli.
/// Ganti `CircularProgressIndicator` polos di `.when(loading:)`.
/// Tanpa package `shimmer` — cukup AnimatedBuilder + gradient bergerak.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 6,
    this.shape = BoxShape.rectangle,
  });

  const Skeleton.circle({super.key, required double size})
      : width = size,
        height = size,
        radius = 0,
        shape = BoxShape.circle;

  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.06),
      base,
    );

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value; // 0..1 kiri -> kanan
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.rectangle
                ? BorderRadius.circular(widget.radius)
                : null,
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * (1 - t), 0),
              end: Alignment(1 - 2 * (1 - t) + 1, 0),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}

/// Baris tile skeleton: leading circle + 2 garis judul/subtitle + garis kanan.
class SkeletonTile extends StatelessWidget {
  const SkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Skeleton(width: 36, height: 36, radius: 6),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 140, height: 13),
                SizedBox(height: 8),
                Skeleton(width: 80, height: 11),
              ],
            ),
          ),
          SizedBox(width: 12),
          Skeleton(width: 64, height: 14),
        ],
      ),
    );
  }
}

/// Baris chip skeleton — buat selector akun/kategori/tipe di form pas loading.
class SkeletonChips extends StatelessWidget {
  const SkeletonChips({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        count,
        (_) => const Skeleton(width: 76, height: 32, radius: 8),
      ),
    );
  }
}

/// List of SkeletonTile — dipakai di semua layar list pas loading.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: List.generate(count, (_) => const SkeletonTile()),
    );
  }
}
