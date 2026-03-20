// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:tokosembakolatihan/admin/batch_produk.dart';
import 'package:tokosembakolatihan/admin/dashboard.dart';
import 'package:tokosembakolatihan/admin/kategori_produk.dart';
import 'package:tokosembakolatihan/admin/manajemen_user.dart';
import 'package:tokosembakolatihan/main.dart';

class DaftarProduk extends StatefulWidget {
  const DaftarProduk({super.key});

  @override
  State<DaftarProduk> createState() => _DaftarProdukState();
}

class _DaftarProdukState extends State<DaftarProduk> {
  //variabel untuk menampung input pencarian
  final TextEditingController _searchController = TextEditingController();

  //data dummy produk
  final List<Map<String, dynamic>> _dummyProducts = [
    {
      'nama': 'Beras Premium',
      'kategori': 'Sembako',
      'harga': 50000,
      'stok': 100,
    },
    {
      'nama': 'Minyak Goreng',
      'kategori': 'Sembako',
      'harga': 15000,
      'stok': 50,
    },
    {'nama': 'Gula Pasir', 'kategori': 'Sembako', 'harga': 20000, 'stok': 75},
    {
      'nama': 'Tepung Terigu',
      'kategori': 'Sembako',
      'harga': 12000,
      'stok': 80,
    },
    {'nama': 'Kopi Bubuk', 'kategori': 'Minuman', 'harga': 30000, 'stok': 40},
    {'nama': 'Kopi Bubuk', 'kategori': 'Minuman', 'harga': 30000, 'stok': 40},
    {'nama': 'Kopi Bubuk', 'kategori': 'Minuman', 'harga': 30000, 'stok': 40},
    {'nama': 'Kopi Bubuk', 'kategori': 'Minuman', 'harga': 30000, 'stok': 40},
    {'nama': 'Kopi Bubuk', 'kategori': 'Minuman', 'harga': 30000, 'stok': 40},
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 241, 241, 241),
      appBar: AppBar(
        title: Text(
          'Daftar Produk',
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
              accountEmail: Text('role@example.com'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blue),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Beranda Admin'),
              onTap: () {
                Navigator.pop(context);
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
              selected: true,
              selectedColor: const Color.fromARGB(255, 95, 133, 218),
              onTap: () {
                Navigator.pop(
                  context,
                ); // Tutup draweravigasi ke halaman Daftar Produk
              },
            ),
            ListTile(
              leading: const Icon(Icons.batch_prediction_outlined),
              title: const Text('Batch Produk'),
              onTap: () {
                Navigator.pop(context);
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
              onTap: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => KategoriProduk()),
                  (route) => false,
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Manajemen User'),
              onTap: () {
                Navigator.pop(context);
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
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        title: const Text(
                          'Konfirmasi Logout',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                        content: const Text(
                          'Apakah Anda yakin ingin logout?',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Batal',
                              style: TextStyle(fontFamily: 'Poppins'),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Tutup dialog
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyApp(),
                                ),
                                (route) => false,
                              );
                            },
                            child: const Text(
                              'Ya',
                              style: TextStyle(fontFamily: 'Poppins'),
                            ),
                          ),
                        ],
                      );
                    },
                  );
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
      ), //ini drWER Yakkk
      //bodynya disini
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            //box search bar
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              //text field untuk search bar
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  prefixIcon: const Icon(Icons.search_outlined),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: (value) {
                  setState(() {
                    // logika searchnya disini nanti janagan lupa cok
                  });
                },
              ),
            ),
          ),
          //sekarang kita buat card buat list produk
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _dummyProducts.length,
              itemBuilder: (context, index) {
                final product = _dummyProducts[index];
                return _buildProductCard(product);
              },
            ),
          ),
          
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //logika tambah produk disini
          print('Tambah produk baru');
        },
        backgroundColor: const Color.fromARGB(255, 95, 133, 218),
        child: const Icon(Icons.add, color: Colors.white,),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image, size: 40, color: Colors.grey),
          ),
          const SizedBox(width: 20),

          //detail produk(masih pake dummy data, nanti tinggal ganti aja dengan data asli dari database)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['nama'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kategori: ${product['kategori']}',
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  'Harga: Rp ${product['harga']}',
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stok: ${product['stok']}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          //tombol edit dan hapus
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            onSelected: (String choice) {
              if (choice == 'edit') {
                //logika edit produk disini
                print('Edit produk: ${product['nama']}');
              } else if (choice == 'delete') {
                //logika hapus produk disini
                print('Hapus produk: ${product['nama']}');
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}
