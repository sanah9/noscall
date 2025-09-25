import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../utils/toast.dart';
import '../utils/loading.dart';
import '../core/account/account.dart';
import 'auth_service.dart';
import 'widgets/gradient_background.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _generatedPrivateKey;

  @override
  void initState() {
    super.initState();
    _generateNewAccount();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _generateNewAccount() {
    _generatedPrivateKey = _authService.generatePrivateKey();
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
          _buildAccountCreationCard(),
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
          'Create Account',
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
          'Enter your name to create a new account',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCreationCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _buildCardDecoration(),
      child: Column(
        children: [
          _buildNameField(),
          const SizedBox(height: 24),
          _buildAccountInfoContainer(),
          const SizedBox(height: 24),
          _buildCreateAccountButton(),
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

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      validator: _validateName,
      decoration: InputDecoration(
        labelText: 'Your Name',
        hintText: 'Enter your display name',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.person),
      ),
    );
  }

  Widget _buildAccountInfoContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: _buildAccountInfoHeader(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPrivateKeyInfo(),
                const SizedBox(height: 8),
                _buildPublicKeyInfo(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoHeader() {
    return Row(
      children: [
        const Icon(
          Icons.account_circle,
          color: Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 8),
        const Text(
          'Account Information',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            setState(() {
              _generateNewAccount();
            });
          },
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.refresh),
          tooltip: 'Generate new account',
          iconSize: 20,
        ),
      ],
    );
  }

  Widget _buildPrivateKeyInfo() {
    return Text(
      'Private Key: $_generatedPrivateKey',
      style: const TextStyle(
        fontSize: 12,
        color: Colors.grey,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildPublicKeyInfo() {
    return Text(
      'Public Key: ${_generatedPrivateKey != null ? _getPublicKey(_generatedPrivateKey!) : ''}',
      style: const TextStyle(
        fontSize: 12,
        color: Colors.grey,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () {
          _dismissKeyboard();
          _createAccount();
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
            : const Icon(Icons.person_add),
        label: Text(
          _isLoading ? 'Creating Account...' : 'Create Account',
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
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'A new account with a unique private key has been generated for you. Your private key will be stored securely on this device.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[700],
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


  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    return null;
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _createAccount() async {
    _dismissKeyboard();

    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final privateKey = _generatedPrivateKey!;

    setState(() {
      _isLoading = true;
    });

    try {
      AppLoading.show('Creating account...');

      final loginSuccess = await _authService.loginWithPrivateKey(privateKey);

      if (!loginSuccess) {
        throw Exception('Failed to create account');
      }

      await _updateUserName(name);

      AppLoading.dismiss();
      AppToast.showSuccess(context, 'Account created successfully!');

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      AppLoading.dismiss();
      AppToast.showError(context, 'Account creation failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateUserName(String name) async {
    try {
      final currentUser = _authService.getCurrentUserDB();
      if (currentUser != null) {
        currentUser.name = name;
        await Account.saveUserToDB(currentUser);
      }
    } catch (e) {
      debugPrint('Failed to update user name: $e');
    }
  }

  String _getPublicKey(String privateKey) {
    try {
      return Account.getPublicKey(privateKey);
    } catch (e) {
      return 'Error generating public key';
    }
  }
}