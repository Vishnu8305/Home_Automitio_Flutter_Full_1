// lib/screens/device_control_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/device_state_provider.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class DeviceControlPage extends StatefulWidget {
  final String deviceName;
  final String macAddress;
  final String mqttBroker;
  final int numDevices;

  const DeviceControlPage({
    Key? key,
    required this.deviceName,
    required this.macAddress,
    required this.mqttBroker,
    required this.numDevices,
  }) : super(key: key);

  @override
  _DeviceControlPageState createState() => _DeviceControlPageState();
}

class _DeviceControlPageState extends State<DeviceControlPage> {
  MqttServerClient? _mqttClient;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _connectToMqttBroker();
  }

  void _connectToMqttBroker() async {
    // Use colons in MAC address for MQTT topic
    _mqttClient = MqttServerClient(
        widget.mqttBroker, 'flutter_client_${widget.macAddress}');
    _mqttClient?.port = 1883;
    _mqttClient?.keepAlivePeriod = 20;
    _mqttClient?.onConnected = _onMqttConnected;
    _mqttClient?.onDisconnected = _onMqttDisconnected;

    try {
      await _mqttClient?.connect();
    } catch (e) {
      print('MQTT Connection Error: $e');
      setState(() {
        _isConnected = false;
      });
    }
  }

  void _onMqttConnected() {
    setState(() {
      _isConnected = true;
    });
    print('Connected to MQTT Broker');
  }

  void _onMqttDisconnected() {
    setState(() {
      _isConnected = false;
    });
    print('Disconnected from MQTT Broker');
  }

  void _publishMqttMessage(int switchNumber, bool state) {
    if (_mqttClient == null || !_isConnected) return;

    // Use colons in MAC address for MQTT topic
    String topic = '${widget.macAddress}/home/switch$switchNumber';

    final builder = MqttClientPayloadBuilder();
    builder.addString(state ? 'ON' : 'OFF');

    _mqttClient?.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }

  @override
  void dispose() {
    _mqttClient?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final deviceStateProvider = Provider.of<DeviceStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.deviceName,
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
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Connection Status Indicator
            _buildConnectionStatusCard(isDark),
            SizedBox(height: 20),

            // MQTT Broker Information Card
            _buildInfoCard(
              'MQTT Broker',
              '${widget.mqttBroker}:1883',
              Icons.cloud_rounded,
              isDark,
            ),
            SizedBox(height: 20),

            // Device Details Card
            _buildInfoCard(
              'Device Details',
              'MAC: ${widget.macAddress}',
              Icons.device_hub_rounded,
              isDark,
            ),
            SizedBox(height: 30),

            // Dynamic Toggle Switches
            Text(
              'Device Controls',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Color(0xFF0D7377),
              ),
            ),
            SizedBox(height: 20),

            // Generate toggle switches based on number of devices
            ...List.generate(
              widget.numDevices,
              (index) =>
                  _buildToggleSwitch(deviceStateProvider, index + 1, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _isConnected
            ? (isDark ? Colors.green[900] : Colors.green[100])
            : (isDark ? Colors.red[900] : Colors.red[100]),
      ),
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            _isConnected ? Icons.check_circle : Icons.error,
            color: _isConnected
                ? (isDark ? Colors.green[300] : Colors.green[700])
                : (isDark ? Colors.red[300] : Colors.red[700]),
          ),
          SizedBox(width: 16),
          Text(
            _isConnected
                ? 'Connected to MQTT Broker'
                : 'Disconnected from MQTT Broker',
            style: TextStyle(
              color: _isConnected
                  ? (isDark ? Colors.white : Colors.green[800])
                  : (isDark ? Colors.white : Colors.red[800]),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String value, IconData icon, bool isDark) {
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
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Color(0xFF0D7377).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white70 : Color(0xFF0D7377),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch(
      DeviceStateProvider deviceStateProvider, int switchNumber, bool isDark) {
    bool currentState =
        deviceStateProvider.getDeviceState(widget.macAddress, switchNumber);

    // Use colons in MAC address for MQTT topic
    String mqttTopic = '${widget.macAddress}/home/switch$switchNumber';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          'Switch $switchNumber',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          'MQTT Topic: $mqttTopic',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        value: currentState,
        onChanged: (bool value) {
          deviceStateProvider.toggleDeviceState(
              widget.macAddress, switchNumber);

          // Publish MQTT message when switch is toggled
          _publishMqttMessage(switchNumber, value);
        },
        activeColor: Color(0xFF0D7377),
        inactiveThumbColor: isDark ? Colors.grey[500] : Colors.grey[300],
        inactiveTrackColor:
            isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300],
      ),
    );
  }
}
