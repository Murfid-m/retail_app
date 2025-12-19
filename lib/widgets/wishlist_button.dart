import 'package:flutter/material.dart';
import '../../main.dart';

/// Wishlist heart button widget for product cards and detail screens
class WishlistButton extends StatelessWidget {
  final bool isInWishlist;
  final VoidCallback onToggle;
  final double size;
  final bool showBackground;

  const WishlistButton({
    super.key,
    required this.isInWishlist,
    required this.onToggle,
    this.size = 24,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      isInWishlist ? Icons.favorite : Icons.favorite_border,
      color: isInWishlist ? Colors.red : Colors.grey,
      size: size,
    );

    if (showBackground) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: icon,
          onPressed: onToggle,
          tooltip: isInWishlist ? 'Hapus dari wishlist' : 'Tambah ke wishlist',
        ),
      );
    }

    return IconButton(
      icon: icon,
      onPressed: onToggle,
      tooltip: isInWishlist ? 'Hapus dari wishlist' : 'Tambah ke wishlist',
    );
  }
}

/// Animated wishlist button with scale effect
class AnimatedWishlistButton extends StatefulWidget {
  final bool isInWishlist;
  final VoidCallback onToggle;
  final double size;

  const AnimatedWishlistButton({
    super.key,
    required this.isInWishlist,
    required this.onToggle,
    this.size = 24,
  });

  @override
  State<AnimatedWishlistButton> createState() => _AnimatedWishlistButtonState();
}

class _AnimatedWishlistButtonState extends State<AnimatedWishlistButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        icon: Icon(
          widget.isInWishlist ? Icons.favorite : Icons.favorite_border,
          color: widget.isInWishlist ? Colors.red : Colors.grey,
          size: widget.size,
        ),
        onPressed: _handleTap,
        tooltip: widget.isInWishlist ? 'Hapus dari wishlist' : 'Tambah ke wishlist',
      ),
    );
  }
}

/// Wishlist badge for app bar
class WishlistBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const WishlistBadge({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: onTap,
          tooltip: 'Wishlist',
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
