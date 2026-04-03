import 'package:flutter/material.dart';

class DroneCard extends StatelessWidget {
  final Map<String, dynamic> drone;
  final VoidCallback onTap;

  const DroneCard({super.key, required this.drone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Batarya rengi mantığı
    Color batteryColor = drone['battery'] > 70 
        ? const Color(0xFF3B82F6) 
        : drone['battery'] > 30 
            ? Colors.yellow.shade700 
            : const Color(0xFFDC2626);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 420,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0A0A).withOpacity(0.95),
              const Color(0xFF050505).withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.1), blurRadius: 20, spreadRadius: 5)
          ],
        ),
        child: Stack(
          children: [
            // Köşe Süslemeleri (React'taki corner decorations)
            Positioned(
              top: 0, right: 0,
              child: _buildCorner(top: true, right: true),
            ),
            Positioned(
              bottom: 0, left: 0,
              child: _buildCorner(bottom: true, left: true),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: İsim ve Durum
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              drone['name'],
                              style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                            ),
                            Text(
                              drone['type'],
                              style: TextStyle(color: const Color(0xFF3B82F6).withOpacity(0.6), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: drone['status'] == 'Active' ? const Color(0xFF3B82F6).withOpacity(0.2) : Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          drone['status'],
                          style: TextStyle(color: drone['status'] == 'Active' ? const Color(0xFF3B82F6) : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Drone Wireframe (SVG yerine Flutter Icon/CustomPaint)
                  Center(
                    child: Icon(Icons.gps_fixed, size: 100, color: const Color(0xFF3B82F6).withOpacity(0.4)),
                  ),
                  
                  const Spacer(),
                  
                  // Stats Section
                  Column(
                    children: [
                      // Battery Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("BATTERY", style: TextStyle(color: Colors.white54, fontSize: 10)),
                          Text("${drone['battery']}%", style: TextStyle(color: batteryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildBatteryBar(drone['battery'], batteryColor),
                      const SizedBox(height: 16),
                      _buildInfoRow("MISSION", drone['mission']),
                      const SizedBox(height: 8),
                      _buildInfoRow("UNIT ID", "KTP-${drone['id'].toString().padLeft(3, '0')}"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner({bool top = false, bool bottom = false, bool left = false, bool right = false}) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: top ? BorderSide(color: const Color(0xFF3B82F6).withOpacity(0.3), width: 2) : BorderSide.none,
          bottom: bottom ? BorderSide(color: const Color(0xFF3B82F6).withOpacity(0.3), width: 2) : BorderSide.none,
          left: left ? BorderSide(color: const Color(0xFF3B82F6).withOpacity(0.3), width: 2) : BorderSide.none,
          right: right ? BorderSide(color: const Color(0xFF3B82F6).withOpacity(0.3), width: 2) : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildBatteryBar(int level, Color color) {
    return Container(
      height: 6, width: double.infinity,
      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(3)),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: level / 100,
        child: Container(
          decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(3),
            boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10)],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        Text(value, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}