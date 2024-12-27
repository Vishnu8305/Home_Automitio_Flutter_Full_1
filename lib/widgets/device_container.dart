// lib/widgets/device_container.dart
import 'package:flutter/material.dart';

class DeviceContainer extends StatelessWidget {
  final String deviceName;
  final String bleAddress;
  final int numberOfDevices;
  final VoidCallback onTap;

  const DeviceContainer({
    Key? key,
    required this.deviceName,
    required this.bleAddress,
    required this.numberOfDevices,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.devices,
                color: Color(0xFF0D7377),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  deviceName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF0D7377),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
