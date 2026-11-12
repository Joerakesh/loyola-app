import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/college_announcement.dart';
import 'glass_container.dart';

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.onTap,
  });

  final CollegeAnnouncement announcement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPdf = announcement.isPdf;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (isPdf ? AppColors.red : AppColors.crimson)
                    .withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isPdf ? Icons.picture_as_pdf_rounded : Icons.campaign_rounded,
                color: isPdf ? AppColors.red : AppColors.crimson,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isPdf ? 'PDF · ${announcement.source}' : announcement.source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isPdf ? Icons.open_in_new_rounded : Icons.arrow_forward_rounded,
              color: AppColors.white54,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
