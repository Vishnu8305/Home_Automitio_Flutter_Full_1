import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'bluetooth_scan.dart';
import '../providers/theme_provider.dart';
import 'dashboard.dart';
import '../wifi.dart';
import '../wifi_constants.dart';

class WiFiSettingsPage extends StatefulWidget {
  @override
  _WiFiSettingsPageState createState() => _WiFiSettingsPageState();
}

class _WiFiSettingsPageState extends State<WiFiSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _defaultWiFiController = TextEditingController();
  final _defaultMQTTBrokerController = TextEditingController();
  final _defaultDeviceNameController = TextEditingController();

  final mqttClient = MqttClient('broker', 'clientIdentifier');

  @override
  void initState() {
    super.initState();
    _loadSavedConfigurations();
    _listenToConnectionStatus();
  }

  void _listenToConnectionStatus() {
    // Listen for incoming messages
    // This is a placeholder and should be replaced with actual BLE message listening logic
    print('Setting up connection status listener');
  }

  void handleConnectionStatus(String status) {
    print('Handling connection status: $status');
    switch (status) {
      case 'Connected':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage()),
        );
        break;
      case 'Wi-Fi Failed':
      default:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BluetoothDevicesPage()),
        );
        break;
    }
  }

  Future<void> _loadSavedConfigurations() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultWiFiController.text = prefs.getString('default_wifi_ssid') ?? '';
      _defaultMQTTBrokerController.text =
          prefs.getString('default_mqtt_broker') ?? '';
      _defaultDeviceNameController.text =
          prefs.getString('default_device_name') ?? '';
    });
  }

  Future<void> _saveConfigurations() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_wifi_ssid', _defaultWiFiController.text);
    await prefs.setString(
        'default_mqtt_broker', _defaultMQTTBrokerController.text);
    await prefs.setString(
        'default_device_name', _defaultDeviceNameController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('WiFi configurations saved successfully!'),
        backgroundColor: Color(0xFF0D7377),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String? _validateSSID(String? value) {
    if (value == null || value.isEmpty) {
      return 'WiFi Network Name is required';
    }
    if (value.length < 2) {
      return 'SSID must be at least 2 characters';
    }
    return null;
  }

  String? _validateMQTTBroker(String? value) {
    if (value == null || value.isEmpty) {
      return 'MQTT Broker IP is required';
    }
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(value)) {
      return 'Please enter a valid IP address (e.g., 192.168.1.100)';
    }
    return null;
  }

  String? _validateDeviceName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Device Name is required';
    }
    if (value.length < 3) {
      return 'Device Name must be at least 3 characters';
    }
    return null;
  }

  void connectToWiFi() {
    // Placeholder method for WiFi connection
    // In a real implementation, this would trigger the ESP32 connection process
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BluetoothDevicesPage()),
    );
  }

  void connectToMQTT() {
    // Placeholder method for MQTT connection
    // In a real implementation, this would trigger the MQTT connection process
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BluetoothDevicesPage()),
    );
  }

  void sendStatusToApp(String message) {
    handleConnectionStatus(message);
  }

  // Manually parse and handle the connection status
  void parseConnectionStatus(String jsonString) {
    try {
      print('Received BLE response: $jsonString');

      // Parse the JSON
      Map<String, dynamic> statusData = json.decode(jsonString);

      // Check if it's a status message
      if (statusData['type'] == 'status') {
        handleConnectionStatus(statusData['message']);
      }
    } catch (e) {
      print('Error parsing connection status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'WiFi Configurations',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDark ? Color(0xFF1A1A1A) : Color(0xFF0D7377),
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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(20),
            children: [
              // WiFi Network Section
              _buildSectionTitle('WiFi Network', isDark),
              SizedBox(height: 10),
              _buildTextField(
                controller: _defaultWiFiController,
                label: 'Default WiFi Network (SSID)',
                icon: Icons.wifi,
                isDark: isDark,
                validator: _validateSSID,
              ),

              SizedBox(height: 20),

              // MQTT Broker Section
              _buildSectionTitle('MQTT Broker', isDark),
              SizedBox(height: 10),
              _buildTextField(
                controller: _defaultMQTTBrokerController,
                label: 'Default MQTT Broker IP',
                icon: Icons.cloud,
                isDark: isDark,
                validator: _validateMQTTBroker,
              ),

              SizedBox(height: 20),

              // Device Name Section
              _buildSectionTitle('Device Name', isDark),
              SizedBox(height: 10),
              _buildTextField(
                controller: _defaultDeviceNameController,
                label: 'Default Device Name',
                icon: Icons.devices,
                isDark: isDark,
                validator: _validateDeviceName,
              ),

              SizedBox(height: 30),

              // Save Button
              _buildSaveButton(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white : Color(0xFF0D7377),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
      ),
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
      ),
      validator: validator,
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D7377), Color(0xFF14BDAC)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF0D7377).withOpacity(0.2),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveConfigurations,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          'Save Configurations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
