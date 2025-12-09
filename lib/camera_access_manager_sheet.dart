import 'package:flutter/material.dart';
import 'package:nicu_app/models/camera_access_request.dart';

class CameraAccessManagerSheet extends StatefulWidget {
  final List<CameraAccessRequest> requests;
  final Future<void> Function(CameraAccessRequest req, String newStatus)
      onToggle;

  const CameraAccessManagerSheet({
    super.key,
    required this.requests,
    required this.onToggle,
  });

  @override
  State<CameraAccessManagerSheet> createState() =>
      _CameraAccessManagerSheetState();
}

class _CameraAccessManagerSheetState extends State<CameraAccessManagerSheet> {
  final Map<int, bool> _loadingMap = {};

  @override
  Widget build(BuildContext context) {
    final sortedRequests = [...widget.requests]..sort((a, b) {
        if (a.pendingRequest && !b.pendingRequest) return -1;
        if (!a.pendingRequest && b.pendingRequest) return 1;
        return (b.requestedAt?.millisecondsSinceEpoch ?? 0) -
            (a.requestedAt?.millisecondsSinceEpoch ?? 0);
      });

    return DraggableScrollableSheet(
      initialChildSize: 0.5, // start at 50% height
      minChildSize: 0.35, // minimum height
      maxChildSize: 0.9, // max height
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0B1B18),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                _buildHandle(),
                _buildHeader(context),
                const SizedBox(height: 8),
                _buildSubtitle(),
                const SizedBox(height: 12),

                /// List
                Expanded(
                  child: sortedRequests.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: sortedRequests.length,
                          itemBuilder: (context, index) {
                            return _buildRequestTile(sortedRequests[index]);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white30,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Live view permissions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Grant or pause parent access to the incubator camera.',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        'No parent assignments yet',
        style: TextStyle(color: Colors.white54),
      ),
    );
  }

  Widget _buildRequestTile(CameraAccessRequest req) {
    final enabled = req.status == 'granted';
    final isLoading = _loadingMap[req.parentId] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: req.pendingRequest
            ? Colors.amber.withOpacity(0.15)
            : const Color(0xFF112C27),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: req.pendingRequest ? Colors.amber : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.parentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Baby ${req.babyId}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                if (req.pendingRequest)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Pending approval',
                      style: TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            activeColor: Colors.greenAccent,
            onChanged: isLoading
    ? null
    : (value) async {
        setState(() {
          // 1. Mark loading
          _loadingMap[req.parentId] = true;
          // 2. Optimistically update the local state
          req.status = value ? 'granted' : 'revoked';
        });

        try {
          // 3. Call API to persist change
          await widget.onToggle(
            req,
            value ? 'granted' : 'revoked',
          );
        } catch (e) {
          // 4. If API fails, revert toggle
          setState(() {
            req.status = value ? 'revoked' : 'granted';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update access: $e')),
          );
        } finally {
          // 5. Remove loading
          setState(() {
            _loadingMap.remove(req.parentId);
          });
        }
      },

          ),
        ],
      ),
    );
  }
}
