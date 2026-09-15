import 'package:flutter/material.dart';
import '../models/notice.dart';
import '../services/supabase_service.dart';
import '../widgets/notice_card.dart';
import '../terminal/secret_terminal_screen.dart';
import 'admin_post_screen.dart';

class NoticeFeedScreen extends StatefulWidget {
  const NoticeFeedScreen({super.key});
  @override
  State<NoticeFeedScreen> createState() => _NoticeFeedScreenState();
}

class _NoticeFeedScreenState extends State<NoticeFeedScreen> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    SupabaseService.instance.isAdmin().then((v) => setState(() => _isAdmin = v));
  }

  // Hidden trigger: long-press the app logo to enter Secret Mode.
  void _enterSecretMode() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SecretTerminalScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: _enterSecretMode,
          child: const Row(
            children: [
              Icon(Icons.campaign),
              SizedBox(width: 8),
              Text('Notice Board'),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => SupabaseService.instance.signOut(),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Post notice'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminPostScreen()),
              ),
            )
          : null,
      body: StreamBuilder<List<Notice>>(
        stream: SupabaseService.instance.watchNotices(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notices = snapshot.data!;
          if (notices.isEmpty) {
            return const Center(child: Text('No notices yet.'));
          }
          return ListView.builder(
            itemCount: notices.length,
            itemBuilder: (context, i) => NoticeCard(
              notice: notices[i],
              isAdmin: _isAdmin,
              onDelete: _isAdmin
                  ? () => SupabaseService.instance.deleteNotice(notices[i].id)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
