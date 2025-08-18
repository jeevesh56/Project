import 'package:flutter/material.dart';
import 'currency_selection_screen.dart';

class AboutMoMoScreen extends StatefulWidget {
  const AboutMoMoScreen({super.key});

  @override
  State<AboutMoMoScreen> createState() => _AboutMoMoScreenState();
}

class _AboutMoMoScreenState extends State<AboutMoMoScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
              const Color(0xFFf093fb),
              const Color(0xFFf5576c),
              const Color(0xFF4facfe),
            ],
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animated Mo-Mo Logo
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade400,
                              Colors.orange.shade600,
                              Colors.red.shade500,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: RotationTransition(
                          turns: _rotateAnimation,
                          child: const Icon(
                            Icons.attach_money,
                            size: 70,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 40),
                  
                  // Animated Welcome Text
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _fadeController,
                        curve: Curves.easeOut,
                      )),
                      child: const Text(
                        'Welcome to Mo-Mo!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2),
                              blurRadius: 4,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                
                  const SizedBox(height: 20),
                  
                  // Animated Description
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _fadeController,
                        curve: Curves.easeOut,
                      )),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Mo-Mo – Your intelligent money manager to track income and expenses with ease! 💰✨',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                
                  const Spacer(),
                  
                  // Animated Start Button
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 220,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade500,
                              Colors.orange.shade600,
                              Colors.red.shade500,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CurrencySelectionScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Get Started! 🚀',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
