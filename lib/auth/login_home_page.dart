import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'widgets/gradient_background.dart';

class LoginHomePage extends StatelessWidget {
  const LoginHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _dismissKeyboard(context),
      child: Scaffold(
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLogo(),
        _buildTitle(),
        _buildSubtitle(),
        const SizedBox(height: 48),
        _buildSignInButton(context),
        const SizedBox(height: 16),
        _buildCreateAccountButton(context),
        const SizedBox(height: 32),
        _buildFooter(),
      ],
    );
  }

  Widget _buildLogo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        'assets/images/icon_app_logo.png',
        height: 120,
        width: 120,
      ),
    );
  }

  Widget _buildTitle() {
    return const Column(
      children: [
        SizedBox(height: 32),
        Text(
          'Noscall',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return const Column(
      children: [
        SizedBox(height: 8),
        Text(
          'Secure Voice & Video Calling',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => context.push('/signin'),
        icon: const Icon(Icons.login),
        label: const Text(
          'Sign In',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E3A8A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildCreateAccountButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () => context.push('/signup'),
        icon: const Icon(Icons.person_add),
        label: const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      'Powered by Nostr Protocol',
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withValues(alpha: 0.6),
      ),
    );
  }

  void _dismissKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}