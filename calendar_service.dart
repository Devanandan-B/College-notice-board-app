import 'package:url_launcher/url_launcher.dart';

class CalendarService {
  /// Formats a DateTime as YYYYMMDDTHHMMSSZ (UTC), the format Google
  /// Calendar's TEMPLATE action expects.
  static String _fmt(DateTime dt) {
    final utc = dt.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year}${two(utc.month)}${two(utc.day)}'
        'T${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
  }

  static Uri buildAddToCalendarUrl({
    required String title,
    required DateTime start,
    DateTime? end,
    String? description,
    String? location,
  }) {
    final endTime = end ?? start.add(const Duration(hours: 1));
    final params = {
      'action': 'TEMPLATE',
      'text': title,
      'dates': '${_fmt(start)}/${_fmt(endTime)}',
      if (description != null) 'details': description,
      if (location != null) 'location': location,
    };
    return Uri.https('calendar.google.com', '/calendar/render', params);
  }

  static Future<void> openAddToCalendar({
    required String title,
    required DateTime start,
    DateTime? end,
    String? description,
    String? location,
  }) async {
    final url = buildAddToCalendarUrl(
      title: title,
      start: start,
      end: end,
      description: description,
      location: location,
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
