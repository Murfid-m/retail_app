import 'package:flutter/material.dart';

class SkeletonLoading extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoading({
    super.key,
    this.width,
    this.height = 20,
    this.borderRadius,
  });

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[200]!,
                Colors.grey[300]!,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

// Product Card Skeleton
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          SkeletonLoading(
            width: double.infinity,
            height: 150,
            borderRadius: BorderRadius.circular(8),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                const SkeletonLoading(
                  width: double.infinity,
                  height: 16,
                ),
                const SizedBox(height: 8),
                // Category skeleton
                SkeletonLoading(
                  width: 80,
                  height: 12,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 8),
                // Price skeleton
                const SkeletonLoading(
                  width: 100,
                  height: 20,
                ),
                const SizedBox(height: 8),
                // Stock skeleton
                const SkeletonLoading(
                  width: 60,
                  height: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Order Card Skeleton
class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SkeletonLoading(width: 120, height: 16),
                SkeletonLoading(
                  width: 80,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const SkeletonLoading(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            const SkeletonLoading(width: 200, height: 14),
            const SizedBox(height: 12),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonLoading(width: 100, height: 14),
                SkeletonLoading(width: 120, height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Statistics Card Skeleton
class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonLoading(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 8),
                const SkeletonLoading(width: 80, height: 14),
              ],
            ),
            const SizedBox(height: 12),
            const SkeletonLoading(width: double.infinity, height: 20),
            const SizedBox(height: 4),
            const SkeletonLoading(width: 100, height: 12),
          ],
        ),
      ),
    );
  }
}

// List Skeleton
class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int)? itemBuilder;
  final Widget? itemSkeleton;
  final EdgeInsetsGeometry? padding;
  final Widget? separator;

  const ListSkeleton({
    super.key,
    this.itemCount = 5,
    this.itemBuilder,
    this.itemSkeleton,
    this.padding,
    this.separator,
  }) : assert(itemBuilder != null || itemSkeleton != null);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: itemCount,
      padding: padding ?? const EdgeInsets.all(16),
      itemBuilder: itemBuilder ?? (context, index) => itemSkeleton!,
      separatorBuilder: (context, index) => separator ?? const SizedBox(height: 0),
    );
  }
}

// Grid Skeleton
class GridSkeleton extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int)? itemBuilder;
  final Widget? itemSkeleton;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry? padding;

  const GridSkeleton({
    super.key,
    this.itemCount = 6,
    this.itemBuilder,
    this.itemSkeleton,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.7,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.padding,
  }) : assert(itemBuilder != null || itemSkeleton != null);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      padding: padding ?? const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: itemBuilder ?? (context, index) => itemSkeleton!,
    );
  }
}
