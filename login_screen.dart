import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isSignUp) {
        await SupabaseService.instance
            .signUp(_email.text.trim(), _password.text, _name.text.trim());
      } else {
        await SupabaseService.instance
            .signIn(_email.text.trim(), _password.text);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.campaign, size: 64),
              const SizedBox(height: 12),
              Text(_isSignUp ? 'Create account' : 'College Notice Board',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              if (_isSignUp)
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'College email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isSignUp ? 'Sign up' : 'Log in'),
              ),
              TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(_isSignUp
                    ? 'Already have an account? Log in'
                    : "New student? Sign up"),
              ),
              const SizedBox(height: 24),
              const Text(
                'New accounts are Students by default.\n'
                'Admin/Faculty access is granted manually by the college.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
