import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notice.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._();
  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  // ---- AUTH ----
  Future<AuthResponse> signIn(String email, String password) =>
      client.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUp(String email, String password, String fullName) =>
      client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

  Future<void> signOut() => client.auth.signOut();

  User? get currentUser => client.auth.currentUser;

  Future<bool> isAdmin() async {
    final uid = currentUser?.id;
    if (uid == null) return false;
    final row = await client
        .from('profiles')
        .select('role')
        .eq('id', uid)
        .single();
    return row['role'] == 'admin';
  }

  // ---- NOTICES ----
  Stream<List<Notice>> watchNotices() {
    return client
        .from('notices')
        .stream(primaryKey: ['id'])
        .order('event_date')
        .map((rows) => rows.map(Notice.fromMap).toList());
  }

  Future<void> createNotice({
    required String title,
    String? description,
    required DateTime eventDate,
    String? venue,
    String? clubId,
  }) async {
    final uid = currentUser!.id;
    await client.from('notices').insert({
      'title': title,
      'description': description,
      'event_date': eventDate.toIso8601String(),
      'venue': venue,
      'club_id': clubId,
      'created_by': uid,
    });
  }

  Future<void> deleteNotice(String id) =>
      client.from('notices').delete().eq('id', id);

  // ---- CLUBS (used by both UI and the secret terminal) ----
  Future<List<Map<String, dynamic>>> listClubs() async {
    final rows = await client.from('clubs').select('id, name, description');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Notice>> eventsForClub(String clubName) async {
    final club = await client
        .from('clubs')
        .select('id')
        .ilike('name', clubName)
        .maybeSingle();
    if (club == null) return [];
    final rows = await client
        .from('notices')
        .select()
        .eq('club_id', club['id'])
        .gte('event_date', DateTime.now().toIso8601String())
        .order('event_date');
    return List<Map<String, dynamic>>.from(rows).map(Notice.fromMap).toList();
  }

  // ---- FCM TOKEN ----
  Future<void> saveFcmToken(String token) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await client.from('profiles').update({'fcm_token': token}).eq('id', uid);
  }
}
