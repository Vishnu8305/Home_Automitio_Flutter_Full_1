import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'wifi_config_page.dart';
import 'device_control_page.dart';
import 'dart:async';
import '../screens/device_control_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothDevicesPage extends StatefulWidget {
  @override
  _BluetoothDevicesPageState createState() => _BluetoothDevicesPageState();
}

class _BluetoothDevicesPageState extends State<BluetoothDevicesPage> {
  List<BluetoothDevice> devices = [];
  bool isScanning = false;
  StreamSubscription? scanSubscription;
  bool hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Check if Bluetooth is available first
      if (!await FlutterBluePlus.isAvailable) {
        showError(
          "Bluetooth Unavailable",
          "Bluetooth is not available on this device.",
        );
        return;
      }

      // Request permissions
      final granted = await requestPermissions();
      setState(() {
        hasPermissions = granted;
      });

      if (!granted) {
        showPermissionError();
        return;
      }

      // Try to turn on Bluetooth
      if (!await FlutterBluePlus.isOn) {
        try {
          await FlutterBluePlus.turnOn();
          // Wait a bit for Bluetooth to fully initialize
          await Future.delayed(Duration(seconds: 2));
        } catch (e) {
          print('Error turning on Bluetooth: $e');
          showError(
            "Bluetooth Error",
            "Failed to turn on Bluetooth. Please turn it on manually.",
          );
          return;
        }
      }

      // Start scanning if everything is OK
      startScan();
    } catch (e) {
      print('Error initializing Bluetooth: $e');
      showError(
        "Bluetooth Error",
        "Please make sure Bluetooth is turned on and permissions are granted.",
      );
    }
  }

  Future<bool> requestPermissions() async {
    try {
      // Request location permissions first
      await Permission.locationWhenInUse.request();
      await Permission.location.request();

      // Request Bluetooth permissions
      await Permission.bluetooth.request();
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      await Permission.bluetoothAdvertise.request();

      // Check if all required permissions are granted
      final locationStatus = await Permission.locationWhenInUse.status;
      final bluetoothStatus = await Permission.bluetoothScan.status;
      final connectStatus = await Permission.bluetoothConnect.status;

      if (!locationStatus.isGranted) {
        print('Location permission not granted');
        return false;
      }
      if (!bluetoothStatus.isGranted) {
        print('Bluetooth scan permission not granted');
        return false;
      }
      if (!connectStatus.isGranted) {
        print('Bluetooth connect permission not granted');
        return false;
      }

      return true;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  void showError(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void showPermissionError() {
    showError(
      "Permissions Required",
      "Bluetooth and location permissions are required to find and connect to devices.",
    );
  }

  void startScan() async {
    if (isScanning) return;

    try {
      setState(() {
        devices.clear();
        isScanning = true;
      });

      // Debug: Print Bluetooth state
      final btOn = await FlutterBluePlus.isOn;
      print('Bluetooth state - Is ON: $btOn');

      // Double check Bluetooth state
      if (!await FlutterBluePlus.isOn) {
        throw Exception('Bluetooth is turned off');
      }

      print('Starting scan...');

      // Debug: Print permission states
      final locationStatus = await Permission.locationWhenInUse.status;
      final bluetoothStatus = await Permission.bluetoothScan.status;
      final connectStatus = await Permission.bluetoothConnect.status;

      print('Permission states:');
      print('Location: $locationStatus');
      print('Bluetooth Scan: $bluetoothStatus');
      print('Bluetooth Connect: $connectStatus');

      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 30), // Increased scan duration
        androidUsesFineLocation: true,
      );

      scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          if (!mounted) return;

          // Debug: Print all discovered devices before filtering
          print('Raw scan results:');
          for (var r in results) {
            print(
                'Found device: ${r.device.name} (${r.device.id}) - RSSI: ${r.rssi}');
          }

          // Filter and sort results
          final validDevices = results
              .where((r) =>
                  r.device.name.isNotEmpty &&
                  (r.device.name.toLowerCase().contains('esp') ||
                      r.device.name.toLowerCase().contains('iot')))
              .toList();

          // Sort by RSSI (signal strength)
          validDevices.sort((a, b) => (b.rssi).compareTo(a.rssi));

          setState(() {
            devices = validDevices.map((r) => r.device).toList();
            devices = devices.toSet().toList(); // Remove duplicates
          });

          print('After filtering - Found ${devices.length} valid devices');
          for (var device in devices) {
            print('Valid device: ${device.name} (${device.id})');
          }
        },
        onError: (error) {
          print('Scan error: $error');
          print('Error stack trace:');
          print(StackTrace.current);
          showError("Scan Error", error.toString());
          stopScan();
        },
      );

      // Auto stop scan after timeout
      Future.delayed(Duration(seconds: 30), () {
        if (mounted && isScanning) {
          print('Auto-stopping scan after timeout');
          stopScan();
        }
      });
    } catch (e) {
      print('Error during scan: $e');
      print('Error stack trace:');
      print(StackTrace.current);
      showError(
        "Scan Error",
        "Failed to start scanning. Please ensure Bluetooth and Location are enabled.",
      );
      stopScan();
    }
  }

  void stopScan() {
    try {
      FlutterBluePlus.stopScan();
      scanSubscription?.cancel();
      setState(() {
        isScanning = false;
      });
      print('Scan stopped');
    } catch (e) {
      print('Error stopping scan: $e');
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    stopScan();
    showConnectingDialog();

    try {
      await device.connect();
      Navigator.pop(context); // Dismiss connecting dialog

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WiFiConfigPage(
            device: device,
            deviceName: device.name ?? "ESP32 Device",
          ),
        ),
      );

      if (result != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceControlPage(
              deviceName: result['deviceName'],
              macAddress: result['macAddress'],
              mqttBroker:
                  result['mqttBroker'], // Only use the broker from WiFi config
              numDevices: result['numDevices'],
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Dismiss connecting dialog
      showConnectionError(e.toString());
    }
  }

  void showConnectingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Connecting..."),
          ],
        ),
      ),
    );
  }

  void showConnectionError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Connection Failed"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select ESP32 Device"),
        actions: [
          if (isScanning)
            Container(
              margin: EdgeInsets.all(16),
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: startScan,
            ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            padding: EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  isScanning ? Icons.search : Icons.bluetooth,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: 8),
                Text(
                  isScanning
                      ? "Scanning for devices..."
                      : "Tap refresh to scan for devices",
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          // Device list
          Expanded(
            child: devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          isScanning
                              ? "Searching for devices..."
                              : "No devices found\nMake sure your device is nearby and in pairing mode",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return ListTile(
                        leading: Icon(Icons.bluetooth),
                        title: Text(device.name.isNotEmpty
                            ? device.name
                            : "Unknown Device"),
                        subtitle: Text(device.id.toString()),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () => connectToDevice(device),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    stopScan();
    super.dispose();
  }
}
