import 'package:flutter/material.dart';
import 'package:tokosembakolatihan/admin/batch_produk.dart';
import 'package:tokosembakolatihan/admin/kategori_produk.dart';
import 'package:tokosembakolatihan/admin/manajemen_user.dart';
import 'package:tokosembakolatihan/main.dart';
import 'package:tokosembakolatihan/admin/daftar_produk.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 241, 241, 241),
      appBar: AppBar(
        title: Text(
          'Beranda',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
          ),
        ),
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
              selected: true,
              selectedColor: const Color.fromARGB(255, 95, 133, 218),
              onTap: () => Navigator.pop(context),
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

                  //tampilkan dialog konfirmasi logout
                  showDialog(context: context, builder:(BuildContext context){
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      title: const Text('Konfirmasi Logout',style: TextStyle(fontFamily: 'Poppins'),),
                      content: const Text('Apakah Anda yakin ingin logout?',style: TextStyle(fontFamily: 'Poppins'),),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal',style: TextStyle(fontFamily: 'Poppins'),)),
                      TextButton(onPressed: (){
                        Navigator.pop(context); // Tutup dialog
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const MyApp()),
                          (route) => false,);
                      }, child: const Text('Ya',style: TextStyle(fontFamily: 'Poppins'),),)],
                    );
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 245, 36, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: const Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
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
              'Selamat Datang di Halaman ADMIN',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Anda login sebagai hak akses: ADMIN'),
          ],
        ),
      ),
    );
  }
}
