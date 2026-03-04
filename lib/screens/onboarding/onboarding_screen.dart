import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:practice/screens/auth/welcome_screen.dart';

// ----- Data Model -----
class _OnboardingData {
  final String image;
  final String tag;
  final String title;
  final String description;
  final Color accentColor;

  const _OnboardingData({
    required this.image,
    required this.tag,
    required this.title,
    required this.description,
    required this.accentColor,
  });
}

const List<_OnboardingData> _pages = [
  _OnboardingData(
    image: 'assets/images/ob_welcome.png',
    tag: 'WELCOME TO AGRIVISION',
    title: 'Revolutionizing Fruit Farming.\nPrecise. Sustainable. Future.',
    description:
        'An all-in-one digital platform for modernized fruit production, diagnostics, and commerce.',
    accentColor: Color(0xFF6FCF97),
  ),
  _OnboardingData(
    image: 'assets/images/ob_disease.png',
    tag: 'AI DISEASE SCAN',
    title: 'Detect Pest & Disease\nInstantly. Save Fruits.',
    description:
        'Use your smartphone camera to perform on-the-spot AI-powered diagnostics on your fruit crops.',
    accentColor: Color(0xFF56CCF2),
  ),
  _OnboardingData(
    image: 'assets/images/ob_spray.png',
    tag: 'WEATHER-AWARE SPRAY RECOMMENDATION',
    title: 'Optimal Spray Windows\nfor Health, Zero Drift.',
    description:
        'AI integrates real-time weather and localized forecasts to recommend the best time to spray, maximizing efficiency.',
    accentColor: Color(0xFFFFD166),
  ),
  _OnboardingData(
    image: 'assets/images/ob_market.png',
    tag: 'AGRIVISION MARKETPLACE',
    title: 'Connect DIRECTLY to\nPremium Buyers.',
    description:
        'List your verified fresh produce and find reliable agricultural partners to grow your business.',
    accentColor: Color(0xFFEB5757),
  ),
];

// ----- Screen -----
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _ctrl = PageController();
  int _current = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _goToWelcome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  void _next() {
    if (_current < _pages.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToWelcome();
    }
  }

  void _back() {
    _ctrl.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── PageView (full-screen) ──────────────────────────────────
          PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
          ),

          // ── Top row: back arrow + skip ──────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back arrow (hidden on first page)
                  if (_current > 0)
                    _GlassButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: _back,
                    )
                  else
                    const SizedBox(width: 44),

                  // Skip
                  TextButton(
                    onPressed: _goToWelcome,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom overlay: text + dots + button ────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomPanel(
              pages: _pages,
              current: _current,
              onNext: _next,
            ),
          ),
        ],
      ),
    );
  }
}

// ----- Full-Screen Page -----
class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Image.asset(
          data.image,
          fit: BoxFit.cover,
        ),
        // Dark gradient so text is readable
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.40, 0.75, 1.0],
              colors: [
                Colors.black.withValues(alpha: 0.15),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.55),
                Colors.black.withValues(alpha: 0.90),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ----- Bottom Text + Controls Panel -----
class _BottomPanel extends StatelessWidget {
  final List<_OnboardingData> pages;
  final int current;
  final VoidCallback onNext;

  const _BottomPanel({
    required this.pages,
    required this.current,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final data = pages[current];
    final bool isLast = current == pages.length - 1;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 30,
        left: 28,
        right: 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag pill
          FadeInUp(
            key: ValueKey('tag_$current'),
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: data.accentColor.withValues(alpha: 0.25),
                border: Border.all(color: data.accentColor, width: 1.5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                data.tag,
                style: GoogleFonts.poppins(
                  color: data.accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Title
          FadeInUp(
            key: ValueKey('title_$current'),
            duration: const Duration(milliseconds: 550),
            delay: const Duration(milliseconds: 80),
            child: Text(
              data.title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Description
          FadeInUp(
            key: ValueKey('desc_$current'),
            duration: const Duration(milliseconds: 550),
            delay: const Duration(milliseconds: 160),
            child: Text(
              data.description,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.80),
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Dots + button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dots
              Row(
                children: List.generate(pages.length, (i) {
                  final bool active = i == current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    margin: const EdgeInsets.only(right: 7),
                    width: active ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          active ? data.accentColor : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              // Next / Get Started button
              GestureDetector(
                onTap: onNext,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  padding: EdgeInsets.symmetric(
                    horizontal: isLast ? 28 : 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        data.accentColor,
                        data.accentColor.withValues(alpha: 0.75),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: data.accentColor.withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLast ? 'Get Started' : 'Next',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isLast
                            ? Icons.check_circle_outline_rounded
                            : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ----- Small Glass Icon Button -----
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.30),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
