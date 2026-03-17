import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../services/supabase/supabase_client_service.dart';

class CourseReviewDialog extends StatefulWidget {
  final String courseId;
  final String userId;
  final VoidCallback onSuccess;

  const CourseReviewDialog({
    super.key,
    required this.courseId,
    required this.userId,
    required this.onSuccess,
  });

  @override
  State<CourseReviewDialog> createState() => _CourseReviewDialogState();
}

class _CourseReviewDialogState extends State<CourseReviewDialog> {
  final _service = SupabaseService.instance;

  int _rating = 5;
  final TextEditingController _reviewC = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    try {
      setState(() => _isSubmitting = true);

      await _service.submitCourseReview(
        userId: widget.userId,
        courseId: widget.courseId,
        rating: _rating,
        reviewText: _reviewC.text.trim().isEmpty
            ? null
            : _reviewC.text.trim(),
      );

      widget.onSuccess();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kPrimaryColor,
      title: const Text(
        'Rate this course',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
                  (i) => IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(
                  i < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reviewC,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Write your review...',
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReview,
          child: _isSubmitting
              ? const CircularProgressIndicator()
              : const Text('Submit'),
        ),
      ],
    );
  }
}
