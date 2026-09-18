import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../network/api_client.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Stream Controllers for Real-Time Push Events
  final StreamController<Map<String, dynamic>> _complaintCreatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _complaintStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _complaintLikedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _complaintCommentController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<void> _complaintsChangedController =
      StreamController<void>.broadcast();

  // Public Streams
  Stream<Map<String, dynamic>> get onComplaintCreated =>
      _complaintCreatedController.stream;
  Stream<Map<String, dynamic>> get onComplaintStatusChanged =>
      _complaintStatusController.stream;
  Stream<Map<String, dynamic>> get onComplaintLiked =>
      _complaintLikedController.stream;
  Stream<Map<String, dynamic>> get onComplaintCommentAdded =>
      _complaintCommentController.stream;
  Stream<void> get onComplaintsChanged => _complaintsChangedController.stream;

  /// Initialize and connect to the backend WebSocket server
  void init() {
    if (_socket != null && _isConnected) return;

    final origin = ApiClient.baseUrl.replaceAll('/api', '');
    debugPrint('⚡ [SocketService] Connecting to WebSocket: $origin');

    try {
      _socket = io.io(
        origin,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling']) // fall back to polling if ws blocked
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(2000)
            .setReconnectionAttempts(10)
            .build(),
      );

      _socket?.onConnect((_) {
        _isConnected = true;
        debugPrint('⚡ [SocketService] Connected successfully to $origin (Socket ID: ${_socket?.id})');
      });

      _socket?.onDisconnect((_) {
        _isConnected = false;
        debugPrint('⚡ [SocketService] Disconnected from WebSocket');
      });

      _socket?.onConnectError((err) {
        _isConnected = false;
        debugPrint('⚠️ [SocketService] Connection error: $err');
      });

      // 1. Complaint Created
      _socket?.on('complaint_created', (data) {
        debugPrint('⚡ [Socket.io] Event received: complaint_created');
        if (data is Map) {
          _complaintCreatedController.add(Map<String, dynamic>.from(data));
          _complaintsChangedController.add(null);
        }
      });

      // 2. Complaint Status Changed
      _socket?.on('complaint_status_changed', (data) {
        debugPrint('⚡ [Socket.io] Event received: complaint_status_changed -> $data');
        if (data is Map) {
          _complaintStatusController.add(Map<String, dynamic>.from(data));
          _complaintsChangedController.add(null);
        }
      });

      // 3. Complaint Liked
      _socket?.on('complaint_liked', (data) {
        debugPrint('⚡ [Socket.io] Event received: complaint_liked');
        if (data is Map) {
          _complaintLikedController.add(Map<String, dynamic>.from(data));
        }
      });

      // 4. Complaint Comment Added
      _socket?.on('complaint_comment_added', (data) {
        debugPrint('⚡ [Socket.io] Event received: complaint_comment_added');
        if (data is Map) {
          _complaintCommentController.add(Map<String, dynamic>.from(data));
        }
      });

      // 5. General Complaints Changed
      _socket?.on('complaints_changed', (_) {
        _complaintsChangedController.add(null);
      });
    } catch (e) {
      debugPrint('⚠️ [SocketService] Exception initializing socket: $e');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
