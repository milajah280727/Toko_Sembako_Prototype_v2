import 'package:flutter/material.dart';
import 'package:tokosembakolatihan/admin/batch_produk.dart';
import 'package:tokosembakolatihan/admin/product/daftar_produk.dart';
import 'package:tokosembakolatihan/admin/dashboard.dart';
import 'package:tokosembakolatihan/admin/manajemen_user.dart';
import 'package:tokosembakolatihan/main.dart';


class KategoriProduk extends StatelessWidget {
  const KategoriProduk({super.key});

  final Color _primaryBlue = const Color.fromARGB(255, 95, 133, 218);
  final Color _dangerRed = const Color.fromARGB(255, 245, 36, 36);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 241, 241, 241),
      appBar: AppBar(
        title: Text('Kategori Produk',style: const TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.w800),),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      // Ini adalah Sidebar (Drawer)
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 95, 133, 218),
              ),
              accountName: Text('ADMIN'),
              accountEmail: Text('admin@example.com'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blue),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Beranda Admin'),
              onTap: () {Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => AdminDashboardPage()),
                (route) => false,
              );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Daftar Produk'),
              onTap: () {Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => DaftarProduk()),
                (route) => false,
              );
              }, 
            ),
            ListTile(
              leading: const Icon(Icons.batch_prediction_outlined),
              title: const Text('Batch Produk'),
              onTap: () {Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => BatchProduk()),
                (route) => false,
              );
              },
            ),

            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Kategori Produk'),
              selected: true,
              selectedColor: const Color.fromARGB(255, 95, 133, 218),
              onTap: () {Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => KategoriProduk()),
                (route) => false,
              );
              }
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Manajemen User'),
              onTap: () {Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => ManajemenUser()),
                (route) => false,
              );
              },
            ),
            const Spacer(), // Dorong tombol logout ke bawah
            const Divider(),
            SizedBox(
              width: 280,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        title: const Text('Peringatan', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                        content: const Text('Apakah Anda yakin ingin logout?', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins')),
                        actions: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                  child: const Text('Batal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MyApp()), (route) => false);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: _dangerRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                  child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          )
                        ],
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: _dangerRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
                child: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
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
              'Selamat Datang di Halaman ',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Anda login sebagai hak akses: '),
          ],
        ),
      ),
    );
  }
}