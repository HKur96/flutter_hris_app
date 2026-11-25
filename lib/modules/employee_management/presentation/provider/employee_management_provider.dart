import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/config/extension.dart';
import 'package:flutter_hris_app/core/config/global.dart';

import '../../domain/entity/employee_profile.dart';
import '../../domain/repository/employee_management_repository.dart';
import '../../data/repository/employee_management_repository_impl.dart';

class EmployeeManagementProvider with ChangeNotifier {
  final EmployeeManagementRepository _repository;

  EmployeeManagementProvider({EmployeeManagementRepository? repository})
    : _repository = repository ?? EmployeeManagementRepositoryImpl() {
    fetchEmployees();
  }

  List<EmployeeProfile> _employees = [];
  List<EmployeeProfile> _filteredEmployees = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  List<EmployeeProfile> get employees => _employees;
  List<EmployeeProfile> get filteredEmployees => _filteredEmployees;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;

  int get totalCount => _employees.length;
  int get activeCount => _employees.where((e) => e.isActive).length;
  int get inactiveCount => _employees.where((e) => !e.isActive).length;

  Future<void> fetchEmployees() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getEmployees();
    result.fold(
      (failure) {
        _errorMessage = failure.errorMessage;
        _isLoading = false;
        notifyListeners();
      },
      (data) {
        _employees = data;
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
    _filteredEmployees = _employees.where((emp) {
      // 1. Search filter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final match =
            emp.name.toLowerCase().contains(q) ||
            emp.nik.toLowerCase().contains(q) ||
            emp.email.toLowerCase().contains(q) ||
            emp.position.toLowerCase().contains(q);
        if (!match) return false;
      }

      // 2. Chip filter
      if (_selectedFilter == 'Semua') {
        return true;
      } else if (_selectedFilter.startsWith('Aktif')) {
        return emp.isActive;
      } else if (_selectedFilter.startsWith('Nonaktif')) {
        return !emp.isActive;
      } else {
        // Filter departemen tertentu (contoh: 'Engineering', 'Operasional')
        return emp.department.toLowerCase().contains(
          _selectedFilter.toLowerCase(),
        );
      }
    }).toList();
  }

  Future<bool> createEmployee(Map<String, dynamic> payload) async {
    _isLoading = true;
    notifyListeners();

    final result = await _repository.createEmployee(payload);

    return result.fold(
      (failure) {
        _errorMessage = failure.errorMessage;
        _isLoading = false;
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (newEmp) {
        if (newEmp == null) return false;

        _employees.insert(0, newEmp);
        _applyFilters();
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> updateEmployee(String id, Map<String, dynamic> payload) async {
    _isLoading = true;
    notifyListeners();

    final result = await _repository.updateEmployee(id, payload);

    return result.fold(
      (failure) {
        _errorMessage = failure.errorMessage;
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (updatedEmp) {
        if (updatedEmp == null) return false;

        final idx = _employees.indexWhere((e) => e.id == id);
        if (idx != -1) {
          _employees[idx] = updatedEmp;
          _applyFilters();
        }
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> deleteEmployee(String id) => softDeleteEmployee(id);

  Future<bool> softDeleteEmployee(String id) async {
    var completer = Completer();
    gNavigatorKey.currentContext?.showLoadingDialog(
      dismissCompleter: completer,
      text: 'Sedang menonaktifkan karyawan',
    );
    try {
      final result = await _repository.softDeleteEmployee(id);

      return await result.fold(
        (failure) {
          if (!completer.isCompleted) {
            completer.complete();
          }
          return false;
        },
        (_) {
          final idx = _employees.indexWhere((e) => e.id == id);
          if (idx != -1) {
            _employees[idx] = _employees[idx].copyWith(
              employmentStatus: 'INACTIVE',
              deletedAt: DateTime.now(),
            );
            _applyFilters();
          }
          if (!completer.isCompleted) {
            completer.complete();
          }
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      if (!completer.isCompleted) completer.complete();
      return false;
    }
  }
}
