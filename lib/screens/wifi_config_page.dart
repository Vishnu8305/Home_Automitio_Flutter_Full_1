import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import '../providers/theme_provider.dart';
import '../screens/dashboard.dart';

class WiFiConfigPage extends StatefulWidget {
  final BluetoothDevice device;
  final String deviceName;

  WiFiConfigPage({
    required this.device,
    required this.deviceName,
  });

  @override
  _WiFiConfigPageState createState() => _WiFiConfigPageState();
}

class _WiFiConfigPageState extends State<WiFiConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _deviceNameController = TextEditingController();
  final _mqttBrokerController = TextEditingController();
  final _numDevicesController = TextEditingController(text: '1');

  bool _isLoading = false;
  String _connectionStatus = 'Disconnected';
  late String _macAddress;
  StreamSubscription? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _deviceNameController.text = widget.deviceName;
    _macAddress = widget.device.id.toString();
  }

  Future<void> _configureDevice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _connectionStatus = "Configuring...";
    });

    try {
      // Prepare JSON configuration
      Map<String, dynamic> config = {
        'ssid': _ssidController.text,
        'password': _passwordController.text,
        'deviceName': _deviceNameController.text,
        'mqttBroker': _mqttBrokerController.text,
        'numDevices': int.parse(_numDevicesController.text)
      };

      // Convert to JSON string
      String jsonConfig = jsonEncode(config);

      // Find the service and characteristic for configuration
      await _sendConfigurationToESP32(jsonConfig);
    } catch (e) {
      _showError('Configuration failed: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendConfigurationToESP32(String jsonConfig) async {
    try {
      // Discover services
      List<BluetoothService> services = await widget.device.discoverServices();

      // Find the characteristic for configuration and status
      BluetoothCharacteristic? configCharacteristic;
      BluetoothCharacteristic? statusCharacteristic;

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          // Configuration characteristic
          if (characteristic.uuid.toString() ==
              "abcdefab-cdef-1234-5678-1234567890ab") {
            configCharacteristic = characteristic;
          }

          // Status characteristic
          if (characteristic.uuid.toString() ==
              "fedcba98-7654-3210-9876-543210fedcba") {
            statusCharacteristic = characteristic;
          }
        }

        // Break if both characteristics are found
        if (configCharacteristic != null && statusCharacteristic != null) break;
      }

      if (configCharacteristic == null) {
        throw Exception("Configuration characteristic not found");
      }

      if (statusCharacteristic == null) {
        throw Exception("Status characteristic not found");
      }

      // Write JSON configuration
      await configCharacteristic.write(utf8.encode(jsonConfig));

      // Listen for status response
      _listenForConfigurationStatus(statusCharacteristic);
    } catch (e) {
      print('Configuration send error: $e'); // Debug print
      _showError('Failed to send configuration: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _listenForConfigurationStatus(BluetoothCharacteristic characteristic) {
    // Cancel any existing subscription
    _statusSubscription?.cancel();

    // Listen for notifications or read responses
    _statusSubscription = characteristic.value.listen((value) {
      if (value.isNotEmpty) {
        try {
          String response = utf8.decode(value);
          print('Received BLE response: $response'); // Debug print

          // Parse the JSON response
          Map<String, dynamic> statusJson = jsonDecode(response);

          // Check for specific status messages
          if (statusJson['type'] == 'status') {
            String message = statusJson['message'];
            print('Status message: $message'); // Debug print

            // Check for connected or success message
            if (message.toLowerCase().contains('connected') ||
                message.toLowerCase().contains('success')) {
              // Successfully configured
              _onDeviceConfigured();
            }
          }
        } catch (e) {
          print('Error processing BLE response: $e');
        }
      }
    }, onError: (error) {
      print('BLE Characteristic Error: $error'); // Debug print
      _showError('Error receiving status: $error');
      setState(() {
        _isLoading = false;
      });
    });

    // Enable notifications and read current value
    characteristic.setNotifyValue(true);
    characteristic.read(); // Attempt to read current value
  }

  void _onDeviceConfigured() {
    // Ensure this is called on the main thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cancel the subscription
      _statusSubscription?.cancel();

      setState(() {
        _connectionStatus = "Connected";
        _isLoading = false;
      });

      // Navigate to dashboard with device configuration
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => DashboardPage(
            newDevice: {
              'deviceName': _deviceNameController.text,
              'macAddress': _macAddress,
              'numDevices': int.parse(_numDevicesController.text),
              'mqttBroker': _mqttBrokerController.text,
            },
          ),
        ),
        (Route<dynamic> route) => false, // Remove all previous routes
      );
    });
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Cancel any ongoing subscriptions
    _statusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'WiFi Configuration',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 24,
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MAC Address and Wi-Fi Status
                _buildInfoCard('Device MAC Address', _macAddress, isDark),
                SizedBox(height: 10),
                _buildInfoCard('Wi-Fi Status', _connectionStatus, isDark),
                SizedBox(height: 20),

                // Device Settings
                _buildSectionHeader('Device Settings', isDark),
                _buildTextField(
                  controller: _deviceNameController,
                  label: 'Device Name',
                  icon: Icons.devices_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the device name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                _buildNumberOfDevicesField(),

                SizedBox(height: 30),

                // Wi-Fi Settings
                _buildSectionHeader('WiFi Settings', isDark),
                _buildTextField(
                  controller: _ssidController,
                  label: 'WiFi Network Name (SSID)',
                  icon: Icons.wifi_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter WiFi SSID';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _passwordController,
                  label: 'WiFi Password',
                  icon: Icons.lock_rounded,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter WiFi password';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 30),

                // MQTT Settings
                _buildSectionHeader('MQTT Settings', isDark),
                _buildTextField(
                  controller: _mqttBrokerController,
                  label: 'MQTT Broker IP',
                  icon: Icons.cloud_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter MQTT broker IP';
                    }
                    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                    if (!ipRegex.hasMatch(value)) {
                      return 'Please enter a valid IP address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),

                // Configure Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _configureDevice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Color(0xFF0D7377),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? Colors.white70 : Colors.white,
                            ),
                          )
                        : Text(
                            'Configure Device',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(icon, color: isDark ? Colors.white70 : Color(0xFF0D7377)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
      ),
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      validator: validator,
    );
  }

  Widget _buildNumberOfDevicesField() {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return TextFormField(
      controller: _numDevicesController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Number of Devices',
        prefixIcon: Icon(Icons.devices_other_rounded,
            color: isDark ? Colors.white70 : Color(0xFF0D7377)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
      ),
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter number of devices';
        }
        final number = int.tryParse(value);
        if (number == null || number < 1 || number > 10) {
          return 'Please enter a valid number (1-10)';
        }
        return null;
      },
    );
  }

  Widget _buildInfoCard(String title, String value, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(
                fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Color(0xFF0D7377)),
    );
  }
}
