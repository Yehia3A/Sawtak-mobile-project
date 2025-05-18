import 'package:flutter/material.dart';
import '../models/post.dart';

class AnnouncementProvider extends ChangeNotifier {
  final List<Attachment> _attachments = [];
  DateTime? _selectedDate;
  String _location = '';
  bool _isLoading = false;

  List<Attachment> get attachments => _attachments;
  DateTime? get selectedDate => _selectedDate;
  String get location => _location;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setDate(DateTime? date) {
    _selectedDate = date;
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

  void removeAttachment(String id) {
    _attachments.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void clear() {
    _attachments.clear();
    _selectedDate = null;
    _location = '';
    _isLoading = false;
    notifyListeners();
  }
}
