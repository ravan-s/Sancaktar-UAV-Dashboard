import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Import metodun içinde değil, burada olmalı!

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  late AnimationController _splitController;
  late AnimationController _shineController;
  bool isSplitting = false;

  @override
  void initState() {
    super.initState();
    // 1. Kontrolcüleri tanımla
    _splitController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _shineController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

    // 2. Senaryoyu başlat
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => isSplitting = true);
        _splitController.forward(); // Kapıları açar
      }

      // Kapılar açılmaya başladıktan 1 saniye sonra Login ekranına geç
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Get.offNamed('/login'); 
        }
      });
    }); // Future.delayed (3 sn) kapanış parantezi
  } // initState kapanış parantezi

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Izgara Arka Planı
          Opacity(
            opacity: 0.1,
            child: GridPaper(color: Colors.blueAccent, interval: 40, divisions: 1, subdivisions: 1),
          ),

          // 2. SOL PANEL (Mavi Gradyan)
          AnimatedBuilder(
            animation: _splitController,
            builder: (context, child) => Positioned(
              left: -size.width * 0.5 * _splitController.value,
              top: 0, bottom: 0, width: size.width * 0.5,
              child: Container(decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [ Color(0xFF0f172a),Color(0xFF1e3a8a)])
              )),
            ),
          ),

          // 3. SAĞ PANEL (Mavi Gradyan)
          AnimatedBuilder(
            animation: _splitController,
            builder: (context, child) => Positioned(
              right: -size.width * 0.5 * _splitController.value,
              top: 0, bottom: 0, width: size.width * 0.5,
              child: Container(decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF1e3a8a), Color(0xFF0f172a)])
              )),
            ),
          ),

          // 4. ORTA İÇERİK
          Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: isSplitting ? 0.0 : 1.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: size.width * 0.7, height: 60,
                        decoration: BoxDecoration(
                          boxShadow: [BoxShadow(color: const Color(0xFFDC2626).withOpacity(0.4), blurRadius: 50, spreadRadius: 10)],
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Color(0xFFDC2626), Color(0xFF7F1D1D)],
                        ).createShader(bounds),
                        child: const Text("SANCAKTAR", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 10, color: Colors.white)),
                      ),
                      AnimatedBuilder(
                        animation: _shineController,
                        builder: (context, child) => ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [Colors.transparent, Colors.white.withOpacity(0.5), Colors.transparent],
                            stops: [_shineController.value - 0.2, _shineController.value, _shineController.value + 0.2],
                          ).createShader(bounds),
                          child: const Text("SANCAKTAR", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 10, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "TACTICAL COMMAND SYSTEM",
                    style: TextStyle(color: Colors.blueAccent.withOpacity(0.7), letterSpacing: 4, fontSize: 12),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: 200, height: 2,
                    decoration: BoxDecoration(color: const Color(0xFF1e3a8a), borderRadius: BorderRadius.circular(10)),
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(seconds: 3),
                          width: isSplitting ? 200 : 150,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.red, Colors.blue]),
                            boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.6), blurRadius: 10)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _splitController.dispose();
    _shineController.dispose();
    super.dispose();
  }
}