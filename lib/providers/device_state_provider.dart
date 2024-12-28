import 'package:flutter/foundation.dart';

class DeviceStateProvider extends ChangeNotifier {
  // Device states mapped by MAC address
  Map<String, dynamic> _deviceStates = {};

  // Getter for device states
  Map<String, dynamic> get deviceStates => _deviceStates;

  // Update state for a specific device
  void updateDeviceState(String macAddress, Map<String, dynamic> state) {
    _deviceStates[macAddress] = state;
    notifyListeners();
  }

  // Get state for a specific device with MAC address and switch number
  bool getDeviceState(String macAddress, int switchNumber) {
    String key = '${macAddress}_switch$switchNumber';
    return _deviceStates[key] ?? false;
  }

  void toggleDeviceState(String macAddress, int switchNumber) {
    String key = '${macAddress}_switch$switchNumber';
    _deviceStates[key] = !(_deviceStates[key] ?? false);
    notifyListeners();
  }
}
