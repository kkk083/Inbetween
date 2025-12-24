import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'signup_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- NOUVELLE FONCTION : MOT DE PASSE OUBLIÉ ---
  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController(
      text: _emailController.text, // Pré-remplit avec l'email déjà tapé
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialisation'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Entrez votre email pour recevoir un lien de récupération.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email étudiant',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer un email valide')),
                );
                return;
              }
              
              Navigator.pop(context); // Ferme le dialogue
              
              try {
                await Provider.of<AuthProvider>(context, listen: false)
                    .resetPassword(email);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email de récupération envoyé ! Vérifiez vos spams.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur : ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      bool success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Erreur de connexion'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppConstants.primaryColor,
              Colors.white,
            ],
            stops: const [0.30, 1.0],
          ),
        ),
        child: SafeArea(
          child: authProvider.isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        _buildHeader(),
                        const SizedBox(height: 48),
                        _buildFormCard(),
                        const SizedBox(height: 24),
                        _buildSignupLink(),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.swap_horiz_rounded,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Bon retour ! 👋',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Connecte-toi pour continuer',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined, color: AppConstants.primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) => (value == null || !value.contains('@')) ? 'Email invalide' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: Icon(Icons.lock_outline, color: AppConstants.primaryColor),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) => (value == null || value.length < 6) ? 'Minimum 6 caractères' : null,
            ),
            const SizedBox(height: 12),
            
            // --- BOUTON MODIFIÉ ICI ---
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: Text(
                  'Mot de passe oublié ?',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Se connecter',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Pas encore de compte ? ', style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SignupScreen()),
            );
          },
          child: Text(
            'Inscris-toi',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
          ),
        ),
      ],
    );
  }
}