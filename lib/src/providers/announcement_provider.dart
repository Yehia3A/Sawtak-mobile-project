import 'package:flutter/material.dart';
import '../models/post.dart';

class AnnouncementProvider extends ChangeNotifier {
  final List<Attachment> _attachments = [];
  final List<Attachment> _pendingAttachments = [];
  String _location = '';
  bool _isLoading = false;

  List<Attachment> get attachments => [..._attachments, ..._pendingAttachments];
  String get location => _location;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setLocation(String location) {
    _location = location;
    notifyListeners();
  }

  void addAttachment(Attachment attachment) {
    _attachments.add(attachment);
    notifyListeners();
  }

  void addPendingAttachment(Attachment attachment) {
    _pendingAttachments.add(attachment);
    notifyListeners();
  }

  void updatePendingAttachmentProgress(String id, double progress) {
    final idx = _pendingAttachments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _pendingAttachments[idx] = _pendingAttachments[idx].copyWith(
        progress: progress,
      );
      notifyListeners();
    }
  }

  void removePendingAttachment(String id) {
    _pendingAttachments.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void removeAttachment(String id) {
    _attachments.removeWhere((a) => a.id == id);
    _pendingAttachments.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void clear() {
    _attachments.clear();
    _pendingAttachments.clear();
    _location = '';
    _isLoading = false;
    notifyListeners();
  }
}
