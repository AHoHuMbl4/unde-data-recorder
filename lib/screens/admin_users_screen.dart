// lib/screens/admin_users_screen.dart
import 'package:flutter/material.dart';
import '../config/users.dart';

class AdminUsersScreen extends StatefulWidget {
  @override
  _AdminUsersScreenState createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    final users = await UserConfig.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  void _showAddUserDialog() {
    final loginController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    String selectedRole = 'collector';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('➕ Добавить пользователя'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: loginController,
                  decoration: InputDecoration(
                    labelText: 'Логин',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Полное имя',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Роль',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'coordinator', child: Text('Координатор')),
                    DropdownMenuItem(value: 'collector', child: Text('Сборщик данных')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (loginController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty &&
                    nameController.text.isNotEmpty) {
                  
                  final success = await UserConfig.addUser(
                    login: loginController.text.trim(),
                    password: passwordController.text.trim(),
                    name: nameController.text.trim(),
                    role: selectedRole,
                  );

                  Navigator.of(context).pop();

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Пользователь добавлен'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadUsers();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Логин уже существует'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final loginController = TextEditingController(text: user['login']);
    final passwordController = TextEditingController(text: user['password']);
    final nameController = TextEditingController(text: user['name']);
    String selectedRole = user['role'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('✏️ Редактировать пользователя'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: loginController,
                  decoration: InputDecoration(
                    labelText: 'Логин',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !user['is_system'], // Системных пользователей нельзя редактировать
                ),
                SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Полное имя',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Роль',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'coordinator', child: Text('Координатор')),
                    DropdownMenuItem(value: 'collector', child: Text('Сборщик данных')),
                    if (user['role'] == 'admin') DropdownMenuItem(value: 'admin', child: Text('Администратор')),
                  ],
                  onChanged: user['role'] == 'admin' ? null : (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                ),
                if (user['is_system']) ...[
                  SizedBox(height: 8),
                  Text(
                    '⚠️ Системный пользователь - ограниченное редактирование',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await UserConfig.updateUser(
                  user['id'],
                  login: user['is_system'] ? null : loginController.text.trim(),
                  password: passwordController.text.trim(),
                  name: nameController.text.trim(),
                  role: user['role'] == 'admin' ? null : selectedRole,
                );

                Navigator.of(context).pop();

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Пользователь обновлен'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadUsers();
                }
              },
              child: Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🗑️ Удалить пользователя'),
        content: Text('Удалить пользователя "${user['name']}"?\n\nЭто действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final success = await UserConfig.deleteUser(user['id']);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Пользователь удален'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadUsers();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('👥 Управление пользователями'),
        backgroundColor: Colors.orange[400],
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddUserDialog,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final isAdmin = user['role'] == 'admin';
                  final isSystem = user['is_system'] == true;

                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isAdmin
                            ? Colors.red
                            : user['role'] == 'coordinator'
                                ? Colors.orange
                                : Colors.blue,
                        child: Icon(
                          isAdmin
                              ? Icons.admin_panel_settings
                              : user['role'] == 'coordinator'
                                  ? Icons.supervisor_account
                                  : Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        user['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isAdmin ? Colors.red[700] : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Логин: ${user['login']}'),
                          Text('Роль: ${_getRoleDisplayName(user['role'])}'),
                          if (isSystem)
                            Text(
                              'Системный пользователь',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      trailing: isAdmin
                          ? Icon(Icons.lock, color: Colors.red)
                          : PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 16),
                                      SizedBox(width: 8),
                                      Text('Редактировать'),
                                    ],
                                  ),
                                ),
                                if (!isSystem)
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 16, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Удалить', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditUserDialog(user);
                                } else if (value == 'delete') {
                                  _deleteUser(user);
                                }
                              },
                            ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.orange[400],
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Администратор';
      case 'coordinator':
        return 'Координатор';
      case 'collector':
        return 'Сборщик данных';
      default:
        return role;
    }
  }
}
