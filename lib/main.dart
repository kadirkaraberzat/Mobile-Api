import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Alışveriş Takip',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
    );
  }
}

// 📌 Ortak API Çağrı Fonksiyonu
Future<http.Response> makePostRequest(String url, Map<String, dynamic> body) {
  return http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );
}

// 📌 Giriş Ekranı
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> loginUser() async {
    setState(() => isLoading = true);
    final response = await makePostRequest('http://10.0.2.2:5000/login', {
      'email': emailController.text,
      'password': passwordController.text,
    });
    setState(() => isLoading = false);

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(userId: data['userId'])),
      );
    } else {
      showError(data['error'] ?? 'Giriş başarısız!');
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Giriş Yap')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, obscureText: true, decoration: InputDecoration(labelText: 'Şifre')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : loginUser,
              child: isLoading ? CircularProgressIndicator() : Text('Giriş Yap'),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen())),
              child: Text('Hesabınız yok mu? Kayıt olun!'),
            ),
          ],
        ),
      ),
    );
  }
}

// 📌 Kayıt Ekranı
class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> registerUser() async {
    setState(() => isLoading = true);
    final response = await makePostRequest('http://10.0.2.2:5000/register', {
      'name': nameController.text,
      'surname': surnameController.text,
      'email': emailController.text,
      'phone': phoneController.text,
      'address': addressController.text,
      'password': passwordController.text,
    });
    setState(() => isLoading = false);

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Kayıt başarılı! Giriş yapılıyor...')));
      loginUserAfterRegister();
    } else {
      showError(data['error'] ?? 'Kayıt başarısız!');
    }
  }

  Future<void> loginUserAfterRegister() async {
    final response = await makePostRequest('http://10.0.2.2:5000/login', {
      'email': emailController.text,
      'password': passwordController.text,
    });
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(userId: data['userId'])),
      );
    } else {
      showError(data['error'] ?? 'Otomatik giriş başarısız!');
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kayıt Ol')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Ad')),
            TextField(controller: surnameController, decoration: InputDecoration(labelText: 'Soyad')),
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: 'Telefon')),
            TextField(controller: addressController, decoration: InputDecoration(labelText: 'Adres')),
            TextField(controller: passwordController, obscureText: true, decoration: InputDecoration(labelText: 'Şifre')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : registerUser,
              child: isLoading ? CircularProgressIndicator() : Text('Kayıt Ol'),
            ),
          ],
        ),
      ),
    );
  }
}

// 📌 Ana Sayfa (Alışveriş Geçmişi)
class HomeScreen extends StatelessWidget {
  final int userId;
  HomeScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ana Sayfa')),
      body: Center(child: Text('Hoş geldiniz! Kullanıcı ID: $userId')),
    );
  }
}
