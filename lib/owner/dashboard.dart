import 'package:flutter/material.dart';
import 'package:tokosembakolatihan/main.dart';

class OwnerDashboardPage extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard OWNER'),
        backgroundColor: const Color.fromARGB(255, 95, 133, 218),
      ),
      // Ini adalah Sidebar (Drawer)
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 95, 133, 218),
              ),
              accountName: Text('OWNER'),
              accountEmail: Text('owner@example.com'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blue),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Beranda Owner'),
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(), // Dorong tombol logout ke bawah
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                // Kembali ke halaman login dan hapus semua history page
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MyApp()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Selamat Datang di Halaman OWNER',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Anda login sebagai hak akses: OWNER'),
          ],
        ),
      ),
    );
  }
}