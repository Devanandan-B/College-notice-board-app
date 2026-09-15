import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

/// Parses and executes the tiny Termux-style command set.
/// Returns the plain-text lines to print to the terminal output.
class TerminalCommands {
  static const manual = '''
Available commands:
  man                         Show this manual
  clubs                       List all college clubs
  events --club [club_name]   List upcoming events for a club
  clear                       Clear the terminal screen
  exit                        Exit Secret Mode
''';

  static Future<List<String>> run(String rawInput) async {
    final input = rawInput.trim();
    if (input.isEmpty) return [];

    final parts = input.split(RegExp(r'\s+'));
    final cmd = parts.first.toLowerCase();

    switch (cmd) {
      case 'man':
      case 'help':
        return manual.split('\n');

      case 'clubs':
        return _listClubs();

      case 'events':
        return _events(parts);

      case 'clear':
        return ['__CLEAR__']; // sentinel handled by the UI

      case 'exit':
        return ['__EXIT__']; // sentinel handled by the UI

      default:
        return ['bash: $cmd: command not found', "Type 'man' to access manual"];
    }
  }

  static Future<List<String>> _listClubs() async {
    final clubs = await SupabaseService.instance.listClubs();
    if (clubs.isEmpty) return ['No clubs found.'];
    return clubs
        .map((c) => '- ${c['name']}${c['description'] != null ? '  (${c['description']})' : ''}')
        .toList();
  }

  static Future<List<String>> _events(List<String> parts) async {
    final flagIndex = parts.indexOf('--club');
    if (flagIndex == -1 || flagIndex + 1 >= parts.length) {
      return ['Usage: events --club [club_name]'];
    }
    final clubName = parts.sublist(flagIndex + 1).join(' ');
    final events = await SupabaseService.instance.eventsForClub(clubName);
    if (events.isEmpty) {
      return ['No upcoming events found for "$clubName".'];
    }
    final fmt = DateFormat('MMM d, h:mm a');
    return [
      'Upcoming events for "$clubName":',
      ...events.map((e) =>
          '  [${fmt.format(e.eventDate)}] ${e.title}${e.venue != null ? ' @ ${e.venue}' : ''}'),
    ];
  }
}
