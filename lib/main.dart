// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:tokosembakolatihan/admin/dashboard.dart' as admin;
import 'package:tokosembakolatihan/kasir/dashboard.dart' as kasir;
import 'package:tokosembakolatihan/owner/dashboard.dart' as owner;
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zwlczviupdfmiepwnqgo.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3bGN6dml1cGRmbWllcHducWdvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwOTM4NTMsImV4cCI6MjA4NTY2OTg1M30.1gh1O7XRsilVIIBibukEaIuSUXfuQOdbYEZP2BZJhWw',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'login app',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true;

  void _Login() async{
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

  // Validasi input apakah kosong atau tidak
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username dan Password tidak boleh kosong'),
        ),
      );
      return;
    }

// Validasi login dengan data yang sudah ditentukan
    try{
      final response = await Supabase.instance.client
      .from('users')
      .select()
      .eq('username', username)
      .maybeSingle();

      if(response == null){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username tidak ditemukan'),
          ),
        );
        return;
      }
      if(response['password'] != password){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password salah'),
          ),
        );
        return;
      }
      if(response['is_active'] == false){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun tidak aktif'),
          ),
        );
        return;
      }
      String role = response['role'];
      _navigateToDashboard(role);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
        ),
      );
    }
  }

  void _navigateToDashboard(String role) {
    Widget targetPage;
    if (role == 'admin') {
      targetPage = admin.AdminDashboardPage();
    } else if (role == 'kasir') {
      targetPage = kasir.KasirDashboardPage();
    } else if (role == 'owner') {
      targetPage = owner.OwnerDashboardPage();
    } else {
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: 400,
            child: CustomPaint(
              painter: WavePainter(
                color: const Color.fromARGB(255, 95, 133, 218),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 50),
                  const CircleAvatar(
                    radius: 50,

                    backgroundImage: AssetImage('assets/image/image.png'),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Selamat Datang!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: const Text(
                      'Silahkan masukan username dan password yang sesuai untuk login!',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Username",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: 380,
                    child: TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        hintText: "Masukkan username",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(9)),
                        ),
                        prefixIcon: Icon(Icons.person_outline),
                        contentPadding: EdgeInsets.only(
                          left: 11,
                          top: 8,
                          bottom: 8,
                          right: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Password",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: 380,
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _isObscure,
                      decoration: InputDecoration(
                        hintText: "Masukkan password",
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(9)),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscure = !_isObscure;
                            });
                          },
                        ),
                        contentPadding: const EdgeInsets.only(
                          left: 11,
                          top: 8,
                          bottom: 8,
                          right: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 380,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _Login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          95,
                          133,
                          218,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final Color color;
  WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = color;
    var path = Path();
    path.moveTo(0, size.height * 0.4);
    var firstControlPoint = Offset(size.width / 4, size.height * 0.55);
    var firstEndPoint = Offset(size.width / 2.25, size.height * 0.35);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    var secondControlPoint = Offset(
      size.width - (size.width / 3.25),
      size.height * 0.15,
    );
    var secondEndPoint = Offset(size.width, size.height * 0.4);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
