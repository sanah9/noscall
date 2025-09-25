import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          _buildLogo(),
          _buildTitle(),
          _buildSubtitle(),
          const SizedBox(height: 40),
          _buildLoginCard(),
          const SizedBox(height: 32),
          _buildFooter(),
        ],
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
    return const Column(
      children: [
        SizedBox(height: 24),
        Text(
          'Sign In',
          style: TextStyle(
            fontSize: 28,
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
          'Enter your private key to continue',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _buildCardDecoration(),
      child: Column(
        children: [
          _buildPrivateKeyField(),
          const SizedBox(height: 24),
          _buildSignInButton(),
          const SizedBox(height: 16),
          _buildInfoContainer(),
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

  Widget _buildPrivateKeyField() {
    return TextFormField(
      controller: _privateKeyController,
      obscureText: _obscureText,
      validator: _validatePrivateKey,
      maxLines: 1,
      decoration: InputDecoration(
        labelText: 'Private Key',
        hintText: 'Enter nsec format or 64-character hex key',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.key),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _toggleObscureText,
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
              ),
              tooltip: _obscureText ? 'Show key' : 'Hide key',
            ),
            IconButton(
              onPressed: _clearPrivateKey,
              icon: const Icon(Icons.clear),
              tooltip: 'Clear',
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
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Enter your private key in nsec format or 64-character hex format. Keep your private key secure!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
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

  String? _validatePrivateKey(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your private key';
    }

    final privateKey = value.trim();

    if (privateKey.startsWith('nsec')) {
      return null;
    }

    if (privateKey.length == 64 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(privateKey)) {
      return null;
    }

    return 'Private key must be nsec format or 64-character hex';
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _signIn() async {
    _dismissKeyboard();

    if (!_formKey.currentState!.validate()) return;

    final privateKey = _privateKeyController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      AppLoading.show('Signing in...');

      final success = await _authService.loginWithPrivateKey(privateKey);

      AppLoading.dismiss();

      if (success) {
        AppToast.showSuccess(context, 'Sign in successful!');
        if (mounted) {
          context.go('/');
        }
      } else {
        AppToast.showError(context, 'Sign in failed. Please check your private key.');
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

  void _clearPrivateKey() {
    _privateKeyController.clear();
  }
}