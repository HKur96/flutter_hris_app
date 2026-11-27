import 'package:flutter/material.dart';

class BaseProvider<T> with ChangeNotifier {
  final T repository;

  BaseProvider({required this.repository});
}
