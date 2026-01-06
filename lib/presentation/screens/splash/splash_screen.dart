import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

/// Professional splash screen with RedPulse branding
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(
        milliseconds: 3000,
      ), // Slower, smoother animation
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final shortestSide = min(screenSize.width, screenSize.height);
    
    // Responsive sizing based on shortest side (consistent across orientations)
    final scaleFactor = (shortestSide / 375).clamp(0.7, 1.3);
    
    final logoSize = (isLandscape ? 50 : 70) * scaleFactor;
    final logoPadding = (isLandscape ? 18 : 28) * scaleFactor;
    final titleSize = (isLandscape ? 26 : 36) * scaleFactor;
    final taglineSize = (isLandscape ? 12 : 14) * scaleFactor;
    final loadingSize = (isLandscape ? 28 : 35) * scaleFactor;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
              AppColors.secondary,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLandscape ? 40 : 24,
                        vertical: isLandscape ? 16 : 24,
                      ),
                      child: isLandscape
                          ? _buildLandscapeLayout(
                              logoSize: logoSize,
                              logoPadding: logoPadding,
                              titleSize: titleSize,
                              taglineSize: taglineSize,
                              loadingSize: loadingSize,
                              scaleFactor: scaleFactor,
                            )
                          : _buildPortraitLayout(
                              logoSize: logoSize,
                              logoPadding: logoPadding,
                              titleSize: titleSize,
                              taglineSize: taglineSize,
                              loadingSize: loadingSize,
                              scaleFactor: scaleFactor,
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout({
    required double logoSize,
    required double logoPadding,
    required double titleSize,
    required double taglineSize,
    required double loadingSize,
    required double scaleFactor,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAnimatedLogo(logoSize, logoPadding),
        SizedBox(height: 32 * scaleFactor),
        _buildAppName(titleSize),
        SizedBox(height: 10 * scaleFactor),
        _buildTagline(taglineSize),
        SizedBox(height: 48 * scaleFactor),
        _buildLoadingIndicator(loadingSize),
        SizedBox(height: 12 * scaleFactor),
        _buildLoadingText(taglineSize * 0.85),
      ],
    );
  }

  Widget _buildLandscapeLayout({
    required double logoSize,
    required double logoPadding,
    required double titleSize,
    required double taglineSize,
    required double loadingSize,
    required double scaleFactor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo on left
        _buildAnimatedLogo(logoSize, logoPadding),
        SizedBox(width: 40 * scaleFactor),
        // Text content on right
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppName(titleSize),
              SizedBox(height: 6 * scaleFactor),
              _buildTagline(taglineSize),
              SizedBox(height: 20 * scaleFactor),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLoadingIndicator(loadingSize * 0.7),
                  SizedBox(width: 12 * scaleFactor),
                  _buildLoadingText(taglineSize * 0.85),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedLogo(double size, double padding) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _pulseAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 3,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.water_drop,
                size: size,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppName(double fontSize) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        AppStrings.appName,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildTagline(double fontSize) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        AppStrings.appTagline,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.white.withOpacity(0.9),
          letterSpacing: 1,
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoadingIndicator(double size) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingText(double fontSize) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        'Loading...',
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.white.withOpacity(0.8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
