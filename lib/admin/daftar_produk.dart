// ignore_for_file: deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:tokosembakolatihan/admin/batch_produk.dart';
import 'package:tokosembakolatihan/admin/dashboard.dart';
import 'package:tokosembakolatihan/admin/kategori_produk.dart';
import 'package:tokosembakolatihan/admin/manajemen_user.dart';
import 'package:tokosembakolatihan/main.dart';
import 'package:tokosembakolatihan/admin/daftar_produk_tambah.dart';
import 'package:tokosembakolatihan/admin/daftar_produk_edit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DaftarProduk extends StatefulWidget {
  const DaftarProduk({super.key});

  @override
  State<DaftarProduk> createState() => _DaftarProdukState();
}

class _DaftarProdukState extends State<DaftarProduk> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _produkList = [];
  List<Map<String, dynamic>> _categoryList = []; // TAMBAHAN: Untuk Chip Kategori
  bool _isLoading = true;

  // Warna Theme
  final Color _primaryBlue = const Color.fromARGB(255, 95, 133, 218);
  final Color _dangerRed = const Color.fromARGB(255, 245, 36, 36);

  // --- STATE UNTUK FILTER & SORT ---
  String? _selectedCategory; // Null berarti "Semua"
  String _selectedStatus = 'all'; // 'all', 'empty', 'low_stock', 'inactive'
  String _sortOption = 'name_asc'; // Default: Nama A-Z

  @override
  void initState() {
    super.initState();
    _fetchProduk();
  }

  // --- LOGIKA FETCH (DITAMBAH FETCH KATEGORI) ---
  Future<void> _fetchProduk() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch Kategori untuk Chip
      final catResponse = await Supabase.instance.client
          .from('categories')
          .select('id_kategori, nama_kategori')
          .order('nama_kategori');
      setState(() {
        _categoryList = List<Map<String, dynamic>>.from(catResponse);
      });

      // 2. Fetch Produk
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    }
  }

  // --- LOGIKA FILTER & SORT GETTER (STANDAR INDUSTRI) ---
  List<Map<String, dynamic>> get filteredProdukList {
    String query = _searchController.text.toLowerCase();

    // 1. FILTERING
    List<Map<String, dynamic>> result = _produkList.where((product) {
      // Filter Search Bar (Nama, Barcode, Kategori)
      if (query.isNotEmpty) {
        final namaLower = product['nama'].toString().toLowerCase();
        final kategoriLower = product['kategori'].toString().toLowerCase();
        final barcode = product['barcode'].toString().toLowerCase();
        if (!namaLower.contains(query) && !kategoriLower.contains(query) && !barcode.contains(query)) {
          return false;
        }
      }

      // Filter Chip Kategori
      if (_selectedCategory != null && product['kategori'] != _selectedCategory) {
        return false;
      }

      // Filter Chip Status
      final stok = product['stok'] as int? ?? 0;
      final isActive = product['is_active'] as bool? ?? true;
      
      switch (_selectedStatus) {
        case 'empty':
          if (stok != 0) return false;
          break;
        case 'low_stock':
          if (stok == 0 || stok > 10) return false; // Stok rendah = 1 sampai 10
          break;
        case 'inactive':
          if (isActive) return false;
          break;
      }

      return true;
    }).toList();

    // 2. SORTING
    switch (_sortOption) {
      case 'name_asc':
        result.sort((a, b) => a['nama'].toString().compareTo(b['nama'].toString()));
        break;
      case 'name_desc':
        result.sort((a, b) => b['nama'].toString().compareTo(a['nama'].toString()));
        break;
      case 'stock_asc': // Paling berguna untuk restock
        result.sort((a, b) => (a['stok'] as int).compareTo(b['stok'] as int));
        break;
      case 'stock_desc':
        result.sort((a, b) => (b['stok'] as int).compareTo(a['stok'] as int));
        break;
      case 'price_asc':
        result.sort((a, b) => (a['harga'] as int).compareTo(b['harga'] as int));
        break;
      case 'price_desc':
        result.sort((a, b) => (b['harga'] as int).compareTo(a['harga'] as int));
        break;
    }

    return result;
  }

  // --- LOGIKA CEK BATCH & TRANSAKSI (TIDAK BERUBAH) ---
  Future<bool> _hasStockBatch(int productId) async {
    try {
      final response = await Supabase.instance.client.from('stok_batch').select('id_batch').eq('id_produk', productId).limit(1);
      return response.isNotEmpty;
    } catch (e) { return false; }
  }

  Future<bool> _hasTransactionHistory(int productId) async {
    try {
      final response = await Supabase.instance.client.from('detail_transaksi').select('id_transaksi').eq('id_produk', productId).limit(1);
      return response.isNotEmpty;
    } catch (e) { return false; }
  }

  // --- LOGIKA DELETE & NON-AKTIF (TIDAK BERUBAH) ---
  Future<void> _deleteProduct(int idProduk, String namaProduk) async {
    final hasBatch = await _hasStockBatch(idProduk);
    if (hasBatch) {
      if (!mounted) return;
      showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), title: const Text('Peringatan', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.black)), content: Text('Tidak dapat menghapus produk "$namaProduk" karena masih memiliki data Batch Stok. Silakan hapus data batch terlebih dahulu.', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Poppins', color: Colors.black54)), actionsAlignment: MainAxisAlignment.center, actions: [SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Kembali', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))]));
      return;
    }

    final hasHistory = await _hasTransactionHistory(idProduk);
    if (hasHistory) {
      if (!mounted) return;
      showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), title: const Text('Peringatan', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.black)), content: Text('Produk "$namaProduk" tercatat dalam riwayat transaksi. Pilih "Nonaktifkan" untuk menyembunyikannya tanpa menghapus laporan.', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Poppins', color: Colors.black54)), actions: [Row(children: [Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Batal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))), const SizedBox(width: 10), Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(context); _deactivateProduct(idProduk); }, style: ElevatedButton.styleFrom(backgroundColor: _dangerRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Nonaktifkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))])]));
      return;
    }

    if (!mounted) return;
    final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), backgroundColor: Colors.white, title: const Text('Peringatan', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.black)), content: Text('Apakah anda yakin ingin menghapus produk "$namaProduk" ini?, produk yang sudah dihapus tidak akan bisa di kembalikan.', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Poppins', color: Colors.black54)), actions: [Row(children: [Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, false), style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Kembali', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))), const SizedBox(width: 10), Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: _dangerRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))])]));

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('produk').delete().eq('id_produk', idProduk);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk berhasil dihapus'), backgroundColor: Colors.green));
        _fetchProduk();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _deactivateProduct(int id) async {
    try {
      await Supabase.instance.client.from('produk').update({'is_active': false}).eq('id_produk', id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk dinonaktifkan')));
      _fetchProduk();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _reactivateProduct(int id, String namaProduk) async {
    final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), title: const Text('Konfirmasi', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.black)), content: Text('Aktifkan kembali produk "$namaProduk"?', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Poppins', color: Colors.black54)), actions: [Row(children: [Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, false), style: ElevatedButton.styleFrom(backgroundColor: _dangerRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Batal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))), const SizedBox(width: 10), Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Aktifkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))])]));

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('produk').update({'is_active': true}).eq('id_produk', id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk aktif kembali')));
        _fetchProduk();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  // --- UI HELPERS ---
  Widget _buildCategoryChip(String? catName) {
    bool isSelected = _selectedCategory == catName;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(catName ?? 'Semua', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        selected: isSelected,
        selectedColor: _primaryBlue.withOpacity(0.15),
        backgroundColor: Colors.white,
        side: BorderSide(color: isSelected ? _primaryBlue : Colors.grey.shade300),
        labelStyle: TextStyle(color: isSelected ? _primaryBlue : Colors.grey.shade600),
        onSelected: (selected) => setState(() => _selectedCategory = selected ? catName : null),
      ),
    );
  }

  Widget _buildStatusChip(String id, String label, {Color? activeColor, Color? activeText}) {
    bool isSelected = _selectedStatus == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        selected: isSelected,
        selectedColor: (activeColor ?? Colors.grey).withOpacity(0.15),
        backgroundColor: Colors.white,
        side: BorderSide(color: isSelected ? (activeColor ?? Colors.grey) : Colors.grey.shade300),
        labelStyle: TextStyle(color: isSelected ? (activeText ?? Colors.grey) : Colors.grey.shade600),
        onSelected: (selected) => setState(() => _selectedStatus = selected ? id : 'all'),
      ),
    );
  }

  void _showSortBottomSheet() {
    final activeIconColor = _primaryBlue;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Urutkan Berdasarkan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildSortOption('name_asc', 'Nama Produk (A-Z)', Icons.sort_by_alpha, activeIconColor),
            _buildSortOption('name_desc', 'Nama Produk (Z-A)', Icons.sort_by_alpha, activeIconColor),
            _buildSortOption('stock_asc', 'Stok Terendah', Icons.arrow_downward, activeIconColor),
            _buildSortOption('stock_desc', 'Stok Tertinggi', Icons.arrow_upward, activeIconColor),
            _buildSortOption('price_asc', 'Harga Termurah', Icons.attach_money, activeIconColor),
            _buildSortOption('price_desc', 'Harga Termahal', Icons.attach_money, activeIconColor),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String id, String title, IconData icon, Color activeColor) {
    bool isSelected = _sortOption == id;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? activeColor : Colors.black87)),
      trailing: Icon(icon, color: isSelected ? activeColor : Colors.grey),
      onTap: () { setState(() => _sortOption = id); Navigator.pop(context); },
    );
  }

  // --- MAIN BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 241, 241, 241),
      appBar: AppBar(
        title: const Text('Daftar Produk', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: _fetchProduk)],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(decoration: BoxDecoration(color: _primaryBlue), accountName: const Text('ADMIN'), accountEmail: const Text('role@example.com'), currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Colors.blue))),
            ListTile(leading: const Icon(Icons.dashboard_outlined), title: const Text('Beranda Admin'), onTap: () { Navigator.pop(context); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AdminDashboardPage()), (route) => false); }),
            const Divider(),
            ListTile(leading: const Icon(Icons.inventory_2_outlined), title: const Text('Daftar Produk'), selected: true, selectedColor: _primaryBlue, onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.batch_prediction_outlined), title: const Text('Batch Produk'), onTap: () { Navigator.pop(context); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const BatchProduk()), (route) => false); }),
            ListTile(leading: const Icon(Icons.category_outlined), title: const Text('Kategori Produk'), onTap: () { Navigator.pop(context); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const KategoriProduk()), (route) => false); }),
            const Divider(),
            ListTile(leading: const Icon(Icons.people_outline), title: const Text('Manajemen User'), onTap: () { Navigator.pop(context); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ManajemenUser()), (route) => false); }),
            const Spacer(), const Divider(),
            SizedBox(width: 280, height: 40, child: ElevatedButton(onPressed: () { showDialog(context: context, builder: (BuildContext context) { return AlertDialog(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), title: const Text('Peringatan', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)), content: const Text('Apakah Anda yakin ingin logout?', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins')), actions: [Row(children: [Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Batal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))), const SizedBox(width: 10), Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MyApp()), (route) => false); }, style: ElevatedButton.styleFrom(backgroundColor: _dangerRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))])]); }); }, style: ElevatedButton.styleFrom(backgroundColor: _dangerRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))), child: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)))),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: Column(
        children: [
          // BARIS 1: SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))]),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(hintText: 'Cari nama, kategori, atau barcode...', prefixIcon: Icon(Icons.search_outlined), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14)),
                // Cukup setState untuk memicu getter
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),

          // BARIS 2: CHIP KATEGORI
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip(null),
                ..._categoryList.map((cat) => _buildCategoryChip(cat['nama_kategori'])),
              ],
            ),
          ),

          // BARIS 3: CHIP STATUS & SORT BUTTON
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildStatusChip('all', 'Semua Status'),
                _buildStatusChip('empty', 'Stok Habis', activeColor: Colors.red, activeText: Colors.red),
                _buildStatusChip('low_stock', 'Stok Rendah (<10)', activeColor: Colors.orange, activeText: Colors.orange),
                _buildStatusChip('inactive', 'Non-Aktif', activeColor: Colors.grey, activeText: Colors.grey),
                
                // Tombol Sortir
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: InkWell(
                    onTap: _showSortBottomSheet,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.swap_vert, size: 16, color: Colors.blue),
                          SizedBox(width: 4),
                          Text('Urutkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // BARIS 4: LIST VIEW PRODUK (Menggunakan Getter)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProdukList.isEmpty
                    ? const Center(child: Text('Tidak ada produk ditemukan'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredProdukList.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(filteredProdukList[index]);
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

  // --- WIDGET CARD PRODUK (TIDAK BERUBAH) ---
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
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, color: Colors.blue), SizedBox(width: 8), Text('Edit')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 8), Text('Hapus')])),
                  ];
                },
              ),
          ],
        ),
      ),
    );
  }
}