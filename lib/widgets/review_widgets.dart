import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/review_model.dart';
import 'star_rating.dart';

// Review Form Dialog
class ReviewFormDialog extends StatefulWidget {
  final ReviewModel? existingReview;
  final Function(int rating, String comment) onSubmit;
  final bool isEmbedded; // When true, doesn't wrap in AlertDialog

  const ReviewFormDialog({
    super.key,
    this.existingReview,
    required this.onSubmit,
    this.isEmbedded = false,
  });

  @override
  State<ReviewFormDialog> createState() => _ReviewFormDialogState();
}

class _ReviewFormDialogState extends State<ReviewFormDialog> {
  late int _rating;
  late TextEditingController _commentController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingReview?.rating ?? 0;
    _commentController = TextEditingController(
      text: widget.existingReview?.comment ?? '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Widget _buildFormContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rating',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Center(
          child: StarRatingInput(
            initialRating: _rating,
            onRatingChanged: (value) {
              setState(() {
                _rating = value;
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Komentar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commentController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Bagikan pengalaman Anda dengan produk ini...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (widget.isEmbedded) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSubmitting || _rating == 0
                    ? null
                    : () async {
                        setState(() => _isSubmitting = true);
                        widget.onSubmit(_rating, _commentController.text.trim());
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kirim'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return _buildFormContent();
    }

    return AlertDialog(
      title: Text(
        widget.existingReview != null ? 'Edit Ulasan' : 'Tulis Ulasan',
      ),
      content: SingleChildScrollView(
        child: _buildFormContent(),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting || _rating == 0
              ? null
              : () async {
                  setState(() => _isSubmitting = true);
                  widget.onSubmit(_rating, _commentController.text.trim());
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Kirim'),
        ),
      ],
    );
  }
}

// Single Review Card
class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReviewCard({
    super.key,
    required this.review,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
  });

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
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    review.userName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.userName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (isOwner) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Anda',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM yyyy').format(review.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                StarRating(rating: review.rating.toDouble(), size: 16),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(review.comment),
            ],
            if (isOwner) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    onPressed: onEdit,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Hapus'),
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Review List Widget
class ReviewList extends StatelessWidget {
  final List<ReviewModel> reviews;
  final String? currentUserId;
  final Function(ReviewModel)? onEdit;
  final Function(ReviewModel)? onDelete;
  final bool showEmpty;

  const ReviewList({
    super.key,
    required this.reviews,
    this.currentUserId,
    this.onEdit,
    this.onDelete,
    this.showEmpty = true,
  });

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty && showEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada ulasan',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Jadilah yang pertama memberikan ulasan!',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: reviews.map((review) {
        final isOwner = currentUserId != null && review.userId == currentUserId;
        return ReviewCard(
          review: review,
          isOwner: isOwner,
          onEdit: isOwner && onEdit != null ? () => onEdit!(review) : null,
          onDelete: isOwner && onDelete != null ? () => onDelete!(review) : null,
        );
      }).toList(),
    );
  }
}
