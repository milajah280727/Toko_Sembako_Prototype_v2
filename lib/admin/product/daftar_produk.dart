// ignore_for_file: deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:tokosembakolatihan/admin/batch_produk.dart';
import 'package:tokosembakolatihan/admin/dashboard.dart';
import 'package:tokosembakolatihan/admin/kategori_produk.dart';
import 'package:tokosembakolatihan/admin/manajemen_user.dart';
import 'package:tokosembakolatihan/main.dart';
import 'package:tokosembakolatihan/admin/product/daftar_produk_tambah.dart';
import 'package:tokosembakolatihan/admin/product/daftar_produk_edit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DaftarProduk extends StatefulWidget {
  const DaftarProduk({super.key});

  @override
  State<DaftarProduk> createState() => _DaftarProdukState();
}

class _DaftarProdukState extends State<DaftarProduk> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _produkList = [];
  List<Map<String, dynamic>> _filteredProdukList = [];
  bool _isLoading = true;

  // Warna Theme
  final Color _primaryBlue = const Color.fromARGB(255, 95, 133, 218);
  final Color _dangerRed = const Color.fromARGB(255, 245, 36, 36);

  @override
  void initState() {
    super.initState();
    _fetchProduk();
  }

  // --- LOGIKA FETCH ---
  Future<void> _fetchProduk() async {
    setState(() => _isLoading = true);

    try {
      final productsResponse = await Supabase.instance.client
          .from('produk')
          .select('*')
          .order('is_active', ascending: false)
          .order('nama_produk', ascending: true);

      final stocksResponse = await Supabase.instance.client
          .from('stok_batch')
          .select('id_produk, jumlah_stok');

      Map<int, int> stockMap = {};
      for (var batch in stocksResponse) {
        int productId = batch['id_produk'];
        int qty = batch['jumlah_stok'];
        if (stockMap.containsKey(productId)) {
          stockMap[productId] = stockMap[productId]! + qty;
        } else {
          stockMap[productId] = qty;
        }
      }

      List<Map<String, dynamic>> processedData = [];
      for (var item in productsResponse) {
        int productId = item['id_produk'];
        int totalStock = stockMap[productId] ?? 0;

        processedData.add({
          'id_produk': item['id_produk'],
          'nama': item['nama_produk'],
          'kategori': item['kategori'],
          'harga': item['harga_jual'],
          'barcode': item['barcode'],
          'gambar': item['gambar'],
          'is_active': item['is_active'],
          'stok': totalStock,
        });
      }

      setState(() {
        _produkList = processedData;
        _filteredProdukList = processedData;
        _isLoading = false;
      });

      if (_searchController.text.isNotEmpty) {
        _filterProduk(_searchController.text);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    }
  }

  void _filterProduk(String query) {
    List<Map<String, dynamic>> results = [];
    if (query.isEmpty) {
      results = _produkList;
    } else {
      results = _produkList.where((product) {
        final namaLower = product['nama'].toString().toLowerCase();
        final kategoriLower = product['kategori'].toString().toLowerCase();
        final inputLower = query.toLowerCase();
        return namaLower.contains(inputLower) || kategoriLower.contains(inputLower);
      }).toList();
    }
    setState(() => _filteredProdukList = results);
  }

  // --- LOGIKA CEK BATCH ---
  Future<bool> _hasStockBatch(int productId) async {
    try {
      final response = await Supabase.instance.client
          .from('stok_batch')
          .select('id_batch')
          .eq('id_produk', productId)
          .limit(1);
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // --- LOGIKA CEK TRANSAKSI ---
  Future<bool> _hasTransactionHistory(int productId) async {
    try {
      final response = await Supabase.instance.client
          .from('detail_transaksi')
          .select('id_transaksi')
          .eq('id_produk', productId)
          .limit(1);
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // --- LOGIKA DELETE DENGAN STYLE DIALOG BARU ---
  Future<void> _deleteProduct(int idProduk, String namaProduk) async {
    // 1. Cek Batch Stok
    final hasBatch = await _hasStockBatch(idProduk);

    if (hasBatch) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            'Peringatan',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.black),
          ),
          content: Text(
            'Tidak dapat menghapus produk "$namaProduk" karena masih memiliki data Batch Stok. Silakan hapus data batch terlebih dahulu.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Poppins', color: Colors.black54),
          ),
          actionsAlignment: MainAxisAlignment.center, // Pusatkan tombol
          actions: [
            // Hanya 1 tombol (Full Width)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Kembali', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Cek Riwayat Transaksi
    final hasHistory = await _hasTransactionHistory(idProduk);

    if (hasHistory) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            'Peringatan',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.black),
          ),
          content: Text(
            'Produk "$namaProduk" tercatat dalam riwayat transaksi. Pilih "Nonaktifkan" untuk menyembunyikannya tanpa menghapus laporan.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Poppins', color: Colors.black54),
          ),
          actions: [
            // Row untuk 2 tombol
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Batal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deactivateProduct(idProduk);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _dangerRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Nonaktifkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      return;
    }

    // 3. Konfirmasi Hapus Permanen (Style Sesuai Gambar)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Peringatan',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: Text(
          'Apakah anda yakin ingin menghapus produk "$namaProduk" ini?, produk yang sudah dihapus tidak akan bisa di kembalikan.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Poppins', color: Colors.black54),
        ),
        actions: [
          // Row untuk 2 tombol sama besar
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue, // Biru untuk Kembali
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Kembali', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10), // Spasi antar tombol
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _dangerRed, // Merah untuk Hapus
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('produk').delete().eq('id_produk', idProduk);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil dihapus'), backgroundColor: Colors.green),
        );
        _fetchProduk();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _deactivateProduct(int id) async {
    try {
      await Supabase.instance.client.from('produk').update({'is_active': false}).eq('id_produk', id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk dinonaktifkan')));
      _fetchProduk();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _reactivateProduct(int id, String namaProduk) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Konfirmasi',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.black),
        ),
        content: Text(
          "Aktifkan kembali produk \"$namaProduk\"?",
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Poppins', color: Colors.black54),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _dangerRed, // Merah untuk Batal
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Batal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue, // Biru untuk Aktifkan
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Aktifkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('produk').update({'is_active': true}).eq('id_produk', id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk aktif kembali')));
        _fetchProduk();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 241, 241, 241),
      appBar: AppBar(
        title: const Text(
          'Daftar Produk',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _fetchProduk,
          )
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: _primaryBlue),
              accountName: const Text('ADMIN'),
              accountEmail: const Text('role@example.com'),
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
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AdminDashboardPage()), (route) => false);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Daftar Produk'),
              selected: true,
              selectedColor: _primaryBlue,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.batch_prediction_outlined),
              title: const Text('Batch Produk'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const BatchProduk()), (route) => false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Kategori Produk'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const KategoriProduk()), (route) => false);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Manajemen User'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ManajemenUser()), (route) => false);
              },
            ),
            const Spacer(),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3))],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Cari produk...',
                  prefixIcon: Icon(Icons.search_outlined),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: (value) => _filterProduk(value),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProdukList.isEmpty
                    ? const Center(child: Text('Tidak ada produk ditemukan'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredProdukList.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(_filteredProdukList[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const DaftarProdukTambah())).then((value) {
            if (value == true) _fetchProduk();
          });
        },
        backgroundColor: _primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    bool isActive = product['is_active'] ?? true;
    bool isOutOfStock = (product['stok'] ?? 0) == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.red[50],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), spreadRadius: 1, blurRadius: 3)],
      ),
      child: InkWell(
        onTap: () {
          if (!isActive) _reactivateProduct(product['id_produk'], product['nama']);
        },
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: (product['gambar'] != null && product['gambar'].toString().isNotEmpty)
                    ? ColorFiltered(
                        colorFilter: ColorFilter.mode(isActive ? Colors.transparent : Colors.grey, BlendMode.saturation),
                        child: Image.network(product['gambar'], fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                      )
                    : Icon(Icons.image, size: 40, color: isActive ? Colors.grey : Colors.grey[400]),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(product['nama'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.red[900])),
                      ),
                      if (!isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                          child: const Text("NON-AKTIF", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Kategori: ${product['kategori']}', style: TextStyle(fontSize: 11, color: isActive ? Colors.grey[700] : Colors.red[300])),
                  const SizedBox(height: 2),
                  Text('Harga: Rp ${product['harga']}', style: TextStyle(fontSize: 11, color: isActive ? Colors.grey[700] : Colors.red[300])),
                  const SizedBox(height: 2),
                  Text('Stok: ${product['stok']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isOutOfStock ? Colors.red : Colors.green)),
                ],
              ),
            ),
            if (isActive)
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                onSelected: (String choice) {
                  if (choice == 'edit') {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => DaftarProdukEdit(produk: product))).then((value) {
                      if (value == true) _fetchProduk();
                    });
                  } else if (choice == 'delete') {
                    _deleteProduct(product['id_produk'], product['nama']);
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [Icon(Icons.edit_outlined, color: Colors.blue), SizedBox(width: 8), Text('Edit')]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 8), Text('Hapus')]),
                    ),
                  ];
                },
              ),
          ],
        ),
      ),
    );
  }
}