import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/uav_controller.dart';

class CommandCockpit extends StatelessWidget {
  const CommandCockpit({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller'ı buluyoruz
    final UavController controller = Get.find<UavController>();

    return Scaffold(
      backgroundColor: const Color(0xFF030A12),
      appBar: AppBar(
        backgroundColor: Colors.black26,
        elevation: 0,
        title: Obx(() => Text(
          controller.selectedUavId.value.toUpperCase(), 
          style: const TextStyle(letterSpacing: 2, fontSize: 16)
        )),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              Obx(() => _buildHeader(controller.selectedUavId.value)),
              
              const SizedBox(height: 30),
              
              // --- CANLI TELEMETRİ SATIRI ---
              Obx(() {
                final uav = controller.currentUav;
                
                if (uav == null) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blue));
                }

                return Row(
                  children: [
                    Expanded(child: _buildStatCard(
                      "İRTİFA", 
                      uav.telemetry.altitude.toStringAsFixed(1), 
                      "METRE"
                    )),
                    const SizedBox(width: 15),
                    Expanded(child: _buildStatCard(
                      "HIZ", 
                      uav.telemetry.speed.toStringAsFixed(1), 
                      "KM/S"
                    )),
                    const SizedBox(width: 15),
                    Expanded(child: _buildStatCard(
                      "BATARYA", 
                      "%${uav.telemetry.battery}", 
                      "KAPASİTE"
                    )),
                  ],
                );
              }),
              
              const Spacer(),
              
              Center(
                child: Obx(() => Column(
                  children: [
                    Icon(
                      Icons.radar, 
                      size: 80, 
                      color: controller.currentUav?.status.isArmed == true ? Colors.red : Colors.blue
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "UÇUŞ MODU: ${controller.currentUav?.status.flightMode ?? 'BEKLENİYOR'}", 
                      style: const TextStyle(color: Colors.blue, letterSpacing: 2, fontSize: 12)
                    ),
                  ],
                )),
              ),

              const Spacer(),

              _buildActionButtons(controller),
              
              const SizedBox(height: 10),
              // DÜZELTİLEN YER: Buraya 'controller' parametresini ekledik
              _buildVoiceCommand(controller), 
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- YARDIMCI WIDGET'LAR ---

  Widget _buildHeader(String droneName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "SANCAKTAR KOMUTA MERKEZİ",
          style: TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 2, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "AKTİF BAĞLANTI: ${droneName.toUpperCase()}",
          style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1621),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(unit, style: const TextStyle(color: Colors.blueGrey, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(UavController controller) {
    return Row(
      children: [
        Expanded(child: _buildOutlinedButton(
          "KALKIŞ (TAKE OFF)", 
          Colors.blue, 
          () => controller.sendCommand("TAKEOFF")
        )),
        const SizedBox(width: 15),
        Expanded(child: _buildOutlinedButton(
          "İNİŞ (LAND)", 
          Colors.red, 
          () => controller.sendCommand("LAND")
        )),
      ],
    );
  }

  Widget _buildOutlinedButton(String label, Color color, VoidCallback onPressed) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildVoiceCommand(UavController controller) {
    return Obx(() {
      final bool isListening = controller.isListening.value;
      final Color activeColor = isListening ? Colors.redAccent : Colors.blueGrey;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (controller.lastWords.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                controller.lastWords.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: activeColor.withOpacity(0.8),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.2,
                ),
              ),
            ),

          GestureDetector(
            onLongPressStart: (_) => controller.toggleListening(),
            onLongPressEnd: (_) => controller.toggleListening(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isListening ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isListening ? Colors.redAccent : Colors.blueGrey.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: isListening ? [
                  BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)
                ] : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isListening ? Icons.mic : Icons.mic_none,
                    color: activeColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isListening ? "DİNLENİYOR..." : "SESLİ KOMUT İÇİN BASILI TUT",
                    style: TextStyle(
                      color: activeColor,
                      fontSize: 11,
                      fontWeight: isListening ? FontWeight.bold : FontWeight.normal,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}