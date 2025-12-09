import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class LiveCameraPage extends StatefulWidget {
  const LiveCameraPage({super.key});

  @override
  State<LiveCameraPage> createState() => _LiveCameraPageState();
}

class _LiveCameraPageState extends State<LiveCameraPage>
    with WidgetsBindingObserver {
  static const streamUrl =
      'https://incubator-dashboard-571778410429.us-central1.run.app/api/pi/8080/?action=stream';

  late final WebViewController _controller;
  final List<Map<String, String>> _cameraSources = [
    {
      'label': 'Baby View',
      'url':
          'https://incubator-dashboard-571778410429.us-central1.run.app/api/pi/8080/?action=stream',
    },
    {
      'label': 'LCD View',
      'url':
          'https://incubator-dashboard-571778410429.us-central1.run.app/api/pi/8081/?action=stream',
    },
  ];

  int _currentTab = 0;

  String get _activeStreamUrl => _cameraSources[_currentTab]['url']!;

  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });

            // ✅ Safety timeout
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted && _isLoading) {
                setState(() => _isLoading = false);
              }
            });
          },
          onProgress: (progress) {
            if (progress > 20 && _isLoading) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (_) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_activeStreamUrl));
  }

  // ✅ Pause stream when app goes to background (battery saver)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.loadHtmlString('<html></html>');
    } else if (state == AppLifecycleState.resumed) {
      _controller.loadRequest(Uri.parse(_activeStreamUrl));
    }
  }

  // ✅ Retry / Reload
  void _reloadStream() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _controller.loadRequest(Uri.parse(
      '$_activeStreamUrl&t=${DateTime.now().millisecondsSinceEpoch}',
    ));
  }

  void _switchTab(int index) {
    if (index == _currentTab) return;

    setState(() {
      _currentTab = index;
      _isLoading = true;
      _hasError = false;
    });

    // Clear current stream before loading another
    _controller.loadHtmlString('<html></html>');

    // Small delay ensures socket is released
    Future.delayed(const Duration(milliseconds: 150), () {
      _controller.loadRequest(Uri.parse(_activeStreamUrl));
    });
  }

  // ✅ Snapshot support
 Future<void> _takeSnapshot() async {
  final permission = await Permission.storage.request();
  if (!permission.isGranted) return;

  try {
    final response = await http.get(Uri.parse(_activeStreamUrl));
    if (response.statusCode != 200) throw 'Failed to fetch frame';

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/camera_snapshot_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(response.bodyBytes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Snapshot saved: ${file.path}')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Snapshot failed: $e')),
    );
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
      backgroundColor: const Color(0xFF0B1B18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1B18),
        title: const Text(
          "Live Camera",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: List.generate(_cameraSources.length, (index) {
              final isSelected = _currentTab == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _switchTab(index),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? Colors.greenAccent
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      _cameraSources[index]['label']!,
                      style: TextStyle(
                        color: isSelected ? Colors.greenAccent : Colors.white60,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            onPressed: _isLoading || _hasError ? null : _takeSnapshot,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _reloadStream,
          ),
        ],
      ),
      body: Stack(
        children: [
          /// ✅ WebView Feed
          Positioned.fill(
            child: !_hasError
                ? WebViewWidget(controller: _controller)
                : _ErrorOverlay(onRetry: _reloadStream),
          ),

          /// ✅ Connecting overlay
          if (_isLoading) const _ConnectingOverlay(),
        ],
      ),
    );
  }
}



class _ConnectingOverlay extends StatelessWidget {
  const _ConnectingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Connecting to camera…',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorOverlay({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'Camera connection failed',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
