import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/otp_viewmodel.dart';
import '../../core/routes.dart';

class OtpValidationScreen extends StatefulWidget {
  final String email;
  const OtpValidationScreen({super.key, required this.email});

  @override
  State<OtpValidationScreen> createState() => _OtpValidationScreenState();
}

class _OtpValidationScreenState extends State<OtpValidationScreen> {
  String _code = '';
  Timer? _timer;
  int _cooldown = 0;
  bool _autoSent = false;

  // 6 champs OTP avec autofocus progressif
  final int _otpLength = 6;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  void _startCooldown(int seconds) {
    setState(() => _cooldown = seconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_cooldown <= 1) { t.cancel(); setState(() => _cooldown = 0); }
      else setState(() => _cooldown--);
    });
  }

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());

    // Auto-send OTP on first frame after navigation
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _autoSent) return;
      final vm = context.read<OtpViewModel>();
      await vm.send(widget.email);
      _autoSent = true;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String _maskedEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '**@$domain';
    return '${name.substring(0, 2)}${'*' * (name.length - 4)}${name.substring(name.length - 2)}@$domain';
  }

  void _onBoxChanged(int index, String value) {
    if (value.isNotEmpty) {
      // garder uniquement le dernier chiffre saisi
      final char = value.characters.last;
      _controllers[index].text = char;
      _controllers[index].selection = TextSelection.fromPosition(TextPosition(offset: 1));
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      if (index > 0) _focusNodes[index - 1].requestFocus();
    }

    _code = _controllers.map((c) => c.text).join();
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFF2F3F5),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E4E8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E4E8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7C4DFF)),
          ),
        ),
        onChanged: (v) => _onBoxChanged(index, v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OtpViewModel>(
      create: (_) => OtpViewModel(),
      child: Consumer<OtpViewModel>(
        builder: (context, vm, _) {
          if (vm.status == OtpStatus.sent && _cooldown == 0 && vm.cooldown > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _startCooldown(vm.cooldown));
          }

          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black87,
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Verification code',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We have sent the code verification to\n${_maskedEmail(widget.email)}.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(_otpLength, _buildOtpBox),
                        ),

                        const SizedBox(height: 28),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 140,
                              child: OutlinedButton(
                                onPressed: (vm.status == OtpStatus.sending || _cooldown > 0)
                                    ? null
                                    : () async {
                                        await vm.send(widget.email);
                                        if (!mounted) return;
                                        if (vm.status == OtpStatus.sent) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Code envoyé.')),
                                          );
                                        } else if (vm.error != null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(vm.error!)),
                                          );
                                        }
                                      },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(_cooldown > 0 ? 'send (${_cooldown}s)' : 'send'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 140,
                              child: ElevatedButton(
                                onPressed: (vm.status == OtpStatus.verifying)
                                    ? null
                                    : () async {
                                        _code = _controllers.map((c) => c.text).join();
                                        final ok = await vm.verify(widget.email, _code);
                                        if (!mounted) return;
                                        if (ok) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Email vérifié, vous pouvez créer un compte.')),
                                          );
                                          AppRoutes.goToRegister(context, email: widget.email);
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C4DFF),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Confirm'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        if (vm.error != null)
                          Text(vm.error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

