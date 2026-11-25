import 'package:flutter/material.dart';

import '../../domain/entity/shift.dart';
import '../../domain/repository/shift_repository.dart';
import '../../data/repository/shift_repository_impl.dart';

class ShiftProvider with ChangeNotifier {
  final ShiftRepository _repository;

  ShiftProvider({ShiftRepository? repository})
    : _repository = repository ?? ShiftRepositoryImpl() {
    fetchShifts();
  }

  List<Shift> _shifts = [];
  List<Shift> _filteredShifts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  List<Shift> get shifts => _shifts;
  List<Shift> get filteredShifts => _filteredShifts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;

  int get totalCount => _shifts.length;
  int get activeCount => _shifts.where((s) => s.isActive).length;
  int get inactiveCount => _shifts.where((s) => !s.isActive).length;
  int get overnightCount => _shifts.where((s) => s.isCrossDayOvernight).length;

  Future<void> fetchShifts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getShifts();
    result.fold(
      (failure) {
        _errorMessage = failure.errorMessage;
        _isLoading = false;
        notifyListeners();
      },
      (data) {
        _shifts = data;
        _applyFilters();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setSelectedFilter(String filter) {
    _selectedFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredShifts = _shifts.where((s) {
      // 1. Search Query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        if (!s.name.toLowerCase().contains(q) &&
            !s.startTime.contains(q) &&
            !s.endTime.contains(q)) {
          return false;
        }
      }

      // 2. Chip Filter
      if (_selectedFilter == 'Semua') {
        return true;
      } else if (_selectedFilter.startsWith('Aktif')) {
        return s.isActive;
      } else if (_selectedFilter.startsWith('Nonaktif')) {
        return !s.isActive;
      } else if (_selectedFilter.startsWith('Overnight') ||
          _selectedFilter.startsWith('Lintas')) {
        return s.isCrossDayOvernight;
      }
      return true;
    }).toList();
  }

  Future<bool> createShift(Map<String, dynamic> payload) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.createShift(payload);
    _isLoading = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.errorMessage;
        notifyListeners();
        return false;
      },
      (newShift) {
        _shifts.insert(0, newShift);
        _applyFilters();
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> updateShift(String id, Map<String, dynamic> payload) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.updateShift(id, payload);
    _isLoading = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.errorMessage;
        notifyListeners();
        return false;
      },
      (updatedShift) {
        final idx = _shifts.indexWhere((s) => s.id == id);
        if (idx != -1) {
          _shifts[idx] = updatedShift;
          _applyFilters();
        }
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> toggleShiftStatus(String id, bool isActive) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.toggleShiftStatus(id, isActive);
    _isLoading = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.errorMessage;
        notifyListeners();
        return false;
      },
      (updatedShift) {
        final idx = _shifts.indexWhere((s) => s.id == id);
        if (idx != -1) {
          _shifts[idx] = updatedShift;
          _applyFilters();
        }
        notifyListeners();
        return true;
      },
    );
  }
}
