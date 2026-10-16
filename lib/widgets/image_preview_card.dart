import 'dart:io';
import 'package:flutter/material.dart';

/// ويدجت مسؤول عن عرض معاينة الصورة الملتقطة أو المختارة.
/// يعرض حالة فارغة (Placeholder) عند عدم وجود صورة،
/// ويعرض الصورة نفسها عند توفرها.
class ImagePreviewCard extends StatelessWidget {
  /// الصورة المختارة (قد تكون null في الحالة الفارغة).
  final File? image;

  /// دالة اختيارية تُستدعى عند الضغط على الصورة
  /// (مفيدة لإعادة التقاط الصورة أو تغييرها).
  final VoidCallback? onTap;

  const ImagePreviewCard({
    super.key,
    required this.image,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: image == null ? _buildEmptyState() : _buildImageState(),
      ),
    );
  }

  /// الحالة الفارغة: أيقونة الكاميرا ونص إرشادي.
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 12),
          Text(
            'التقط صورة لثلاجتك',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 4),
          Text(
            'أو اختر صورة من المعرض',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// حالة وجود صورة: عرضها بزوايا دائرية.
  Widget _buildImageState() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            image!,
            fit: BoxFit.cover,
          ),
        ),
        // شارة صغيرة أعلى الصورة لتوضيح إمكانية تغييرها
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, color: Colors.white, size: 15),
                SizedBox(width: 5),
                Text(
                  'تغيير الصورة',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}