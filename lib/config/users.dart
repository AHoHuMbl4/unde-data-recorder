// lib/config/users.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserConfig {
  // Системный администратор (нельзя удалить)
  static const Map<String, dynamic> adminUser = {
    'id': 0,
    'login': 'admin',
    'password': 'admin2025',
    'name': 'Системный администратор',
    'role': 'admin',
    'team_id': 1,
    'is_system': true,
  };

  // Пользователи по умолчанию
  static const List<Map<String, dynamic>> defaultUsers = [
    {
      'id': 1,
      'login': 'alex',
      'password': '1234',
      'name': 'Алексей Иванов',
      'role': 'coordinator',
      'team_id': 1,
      'is_system': false,
    },
    {
      'id': 2,
      'login': 'maria',
      'password': '1234',
      'name': 'Мария Петрова',
      'role': 'collector',
      'team_id': 1,
      'is_system': false,
    },
    {
      'id': 3,
      'login': 'ivan',
      'password': '1234',
      'name': 'Иван Смирнов',
      'role': 'collector',
      'team_id': 1,
      'is_system': false,
    },
    {
      'id': 4,
      'login': 'elena',
      'password': '1234',
      'name': 'Елена Волкова',
      'role': 'collector',
      'team_id': 1,
      'is_system': false,
    },
    {
      'id': 5,
      'login': 'test',
      'password': '0000',
      'name': 'Тестовый пользователь',
      'role': 'collector',
      'team_id': 1,
      'is_system': false,
    },
  ];

  // Получение всех пользователей (админ + кастомные + дефолтные)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final customUsers = await getCustomUsers();
    final allUsers = <Map<String, dynamic>>[];
    
    // Добавляем админа первым
    allUsers.add(adminUser);
    
    // Добавляем кастомных пользователей
    allUsers.addAll(customUsers);
    
    // Добавляем дефолтных пользователей (если их нет среди кастомных)
    for (final defaultUser in defaultUsers) {
      if (!customUsers.any((u) => u['login'] == defaultUser['login'])) {
        allUsers.add(defaultUser);
      }
    }
    
    return allUsers;
  }

  // Поиск пользователя по логину/паролю
  static Future<Map<String, dynamic>?> findUser(String login, String password) async {
    final users = await getAllUsers();
    try {
      return users.firstWhere(
        (user) => user['login'] == login && user['password'] == password,
      );
    } catch (e) {
      return null;
    }
  }

  // Поиск пользователя по ID
  static Future<Map<String, dynamic>?> getUserById(int id) async {
    final users = await getAllUsers();
    try {
      return users.firstWhere((user) => user['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // Получение кастомных пользователей из локального хранилища
  static Future<List<Map<String, dynamic>>> getCustomUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('custom_users');
    
    if (usersJson != null) {
      final List<dynamic> usersList = jsonDecode(usersJson);
      return usersList.cast<Map<String, dynamic>>();
    }
    
    return [];
  }

  // Сохранение кастомных пользователей
  static Future<void> saveCustomUsers(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_users', jsonEncode(users));
  }

  // Добавление нового пользователя (только для админа)
  static Future<bool> addUser({
    required String login,
    required String password,
    required String name,
    required String role,
    int teamId = 1,
  }) async {
    // Проверяем, что логин уникален
    final existingUsers = await getAllUsers();
    if (existingUsers.any((user) => user['login'] == login)) {
      return false; // Логин уже существует
    }

    final customUsers = await getCustomUsers();
    final newId = existingUsers.map((u) => u['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
    
    final newUser = {
      'id': newId,
      'login': login,
      'password': password,
      'name': name,
      'role': role,
      'team_id': teamId,
      'is_system': false,
    };

    customUsers.add(newUser);
    await saveCustomUsers(customUsers);
    return true;
  }

  // Редактирование пользователя (только для админа)
  static Future<bool> updateUser(int id, {
    String? login,
    String? password,
    String? name,
    String? role,
    int? teamId,
  }) async {
    if (id == 0) return false; // Нельзя редактировать админа

    final customUsers = await getCustomUsers();
    final userIndex = customUsers.indexWhere((user) => user['id'] == id);
    
    if (userIndex != -1) {
      if (login != null) customUsers[userIndex]['login'] = login;
      if (password != null) customUsers[userIndex]['password'] = password;
      if (name != null) customUsers[userIndex]['name'] = name;
      if (role != null) customUsers[userIndex]['role'] = role;
      if (teamId != null) customUsers[userIndex]['team_id'] = teamId;
      
      await saveCustomUsers(customUsers);
      return true;
    }
    
    return false;
  }

  // Удаление пользователя (только для админа)
  static Future<bool> deleteUser(int id) async {
    if (id == 0) return false; // Нельзя удалить админа

    final customUsers = await getCustomUsers();
    final originalLength = customUsers.length;
    
    customUsers.removeWhere((user) => user['id'] == id);
    
    if (customUsers.length < originalLength) {
      await saveCustomUsers(customUsers);
      return true;
    }
    
    return false;
  }

  // Сброс к дефолтным пользователям (только для админа)
  static Future<void> resetToDefaults() async {
    await saveCustomUsers([]);
  }
}
