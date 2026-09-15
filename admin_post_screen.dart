import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class AdminPostScreen extends StatefulWidget {
  const AdminPostScreen({super.key});
  @override
  State<AdminPostScreen> createState() => _AdminPostScreenState();
}

class _AdminPostScreenState extends State<AdminPostScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _venue = TextEditingController();
  DateTime? _eventDate;
  List<Map<String, dynamic>> _clubs = [];
  String? _selectedClubId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    SupabaseService.instance.listClubs().then((c) => setState(() => _clubs = c));
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    setState(() => _eventDate = DateTime(
        date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _eventDate == null) return;
    setState(() => _saving = true);
    try {
      await SupabaseService.instance.createNotice(
        title: _title.text.trim(),
        description: _description.text.trim(),
        eventDate: _eventDate!,
        venue: _venue.text.trim(),
        clubId: _selectedClubId,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a notice')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title')),
          TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description')),
          TextField(
              controller: _venue,
              decoration: const InputDecoration(labelText: 'Venue')),
          const SizedBox(height: 12),
          ListTile(
            title: Text(_eventDate == null
                ? 'Pick date & time'
                : _eventDate.toString()),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDateTime,
          ),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Club (optional)'),
            value: _selectedClubId,
            items: _clubs
                .map((c) => DropdownMenuItem(
                    value: c['id'] as String, child: Text(c['name'])))
                .toList(),
            onChanged: (v) => setState(() => _selectedClubId = v),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const CircularProgressIndicator()
                : const Text('Publish notice'),
          ),
        ],
      ),
    );
  }
}
