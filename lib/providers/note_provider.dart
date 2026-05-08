import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/note.dart';

class NoteProvider with ChangeNotifier {
  List<Note> _notes = [];
  bool _loading = false;
  String? _error;

  List<Note> get notes => _notes;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchNotes() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.get('notes');
      debugPrint('Notes API Result: $result');
      if (result['success']) {
        _notes = (result['data'] as List)
            .map((json) => Note.fromJson(json))
            .toList();
        debugPrint('Parsed ${_notes.length} notes');
      } else {
        _error = result['message'] ?? 'فشل تحميل الملاحظات';
        debugPrint('Notes API Error: $_error');
      }
    } catch (e) {
      _error = 'حدث خطأ غير متوقع';
      debugPrint('Notes Provider Exception: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> postNote(String content) async {
    try {
      final result = await ApiService.post('notes', {'content': content});
      if (result['success']) {
        await fetchNotes();
        return true;
      }
    } catch (e) {
      debugPrint('Error posting note: $e');
    }
    return false;
  }

  Future<bool> deleteNote() async {
    try {
      final result = await ApiService.delete('notes');
      if (result['success']) {
        await fetchNotes();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting note: $e');
    }
    return false;
  }
}
