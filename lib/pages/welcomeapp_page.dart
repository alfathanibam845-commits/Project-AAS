
import 'package:flutter/material.dart';
import 'package:item_shop/pages/login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static const Color green = Color(0xFF174D3A);
  static const Color dark = Color(0xFF26352D);
  static const Color muted = Color(0xFF7B887F);
  static const Color background = Color(0xFFF7F8F4);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 520,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // =====================================
                  // IMAGE SECTION
                  // =====================================

                  SizedBox(
                    height: screenHeight * 0.43,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // BACKGROUND IMAGE
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: SizedBox(
                              height: screenHeight * 0.40,
                              width: double.infinity,
                              child: ClipPath(
                                clipper: _CurvedImageClipper(),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // LOCAL IMAGE
                                    Image.asset(
                                      'assets/images/barwell.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          color: const Color(0xFFDCE9DF),
                                          child: const Center(
                                            child: Icon(
                                              Icons.image_not_supported_outlined,
                                              size: 55,
                                              color: green,
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                    // IMAGE OVERLAY
                                    Container(
                                      color: Colors.black.withOpacity(0.25),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // CENTER LOGO
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: -4,
                          child: Center(
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: background,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.10),
                                    blurRadius: 18,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE5EDE5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.inventory_2_rounded,
                                  size: 43,
                                  color: green,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // =====================================
                  // BRAND NAME
                  // =====================================

                  const Text(
                    'BARKAS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: dark,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Temukan Barang Impianmu',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: green,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'Temukan berbagai barang pilihan dengan mudah.\n'
                    'Belanja lebih praktis bersama BARKAS.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: muted,
                      fontSize: 14,
                      height: 1.7,
                    ),
                  ),

                  const SizedBox(height: 38),

                  // =====================================
                  // LOGIN BUTTON
                  // =====================================

                  SizedBox(
                    width: 190,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // FOOTER
                  const Text(
                    'BARKAS • BELANJA LEBIH MUDAH',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// CUSTOM CURVED IMAGE
// ==========================================

class _CurvedImageClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.76);

    path.quadraticBezierTo(
      size.width * 0.78,
      size.height * 1.08,
      size.width * 0.50,
      size.height * 0.98,
    );

    path.quadraticBezierTo(
      size.width * 0.20,
      size.height * 1.08,
      0,
      size.height * 0.76,
    );

    path.close();

    return path;
  }

  @override
  bool shouldReclip(
    covariant CustomClipper<Path> oldClipper,
  ) {
    return false;
  }
}
