import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sancaktar_gcs/controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  // 1. AuthController'ı buluyoruz (Firebase bağlantısı için)
  final AuthController _authController = Get.find<AuthController>();
  
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // DERİN LACİVERT VE BORDO GRADYAN
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF020617), // Çok Koyu Lacivert
              Color(0xFF450a0a), // Çok Koyu Bordo (Kuytu)
            ],
          ),
        ),
        child: Stack(
          children: [
            // 2. Arka Plan Ortam Işıkları (Buğu efekti için)
            _buildAmbientLight(const Alignment(-0.8, -0.5), Colors.blue),
            _buildAmbientLight(const Alignment(0.8, 0.5), const Color(0xFFDC2626)),

            // 3. Arka Plan Izgarası
            Opacity(
              opacity: 0.05,
              child: GridPaper(color: Colors.blueAccent, interval: 50, divisions: 1, subdivisions: 1),
            ),

            // 4. Login Kartı
            Center(
              child: SingleChildScrollView(
                child: Container(
                  width: size.width > 500 ? 400 : size.width * 0.85,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.85), // Şeffaf Lacivert Kart
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.3)), // Bordo İnce Çerçeve
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withOpacity(0.15), // Bordo Buğu
                        blurRadius: 40, 
                        spreadRadius: 5
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      _buildCorner(Alignment.topRight, Colors.blue),
                      _buildCorner(Alignment.bottomLeft, const Color(0xFFDC2626)),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "SANCAKTAR",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              color: Color(0xFFDC2626), // Sancaktar Kırmızısı
                            ),
                          ),
                          const Text(
                            "SECURE ACCESS PORTAL",
                            style: TextStyle(color: Colors.blue, fontSize: 10, letterSpacing: 2),
                          ),
                          const SizedBox(height: 40),
                          // TextField'lar
                          _buildTextField("USERNAME", Icons.person_outline, _userController),
                          const SizedBox(height: 20),
                          _buildTextField("PASSWORD", Icons.lock_outline, _passController, isObscure: true),
                          const SizedBox(height: 30),
                          _buildAccessButton(),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () {},
                            child: const Text("ŞİFREMİ UNUTTUM", style: TextStyle(color: Color(0xFFDC2626), fontSize: 11)),
                          ),
                          const Divider(color: Colors.white10, height: 40),
                          _buildStatusRow(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 5. Tarama Çizgisi (Laser Scan)
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, child) => Positioned(
                top: size.height * _scanController.value,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, const Color(0xFFDC2626).withOpacity(0.5), Colors.transparent]
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- YARDIMCI METODLAR (TÜMÜ) ---

  // 1. ORTAM IŞIĞI (Ambient Light) - Arka plandaki buğu efekti
  Widget _buildAmbientLight(Alignment align, Color color) {
    return Align(
      alignment: align,
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15), 
              blurRadius: 100, 
              spreadRadius: 50
            ),
          ],
        ),
      ),
    );
  }

  // 2. KÖŞE DETAYLARI - Giriş kutusunun köşelerindeki L çizgileri
  Widget _buildCorner(Alignment align, Color color) {
    return Positioned(
      top: align == Alignment.topRight ? 0 : null,
      bottom: align == Alignment.bottomLeft ? 0 : null,
      right: align == Alignment.topRight ? 0 : null,
      left: align == Alignment.bottomLeft ? 0 : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: align == Alignment.topRight 
                ? BorderSide(color: color.withOpacity(0.5), width: 2) 
                : BorderSide.none,
            right: align == Alignment.topRight 
                ? BorderSide(color: color.withOpacity(0.5), width: 2) 
                : BorderSide.none,
            bottom: align == Alignment.bottomLeft 
                ? BorderSide(color: color.withOpacity(0.5), width: 2) 
                : BorderSide.none,
            left: align == Alignment.bottomLeft 
                ? BorderSide(color: color.withOpacity(0.5), width: 2) 
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  // 3. TEXTFIELD TASARIMI (Hatasız)
  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isObscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          style: const TextStyle(color: Colors.white),
          // E-posta klavyesi ve otomatik büyütmeyi kapatma
          keyboardType: isObscure ? TextInputType.text : TextInputType.emailAddress,
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blue.withOpacity(0.5), size: 20),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue.withOpacity(0.1)), 
              borderRadius: BorderRadius.circular(12)
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFDC2626)), 
              borderRadius: BorderRadius.circular(12)
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ],
    );
  }

  // 4. MAVİ GİRİŞ BUTONU (AuthController'ı çağıran yer)
  Widget _buildAccessButton() {
    return InkWell(
      // BURASI KRİTİK: AuthController'daki hileyi çalıştıran fonksiyonu çağırdık
      onTap: () => _authController.login(_userController.text, _passController.text),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10)],
        ),
        child: const Center(
          child: Text("ACCESS SYSTEM", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)
          )
        ),
      ),
    );
  }

  // 5. DURUM SATIRI (System Online / Secure)
  Widget _buildStatusRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatusIcon("SYSTEM ONLINE", Colors.blue),
        _buildStatusIcon("SECURE CONNECTION", Colors.green),
      ],
    );
  }

  // 6. DURUM İKONU
  Widget _buildStatusIcon(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: color.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }
}