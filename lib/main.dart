// Copyright 2017-2023, Charles Weinberger & Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// import 'screens/bluetooth_off_screen.dart';
// import 'screens/scan_screen.dart';
import 'screens/bluetooth_controller_screen.dart';

void main() {
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: App(),
    );
  }
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<StatefulWidget> createState() => _AppState();
}

class _AppState extends State<StatefulWidget> {
  List<ScanResult> _scanResults = [];
  BluetoothDevice? myDevice;
  // ignore: unused_field
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;

  @override
  void initState() {
    super.initState();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          ScanResult r = results.last; // the most recently found device
          if (r.advertisementData.advName == 'BT05') {
            setState(() {
              myDevice = r.device;
            });
          }
        }
        _scanResults = results;
        if (mounted) {
          setState(() {});
        }
      },
      onError: (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Scan Error: $e'),
        ));
      },
      onDone: () {
        print("Scan Done");
      },
    );
  }

  Future onScanPressed() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
      ));
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: onScanPressed,
                    child: const Text('Scan'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      FlutterBluePlus.stopScan();
                    },
                    child: const Text('Stop Scan'),
                  ),
                  myDevice != null
                      ? ElevatedButton(
                          onPressed: () {
                            if (myDevice == null) {
                              return;
                            }
                            FlutterBluePlus.stopScan();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) {
                                  return BluetoothControllerScreen(
                                      device: myDevice!);
                                },
                              ),
                            );
                          },
                          child: const Text('Connect to BT05'),
                        )
                      : const SizedBox(),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _scanResults
                    .map(
                      (r) => Text(
                        '${r.device.remoteId}: "${r.advertisementData.advName}"',
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//
// This widget shows BluetoothOffScreen or
// ScanScreen depending on the adapter state
//
// class FlutterBlueApp extends StatefulWidget {
//   const FlutterBlueApp({Key? key}) : super(key: key);

//   @override
//   State<FlutterBlueApp> createState() => _FlutterBlueAppState();
// }

// class _FlutterBlueAppState extends State<FlutterBlueApp> {
//   BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

//   late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

//   @override
//   void initState() {
//     super.initState();
//     _adapterStateStateSubscription =
//         FlutterBluePlus.adapterState.listen((state) {
//       _adapterState = state;
//       if (mounted) {
//         setState(() {});
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _adapterStateStateSubscription.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     Widget screen = _adapterState == BluetoothAdapterState.on
//         ? const ScanScreen()
//         : BluetoothOffScreen(adapterState: _adapterState);

//     return MaterialApp(
//       color: Colors.lightBlue,
//       home: screen,
//       navigatorObservers: [BluetoothAdapterStateObserver()],
//     );
//   }
// }

// //
// // This observer listens for Bluetooth Off and dismisses the DeviceScreen
// //
// class BluetoothAdapterStateObserver extends NavigatorObserver {
//   StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

//   @override
//   void didPush(Route route, Route? previousRoute) {
//     super.didPush(route, previousRoute);
//     if (route.settings.name == '/DeviceScreen') {
//       // Start listening to Bluetooth state changes when a new route is pushed
//       _adapterStateSubscription ??=
//           FlutterBluePlus.adapterState.listen((state) {
//         if (state != BluetoothAdapterState.on) {
//           // Pop the current route if Bluetooth is off
//           navigator?.pop();
//         }
//       });
//     }
//   }

//   @override
//   void didPop(Route route, Route? previousRoute) {
//     super.didPop(route, previousRoute);
//     // Cancel the subscription when the route is popped
//     _adapterStateSubscription?.cancel();
//     _adapterStateSubscription = null;
//   }
// }
