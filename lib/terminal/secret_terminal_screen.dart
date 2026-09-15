import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'terminal_commands.dart';

/// Secret Mode: replaces the ENTIRE app UI with a pure black,
/// monospaced, green-on-black terminal. Nothing from the normal
/// Scaffold/AppBar/etc. is visible while this is on screen.
class SecretTerminalScreen extends StatefulWidget {
  const SecretTerminalScreen({super.key});

  @override
  State<SecretTerminalScreen> createState() => _SecretTerminalScreenState();
}

class _SecretTerminalScreenState extends State<SecretTerminalScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<String> _output = [];
  bool _busy = false;

  static const _green = Color(0xFF39FF14);
  static const _mono = TextStyle(
    color: _green,
    fontFamily: 'monospace',
    fontSize: 14,
    height: 1.4,
  );

  Future<void> _submit(String value) async {
    final cmd = value.trim();
    if (cmd.isEmpty || _busy) return;
    setState(() {
      _output.add('\$ $cmd');
      _busy = true;
    });
    _input.clear();

    final result = await TerminalCommands.run(cmd);

    if (result.contains('__EXIT__')) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (result.contains('__CLEAR__')) {
      setState(() {
        _output.clear();
        _busy = false;
      });
      return;
    }

    setState(() {
      _output.addAll(result);
      _busy = false;
    });
    await Future.delayed(const Duration(milliseconds: 50));
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Full-screen black overlay — hides status bar tint too.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Type *man* to access manual", style: _mono),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    itemCount: _output.length,
                    itemBuilder: (context, i) =>
                        Text(_output[i], style: _mono),
                  ),
                ),
                Row(
                  children: [
                    const Text('\$ ', style: _mono),
                    Expanded(
                      child: TextField(
                        controller: _input,
                        autofocus: true,
                        style: _mono,
                        cursorColor: _green,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: _submit,
                        enabled: !_busy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
