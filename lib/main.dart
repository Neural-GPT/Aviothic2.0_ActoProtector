// main.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AttendanceScreen(),
    );
  }
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<String> classNames = ["Arjun", "Deepak", "Abhay"];
  final int embeddingSize = 128;
  final double matchThreshold = 0.55;

  bool _appReady = false;
  List<double> lastEmbeddingSlice = [];
  String confidenceStr = "0.0";
  String rmsStr = "0.0";
  String statusMessage = "Loading app...";
  List<Map<String, dynamic>> attendanceLog = [];

  @override
  void initState() {
    super.initState();
    _initFakeDb();
  }

  void _initFakeDb() {
    // Simulate fake embeddings DB for demo
    setState(() {
      _appReady = true;
      statusMessage = "Ready";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Smart Attendance',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: !_appReady
          ? const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildTopGif(),
                    const SizedBox(height: 12),
                    _buildGraphAndStats(),
                    const SizedBox(height: 12),
                    _buildStatusBox(),
                    const SizedBox(height: 12),
                    _buildCameraButton(),
                    const SizedBox(height: 12),
                    _buildAttendanceLog(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTopGif() {
    return SizedBox(
      height: 150,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset('assets/nn_top.gif', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildGraphAndStats() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.tealAccent),
            ),
            child: lastEmbeddingSlice.isEmpty
                ? const Center(
                    child: Text(
                      'Embeddings graph (empty)',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : CustomPaint(painter: EmbeddingPainter(lastEmbeddingSlice)),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          children: [
            _statBox("CL", confidenceStr),
            const SizedBox(height: 8),
            _statBox("RMS", rmsStr),
          ],
        )
      ],
    );
  }

  Widget _buildStatusBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.greenAccent,
          width: 2,
        ),
      ),
      child: Text(
        statusMessage,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  Widget _buildCameraButton() {
    return GestureDetector(
      onTap: _openNativeCamera,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt, color: Colors.white38, size: 50),
              SizedBox(height: 6),
              Text("Tap to capture photo",
                  style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceLog() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: attendanceLog.isEmpty
            ? const Center(
                child: Text(
                  "No entries yet",
                  style: TextStyle(color: Colors.white54),
                ),
              )
            : ListView.builder(
                itemCount: attendanceLog.length,
                itemBuilder: (context, idx) {
                  final e = attendanceLog[idx];
                  final bool success = e['success'] as bool;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: success ? Colors.greenAccent : Colors.redAccent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e['label'],
                            style: const TextStyle(color: Colors.white)),
                        Text(e['time'],
                            style: const TextStyle(color: Colors.white54)),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Future<void> _openNativeCamera() async {
    final XFile? file =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (file == null) return;

    final bytes = await File(file.path).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      setState(() => statusMessage = "❌ Image decode failed");
      return;
    }

    // Fake embedding generation for demo
    final rand = Random();
    final embedding =
        List.generate(embeddingSize, (_) => rand.nextDouble() * 2 - 1);
    final label = classNames[rand.nextInt(classNames.length)];
    final confidence = rand.nextDouble() * 0.5 + 0.5; // 50%-100%
    final success = confidence >= matchThreshold;

    _processFaceRecognitionResult(embedding, label, success, confidence * 100);
  }

  void _processFaceRecognitionResult(
      List<double> embedding, String label, bool success, double cl) {
    double rms = sqrt(embedding.fold(0.0, (p, v) => p + v * v) / embedding.length);

    // Generate smooth 36-point slice for graph
    List<double> smoothSlice = [];
    for (int i = 0; i < 36; i++) {
      int idx = (i * embedding.length ~/ 36);
      double val = embedding[idx];
      val = val * 0.8 + 0.1 * sin(i * pi / 12);
      smoothSlice.add(val.clamp(-1.0, 1.0));
    }

    setState(() {
      lastEmbeddingSlice = smoothSlice;
      confidenceStr = cl.toStringAsFixed(2);
      rmsStr = rms.toStringAsFixed(4);
      statusMessage = label;
      attendanceLog.add({
        'label': label,
        'time': DateFormat('HH:mm:ss').format(DateTime.now()),
        'success': success,
      });
    });
  }
}

class EmbeddingPainter extends CustomPainter {
  final List<double> data;
  EmbeddingPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Colors.tealAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (int i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final y = size.height * (1 - (data[i] + 1) / 2);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
