import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothControllerScreen extends StatefulWidget {
  final BluetoothDevice device;
  static const String myService = '0000ffe0-0000-1000-8000-00805f9b34fb';
  static const String myCharacteristic = '0000ffe1-0000-1000-8000-00805f9b34fb';
  final player = AudioPlayer();

  BluetoothControllerScreen({super.key, required this.device});

  @override
  State<BluetoothControllerScreen> createState() =>
      _BluetoothControllerScreenState();
}

class _BluetoothControllerScreenState extends State<BluetoothControllerScreen> {
  BluetoothCharacteristic? _characteristic;
  bool isPlayingAudio = false;
  List<String> messages = [];

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    widget.device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.connected) {
        // Do something when connected
      }
    });
  }

  void getServices() async {
    var connectionState = await widget.device.connectionState.first;
    if (connectionState != BluetoothConnectionState.connected) {
      await widget.device.connect();
    }
    List<BluetoothService> services = await widget.device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.uuid.str128 ==
                BluetoothControllerScreen.myCharacteristic &&
            service.uuid.str128 == BluetoothControllerScreen.myService) {
          setState(() {
            _characteristic = characteristic;
          });

          _characteristic!.setNotifyValue(true);
          _characteristic!.lastValueStream.listen((value) {
            String receivedData = utf8.decode(value);
            setState(() {
              messages.add('Jetson Nano: $receivedData');
            });
            receivedDataHandler(receivedData);
          });
        }
      }
    }
  }

  void sendData(String data) async {
    try {
      if (_characteristic != null && _characteristic!.properties.write) {
        await _characteristic!.write(data.codeUnits, withoutResponse: true);
        setState(() {
          messages.add('My phone: $data');
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending data: $e');
      }
    }
  }

  void receivedDataHandler(String data) {
    if (data == '1' && !isPlayingAudio) {
      playSound();
    }
  }

  void playSound() async {
    setState(() {
      isPlayingAudio = true;
    });
    try {
      await widget.player.play(AssetSource('sounds/low_hip.wav'));
    } finally {
      setState(() {
        isPlayingAudio = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Controller'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: getServices, // Get services
            child: const Text('Get Services'),
          ),
          _characteristic != null
              ? Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Enter data to send',
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        sendData(_controller.text);
                        _controller.clear();
                      },
                      child: const Text('Send Data'),
                    ),
                  ],
                )
              : const SizedBox(),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    messages[index],
                    style: TextStyle(
                      color: messages[index].contains('My phone')
                          ? Colors.blue
                          : Colors.green,
                    ),
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
