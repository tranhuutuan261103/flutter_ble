import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class WifiConfigScreen extends StatefulWidget {
  final BluetoothDevice device;
  static const String myService = '0000ffe0-0000-1000-8000-00805f9b34fb';
  static const String myCharacteristic = '0000ffe1-0000-1000-8000-00805f9b34fb';
  final player = AudioPlayer();

  WifiConfigScreen({super.key, required this.device});

  @override
  State<WifiConfigScreen> createState() =>
      _WifiConfigScreenState();
}

class _WifiConfigScreenState extends State<WifiConfigScreen> {
  BluetoothCharacteristic? _characteristic;
  bool isPlayingAudio = false;
  List<String> messages = [];

  String latestData = '';

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
                WifiConfigScreen.myCharacteristic &&
            service.uuid.str128 == WifiConfigScreen.myService) {
          setState(() {
            _characteristic = characteristic;
          });

          _characteristic!.setNotifyValue(true);
          _characteristic!.lastValueStream.listen((value) {
            String receivedData = utf8.decode(value);
            setState(() {
              messages.add('Jetson Nano: $receivedData');
              latestData = receivedData;
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
    List<String> errors = [
      'elbow_to_after',
      'elbow_to_front',
      'high_hip',
      'low_hip_elbow_to_after',
      'low_hip_elbow_to_front',
      'low_hip',
      'wrong_exercise'
    ];
    if (errors.contains(data) && !isPlayingAudio) {
      playSound(data);
    }
  }

  void playSound(String path) async {
    setState(() {
      isPlayingAudio = true;
    });
    try {
      await widget.player.play(AssetSource('sounds/$path.wav'));
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(latestData,
                  style: const TextStyle(fontSize: 20, color: Colors.red),
                  textAlign: TextAlign.center),
            ],
          ),
          _characteristic != null
              ? Expanded(
                  child: Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        "Exercise Controller",
                        style: TextStyle(fontSize: 20),
                      ),
                      MaterialButton(
                        onPressed: () {
                          sendData("list_wifi");
                        },
                        child: const Text(
                          "Start",
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                      MaterialButton(
                        onPressed: () {
                          sendData("s");
                        },
                        child: const Text(
                          "Stop",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ))
              : const SizedBox(),
        ],
      ),
    );
  }
}
