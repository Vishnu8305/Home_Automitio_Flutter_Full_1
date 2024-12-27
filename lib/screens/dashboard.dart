import 'package:flutter/material.dart';
import '../widgets/drawer_menu.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'bluetooth_scan.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_control_page.dart';
import '../widgets/device_container.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic>? newDevice;

  const DashboardPage({Key? key, this.newDevice}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Map<String, dynamic>> _devices = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    String? devicesJson = prefs.getString('saved_devices');

    setState(() {
      if (devicesJson != null) {
        List<dynamic> savedDevices = json.decode(devicesJson);
        _devices =
            savedDevices.map((d) => Map<String, dynamic>.from(d)).toList();
      }

      // Update or add new device if provided
      if (widget.newDevice != null) {
        // Find index of existing device with same MAC address
        int existingDeviceIndex = _devices.indexWhere((device) =>
            device['macAddress'] == widget.newDevice!['macAddress']);

        if (existingDeviceIndex != -1) {
          // Replace existing device
          _devices[existingDeviceIndex] = widget.newDevice!;
        } else {
          // Add new device
          _devices.add(widget.newDevice!);
        }

        _saveDevices();
      }
    });
  }

  Future<void> _saveDevices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_devices', json.encode(_devices));
  }

  Future<void> navigateToBluetoothScanPage() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BluetoothDevicesPage(),
      ),
    );
  }

  Widget _buildDeviceList() {
    if (_devices.isEmpty) {
      return const Center(
        child: Text("No devices added yet."),
      );
    }

    return ListView.builder(
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];

        return DeviceContainer(
          deviceName: device['deviceName'],
          bleAddress: device['macAddress'],
          numberOfDevices: device['numDevices'],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeviceControlPage(
                  deviceName: device['deviceName'],
                  macAddress: device['macAddress'],
                  mqttBroker: device['mqttBroker'],
                  numDevices: device['numDevices'],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      drawer: DrawerMenu(),
      appBar: AppBar(
        title: const Text(
          "Smart Home",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 24,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDark ? Color(0xFF1A1A1A) : Color(0xFF0D7377),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Color(0xFF1A1A1A), Color(0xFF2D2D2D)]
                : [Color(0xFFF8FDFF), Color(0xFFF0F8FA)],
          ),
        ),
        child: Column(
          children: [
            // Welcome Section
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D7377), Color(0xFF14BDAC)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF0D7377).withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.home_outlined,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Welcome Home",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${_devices.length} devices connected",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Device List
            Expanded(
              child: _buildDeviceList(),
            ),

            // Add Device Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: navigateToBluetoothScanPage,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("Add Device"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white24 : Color(0xFF0D7377),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
