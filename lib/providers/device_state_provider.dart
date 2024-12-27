import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DeviceStateProvider with ChangeNotifier {
  Map<String, bool> _deviceStates = {};
  static const String DEVICE_STATES_KEY = 'device_toggle_states';
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  DeviceStateProvider() {
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadStatesFromPrefs();
    _isInitialized = true;
  }

  bool getDeviceState(String deviceId, int switchNumber) {
    String key = '${deviceId}_switch$switchNumber';
    return _deviceStates[key] ?? false;
  }

  Future<void> _loadStatesFromPrefs() async {
    String? statesJson = _prefs.getString(DEVICE_STATES_KEY);
    if (statesJson != null) {
      try {
        Map<String, dynamic> decoded = jsonDecode(statesJson);
        _deviceStates =
            decoded.map((key, value) => MapEntry(key, value as bool));
        print('Loaded device states: $_deviceStates');
      } catch (e) {
        print('Error loading device states: $e');
        _deviceStates = {};
      }
    }
    notifyListeners();
  }

  Future<void> toggleDeviceState(String deviceId, int switchNumber) async {
    if (!_isInitialized) await _initializePrefs();

    String key = '${deviceId}_switch$switchNumber';
    _deviceStates[key] = !(_deviceStates[key] ?? false);

    await _saveStates();
    notifyListeners();
  }

  Future<void> setDeviceState(
      String deviceId, int switchNumber, bool state) async {
    if (!_isInitialized) await _initializePrefs();

    String key = '${deviceId}_switch$switchNumber';
    if (_deviceStates[key] != state) {
      _deviceStates[key] = state;
      print('Setting device state: $key to $state');

      await _saveStates();
      notifyListeners();
    }
  }

  Future<void> _saveStates() async {
    try {
      await _prefs.setString(DEVICE_STATES_KEY, jsonEncode(_deviceStates));
      print('Saved device states: $_deviceStates');
    } catch (e) {
      print('Error saving device states: $e');
    }
  }

  Future<void> clearStates() async {
    if (!_isInitialized) await _initializePrefs();

    _deviceStates.clear();
    await _prefs.remove(DEVICE_STATES_KEY);
    notifyListeners();
  }
}
