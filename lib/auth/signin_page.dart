import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/toast.dart';
import '../utils/loading.dart';
import 'auth_service.dart';
import 'widgets/gradient_background.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _privateKeyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureText = true;
  bool _isAmberLoading = false;

  @override
  void dispose() {
    _privateKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        appBar: _buildAppBar(),
        extendBodyBehindAppBar: true,
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.go('/login'),
      ),
    );
  }

  Widget _buildBody() {
    return GradientBackground(
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              _buildLogo(),
              const SizedBox(height: 32),
              _buildTitle(),
              const SizedBox(height: 32),
              _buildLoginCard(),
              const SizedBox(height: 32),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        'assets/images/icon_app_logo.png',
        height: 80,
        width: 80,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Sign In',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _buildCardDecoration(),
      child: Column(
        children: [
          _buildInputField(),
          const SizedBox(height: 24),
          _buildSignInButton(),
          if (Platform.isAndroid) ...[
            const SizedBox(height: 16),
            _buildOrDivider(),
            const SizedBox(height: 16),
            _buildAmberButton(),
          ],
        ],
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildInputField() {
    const iconSize = 40.0;
    return TextFormField(
      controller: _privateKeyController,
      obscureText: _obscureText,
      validator: _validateInput,
      maxLines: 1,
      decoration: InputDecoration(
        hintText: 'nsec or bunker://',
        hintStyle: const TextStyle(
          fontSize: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIconConstraints: BoxConstraints.tight(const Size.square(iconSize)),
        prefixIcon: const Icon(Icons.key, size: 20),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: _toggleObscureText,
                iconSize: 20,
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                ),
                tooltip: _obscureText ? 'Show key' : 'Hide key',
              ),
            ),
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: _clearInput,
                iconSize: 20,
                icon: const Icon(
                  Icons.clear,
                ),
                tooltip: 'Clear',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () {
          _dismissKeyboard();
          _signIn();
        },
        icon: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Icon(Icons.login),
        label: Text(
          _isLoading ? 'Signing in...' : 'Sign In',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildInfoContainer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Enter your private key (nsec/hex) or Bunker URL (bunker:///nostrconnect://). Keep your private key secure!',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1976D2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }

  Widget _buildAmberButton() {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isAmberLoading ? null : _loginWithAmber,
        icon: _isAmberLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Icon(Icons.phone_android),
        label: Text(
          _isAmberLoading ? 'Connecting...' : 'Sign in with Amber',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
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

  String? _validateInput(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your private key or Bunker URL';
    }

    final input = value.trim();

    // Check for private key formats
    if (input.startsWith('nsec')) {
      return null;
    }

    if (input.length == 64 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(input)) {
      return null;
    }

    // Check for Bunker URL formats
    if (input.startsWith('bunker://') || input.startsWith('nostrconnect://')) {
      return null;
    }

    return 'Must be nsec format, 64-character hex, bunker:// or nostrconnect:// URL';
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _signIn() async {
    _dismissKeyboard();

    if (!_formKey.currentState!.validate()) return;

    final input = _privateKeyController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      AppLoading.show('Signing in...');

      bool success = false;

      // Check if input is a Bunker URL
      if (input.startsWith('bunker://') || input.startsWith('nostrconnect://')) {
        success = await _authService.loginWithBunkerUrl(input);
      } else {
        // Assume it's a private key
        success = await _authService.loginWithPrivateKey(input);
      }

      AppLoading.dismiss();

      if (success) {
        AppToast.showSuccess(context, 'Sign in successful!');
        if (mounted) {
          context.go('/');
        }
      } else {
        AppToast.showError(context, 'Sign in failed. Please check your input.');
      }
    } catch (e) {
      AppLoading.dismiss();
      AppToast.showError(context, 'Sign in error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _clearInput() {
    _privateKeyController.clear();
  }

  // Action methods
  Future<void> _loginWithAmber() async {
    _dismissKeyboard();

    setState(() {
      _isAmberLoading = true;
    });

    try {
      AppLoading.show('Connecting to Amber...');

      await _authService.loginWithAmber();

      AppLoading.dismiss();

      AppToast.showSuccess(context, 'Amber login successful!');
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      AppLoading.dismiss();
      AppToast.showError(context, 'Amber login error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAmberLoading = false;
        });
      }
    }
  }
}