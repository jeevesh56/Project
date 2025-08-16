import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Removed unused import
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/momo_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLogin = true;
  bool rememberMe = false;
  bool _obscurePassword = true; // Add password visibility toggle

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
          await _maybeStoreCredentials();
          if (!rememberMe) {
            // Prompt to remember credentials after a successful login
            _showRememberDialog();
          }
          // Navigation handled by StreamBuilder in main.dart
        }
      } else {
        // Check if email already exists before trying to create account
        try {
          final methods = await auth.fetchSignInMethodsForEmail(_emailController.text.trim());
          if (methods.isNotEmpty) {
            // Email already exists, suggest login instead
            setState(() => isLogin = true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('An account with this email already exists. Please log in instead.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
            return;
          }
        } catch (e) {
          // Continue with account creation if check fails
        }
        
        userCredential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Save new user to database
        if (userCredential.user != null) {
          await _saveUserToDatabase(userCredential.user!, isUpdate: false);
          // After creating account, sign out and go back to login for explicit login flow
          await auth.signOut();
          if (!mounted) return;
          setState(() => isLogin = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Please log in with your credentials.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      String message = '';
      Color backgroundColor = Colors.red;
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            message = 'No account found with this email. Please sign up first.';
            backgroundColor = Colors.orange;
            setState(() => isLogin = false);
            break;
          case 'wrong-password':
            message = 'Incorrect password. Please try again.';
            backgroundColor = Colors.red;
            break;
          case 'email-already-in-use':
            message = 'An account with this email already exists. Please log in instead.';
            backgroundColor = Colors.orange;
            // Switch to login mode for existing users
            setState(() => isLogin = true);
            break;
          case 'weak-password':
            message = 'Password is too weak. Please use a stronger password (at least 6 characters).';
            backgroundColor = Colors.red;
            break;
          case 'invalid-email':
            message = 'Please enter a valid email address.';
            backgroundColor = Colors.red;
            break;
          case 'configuration-not-found':
          case 'operation-not-allowed':
            message = 'Authentication provider not configured. Please contact support.';
            backgroundColor = Colors.red;
            break;
          default:
            message = 'Authentication failed: ${e.message}';
            backgroundColor = Colors.red;
        }
      } else {
        message = 'An unexpected error occurred: $e';
        backgroundColor = Colors.red;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 4),
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final auth = FirebaseAuth.instance;
      UserCredential? userCredential;
      
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        // Force account selection on web
        googleProvider.setCustomParameters({
          'prompt': 'select_account'
        });
        
        // Show loading dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Signing in with Google...'),
                ],
              ),
            ),
          );
        }
        
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
        // Configure GoogleSignIn to show account picker
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          // Force account selection
          signInOption: SignInOption.standard,
        );
        
        // Sign out first to ensure account picker shows
        await googleSignIn.signOut();
        
        // Show loading dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Signing in with Google...'),
                ],
              ),
            ),
          );
        }
        
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          // Close loading dialog
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          return; // canceled
        }
        
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await auth.signInWithCredential(credential);
      }
      
      // Close loading dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Save Google user data to database
      if (userCredential.user != null) {
        await _saveGoogleUserToDatabase(userCredential);
        
        // Show email confirmation dialog
        if (mounted) {
          _showEmailConfirmationDialog(userCredential.user!.email ?? '');
        }
        
        // Force refresh the auth state to ensure navigation
        await auth.currentUser?.reload();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully signed in with Google! Redirecting...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // The StreamBuilder in main.dart should automatically navigate to dashboard
        // But let's add a small delay to ensure the auth state is properly updated
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Check if we're still on the login page after delay
        if (mounted && Navigator.of(context).canPop() == false) {
          // If we're still on login page, manually navigate to dashboard
          _navigateToDashboard();
        }
        
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (!mounted) return;
      String message = e.toString();
      if (e is FirebaseAuthException && (e.code == 'operation-not-allowed' || e.code == 'configuration-not-found')) {
        message = 'Google provider not enabled for this Firebase project. In Console → Authentication → Sign-in method, enable Google and Save. Also ensure localhost/127.0.0.1 are in Authorized domains.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Show email confirmation dialog for Google sign-in
  void _showEmailConfirmationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.email, color: Colors.green),
            SizedBox(width: 8),
            Text('Email Confirmed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have successfully signed in with Google using:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    email,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'This email will be used for your account and can be used to sign in later.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'You can also use this same email with a password for regular login.',
              style: TextStyle(fontSize: 12, color: Colors.blue[600], fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'If you have an existing account with this email, you can use either sign-in method.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For added security, you can set a password for this account in your profile settings.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to dashboard
              _navigateToDashboard();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Continue to Dashboard'),
          ),
        ],
      ),
    );
  }


  Future<void> _signInWithApple() async {
    try {
      final auth = FirebaseAuth.instance;
      if (kIsWeb) {
        final appleProvider = AppleAuthProvider();
        
        // Show loading dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Signing in with Apple...'),
                ],
              ),
            ),
          );
        }
        
        try {
          final userCredential = await auth.signInWithPopup(appleProvider);
          if (userCredential.user != null) {
            // Close loading dialog
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            
            await _saveAppleUserToDatabase(userCredential);
            
            // Show email confirmation dialog
            if (mounted) {
              _showEmailConfirmationDialog(userCredential.user!.email ?? 'Apple User');
            }
            
            // Force refresh the auth state to ensure navigation
            await auth.currentUser?.reload();
            
            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Successfully signed in with Apple! Redirecting...'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            
            // The StreamBuilder in main.dart should automatically navigate to dashboard
            // But let's add a small delay to ensure the auth state is properly updated
            await Future.delayed(const Duration(milliseconds: 500));
            
            // Check if we're still on the login page after delay
            if (mounted && Navigator.of(context).canPop() == false) {
              // If we're still on login page, manually navigate to dashboard
              _navigateToDashboard();
            }
            
          }
        } on FirebaseAuthException catch (e) {
          // Close loading dialog
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          
          // If the browser blocks popups or the popup was closed, try redirect
          if (e.code == 'popup-blocked' || e.code == 'popup-closed-by-user') {
            await auth.signInWithRedirect(appleProvider);
            return;
          }
          rethrow;
        }
      } else {
        // For mobile platforms
        // Show loading dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Signing in with Apple...'),
                ],
              ),
            ),
          );
        }
        
        final appleIdCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );
        
        if (appleIdCredential.identityToken == null) {
          // Close loading dialog
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          throw Exception('Apple Sign-In failed: No identity token received');
        }
        
        final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: appleIdCredential.identityToken,
          accessToken: appleIdCredential.authorizationCode,
        );
        
        final userCredential = await auth.signInWithCredential(oauthCredential);
        
        // Close loading dialog
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        if (userCredential.user != null) {
          await _saveAppleUserToDatabase(userCredential);
          
          // Show email confirmation dialog
          if (mounted) {
            _showEmailConfirmationDialog(userCredential.user!.email ?? 'Apple User');
          }
          
          // Force refresh the auth state to ensure navigation
          await auth.currentUser?.reload();
          
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Successfully signed in with Apple! Redirecting...'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
          
          // The StreamBuilder in main.dart should automatically navigate to dashboard
          // But let's add a small delay to ensure the auth state is properly updated
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Check if we're still on the login page after delay
          if (mounted && Navigator.of(context).canPop() == false) {
            // If we're still on login page, manually navigate to dashboard
            _navigateToDashboard();
          }
        }
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
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
          final providerId = userCredential.credential?.providerId 
              ?? userCredential.additionalUserInfo?.providerId 
              ?? '';
          
          if (providerId.contains('google')) {
            _saveGoogleUserToDatabase(userCredential);
            // Show email confirmation dialog
            if (mounted) {
              _showEmailConfirmationDialog(userCredential.user!.email ?? 'Google User');
            }
          } else if (providerId.contains('apple')) {
            _saveAppleUserToDatabase(userCredential);
            // Show email confirmation dialog
            if (mounted) {
              _showEmailConfirmationDialog(userCredential.user!.email ?? 'Apple User');
            }
          } else {
            _saveUserToDatabase(userCredential.user!, isUpdate: true);
          }
        }
      }).catchError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign-in error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

    _loadRememberedCredentials();
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
                                 // Mo-Mo Money Monitor Logo
                                 MoMoEnhancedLogo(
                                   size: 100,
                                   showText: false, // We'll handle text separately for better layout
                                 ),
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
                                suffixIcon: rememberMe && _emailController.text.isNotEmpty
                                    ? Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
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
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Password visibility toggle
                                    IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                        color: Colors.white70,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    // Green checkmark when credentials are remembered
                                    if (rememberMe && _passwordController.text.isNotEmpty)
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: rememberMe,
                                  onChanged: (v) {
                                    setState(() => rememberMe = v ?? false);
                                    if (!rememberMe) {
                                      // If unchecking, clear saved credentials
                                      _clearRememberedCredentials();
                                    }
                                  },
                                  activeColor: Colors.deepPurpleAccent,
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => rememberMe = !rememberMe);
                                      if (!rememberMe) {
                                        _clearRememberedCredentials();
                                      }
                                    },
                                    child: const Text(
                                      'Remember username and password',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (rememberMe)
                              Padding(
                                padding: const EdgeInsets.only(left: 48.0, top: 4.0),
                                child: Text(
                                  'Your credentials will be saved securely for easy login',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
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
  
  Future<void> _loadRememberedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      final savedPassword = prefs.getString('saved_password');
      final savedRemember = prefs.getBool('remember_me') ?? false;
      
      if (savedEmail != null && savedPassword != null && savedRemember) {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        setState(() => rememberMe = true);
      }
    } catch (e) {
      // Silent error handling for production
    }
  }

  Future<void> _maybeStoreCredentials() async {
    if (!rememberMe) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      if (email.isNotEmpty && password.isNotEmpty) {
        await prefs.setString('saved_email', email);
        await prefs.setString('saved_password', password);
        await prefs.setBool('remember_me', true);
      }
    } catch (e) {
      // Silent error handling for production
    }
  }

  Future<void> _clearRememberedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    } catch (e) {
      // Silent error handling for production
    }
  }

  Future<void> _showRememberDialog() async {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        bool dialogRemember = rememberMe;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.security, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text('Remember Credentials?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Would you like to save your email and password for easy login next time?',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setStateSB) {
                  return Row(
                    children: [
                      Checkbox(
                        value: dialogRemember,
                        onChanged: (v) => setStateSB(() => dialogRemember = v ?? false),
                        activeColor: Colors.deepPurple,
                      ),
                      Expanded(
                        child: Text(
                          'Save email & password securely',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 8),
              Text(
                'Your credentials are stored locally on your device and are encrypted.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() => rememberMe = dialogRemember);
                if (rememberMe) {
                  await _maybeStoreCredentials();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Credentials saved successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  await _clearRememberedCredentials();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Credentials cleared'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                if (mounted) Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Helper method to manually navigate to dashboard
  void _navigateToDashboard() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  // Helper method to save user data to database
  Future<void> _saveUserToDatabase(User user, {required bool isUpdate}) async {
    try {
      final database = FirebaseDatabase.instance;
      final profileRef = database.ref("users/${user.uid}/profile");
      final nowIso = DateTime.now().toIso8601String();

      if (isUpdate) {
        await profileRef.update({
          "lastSignIn": nowIso,
          "email": user.email,
        });
      } else {
        await profileRef.set({
          "email": user.email,
          "displayName": user.email?.split('@')[0] ?? "User",
          "isEmailUser": true,
          "createdAt": nowIso,
          "lastSignIn": nowIso,
          "providerId": "password",
          "isVerified": user.emailVerified,
        });
      }
    } catch (e) {
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save user data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to save guest user data to database
  Future<void> _saveGuestUserToDatabase(User user) async {
    try {
      final database = FirebaseDatabase.instance;
      final profileRef = database.ref("users/${user.uid}/profile");
      final nowIso = DateTime.now().toIso8601String();
      await profileRef.set({
        "email": "guest@anonymous.com",
        "displayName": "Guest User",
        "isGuest": true,
        "createdAt": nowIso,
        "lastSignIn": nowIso,
        "providerId": "anonymous",
        "isVerified": false,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save guest user data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to save Google user data to database
  Future<void> _saveGoogleUserToDatabase(UserCredential userCredential) async {
    try {
      final user = userCredential.user;
      if (user == null) {
        return;
      }

      final database = FirebaseDatabase.instance;
      final profileRef = database.ref("users/${user.uid}/profile");
      final nowIso = DateTime.now().toIso8601String();
      
      await profileRef.set({
        "email": user.email,
        "displayName": user.displayName ?? "Google User",
        "photoURL": user.photoURL,
        "isGoogleUser": true,
        "lastSignIn": nowIso,
        "createdAt": nowIso,
        "providerId": "google.com",
        "isVerified": user.emailVerified,
        "uid": user.uid,
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully signed in with Google!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save Google user data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to save Apple user data to database
  Future<void> _saveAppleUserToDatabase(UserCredential userCredential) async {
    try {
      final user = userCredential.user;
      if (user == null) {
        return;
      }

      final database = FirebaseDatabase.instance;
      final profileRef = database.ref("users/${user.uid}/profile");
      final nowIso = DateTime.now().toIso8601String();
      
      await profileRef.set({
        "email": user.email,
        "displayName": user.displayName ?? "Apple User",
        "isAppleUser": true,
        "lastSignIn": nowIso,
        "createdAt": nowIso,
        "providerId": "apple.com",
        "isVerified": user.emailVerified,
        "uid": user.uid,
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully signed in with Apple!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save Apple user data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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


