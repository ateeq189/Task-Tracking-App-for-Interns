import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  // Signup remains intern-only; keep this role value mutable as requested.
  // ignore: prefer_final_fields
  String _role = 'intern';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = AuthService();
      if (_isSignUp) {
        await auth.signUp(
          _name.text.trim(),
          _email.text.trim(),
          _password.text,
          _role,
        );
      } else {
        await auth.login(_email.text.trim(), _password.text);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Something went wrong')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pehle upar apni email likhein')),
      );
      return;
    }
    try {
      await AuthService().resetPassword(email);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.mark_email_read_outlined, size: 40),
          title: const Text('Check your email'),
          content: Text(
            'Agar $email se account bana hai to password reset ka link bhej diya gaya hai. Spam folder bhi check karein.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Something went wrong')),
        );
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  static const _indigo = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final scheme = ColorScheme.fromSeed(
      seedColor: _indigo,
      brightness: base.brightness,
    );
    return Theme(
      data: base.copyWith(
        colorScheme: scheme,
        textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
      ),
      child: Builder(builder: (context) => _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withValues(alpha: 0.55),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.task_alt,
                        size: 40,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Task Tracker',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Organize. Submit. Grow.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Text(
                                _isSignUp ? 'Create Account' : 'Welcome Back',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 20),
                              if (_isSignUp) ...[
                                TextFormField(
                                  controller: _name,
                                  decoration: const InputDecoration(
                                    labelText: 'Full name',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: (v) => v!.trim().isEmpty
                                      ? 'Enter your name'
                                      : null,
                                ),
                                const SizedBox(height: 14),
                              ],
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (v) => v!.contains('@')
                                    ? null
                                    : 'Enter a valid email',
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _password,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                validator: (v) => v!.length < 6
                                    ? 'At least 6 characters'
                                    : null,
                              ),
                              if (!_isSignUp)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _forgotPassword,
                                    child: const Text('Forgot password?'),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _loading ? null : _submit,
                                  child: _loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(_isSignUp ? 'Sign Up' : 'Login'),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _isSignUp = !_isSignUp),
                                child: Text(
                                  _isSignUp
                                      ? 'Already have an account? Login'
                                      : 'No account? Sign up',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
