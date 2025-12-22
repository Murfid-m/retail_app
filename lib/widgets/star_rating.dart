import 'package:flutter/material.dart';

// Star Rating Display Widget
class StarRating extends StatelessWidget {
  final double rating;
  final int starCount;
  final double size;
  final Color color;
  final Color emptyColor;
  final bool showValue;
  final TextStyle? textStyle;

  const StarRating({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.size = 20,
    this.color = Colors.amber,
    this.emptyColor = Colors.grey,
    this.showValue = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(starCount, (index) {
          final starValue = index + 1;
          if (rating >= starValue) {
            return Icon(Icons.star, size: size, color: color);
          } else if (rating >= starValue - 0.5) {
            return Icon(Icons.star_half, size: size, color: color);
          } else {
            return Icon(Icons.star_border, size: size, color: emptyColor);
          }
        }),
        if (showValue) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: textStyle ?? TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}

// Interactive Star Rating Input Widget
class StarRatingInput extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int> onRatingChanged;
  final double size;
  final Color color;
  final Color emptyColor;

  const StarRatingInput({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 40,
    this.color = Colors.amber,
    this.emptyColor = Colors.grey,
  });

  @override
  State<StarRatingInput> createState() => _StarRatingInputState();
}

class _StarRatingInputState extends State<StarRatingInput> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentRating = starValue;
            });
            widget.onRatingChanged(starValue);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              _currentRating >= starValue ? Icons.star : Icons.star_border,
              size: widget.size,
              color: _currentRating >= starValue ? widget.color : widget.emptyColor,
            ),
          ),
        );
      }),
    );
  }
}

// Rating Distribution Bar
class RatingBar extends StatelessWidget {
  final int starCount;
  final int count;
  final int totalCount;
  final Color barColor;

  const RatingBar({
    super.key,
    required this.starCount,
    required this.count,
    required this.totalCount,
    this.barColor = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalCount > 0 ? count / totalCount : 0.0;
    
    return Row(
      children: [
        Text('$starCount', style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        const Icon(Icons.star, size: 12, color: Colors.amber),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            '$count',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

// Rating Summary Card
class RatingSummaryCard extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> distribution;

  const RatingSummaryCard({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Left side - Average rating
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  StarRating(rating: averageRating, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    '$totalReviews ulasan',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // Right side - Distribution
            Expanded(
              flex: 3,
              child: Column(
                children: List.generate(5, (index) {
                  final star = 5 - index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: RatingBar(
                      starCount: star,
                      count: distribution[star] ?? 0,
                      totalCount: totalReviews,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
