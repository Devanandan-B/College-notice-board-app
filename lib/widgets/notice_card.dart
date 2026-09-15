import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notice.dart';
import '../services/calendar_service.dart';

class NoticeCard extends StatelessWidget {
  final Notice notice;
  final bool isAdmin;
  final VoidCallback? onDelete;

  const NoticeCard({
    super.key,
    required this.notice,
    this.isAdmin = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, MMM d • h:mm a');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(notice.title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                if (isAdmin && onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                  ),
              ],
            ),
            if (notice.description != null && notice.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(notice.description!),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 4),
                Text(dateFmt.format(notice.eventDate)),
              ],
            ),
            if (notice.venue != null && notice.venue!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text(notice.venue!),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_month, size: 18),
                label: const Text('Add to Google Calendar'),
                onPressed: () => CalendarService.openAddToCalendar(
                  title: notice.title,
                  start: notice.eventDate,
                  description: notice.description,
                  location: notice.venue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
