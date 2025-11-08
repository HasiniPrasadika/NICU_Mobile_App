import 'package:flutter/material.dart';

class LiveCameraPage extends StatefulWidget {
  const LiveCameraPage({super.key});

  @override
  State<LiveCameraPage> createState() => _LiveCameraPageState();
}

class _LiveCameraPageState extends State<LiveCameraPage> {
  bool connectionFailed = true;

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00B686);
    const darkBg = Color(0xFF0B1B18);
    const panelBg = Color(0xFF112C27);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Live Camera · Full View',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monitor the incubator feed with snapshot exports, resolution controls, and connection diagnostics.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Outer container (border frame)
              Container(
                decoration: BoxDecoration(
                  color: panelBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.redAccent.withOpacity(0.4),
                    width: 1.4,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header bar
                    Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1B18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.3),
                            width: 1.0,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.circle,
                                          color: Colors.redAccent, size: 10),
                                      SizedBox(width: 8),
                                      Text(
                                        'INC-001',
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Live Camera',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow
                                        .ellipsis, // Prevents long text overflow
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 30),
                            Flexible(
                              fit: FlexFit.loose,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    connectionFailed = !connectionFailed;
                                  });
                                },
                                icon: const Icon(Icons.refresh,
                                    size: 18, color: Colors.white),
                                label: const Text('Retry',
                                    overflow: TextOverflow.ellipsis),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      primaryGreen.withOpacity(0.15),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: primaryGreen.withOpacity(0.4)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )),
                    const SizedBox(height: 20),

                    // Video / Status Box
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 300,
                      decoration: BoxDecoration(
                        color: panelBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.3),
                          width: 1.0,
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.5),
                            const Color(0xFF0B1B18),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: connectionFailed
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.white38, size: 48),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Connection Failed',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Unable to connect to camera feed',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        connectionFailed = false;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 14),
                                    ),
                                    child: const Text(
                                      'Try Again',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const Center(
                                child: Text(
                                  'Live feed streaming...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
