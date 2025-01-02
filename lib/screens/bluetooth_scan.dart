import 'dart:async';
import 'dart:convert';
import 'dart:math' show sin;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'wifi_settings.dart';
import 'wifi_config_page.dart';

class BluetoothDevicesPage extends StatefulWidget {
  final bool isReconnecting;

  const BluetoothDevicesPage({Key? key, this.isReconnecting = false})
      : super(key: key);

  @override
  _BluetoothDevicesPageState createState() => _BluetoothDevicesPageState();
}

// Top-level ConnectionProgressDialog class
class ConnectionProgressDialog extends StatefulWidget {
  final String deviceName;
  final VoidCallback onCancel;

  const ConnectionProgressDialog({
    Key? key,
    required this.deviceName,
    required this.onCancel,
  }) : super(key: key);

  @override
  _ConnectionProgressDialogState createState() =>
      _ConnectionProgressDialogState();
}

class _ConnectionProgressDialogState extends State<ConnectionProgressDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildConnectionStep(String step) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.white54,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              step,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 15,
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D7377), Color(0xFF14BDAC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Animated Connection Icon
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 + 0.1 * sin(_animation.value * 2 * 3.14),
                    child: Icon(
                      Icons.bluetooth_connected,
                      size: 60,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              SizedBox(height: 16),

              // Connection Text
              Text(
                'Connecting to ${widget.deviceName}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              SizedBox(height: 12),

              // Detailed Connection Steps
              _buildConnectionStep('Establishing Bluetooth Connection'),
              _buildConnectionStep('Discovering Services'),
              _buildConnectionStep('Configuring Communication'),

              SizedBox(height: 16),

              // Progress Indicator
              LinearProgressIndicator(
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),

              // Cancel Button
              ElevatedButton(
                onPressed: widget.onCancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF0D7377),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
                child: Text(
                  'Cancel Connection',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BluetoothDevicesPageState extends State<BluetoothDevicesPage> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  StreamSubscription? _scanResultsSubscription;
  StreamSubscription? _characteristicSubscription;
  String _scanStatus = 'Ready to scan';
  BluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();

    // Always check permissions and start scanning automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription?.cancel();
    _characteristicSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _checkBluetoothPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    bool isAvailable = await FlutterBluePlus.isAvailable;
    bool isOn = await FlutterBluePlus.isOn;

    setState(() {
      _scanStatus = isAvailable
          ? (isOn ? 'Bluetooth is ready' : 'Bluetooth is off')
          : 'Bluetooth not available';
    });

    if (!isAvailable) {
      _showBluetoothUnavailableDialog();
    } else if (!isOn) {
      _showBluetoothOffDialog();
    }
  }

  void _startScan() async {
    await _checkBluetoothPermissions();

    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _scanResults.clear();
      _scanStatus = 'Scanning for devices...';
    });

    try {
      await FlutterBluePlus.turnOn();

      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 15),
      );

      _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
        print('Total scan results: ${results.length}');
        setState(() {
          _scanResults = results.where((result) {
            bool isEsp32 = result.device.name.toLowerCase().contains('esp32') ||
                result.device.name.toLowerCase().contains('wifi') ||
                result.device.name.isNotEmpty;

            if (isEsp32) {
              print('Found potential device: ${result.device.name}');
            }
            return isEsp32;
          }).toList();
        });
      }, onError: (e) {
        print('Scan error: $e');
        setState(() {
          _scanStatus = 'Scan error: $e';
        });
      });

      await Future.delayed(Duration(seconds: 15));
      await FlutterBluePlus.stopScan();

      setState(() {
        _isScanning = false;
        _scanStatus = _scanResults.isEmpty
            ? 'No devices found'
            : 'Scan complete: ${_scanResults.length} devices found';
      });
    } catch (e) {
      print('Scan exception: $e');
      setState(() {
        _isScanning = false;
        _scanStatus = 'Scan failed: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bluetooth scanning error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBluetoothUnavailableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bluetooth Unavailable'),
        content: Text(
            'Your device does not support Bluetooth or it is not working correctly.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBluetoothOffDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bluetooth is Off'),
        content: Text('Please turn on Bluetooth to scan for devices.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              FlutterBluePlus.turnOn();
            },
            child: Text('Turn On'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _connectToDevice(BluetoothDevice device) async {
    // Show a custom connection dialog
    _showConnectionDialog(device);
  }

  void _showConnectionDialog(BluetoothDevice device) {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ConnectionProgressDialog(
          deviceName: device.name ?? 'Unknown Device',
          onCancel: () {
            // Close the dialog
            Navigator.of(context).pop();
          },
        );
      },
    );

    // Perform connection in a separate method
    _connectToDeviceAsync(device);
  }

  Future<void> _connectToDeviceAsync(BluetoothDevice device) async {
    try {
      // Actual connection process
      await device.connect(
        timeout: Duration(seconds: 15),
        autoConnect: false,
      );

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      print('Discovered ${services.length} services');

      // Find the status characteristic
      BluetoothCharacteristic? statusCharacteristic;
      for (BluetoothService service in services) {
        print('Service UUID: ${service.uuid}');
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          print('Characteristic UUID: ${characteristic.uuid}');
          if (characteristic.uuid ==
              Guid('fedcba98-7654-3210-9876-543210fedcba')) {
            statusCharacteristic = characteristic;
            break;
          }
        }
        if (statusCharacteristic != null) break;
      }

      if (statusCharacteristic != null) {
        // Enable notifications
        await statusCharacteristic.setNotifyValue(true);

        // Listen to characteristic changes
        _characteristicSubscription =
            statusCharacteristic.value.listen((value) {
          if (value.isNotEmpty) {
            _handleIncomingMessage(value);
          }
        });

        // Close loading dialog
        Navigator.of(context).pop();

        // Navigate to WiFi Config Page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WiFiConfigPage(
              device: device,
              deviceName: device.name ?? "ESP32 Device",
            ),
          ),
        );
      } else {
        // Close loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find status characteristic'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Connection error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect to device: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleIncomingMessage(List<int> value) {
    try {
      // Convert bytes to string
      String jsonString = utf8.decode(value);
      print('Received BLE response: $jsonString');

      // Parse the JSON
      Map<String, dynamic> statusData = json.decode(jsonString);

      // Check if it's a status message
      if (statusData['type'] == 'status') {
        _handleConnectionStatus(statusData['message']);
      }
    } catch (e) {
      print('Error parsing connection status: $e');
    }
  }

  void _handleConnectionStatus(String status) {
    print('Handling connection status: $status');
    switch (status) {
      case 'Connected':
        if (_connectedDevice != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WiFiConfigPage(
                device: _connectedDevice!,
                deviceName: _connectedDevice!.name ?? "ESP32 Device",
              ),
            ),
          );
        }
        break;
      case 'Wi-Fi Failed':
      default:
        // Show a dialog with reconnection options
        _showWiFiFailedDialog();
        break;
    }
  }

  void _showWiFiFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Wi-Fi Connection Failed'),
          content: Text(
            'The device could not connect to the specified Wi-Fi network. '
            'Would you like to try again?',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Retry Connection'),
              onPressed: () {
                // Close the dialog
                Navigator.of(context).pop();

                // Navigate back to WiFi Config Page to resend credentials
                if (_connectedDevice != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WiFiConfigPage(
                        device: _connectedDevice!,
                        deviceName: _connectedDevice!.name ?? "ESP32 Device",
                      ),
                    ),
                  );
                }
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isReconnecting ? 'Reconnect Device' : 'Bluetooth Devices'),
        actions: [
          // Add rescan icon
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Rescan Devices',
            onPressed: () {
              // Stop any ongoing scan first
              if (_isScanning) {
                FlutterBluePlus.stopScan();
              }

              // Clear previous scan results
              setState(() {
                _scanResults.clear();
                _scanStatus = 'Restarting scan...';
              });

              // Start a new scan
              _startScan();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Scan status indicator with reconnection hint if applicable
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color:
                widget.isReconnecting ? Colors.yellow[100] : Colors.grey[200],
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(
                  _isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
                  color: _isScanning ? Colors.blue : Colors.grey,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isReconnecting
                        ? 'Reconnecting... Scan for your ESP32 device'
                        : _scanStatus,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.isReconnecting
                          ? Colors.orange
                          : (_isScanning ? Colors.blue : Colors.black),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),

          if (_isScanning) LinearProgressIndicator(),

          Expanded(
            child: _scanResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isScanning
                              ? Icons.bluetooth_searching
                              : Icons.bluetooth_disabled,
                          size: 64,
                          color: _isScanning ? Colors.blue : Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          _isScanning
                              ? 'Searching for Bluetooth devices...'
                              : (widget.isReconnecting
                                  ? 'Reconnection attempt\n'
                                      'Make sure your ESP32 is:\n'
                                      '- Turned on\n'
                                      '- In Bluetooth pairing mode\n'
                                      '- Nearby'
                                  : 'No devices found.\n'
                                      'Make sure:\n'
                                      '- Bluetooth is on\n'
                                      '- Device is nearby\n'
                                      '- Device is in pairing mode'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _isScanning ? Colors.blue : Colors.grey,
                              fontWeight: _isScanning
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _scanResults.length,
                    itemBuilder: (context, index) {
                      ScanResult result = _scanResults[index];
                      return ListTile(
                        title: Text(result.device.name ?? 'Unknown Device'),
                        subtitle: Text(result.device.id.toString()),
                        trailing: ElevatedButton(
                          child: Text('Connect'),
                          onPressed: () => _connectToDevice(result.device),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
