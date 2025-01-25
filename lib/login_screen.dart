import 'dart:io' show Platform;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // FirebaseAuth instancja
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Zmienna do wskazania, czy aktualnie logujemy się czy rejestrujemy
  bool _isSignUpMode = false;
  final bool _appleAuthEnabled = false;

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logEvent(
      name: 'screen_view',
      parameters: {
        'screen_name': "LoginScreen",
        'screen_class': "LoginScreen",
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Logowanie Baby Care'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // === Email/Password ===
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                ),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Hasło',
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isSignUpMode ? _registerWithEmailPassword : _signInWithEmailPassword,
                child: Text(_isSignUpMode ? 'Zarejestruj' : 'Zaloguj'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSignUpMode = !_isSignUpMode;
                  });
                },
                child: Text(
                  _isSignUpMode
                      ? 'Masz już konto? Zaloguj się'
                      : 'Nie masz konta? Zarejestruj się',
                ),
              ),

              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),

              SignInButton(
                Buttons.google,
                onPressed: _signInWithGoogle,
              ),

              // === Apple (tylko iOS/macOS) ===
              if (_appleAuthEnabled && (Platform.isIOS || Platform.isMacOS))
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: SignInWithAppleButton(
                    style: SignInWithAppleButtonStyle.black, // styl przycisku
                    onPressed: _signInWithApple,
                  ),
                ),
            ],
          ),
        ),
      ),

    );
  }

  // ======================
  // Metody logowania Firebase
  // ======================

  // 1. E-mail / Hasło: Logowanie
  Future<void> _signInWithEmailPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _navigateToHome(userCredential.user);
    } on FirebaseAuthException catch (e) {
      print('Błąd logowania (e-mail/hasło): ${e.code}');
      _showError(e.message);
    } catch (e) {
      print('Inny błąd logowania: $e');
      _showError(e.toString());
    }
  }

  // 2. E-mail / Hasło: Rejestracja
  Future<void> _registerWithEmailPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _navigateToHome(userCredential.user);
    } on FirebaseAuthException catch (e) {
      print('Błąd rejestracji (e-mail/hasło): ${e.code}');
      _showError(e.message);
    } catch (e) {
      print('Inny błąd rejestracji: $e');
      _showError(e.toString());
    }
  }

  // 3. Google
  Future<void> _signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // Użytkownik anulował wybór konta
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      _navigateToHome(userCredential.user);
    } catch (e) {
      print('Błąd logowania przez Google: $e');
      _showError(e.toString());
    }
  }

  // 4. Apple
  Future<void> _signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      _navigateToHome(userCredential.user);
    } catch (e) {
      print('Błąd logowania przez Apple: $e');
      _showError(e.toString());
    }
  }

  // Wyświetlenie błędu w formie SnackBar (lub dialogu)
  void _showError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Wystąpił nieznany błąd')),
    );
  }

  // Przykładowa nawigacja po udanym logowaniu
  void _navigateToHome(User? user) {
    if (user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(user: user),
      ),
    );
  }
}
