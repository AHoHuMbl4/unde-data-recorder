// lib/screens/team_login_screen.dart
import 'package:flutter/material.dart';
import '../services/server_service.dart';
import '../config/users.dart';
import 'home_screen.dart';
import 'admin_users_screen.dart';

class TeamLoginScreen extends StatefulWidget {
  @override
  _TeamLoginScreenState createState() => _TeamLoginScreenState();
}

class _TeamLoginScreenState extends State<TeamLoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
  }

  Future<void> _checkExistingLogin() async {
    final serverService = ServerService();
    await serverService.initialize();
    await serverService.loadCurrentUser();
    
    if (serverService.isLoggedIn) {
      // Пользователь уже авторизован
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  Future<void> _login() async {
    if (_loginController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Заполните все поля';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final serverService = ServerService();
      final success = await serverService.loginUser(
        _loginController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success) {
        // Успешная авторизация
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Неверный логин или пароль';
        });
      }
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showUsersList() async {
    final users = await UserConfig.getAllUsers();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('👥 Доступные пользователи'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Для тестирования:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              ...users.map((user) {
                final isAdmin = user['role'] == 'admin';
                return Card(
                  color: isAdmin ? Colors.red[50] : null,
                  child: ListTile(
                    title: Text(
                      user['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isAdmin ? Colors.red[700] : null,
                      ),
                    ),
                    subtitle: Text('${user['login']} (${_getRoleDisplayName(user['role'])})')
                    leading: CircleAvatar(
                      child: Icon(
                        isAdmin ? Icons.admin_panel_settings :
                        user['role'] == 'coordinator' ? Icons.supervisor_account : Icons.person,
                        color: Colors.white,
                      ),
                      backgroundColor: isAdmin ? Colors.red :
                                     user['role'] == 'coordinator' ? Colors.orange : Colors.blue,
                    ),
                    onTap: () {
                      _loginController.text = user['login'];
                      // Убираем автозаполнение пароля для безопасности
                      Navigator.of(context).pop();
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showAdminPasswordDialog() {
    final adminPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🔐 Вход администратора'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Введите пароль администратора:'),
            SizedBox(height: 16),
            TextField(
              controller: adminPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Пароль админа',
                hintText: 'admin2025',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (adminPasswordController.text == 'admin2025') {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => AdminUsersScreen()),
                );
              } else {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Неверный пароль администратора'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Войти'),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Вход в систему UNDE'),
        backgroundColor: Colors.blue[400],
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: _showUsersList,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.account_circle,
              size: 80,
              color: Colors.blue[400],
            ),
            SizedBox(height: 32),
            
            Text(
              'Система сбора данных для indoor positioning',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Войдите под своей учетной записью',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                textAlign: TextAlign.center,
              ),
            ),
            
            SizedBox(height: 40),
            
            TextField(
              controller: _loginController,
              decoration: InputDecoration(
                labelText: 'Логин',
                hintText: 'alex, maria, ivan, elena, test, admin',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            
            SizedBox(height: 16),
            
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Пароль',
                hintText: '1234, 0000 или admin2025',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            
            if (_errorMessage != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            
            SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[400],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Войти',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            
            SizedBox(height: 16),
            
            TextButton.icon(
              onPressed: _showUsersList,
              icon: Icon(Icons.list),
              label: Text('Показать доступных пользователей'),
            ),
            
            SizedBox(height: 8),
            
            TextButton.icon(
              onPressed: () async {
                // Проверяем права админа
                final serverService = ServerService();
                await serverService.initialize();
                await serverService.loadCurrentUser();
                
                if (serverService.currentUserRole == 'admin') {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => AdminUsersScreen()),
                  );
                } else {
                  // Запрашиваем пароль админа
                  _showAdminPasswordDialog();
                }
              },
              icon: Icon(Icons.admin_panel_settings, color: Colors.orange),
              label: Text(
                'Управление пользователями (админ)', 
                style: TextStyle(color: Colors.orange)
              ),
            ),
            
            SizedBox(height: 8),
            
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              },
              child: Text('Пропустить авторизацию'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
