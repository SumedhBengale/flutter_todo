// Copyright (c) 2022, Very Good Ventures
// https://verygood.ventures
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todos_api/todos_api.dart';

/// {@template local_storage_todos_api}
/// A Flutter implementation of the TodosApi that uses local storage.
/// {@endtemplate}
class LocalStorageTodosApi extends TodosApi {
  /// {@macro local_storage_todos_api}
  LocalStorageTodosApi({
    required SharedPreferences plugin,
  }) : _plugin = plugin {
    _init();
  }
  final SharedPreferences _plugin;
  final _todoStreamController = BehaviorSubject<List<Todo>>.seeded(const []);

  ///Only avaliable in Testing, the user should not be able to access this.
  @visibleForTesting
  static const kTodosCollectionKey = '__todos_collection_key';

  String? _getValue(String key) => _plugin.getString(key);

  Future<void> _setValue(String key, String value) =>
      _plugin.setString(key, value);

  void _init() {
    final todosJson = _getValue(kTodosCollectionKey);
    if (todosJson != null) {
      final todos = List<Map<dynamic, dynamic>>.from(
        json.decode(todosJson) as List,
      )
          .map((jsonMap) => Todo.fromJson(Map<String, dynamic>.from(jsonMap)))
          .toList();
      _todoStreamController.add(todos);
    } else {
      _todoStreamController.add(const []);
    }
  }

  @override
  Future<int> clearCompleted() async {
    final todos = [..._todoStreamController.value];
    final completedTodosAmount =
        todos.where((element) => element.isCompleted).length;
    todos.removeWhere((element) => element.isCompleted);
    _todoStreamController.add(todos);
    await _setValue(kTodosCollectionKey, json.encode(todos));
    return completedTodosAmount;
  }

  @override
  Future<int> completeAll({required bool isCompleted}) async {
    final todos = [..._todoStreamController.value];
    final changedTodosAmount = todos
        .where(
          (element) => element.isCompleted != isCompleted,
        )
        .length;
    final newTodos = [
      for (final todo in todos)
        todo.copyWith(
          isCompleted: isCompleted,
        )
    ];
    _todoStreamController.add(newTodos);
    await _setValue(kTodosCollectionKey, json.encode(newTodos));
    return changedTodosAmount;
  }

  @override
  Future<void> deleteTodo(String id) {
    final todos = [..._todoStreamController.value];
    final todoIndex = todos.indexWhere((element) => element.id == id);
    if (todoIndex == -1) {
      throw TodoNotFoundException();
    } else {
      todos.removeAt(todoIndex);
      _todoStreamController.add(todos);
      return _setValue(kTodosCollectionKey, json.encode(todos));
    }
  }

  @override
  Stream<List<Todo>> getTodos() => _todoStreamController.asBroadcastStream();

  @override
  Future<void> saveTodo(Todo todo) {
    final todos = [..._todoStreamController.value];
    final todoIndex = todos.indexWhere((element) => element.id == todo.id);
    if (todoIndex >= 0) {
      todos[todoIndex] = todo;
    } else {
      todos.add(todo);
    }
    _todoStreamController.add(todos);
    return _setValue(kTodosCollectionKey, json.encode(todos));
  }
}
