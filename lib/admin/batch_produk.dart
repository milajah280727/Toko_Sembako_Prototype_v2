// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tokosembakolatihan/admin/dashboard.dart';
import 'package:tokosembakolatihan/admin/kategori_produk.dart';
import 'package:tokosembakolatihan/admin/manajemen_user.dart';
import 'package:tokosembakolatihan/admin/product/daftar_produk.dart';
import 'package:tokosembakolatihan/main.dart';

class BatchProduk extends StatefulWidget {
  const BatchProduk({super.key});

  @override
  State<BatchProduk> createState() => _BatchProdukState();
}

class _BatchProdukState extends State<BatchProduk> {
  List<Map<String, dynamic>> _batchList = [];
  bool _isLoading = true;

  // Warna Theme
  final Color _primaryBlue = const Color.fromARGB(255, 95, 133, 218);
  final Color _dangerRed = const Color.fromARGB(255, 245, 36, 36);

  @override
  void initState() {
    super.initState();
    _fetchBatch();
  }

  // --- LOGIKA AMBIL DATA BATCH ---
  Future<void> _fetchBatch() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('stok_batch')
          .select('*, produk(nama_produk)') // Join ke tabel produk
          .order('tanggal_masuk', ascending: false);

      setState(() {
        _batchList = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data batch: $e')),
      );
    }
  }

  // --- LOGIKA HAPUS BATCH ---
  Future<void> _deleteBatch(int idBatch, String namaProduk) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Peringatan', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus batch stok "$namaProduk"?', textAlign: TextAlign.center),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Batal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: _dangerRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('stok_batch').delete().eq('id_batch', idBatch);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch berhasil dihapus'), backgroundColor: Colors.green));
        _fetchBatch();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
      }
    }
  }

  // --- MODAL TAMBAH STOK ---
  void _showAddStockModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddStockModal(
        onSuccess: () {
          Navigator.pop(context);
          _fetchBatch();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 241, 241, 241),
      appBar: AppBar(
        title: const Text('Batch Stok', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _fetchBatch,
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
              onTap: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const DaftarProduk()), (route) => false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.batch_prediction_outlined),
              title: const Text('Batch Produk'),
              selected: true,
              selectedColor: _primaryBlue,
              onTap: () => Navigator.pop(context),
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
                        title: const Text('Peringatan', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                        content: const Text('Apakah Anda yakin ingin logout?', textAlign: TextAlign.center),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _batchList.isEmpty
              ? const Center(child: Text('Belum ada data batch stok'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _batchList.length,
                  itemBuilder: (context, index) {
                    final batch = _batchList[index];
                    final produk = batch['produk'] as Map<String, dynamic>?;
                    return _buildBatchCard(batch, produk);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStockModal,
        backgroundColor: _primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBatchCard(Map<String, dynamic> batch, Map<String, dynamic>? produk) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final formatDate = DateFormat('d MMM yyyy');

    // Handle jika produk null (terhapus)
    String namaProduk = produk?['nama_produk'] ?? 'Produk Dihapus';
    
    // Parsing tanggal aman
    DateTime tglMasuk = DateTime.parse(batch['tanggal_masuk']);
    DateTime tglExp = DateTime.parse(batch['tanggal_exp']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), spreadRadius: 1, blurRadius: 3)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Nama Produk & Tombol Hapus
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  namaProduk,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              InkWell(
                onTap: () => _deleteBatch(batch['id_batch'], namaProduk),
                child: Icon(Icons.delete_outline, color: Colors.grey[400], size: 20),
              )
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          
          // Info Grid
          Row(
            children: [
              // Kolom Kiri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Masuk: ${formatDate.format(tglMasuk)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('Jumlah: ${batch['jumlah_stok']} pcs', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              // Kolom Kanan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Harga Beli: ${formatCurrency.format(batch['harga_beli_satuan'])}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('EXP: ${formatDate.format(tglExp)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red[400])),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- WIDGET MODAL TAMBAH STOK ---
class _AddStockModal extends StatefulWidget {
  final VoidCallback onSuccess;
  const _AddStockModal({required this.onSuccess});

  @override
  State<_AddStockModal> createState() => _AddStockModalState();
}

class _AddStockModalState extends State<_AddStockModal> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController();
  final _hargaBeliController = TextEditingController();
  
  List<Map<String, dynamic>> _produkList = [];
  int? _selectedProductId;
  DateTime _tanggalMasuk = DateTime.now();
  DateTime _tanggalExp = DateTime.now().add(const Duration(days: 30)); // Default 1 bulan
  bool _isLoading = false;
  bool _isLoadingProduk = true;

  final Color _primaryBlue = const Color.fromARGB(255, 95, 133, 218);

  @override
  void initState() {
    super.initState();
    _fetchProduk();
  }

  Future<void> _fetchProduk() async {
    try {
      final response = await Supabase.instance.client
          .from('produk')
          .select('id_produk, nama_produk')
          .eq('is_active', true)
          .order('nama_produk', ascending: true);
      
      setState(() {
        _produkList = List<Map<String, dynamic>>.from(response);
        _isLoadingProduk = false;
        if (_produkList.isNotEmpty) {
          _selectedProductId = _produkList.first['id_produk'];
        }
      });
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat produk: $e')));
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedProductId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih produk terlebih dahulu')));
        return;
      }

      setState(() => _isLoading = true);
      try {
        await Supabase.instance.client.from('stok_batch').insert({
          'id_produk': _selectedProductId,
          'jumlah_stok': int.parse(_jumlahController.text),
          'harga_beli_satuan': int.parse(_hargaBeliController.text),
          'tanggal_masuk': _tanggalMasuk.toIso8601String(),
          'tanggal_exp': _tanggalExp.toIso8601String().split('T').first, // Format Date only
        });

        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok berhasil ditambahkan'), backgroundColor: Colors.green));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5))),
                ),
                const SizedBox(height: 15),
                const Text('Tambah Stok Masuk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Dropdown Produk
                if (_isLoadingProduk)
                  const Center(child: CircularProgressIndicator())
                else
                  DropdownButtonFormField<int>(
                    value: _selectedProductId,
                    decoration: InputDecoration(
                      labelText: 'Produk',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    items: _produkList.map((p) {
                      return DropdownMenuItem<int>(
                        value: p['id_produk'],
                        child: Text(p['nama_produk']),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedProductId = val),
                  ),
                const SizedBox(height: 15),

                // Input Jumlah & Harga
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _jumlahController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Jumlah',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        validator: (v) => v!.isEmpty ? 'Wajib' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _hargaBeliController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Harga Beli (Satuan)',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        validator: (v) => v!.isEmpty ? 'Wajib' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // Date Pickers
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(context: context, initialDate: _tanggalMasuk, firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (picked != null) setState(() => _tanggalMasuk = picked);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Tgl Masuk',
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          child: Text(DateFormat('d MMM yyyy').format(_tanggalMasuk)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(context: context, initialDate: _tanggalExp, firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (picked != null) setState(() => _tanggalExp = picked);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Tgl EXP',
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          child: Text(DateFormat('d MMM yyyy').format(_tanggalExp)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Tombol Simpan
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Tambah Stok', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}