import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Removed unused import
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:math' as math;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLogin = true;

  // Toggle which providers are clickable to avoid runtime config errors
  // Set to true after enabling each provider in Firebase Console
  static const bool _googleEnabled = true;
  static const bool _appleEnabled = true;
  static const bool _anonymousEnabled = true;

  late final AnimationController _bgController;
  late final AnimationController _particleController;
  late final AnimationController _waveController;
  late final List<_Particle> _particles;
  late final List<_Wave> _waves;

  Future<void> _authenticate() async {
    try {
      final auth = FirebaseAuth.instance;
      UserCredential? userCredential;
      
      if (isLogin) {
        userCredential = await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        // Update last sign-in time for existing users
        if (userCredential.user != null) {
          await _saveUserToDatabase(userCredential.user!, isUpdate: true);
        }
      } else {
        userCredential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Save new user to database
        if (userCredential.user != null) {
          await _saveUserToDatabase(userCredential.user!, isUpdate: false);
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
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      
      // Save guest user to database
      if (userCredential.user != null) {
        await _saveGuestUserToDatabase(userCredential.user!);
      }
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
      UserCredential? userCredential;
      
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        try {
          userCredential = await auth.signInWithPopup(googleProvider);
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
        userCredential = await auth.signInWithCredential(credential);
      }
      
      // Save Google user data to database
      if (userCredential.user != null) {
        await _saveGoogleUserToDatabase(userCredential);
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



  Future<void> _signInWithApple() async {
    try {
      final auth = FirebaseAuth.instance;
      if (kIsWeb) {
        final appleProvider = AppleAuthProvider();
        try {
          await auth.signInWithPopup(appleProvider);
        } on FirebaseAuthException catch (e) {
          // If the browser blocks popups or the popup was closed, try redirect
          if (e.code == 'popup-blocked' || e.code == 'popup-closed-by-user') {
            await auth.signInWithRedirect(appleProvider);
            return;
          }
          rethrow;
        }
      } else {
        // For mobile platforms
        final appleIdCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );
        
        if (appleIdCredential.identityToken == null) {
          throw Exception('Apple Sign-In failed: No identity token received');
        }
        
        final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: appleIdCredential.identityToken,
          accessToken: appleIdCredential.authorizationCode,
        );
        
        await auth.signInWithCredential(oauthCredential);
      }
    } catch (e) {
      if (!mounted) return;
      String message = e.toString();
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'operation-not-allowed':
            message = 'Apple Sign-In not enabled. Enable it in Firebase Console → Authentication → Sign-in method.';
            break;
          case 'configuration-not-found':
            message = 'Apple Sign-In not configured. Set up Apple provider in Firebase Console.';
            break;
          case 'user-disabled':
            message = 'This account has been disabled.';
            break;
          case 'invalid-credential':
            message = 'Invalid Apple Sign-In credentials.';
            break;
          case 'web-storage-unsupported':
            message = 'Apple Sign-In requires web storage support. Please enable cookies.';
            break;
          default:
            message = 'Apple Sign-In failed: ${e.message}';
        }
      } else if (e.toString().contains('SignInWithApple')) {
        message = 'Apple Sign-In was cancelled or failed. Please try again.';
      } else if (e.toString().contains('operation-not-allowed')) {
        message = 'Apple Sign-In is not enabled in Firebase Console. Please enable it in Authentication → Sign-in method.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _bgController.dispose();
    _particleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Color _getRandomColor(math.Random random) {
    final colors = [
      Colors.deepPurple,
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.pink,
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 30))
      ..repeat();
    _particleController = AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 15))
      ..repeat();
    
    // Initialize particles
    final random = math.Random(42);
    _particles = List.generate(50, (index) {
      return _Particle(
        x: random.nextDouble() * 100,
        y: random.nextDouble() * 100,
        size: 2 + random.nextDouble() * 4,
        speed: 0.5 + random.nextDouble() * 2,
        angle: random.nextDouble() * math.pi * 2,
        color: _getRandomColor(random),
        type: random.nextInt(3), // 0: circle, 1: square, 2: triangle
      );
    });
    
    // Initialize waves
    _waves = List.generate(3, (index) {
      return _Wave(
        amplitude: 20 + random.nextDouble() * 60,
        frequency: 0.02 + random.nextDouble() * 0.03,
        speed: 0.5 + random.nextDouble() * 1.5,
        phase: random.nextDouble() * math.pi * 2,
        color: _getRandomColor(random),
        yOffset: 20 + index * 30,
      );
    });

    // Complete any pending Google sign-in redirect on Web and listen for auth changes
    if (kIsWeb) {
      FirebaseAuth.instance.getRedirectResult().then((userCredential) {
        if (userCredential.user != null) {
          // Save Google user data to database after redirect
          _saveGoogleUserToDatabase(userCredential);
        }
      }).catchError((error) {
        debugPrint("Redirect result error: $error");
      });
    }
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return; // Check again after post frame callback
        final email = user.email ?? (user.isAnonymous ? 'Guest' : 'Signed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signed in as $email')),
        );
      });
    });
  }

  // Compute animated gradient colors based on time t in [0,1] - cozy warm theme
  List<Color> _animatedGradient(double t) {
    Color shift(double baseHue, double delta) {
      final hue = (baseHue + delta) % 360.0;
      return HSLColor.fromAHSL(1.0, hue, 0.55, 0.45).toColor();
    }
    // Warm, cozy colors: deep purples, warm oranges, soft teals
    final a = shift(280, t * 360); // Deep purple
    final b = shift(25, (t * 360 + 120) % 360); // Warm orange
    final c = shift(200, (t * 360 + 240) % 360); // Soft teal
    return [a, b, c];
  }

  Widget _buildAdvancedAnimationLayer(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    
    return Stack(
      children: [
        // Animated particles
        AnimatedBuilder(
          animation: _particleController,
          builder: (context, _) {
            return CustomPaint(
              size: Size(width, height),
              painter: _ParticlePainter(
                particles: _particles,
                animationValue: _particleController.value,
                width: width,
                height: height,
              ),
            );
          },
        ),
        
        // Animated waves
        AnimatedBuilder(
          animation: _waveController,
          builder: (context, _) {
            return CustomPaint(
              size: Size(width, height),
              painter: _WavePainter(
                waves: _waves,
                animationValue: _waveController.value,
                width: width,
                height: height,
              ),
            );
          },
        ),
      ],
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

                             // Advanced particle and wave animation layer
               _buildAdvancedAnimationLayer(constraints),

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
                                                         Column(
                               children: [
                                 const Icon(Icons.psychology, size: 60, color: Colors.white),
                                 const SizedBox(height: 8),
                                 const Text(
                                   "Mo-Mo",
                                   style: TextStyle(
                                     fontSize: 28,
                                     fontWeight: FontWeight.bold,
                                     color: Colors.white,
                                   ),
                                 ),
                                 Text(
                                   "Money Monitor",
                                   style: TextStyle(
                                     fontSize: 14,
                                     color: Colors.white70,
                                     fontStyle: FontStyle.italic,
                                   ),
                                 ),
                               ],
                             ),
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
                                    icon: FontAwesomeIcons.google,
                                   enabled: _googleEnabled,
                                   onPressed: _signInWithGoogle,
                                   semanticsLabel: 'Sign in with Google',
                                    color: Colors.white,
                                 ),
                                 const SizedBox(width: 12),
                                 _SocialCircleButton(
                                    icon: FontAwesomeIcons.apple,
                                   enabled: _appleEnabled,
                                   onPressed: _signInWithApple,
                                   semanticsLabel: 'Sign in with Apple',
                                   color: Colors.white,
                                 ),
                               ],
                             ),
                            const SizedBox(height: 8),
                                                         TextButton(
                               onPressed: _anonymousEnabled ? _signInAnonymously : null,
                               child: const Text('Continue without an account', style: TextStyle(color: Colors.white)),
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
  
  // Helper method to save user data to database
  Future<void> _saveUserToDatabase(User user, {required bool isUpdate}) async {
    try {
      // Use default instance to avoid multiple database initializations
      final database = FirebaseDatabase.instance;
      if (isUpdate) {
          // Update last sign-in time for existing users
          await database.ref("users/${user.uid}/lastSignIn").set(
            DateTime.now().toIso8601String(),
          );
        } else {
          // Save new user data
          await database.ref("users/${user.uid}").set({
            "email": user.email,
            "displayName": user.email?.split('@')[0] ?? "User",
            "isEmailUser": true,
            "createdAt": DateTime.now().toIso8601String(),
            "lastSignIn": DateTime.now().toIso8601String(),
          });
        }
    } catch (e) {
      debugPrint("Error saving user to database: $e");
    }
  }

  // Helper method to save guest user data to database
  Future<void> _saveGuestUserToDatabase(User user) async {
    try {
      final database = FirebaseDatabase.instance;
      await database.ref("users/${user.uid}").set({
          "email": "guest@anonymous.com",
          "displayName": "Guest User",
          "isGuest": true,
          "createdAt": DateTime.now().toIso8601String(),
        });
    } catch (e) {
      debugPrint("Error saving guest user to database: $e");
    }
  }

  // Helper method to save Google user data to database
  Future<void> _saveGoogleUserToDatabase(UserCredential userCredential) async {
    try {
      final database = FirebaseDatabase.instance;
      await database.ref("users/${userCredential.user!.uid}").set({
          "email": userCredential.user!.email,
          "displayName": userCredential.user!.displayName ?? "Google User",
          "photoURL": userCredential.user!.photoURL,
          "isGoogleUser": true,
          "lastSignIn": DateTime.now().toIso8601String(),
          "createdAt": DateTime.now().toIso8601String(),
        });
    } catch (e) {
      debugPrint("Error saving Google user to database: $e");
    }
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double angle;
  final Color color;
  final int type; // 0: circle, 1: square, 2: triangle

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
    required this.color,
    required this.type,
  });
}

class _Wave {
  final double amplitude;
  final double frequency;
  final double speed;
  final double phase;
  final Color color;
  final double yOffset;

  const _Wave({
    required this.amplitude,
    required this.frequency,
    required this.speed,
    required this.phase,
    required this.color,
    required this.yOffset,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;
  final double width;
  final double height;

  _ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(0.6)
        ..style = PaintingStyle.fill;

      // Calculate animated position
      final x = (particle.x + animationValue * particle.speed * 100) % width;
      final y = (particle.y + math.sin(animationValue * math.pi * 2 + particle.angle) * 20) % height;

      // Draw different shapes
      switch (particle.type) {
        case 0: // Circle
          canvas.drawCircle(Offset(x, y), particle.size, paint);
          break;
        case 1: // Square
          final rect = Rect.fromCenter(
            center: Offset(x, y),
            width: particle.size * 2,
            height: particle.size * 2,
          );
          canvas.drawRect(rect, paint);
          break;
        case 2: // Triangle
          final path = Path()
            ..moveTo(x, y - particle.size)
            ..lineTo(x - particle.size, y + particle.size)
            ..lineTo(x + particle.size, y + particle.size)
            ..close();
          canvas.drawPath(path, paint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _WavePainter extends CustomPainter {
  final List<_Wave> waves;
  final double animationValue;
  final double width;
  final double height;

  _WavePainter({
    required this.waves,
    required this.animationValue,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final wave in waves) {
      final paint = Paint()
        ..color = wave.color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final path = Path();
      final y = wave.yOffset + wave.amplitude * math.sin(wave.frequency * width + wave.phase + animationValue * wave.speed * math.pi * 2);
      
      path.moveTo(0, y);
      
      for (double x = 0; x <= width; x += 2) {
        final waveY = wave.yOffset + wave.amplitude * math.sin(wave.frequency * x + wave.phase + animationValue * wave.speed * math.pi * 2);
        path.lineTo(x, waveY);
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SocialCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String semanticsLabel;
  final bool enabled;
  final Color color;

  const _SocialCircleButton({
    required this.icon,
    required this.onPressed,
    required this.semanticsLabel,
    this.enabled = true,
    this.color = Colors.white,
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
             child: Icon(
               icon,
               size: 24,
               color: color,
             ),
           ),
        ),
      ),
    );
  }
}


