import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';

class VideoStream extends StatefulWidget {
  const VideoStream({super.key});

  @override
  State<VideoStream> createState() => _VideoStreamState();
}

class _VideoStreamState extends State<VideoStream> {
  final channel = IOWebSocketChannel.connect(
      'ws://192.168.1.10:7749'); // Replace with server IP and port
  Uint8List? imageData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Stream')),
      body: Center(
        child: RepaintBoundary(
          child: imageData == null
              ? const Text("Waiting for video...")
              : Image.memory(
                  imageData!,
                  gaplessPlayback: true, // Tránh nhấp nháy khi đổi ảnh
                ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    channel.stream.listen((data) {
      if (!mounted) return; // Kiểm tra nếu widget vẫn còn trong cây
      try {
        final decodedData = base64Decode(data);
        setState(() {
          imageData = decodedData;
        });
      } catch (e) {
        // print("Error decoding data: $e");
      }
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }
}