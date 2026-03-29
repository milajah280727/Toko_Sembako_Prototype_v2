// ignore_for_file: deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tokosembakolatihan/admin/batch_produk.dart';
import 'package:tokosembakolatihan/admin/daftar_produk.dart';
import 'package:tokosembakolatihan/admin/dashboard.dart';
import 'package:tokosembakolatihan/admin/manajemen_user.dart';
import 'package:tokosembakolatihan/main.dart';

class KategoriProduk extends StatefulWidget {
  const KategoriProduk({super.key});

  @override
  State<KategoriProduk> createState() => _KategoriProdukState();
}

class _KategoriProdukState extends State<KategoriProduk> {
  List<Map<String, dynamic>> _kategoriList = [];
  bool _isLoading = true;
  
  final TextEditingController _searchKategoriController = TextEditingController();

  final Color _primaryBlue = const Color.fromARGB(255, 95, 133, 218);
  final Color _dangerRed = const Color.fromARGB(255, 245, 36, 36);

  @override
  void initState() {
    super.initState();
    _fetchKategori();
  }

  Future<void> _fetchKategori() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select('*')
          .order('nama_kategori');
      setState(() {
        _kategoriList = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat: $e')));
    }
  }

  List<Map<String, dynamic>> get _filteredKategoriList {
    String query = _searchKategoriController.text.toLowerCase();
    if (query.isEmpty) return _kategoriList;
    return _kategoriList.where((k) => 
      (k['nama_kategori'] ?? '').toString().toLowerCase().contains(query)
    ).toList();
  }

  void _showProductsByCategoryModal(String kategoriNama) {
    final TextEditingController searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FutureBuilder(
              future: Supabase.instance.client
                  .from('produk')
                  .select('nama_produk, harga_jual')
                  .eq('kategori', kategoriNama)
                  .order('nama_produk'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 400,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final allProducts = List<Map<String, dynamic>>.from(snapshot.data ?? []);
                String query = searchCtrl.text.toLowerCase();
                
                List<Map<String, dynamic>> filteredProducts = allProducts.where((p) {
                  return (p['nama_produk'] ?? '').toString().toLowerCase().contains(query);
                }).toList();

                return Container(
                  height: MediaQuery.of(context).size.height * 0.65,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20))
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                      ),
                      Text(
                        'Produk: $kategoriNama',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Cari produk di kategori ini...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true, fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: (value) => setModalState(() {}),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filteredProducts.isEmpty
                            ? const Center(child: Text('Tidak ada produk ditemukan', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final prod = filteredProducts[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade200, width: 0.5),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            prod['nama_produk'] ?? '-',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          'Rp ${NumberFormat('#,###').format(prod['harga_jual'])}',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _primaryBlue),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddDialog() {
    final TextEditingController ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Tambahkan Kategori', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'Masukkan nama kategori',
            filled: true, fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (ctrl.text.trim().isEmpty) return;
                Navigator.pop(context);
                await _saveKategori(ctrl.text.trim());
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveKategori(String nama) async {
    try {
      await Supabase.instance.client.from('categories').insert({'nama_kategori': nama});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kategori berhasil ditambahkan'), backgroundColor: Colors.green));
      _fetchKategori();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menambahkan: $e'), backgroundColor: Colors.red));
    }
  }

  void _showEditDialog(int id, String namaLama) {
    final TextEditingController ctrl = TextEditingController(text: namaLama);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Edit Kategori', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            filled: true, fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Batal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(onPressed: () async { if (ctrl.text.trim().isEmpty || ctrl.text.trim() == namaLama) return; Navigator.pop(context); await _updateKategori(id, namaLama, ctrl.text.trim()); }, style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateKategori(int id, String namaLama, String namaBaru) async {
    try {
      await Supabase.instance.client.from('categories').update({'nama_kategori': namaBaru}).eq('id_kategori', id);
      await Supabase.instance.client.from('produk').update({'kategori': namaBaru}).eq('kategori', namaLama);

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kategori berhasil diperbarui'), backgroundColor: Colors.green));
      _fetchKategori();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal update: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _handleDelete(int id, String namaKategori) async {
    try {
      final response = await Supabase.instance.client.from('produk').select('id_produk').eq('kategori', namaKategori).limit(1);
      
      if (response.isNotEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text('Peringatan', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              content: Text('Kategori "$namaKategori" tidak dapat dihapus karena sudah digunakan oleh produk.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
              actions: [
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Kembali', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
              ],
            ),
          );
        }
      } else {
        bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text('Konfirmasi Hapus', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text('Yakin ingin menghapus kategori "$namaKategori"?', textAlign: TextAlign.center),
            actions: [
              Row(children: [
                Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, false), style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Batal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: _dangerRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
              ]),
            ],
          ),
        );

        if (confirm == true) {
          await Supabase.instance.client.from('categories').delete().eq('id_kategori', id);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kategori berhasil dihapus'), backgroundColor: Colors.green));
          _fetchKategori();
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal cek data: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 241, 241, 241),
      appBar: AppBar(
        title: const Text('Kategori Produk', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(decoration: BoxDecoration(color: _primaryBlue), accountName: const Text('ADMIN'), accountEmail: const Text('admin@example.com'), currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Colors.blue))),
            ListTile(leading: const Icon(Icons.dashboard_outlined), title: const Text('Beranda Admin'), onTap: () { Navigator.pop(context); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AdminDashboardPage()), (route) => false); }),
            const Divider(),
            ListTile(leading: const Icon(Icons.inventory_2_outlined), title: const Text('Daftar Produk'), onTap: () { Navigator.pop(context); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const DaftarProduk()), (route) => false); }),
            ListTile(leading: const Icon(Icons.batch_prediction_outlined), title: const Text('Batch Produk'), onTap: () { Navigator.pop(context); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const BatchProduk()), (route) => false); }),
            ListTile(leading: const Icon(Icons.category_outlined), title: const Text('Kategori Produk'), selected: true, selectedColor: _primaryBlue, onTap: () => Navigator.pop(context)),
            const Divider(),
            ListTile(leading: const Icon(Icons.people_outline), title: const Text('Manajemen User'), onTap: () { Navigator.pop(context); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ManajemenUser()), (route) => false); }),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))]),
              child: TextField(
                controller: _searchKategoriController,
                decoration: const InputDecoration(hintText: 'Cari kategori...', prefixIcon: Icon(Icons.search_outlined, color: Colors.grey), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14)),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _filteredKategoriList.isEmpty 
                    ? const Center(child: Text('Tidak ada kategori ditemukan'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredKategoriList.length,
                        itemBuilder: (context, index) {
                          final kategori = _filteredKategoriList[index];
                          final namaKategori = kategori['nama_kategori'];
                          final idKategori = kategori['id_kategori'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              onTap: () => _showProductsByCategoryModal(namaKategori),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              title: Text(namaKategori, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => _showEditDialog(idKategori, namaKategori),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.edit_outlined, size: 18, color: _primaryBlue)),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _handleDelete(idKategori, namaKategori),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _dangerRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.delete_outline, size: 18, color: _dangerRed)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ), // <-- PERBAIKAN: KURUNG TUTUP COLUMN YANG TADI HILANG SUDAH DITAMBAHKAN DI SINI
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: _primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}