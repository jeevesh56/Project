import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:math' as math;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLogin = true;

  // Toggle which providers are clickable to avoid runtime config errors
  // Set to true after enabling each provider in Firebase Console
  static const bool _googleEnabled = true;
  static const bool _facebookEnabled = false;
  static const bool _appleEnabled = false;
  static const bool _anonymousEnabled = true;

  late final AnimationController _bgController;
  late final List<_FlyingSpec> _flyingSpecs;

  Future<void> _authenticate() async {
    try {
      final auth = FirebaseAuth.instance;
      if (isLogin) {
        await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Only write to Realtime Database if a databaseURL is configured
        final app = Firebase.app();
        final databaseUrl = app.options.databaseURL;
        if (databaseUrl != null && databaseUrl.isNotEmpty) {
          final database = FirebaseDatabase.instanceFor(app: app, databaseURL: databaseUrl);
          await database.ref("users/${userCredential.user!.uid}").set({
            "email": _emailController.text.trim(),
            "createdAt": DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      String message = e.toString();
      if (e is FirebaseAuthException &&
          (e.code == 'configuration-not-found' || e.code == 'operation-not-allowed')) {
        message = 'Auth provider not configured. Please enable the provider in Firebase Console.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _signInAnonymously() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      if (!mounted) return;
      String message = e.toString();
      if (e is FirebaseAuthException && (e.code == 'operation-not-allowed')) {
        message = 'Anonymous auth not enabled. Enable it in Firebase Console > Authentication.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final auth = FirebaseAuth.instance;
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        try {
          await auth.signInWithPopup(googleProvider);
        } on FirebaseAuthException catch (e) {
          // If the browser blocks popups or the popup was closed, try redirect
          if (e.code == 'popup-blocked' || e.code == 'popup-closed-by-user') {
            await auth.signInWithRedirect(googleProvider);
            return;
          }
          rethrow;
        }
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return; // canceled
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await auth.signInWithCredential(credential);
      }
    } catch (e) {
      if (!mounted) return;
      String message = e.toString();
      if (e is FirebaseAuthException && (e.code == 'operation-not-allowed' || e.code == 'configuration-not-found')) {
        message = 'Google provider not enabled for this Firebase project. In Console → Authentication → Sign-in method, enable Google and Save. Also ensure localhost/127.0.0.1 are in Authorized domains.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _signInWithFacebook() async {
    try {
      final auth = FirebaseAuth.instance;
      if (kIsWeb) {
        final provider = FacebookAuthProvider();
        await auth.signInWithPopup(provider);
      } else {
        final LoginResult result = await FacebookAuth.instance.login();
        if (result.status != LoginStatus.success || result.accessToken == null) return;
        final credential = FacebookAuthProvider.credential(result.accessToken!.token);
        await auth.signInWithCredential(credential);
      }
    } catch (e) {
      if (!mounted) return;
      String message = e.toString();
      if (e is FirebaseAuthException && (e.code == 'operation-not-allowed' || e.code == 'configuration-not-found')) {
        message = 'Facebook sign-in not configured. Enable Facebook provider and set App ID/Secret in Firebase Console.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _signInWithApple() async {
    try {
      final auth = FirebaseAuth.instance;
      if (kIsWeb) {
        final appleProvider = AppleAuthProvider();
        await auth.signInWithPopup(appleProvider);
      } else {
        final appleIdCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );
        final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: appleIdCredential.identityToken,
          accessToken: appleIdCredential.authorizationCode,
        );
        await auth.signInWithCredential(oauthCredential);
      }
    } catch (e) {
      if (!mounted) return;
      String message = e.toString();
      if (e is FirebaseAuthException && (e.code == 'operation-not-allowed' || e.code == 'configuration-not-found')) {
        message = 'Apple sign-in not configured. Enable Apple provider and set Services ID/keys in Firebase Console.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
    final random = math.Random(42);
    _flyingSpecs = List.generate(18, (index) {
      final speed = 20 + random.nextInt(25); // seconds to cross
      final size = 18.0 + random.nextDouble() * 22.0;
      final verticalAnchor = random.nextDouble();
      final amplitude = 20 + random.nextDouble() * 60;
      final phase = random.nextDouble() * math.pi * 2;
      final icon = index % 3 == 0
          ? Icons.attach_money
          : (index % 3 == 1 ? Icons.payments_rounded : Icons.savings_rounded);
      return _FlyingSpec(
        speedSeconds: speed.toDouble(),
        size: size,
        verticalAnchor: verticalAnchor,
        amplitude: amplitude,
        phase: phase,
        iconData: icon,
      );
    });

    // Complete any pending Google sign-in redirect on Web and listen for auth changes
    if (kIsWeb) {
      FirebaseAuth.instance.getRedirectResult().catchError((_) {});
    }
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final email = user.email ?? (user.isAnonymous ? 'Guest' : 'Signed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signed in as $email')),
        );
      });
    });
  }

  // Compute animated gradient colors based on time t in [0,1]
  List<Color> _animatedGradient(double t) {
    Color shift(double baseHue, double delta) {
      final hue = (baseHue + delta) % 360.0;
      return HSLColor.fromAHSL(1.0, hue, 0.65, 0.52).toColor();
    }
    final a = shift(160, t * 360);
    final b = shift(260, (t * 360 + 60) % 360);
    final c = shift(330, (t * 360 + 120) % 360);
    return [a, b, c];
  }

  Widget _buildFlyingLayer(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, _) {
        final t = _bgController.value; // 0..1
        return Stack(
          children: _flyingSpecs.map((spec) {
            // progress for this spec based on its own speed
            final cycle = (t * (20.0 / (spec.speedSeconds / 20.0))) % 1.0;
            final x = -60.0 + (width + 120.0) * cycle;
            final y = spec.verticalAnchor * height + math.sin(cycle * math.pi * 2 + spec.phase) * spec.amplitude;
            return Positioned(
              left: x,
              top: y.clamp(0.0, height - spec.size),
              child: Opacity(
                opacity: 0.25 + 0.35 * (0.5 + 0.5 * math.sin(cycle * math.pi * 2 + spec.phase)),
                child: Icon(
                  spec.iconData,
                  size: spec.size,
                  color: Colors.white,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Animated gradient background
              AnimatedBuilder(
                animation: _bgController,
                builder: (context, _) {
                  final colors = _animatedGradient(_bgController.value);
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  );
                },
              ),

              // Floating money/finance icons layer
              _buildFlyingLayer(constraints),

              // Content card
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Material(
                      elevation: 8,
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.savings_rounded, size: 80, color: Colors.white),
                            const SizedBox(height: 16),
                            Text(
                              isLogin ? "Welcome Back" : "Create Account",
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: "Email",
                                labelStyle: const TextStyle(color: Colors.white70),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.white24),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.white70),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: "Password",
                                labelStyle: const TextStyle(color: Colors.white70),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.white24),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.white70),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _authenticate,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: Colors.deepPurpleAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  isLogin ? "Login" : "Sign Up",
                                  style: const TextStyle(fontSize: 18, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: const [
                                Expanded(child: Divider(color: Colors.white24)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text('or continue with', style: TextStyle(color: Colors.white70)),
                                ),
                                Expanded(child: Divider(color: Colors.white24)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _SocialCircleButton(
                                  emoji: '🌐',
                                  enabled: _googleEnabled,
                                  onPressed: _signInWithGoogle,
                                  semanticsLabel: 'Sign in with Google',
                                ),
                                const SizedBox(width: 12),
                                _SocialCircleButton(
                                  emoji: '📘',
                                  enabled: _facebookEnabled,
                                  onPressed: _signInWithFacebook,
                                  semanticsLabel: 'Sign in with Facebook',
                                ),
                                const SizedBox(width: 12),
                                _SocialCircleButton(
                                  emoji: '🍎',
                                  enabled: _appleEnabled,
                                  onPressed: _signInWithApple,
                                  semanticsLabel: 'Sign in with Apple',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _anonymousEnabled ? _signInAnonymously : null,
                              child: const Text('🚪 Continue without an account', style: TextStyle(color: Colors.white)),
                            ),
                            TextButton(
                              onPressed: () => setState(() => isLogin = !isLogin),
                              child: Text(
                                isLogin ? "Don't have an account? Sign Up" : "Already have an account? Login",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FlyingSpec {
  final double speedSeconds;
  final double size;
  final double verticalAnchor; // 0..1 of height
  final double amplitude;
  final double phase;
  final IconData iconData;

  const _FlyingSpec({
    required this.speedSeconds,
    required this.size,
    required this.verticalAnchor,
    required this.amplitude,
    required this.phase,
    required this.iconData,
  });
}

class _SocialCircleButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onPressed;
  final String semanticsLabel;
  final bool enabled;

  const _SocialCircleButton({
    super.key,
    required this.emoji,
    required this.onPressed,
    required this.semanticsLabel,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.06),
            border: Border.all(color: enabled ? Colors.white30 : Colors.white12),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }
}


