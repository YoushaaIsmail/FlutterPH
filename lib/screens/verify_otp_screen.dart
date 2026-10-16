import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  const VerifyOtpScreen({super.key, required this.email});

  @override
  _VerifyOtpScreenState createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.verifyOtp(
        widget.email,
        _codeController.text.trim(),
      );

      // Show success and go back to login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Verification successful! Please log in.')),
      );
      Navigator.popUntil(
          context, (route) => route.isFirst); // go to LoginScreen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display email (read‑only)
              TextFormField(
                initialValue: widget.email,
                decoration: const InputDecoration(labelText: 'Email'),
                enabled: false,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration:
                    const InputDecoration(labelText: 'Verification Code'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter the code' : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _verifyOtp,
                      child: const Text('Verify'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
