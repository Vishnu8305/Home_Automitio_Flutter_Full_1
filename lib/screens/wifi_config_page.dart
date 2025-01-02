import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import '../providers/theme_provider.dart';
import '../screens/dashboard.dart';
import '../screens/bluetooth_scan.dart';

// Color Palette Class
class AppColorPalette {
  // Light Theme Colors
  static const lightPrimary = Color(0xFF2196F3);
  static const lightSecondary = Color(0xFF4CAF50);
  static const lightBackground = Color(0xFFF5F5F5);
  static const lightAccent = Color(0xFF03A9F4);

  // Dark Theme Colors
  static const darkPrimary = Color(0xFF1976D2);
  static const darkSecondary = Color(0xFF388E3C);
  static const darkBackground = Color(0xFF121212);
  static const darkAccent = Color(0xFF00BCD4);

  // Gradient Colors
  static const lightGradient = [
    Color(0xFFE3F2FD),
    Color(0xFFBBDEFB),
  ];

  static const darkGradient = [
    Color(0xFF1A237E),
    Color(0xFF283593),
  ];
}

class WiFiConfigPage extends StatefulWidget {
  final BluetoothDevice device;
  final String deviceName;

  const WiFiConfigPage({
    Key? key,
    required this.device,
    required this.deviceName,
  }) : super(key: key);

  @override
  _WiFiConfigPageState createState() => _WiFiConfigPageState();
}

class _WiFiConfigPageState extends State<WiFiConfigPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _deviceNameController = TextEditingController();
  final _mqttBrokerController = TextEditingController();
  final _mqttPasswordController = TextEditingController();
  final _numDevicesController = TextEditingController(text: '1');

  bool _isLoading = false;
  String _connectionStatus = 'Disconnected';
  late String _macAddress;
  StreamSubscription? _statusSubscription;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isDeviceConfigured = false;
  bool _isWiFiPasswordVisible = false;
  bool _isMQTTPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // _deviceNameController.text = widget.deviceName;
    _macAddress = widget.device.id.toString();

    // Setup animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _animationController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    _deviceNameController.dispose();
    _mqttBrokerController.dispose();
    _mqttPasswordController.dispose();
    _numDevicesController.dispose();
    super.dispose();
  }

  Future<void> _configureDevice() async {
    // Prevent multiple configuration attempts
    if (_isLoading) return;

    // Reset device configured flag
    _isDeviceConfigured = false;

    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Always set loading state to true
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
        'mqttPassword': _mqttPasswordController.text,
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
        _connectionStatus = "Configuration Error";
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

      // Cancel any existing subscription before setting up a new one
      _statusSubscription?.cancel();

      // Setup a timeout for configuration
      final completer = Completer<void>();
      Timer? timeoutTimer;

      // Listen for status response before writing configuration
      _statusSubscription = statusCharacteristic.value.listen((value) {
        if (value.isNotEmpty) {
          try {
            String response = utf8.decode(value);
            print('Received BLE response: $response');

            Map<String, dynamic> statusJson = jsonDecode(response);

            if (statusJson['type'] == 'status') {
              String message = statusJson['message'];
              print('Status message: $message');

              setState(() {
                _connectionStatus = message;

                // Reset loading state for any failed configuration
                if (message.toLowerCase().contains('failed')) {
                  _isLoading = false;
                  _isDeviceConfigured = false;
                }
              });

              // Complete the configuration process
              if (!_isDeviceConfigured) {
                if (message.toLowerCase() == 'connected') {
                  _onDeviceConfigured();
                }
              }

              // Cancel the timeout timer
              timeoutTimer?.cancel();
              if (!completer.isCompleted) {
                completer.complete();
              }
            }
          } catch (e) {
            print('Error processing BLE response: $e');
            setState(() {
              _isLoading = false;
              _connectionStatus = "Error: $e";
            });

            // Complete with error
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          }
        }
      }, onError: (error) {
        print('BLE Characteristic Error: $error');
        setState(() {
          _connectionStatus = "Error: $error";
          _isLoading = false;
        });

        // Complete with error
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      });

      // Set up a timeout
      timeoutTimer = Timer(Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.completeError(TimeoutException('Configuration timed out'));
          setState(() {
            _isLoading = false;
            _connectionStatus = "Configuration Timeout";
          });
        }
      });

      // Enable notifications
      await statusCharacteristic.setNotifyValue(true);

      // Write configuration
      await configCharacteristic.write(utf8.encode(jsonConfig));

      // Wait for the configuration process to complete
      await completer.future;
    } catch (e) {
      print('Configuration send error: $e');
      _showError('Failed to send configuration: $e');
      setState(() {
        _isLoading = false;
        _connectionStatus = "Configuration Error";
      });
    }
  }

  void _onDeviceConfigured() {
    // Ensure this is called on the main thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Prevent multiple calls
      if (_isDeviceConfigured) return;

      // Set flag to prevent multiple triggers
      _isDeviceConfigured = true;

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

  void _onWiFiFailed() {
    // Ensure this is called on the main thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Prevent multiple calls
      if (_isDeviceConfigured) return;

      // Cancel the subscription
      _statusSubscription?.cancel();

      setState(() {
        _connectionStatus = "Wi-Fi Failed";
        _isLoading = false;
      });

      // Show dialog about Wi-Fi connection failure
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Wi-Fi Connection Failed'),
            content: Text(
              'The device could not connect to the specified Wi-Fi network. '
              'Please check your credentials and try again.',
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Retry Configuration'),
                onPressed: () {
                  // Close the dialog
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Rescan Devices'),
                onPressed: () {
                  // Close the dialog
                  Navigator.of(context).pop();

                  // Navigate to Bluetooth scan page for reconnection
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BluetoothDevicesPage(
                        isReconnecting: true,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
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

  // Enhanced Validation Methods
  String? _validateDeviceName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Device Name is required';
    }
    if (value.length < 3) {
      return 'Device Name must be at least 3 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_\-\s]+$').hasMatch(value)) {
      return 'Device Name can only contain letters, numbers, spaces, underscores, and hyphens';
    }
    return null;
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

  String? _validateWiFiPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'WiFi Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateMQTTBroker(String? value) {
    if (value == null || value.isEmpty) {
      return 'MQTT Broker is required';
    }
    // Allow alphanumeric characters, dots, and hyphens for domain names
    final brokerRegex = RegExp(r'^[a-zA-Z0-9.-]+$');
    if (!brokerRegex.hasMatch(value)) {
      return 'Please enter a valid broker address (e.g., broker.example.com)';
    }
    return null;
  }

  String? _validateNumDevices(String? value) {
    if (value == null || value.isEmpty) {
      return 'Number of Devices is required';
    }
    final number = int.tryParse(value);
    if (number == null || number < 1 || number > 10) {
      return 'Please select a valid number of devices (1-10)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text(
          'Device Configuration',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 24,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDark ? Color(0xFF1A1A1A) : Color(0xFF0D7377),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Cards
                  _buildStatusCards(isDark),
                  SizedBox(height: 20),

                  // Device Settings Section
                  _buildSectionTitle('Device Settings', isDark),
                  SizedBox(height: 10),
                  _buildDeviceSettingsFields(isDark),

                  SizedBox(height: 20),

                  // WiFi Settings Section
                  _buildSectionTitle('WiFi Settings', isDark),
                  SizedBox(height: 10),
                  _buildWiFiSettingsFields(isDark),

                  SizedBox(height: 20),

                  // MQTT Settings Section
                  _buildSectionTitle('MQTT Settings', isDark),
                  SizedBox(height: 10),
                  _buildMQTTSettingsFields(isDark),

                  SizedBox(height: 30),

                  // Configure Button
                  _buildConfigureButton(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCards(bool isDark) {
    Color statusColor;
    IconData statusIcon;

    // Determine status color and icon based on connection status
    switch (_connectionStatus.toLowerCase()) {
      case 'connected':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'wifi failed':
      case 'mqtt failed':
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        break;
      case 'configuring':
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.device_unknown;
    }

    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(16),
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
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoCard('Device MAC Address', _macAddress,
              Icons.device_hub_rounded, isDark),
          SizedBox(height: 10),
          _buildInfoCard(
            'Connection Status',
            _connectionStatus,
            statusIcon,
            isDark,
            statusColor: statusColor,
          ),
        ],
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

  Widget _buildInfoCard(String title, String value, IconData icon, bool isDark,
      {Color? statusColor}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: statusColor ?? Colors.white,
              size: 30,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor ?? Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigureButton(bool isDark) {
    bool isFailedStatus = _connectionStatus.toLowerCase().contains('failed');

    return Container(
      margin: EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFailedStatus
              ? [Colors.red.shade700, Colors.red.shade500]
              : [Color(0xFF0D7377), Color(0xFF14BDAC)],
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
        // Disable button completely when loading
        onPressed: _isLoading ? null : _configureDevice,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: _isLoading
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : Text(
                isFailedStatus ? 'Retry Configuration' : 'Configure Device',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // Update other methods to match this styling approach
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
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

  Widget _buildDeviceSettingsFields(bool isDark) {
    return Column(
      children: [
        _buildTextField(
          controller: _deviceNameController,
          label: 'Device Name *',
          icon: Icons.devices_rounded,
          isDark: isDark,
          validator: _validateDeviceName,
        ),
        SizedBox(height: 15),
        _buildNumberOfDevicesField(isDark),
      ],
    );
  }

  Widget _buildWiFiSettingsFields(bool isDark) {
    return Column(
      children: [
        _buildTextField(
          controller: _ssidController,
          label: 'WiFi Network Name (SSID) *',
          icon: Icons.wifi_rounded,
          isDark: isDark,
          validator: _validateSSID,
        ),
        SizedBox(height: 15),
        _buildTextField(
          controller: _passwordController,
          label: 'WiFi Password *',
          icon: Icons.lock_rounded,
          isPassword: true,
          isDark: isDark,
          validator: _validateWiFiPassword,
        ),
      ],
    );
  }

  Widget _buildMQTTSettingsFields(bool isDark) {
    return Column(
      children: [
        _buildTextField(
          controller: _mqttBrokerController,
          label: 'MQTT Broker IP *',
          icon: Icons.cloud_rounded,
          isDark: isDark,
          validator: _validateMQTTBroker,
        ),
        SizedBox(height: 15),
        _buildTextField(
          controller: _mqttPasswordController,
          label: 'MQTT Broker Password (Optional)',
          icon: Icons.lock_rounded,
          isPassword: true,
          isDark: isDark,
          validator: _validateMQTTBroker,
        ),
      ],
    );
  }

  Widget _buildNumberOfDevicesField(bool isDark) {
    return DropdownButtonFormField<int>(
      value: int.tryParse(_numDevicesController.text) ?? 1,
      decoration: InputDecoration(
        labelText: 'Number of Devices',
        prefixIcon: Icon(
          Icons.devices_other_rounded,
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
      dropdownColor: isDark ? Colors.grey[900] : Colors.white,
      items: List.generate(10, (index) => index + 1)
          .map((number) => DropdownMenuItem(
                value: number,
                child: Text(
                  '$number',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          _numDevicesController.text = value.toString();
        }
      },
      validator: (value) {
        if (value == null) {
          return 'Please select number of devices';
        }
        return null;
      },
      icon: Icon(
        Icons.arrow_drop_down,
        color: isDark ? Colors.white70 : Colors.black54,
      ),
    );
  }
}
