import 'package:flutter/material.dart';
import '../../../data/datasources/signalr_service.dart';

class ConnectionStatusBanner extends StatelessWidget {
  final SignalRConnectionState connectionState;

  const ConnectionStatusBanner({
    super.key,
    required this.connectionState,
  });

  @override
  Widget build(BuildContext context) {
    if (connectionState == SignalRConnectionState.connected) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (connectionState == SignalRConnectionState.connecting ||
                connectionState == SignalRConnectionState.reconnecting)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
                ),
              )
            else
              Icon(
                _getIcon(),
                size: 18,
                color: _getTextColor(),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getMessage(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (connectionState) {
      case SignalRConnectionState.disconnected:
        return Colors.grey.shade300;
      case SignalRConnectionState.connecting:
        return Colors.blue.shade100;
      case SignalRConnectionState.connected:
        return Colors.green.shade100;
      case SignalRConnectionState.reconnecting:
        return Colors.orange.shade100;
      case SignalRConnectionState.failed:
        return Colors.red.shade100;
    }
  }

  Color _getTextColor() {
    switch (connectionState) {
      case SignalRConnectionState.disconnected:
        return Colors.grey.shade700;
      case SignalRConnectionState.connecting:
        return Colors.blue.shade900;
      case SignalRConnectionState.connected:
        return Colors.green.shade900;
      case SignalRConnectionState.reconnecting:
        return Colors.orange.shade900;
      case SignalRConnectionState.failed:
        return Colors.red.shade900;
    }
  }

  IconData _getIcon() {
    switch (connectionState) {
      case SignalRConnectionState.disconnected:
        return Icons.cloud_off;
      case SignalRConnectionState.connecting:
        return Icons.cloud_sync;
      case SignalRConnectionState.connected:
        return Icons.cloud_done;
      case SignalRConnectionState.reconnecting:
        return Icons.cloud_sync;
      case SignalRConnectionState.failed:
        return Icons.error_outline;
    }
  }

  String _getMessage() {
    switch (connectionState) {
      case SignalRConnectionState.disconnected:
        return 'Not connected - Messages will not update in real-time';
      case SignalRConnectionState.connecting:
        return 'Connecting to messaging service...';
      case SignalRConnectionState.connected:
        return 'Connected';
      case SignalRConnectionState.reconnecting:
        return 'Connection lost - Reconnecting...';
      case SignalRConnectionState.failed:
        return 'Connection failed - Tap to retry';
    }
  }
}

