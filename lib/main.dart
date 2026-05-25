import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CBT MA 2026',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'Memeriksa koneksi internet…';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _checkInternetAndProceed();
  }

  Future<void> _checkInternetAndProceed() async {
    setState(() {
      _status = 'Memeriksa koneksi internet…';
      _hasError = false;
    });

    try {
      // Wait to show splash screen briefly
      await Future.delayed(const Duration(milliseconds: 1500));
      
      final response = await http.get(Uri.parse('http://asat.ma.putrarinjani.sch.id/')).timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 500) {
        setState(() {
          _status = 'Koneksi tersedia. Memulai…';
        });
        await Future.delayed(const Duration(milliseconds: 800));
        
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ExamPage()),
        );
      } else {
        setState(() {
          _status = 'Tidak ada koneksi internet.\nPastikan perangkat terhubung ke jaringan.';
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Tidak ada koneksi internet.\nPastikan perangkat terhubung ke jaringan.';
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0E5A1D),
              Color(0xFF1B8A2E),
              Color(0xFF2AB041),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Text(
              'CBT MA 2026',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Sistem Ujian Madrasah Berbasis Android & iOS',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            const Text(
              'MA NW Putra Rinjani',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            if (!_hasError)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            const SizedBox(height: 20),
            Text(
              _status,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_hasError)
              ElevatedButton(
                onPressed: _checkInternetAndProceed,
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color(0xFF0E5A1D), backgroundColor: Colors.white,
                ),
                child: const Text('Coba Lagi'),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class ExamPage extends StatefulWidget {
  const ExamPage({super.key});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _cheatDetected = false;

  final String _examUrl = 'http://asat.ma.putrarinjani.sch.id/';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _controller.runJavaScript(
                "document.body.style.webkitUserSelect='none';"
                "document.body.style.userSelect='none';"
                "document.body.style.webkitTouchCallout='none';"
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(_examUrl));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (!_cheatDetected) {
        setState(() {
          _cheatDetected = true;
        });
        _controller.clearCache();
        _controller.clearLocalStorage();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_cheatDetected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Indikasi kecurangan terdeteksi! Sesi direset.'),
            duration: Duration(seconds: 4),
            backgroundColor: Colors.red,
          ),
        );
        _controller.loadRequest(Uri.parse(_examUrl));
        setState(() {
          _cheatDetected = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
