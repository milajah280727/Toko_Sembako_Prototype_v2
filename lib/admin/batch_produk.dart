// ignore_for_file: deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tokosembakolatihan/admin/dashboard.dart';
import 'package:tokosembakolatihan/admin/kategori_produk.dart';
import 'package:tokosembakolatihan/admin/manajemen_user.dart';
import 'package:tokosembakolatihan/admin/daftar_produk.dart';
import 'package:tokosembakolatihan/main.dart';

class BatchProduk extends StatefulWidget {
  const BatchProduk({super.key});

  @override
  State<BatchProduk> createState() => _BatchProdukState();
}

class _BatchProdukState extends State<BatchProduk> {
  List<Map<String, dynamic>> _batchList = [];
  bool _isLoading = true;

  final Color _primaryBlue = const Color.fromARGB(255, 95, 133, 218);
  final Color _dangerRed = const Color.fromARGB(255, 245, 36, 36);

  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; 
  String _selectedDatePreset = 'Semua Tanggal'; 
  String _sortOption = 'date_desc'; // STATE BARU UNTUK SORTIR

  @override
  void initState() {
    super.initState();
    _fetchBatch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime _safeParseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    String dateStr = dateValue.toString();
    if (dateStr.length >= 10) {
      dateStr = dateStr.substring(0, 10);
    }
    return DateTime.parse(dateStr); 
  }

  List<Map<String, dynamic>> get _filteredBatchList {
    String query = _searchController.text.toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); 

    List<Map<String, dynamic>> result = _batchList.where((batch) {
      final produk = batch['produk'] as Map<String, dynamic>?;
      final namaProduk = (produk?['nama_produk'] ?? '').toString().toLowerCase();
      
      if (query.isNotEmpty && !namaProduk.contains(query)) return false;

      final stokRaw = batch['jumlah_stok']?.toString() ?? '0';
      final stok = int.tryParse(stokRaw) ?? 0;
      
      final tanggalExp = _safeParseDate(batch['tanggal_exp']);
      final tanggalMasuk = _safeParseDate(batch['tanggal_masuk']);
      
      final expDateOnly = DateTime(tanggalExp.year, tanggalExp.month, tanggalExp.day);
      final masukDateOnly = DateTime(tanggalMasuk.year, tanggalMasuk.month, tanggalMasuk.day);

      switch (_selectedFilter) {
        case 'empty': return stok == 0;
        case 'expired': return expDateOnly.isBefore(today);
        case 'near_exp':
          final thirtyDaysFromNow = today.add(const Duration(days: 30));
          return (expDateOnly.isAfter(today) || expDateOnly.isAtSameMomentAs(today)) && expDateOnly.isBefore(thirtyDaysFromNow);
        case 'date':
          switch (_selectedDatePreset) {
            case 'Hari Ini': return masukDateOnly.isAtSameMomentAs(today);
            case '7 Hari Terakhir':
              final sevenDaysAgo = today.subtract(const Duration(days: 7));
              return masukDateOnly.isAfter(sevenDaysAgo) || masukDateOnly.isAtSameMomentAs(sevenDaysAgo);
            case '30 Hari Terakhir':
              final thirtyDaysAgo = today.subtract(const Duration(days: 30));
              return masukDateOnly.isAfter(thirtyDaysAgo) || masukDateOnly.isAtSameMomentAs(thirtyDaysAgo); // Fixed typo pada original
            case 'Bulan Ini': return masukDateOnly.year == today.year && masukDateOnly.month == today.month;
            default: return true;
          }
        default: return true;
      }
    }).toList();

    // --- LOGIKA SORTIR BARU ---
    switch (_sortOption) {
      case 'name_asc':
        result.sort((a, b) => ((a['produk'] as Map?)?['nama_produk'] ?? '').toString().compareTo(((b['produk'] as Map?)?['nama_produk'] ?? '').toString()));
        break;
      case 'name_desc':
        result.sort((a, b) => ((b['produk'] as Map?)?['nama_produk'] ?? '').toString().compareTo(((a['produk'] as Map?)?['nama_produk'] ?? '').toString()));
        break;
      case 'stock_asc':
        result.sort((a, b) => (int.tryParse(a['jumlah_stok'].toString()) ?? 0).compareTo(int.tryParse(b['jumlah_stok'].toString()) ?? 0));
        break;
      case 'stock_desc':
        result.sort((a, b) => (int.tryParse(b['jumlah_stok'].toString()) ?? 0).compareTo(int.tryParse(a['jumlah_stok'].toString()) ?? 0));
        break;
      case 'exp_asc': // Kadaluarsa Terdekat
        result.sort((a, b) => _safeParseDate(a['tanggal_exp']).compareTo(_safeParseDate(b['tanggal_exp'])));
        break;
      case 'date_desc': // Terbaru (Default)
        result.sort((a, b) => _safeParseDate(b['tanggal_masuk']).compareTo(_safeParseDate(a['tanggal_masuk'])));
        break;
    }

    return result;
  }

  void _showDateFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Tanggal Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildDateOption('Semua Tanggal'),
            _buildDateOption('Hari Ini'),
            _buildDateOption('7 Hari Terakhir'),
            _buildDateOption('30 Hari Terakhir'),
            _buildDateOption('Bulan Ini'),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDateOption(String title) {
    bool isSelected = _selectedDatePreset == title;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: isSelected ? _primaryBlue.withOpacity(0.1) : Colors.transparent,
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? _primaryBlue : Colors.black87)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
      onTap: () { setState(() => _selectedDatePreset = title); Navigator.pop(context); },
    );
  }

  // --- UI HELPER SORTIR BARU ---
  void _showSortBottomSheet() {
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
            _buildSortOption('date_desc', 'Tanggal Masuk Terbaru', Icons.calendar_today),
            _buildSortOption('name_asc', 'Nama Produk (A-Z)', Icons.sort_by_alpha),
            _buildSortOption('name_desc', 'Nama Produk (Z-A)', Icons.sort_by_alpha),
            _buildSortOption('stock_asc', 'Stok Terendah', Icons.arrow_downward),
            _buildSortOption('stock_desc', 'Stok Tertinggi', Icons.arrow_upward),
            _buildSortOption('exp_asc', 'Kadaluarsa Terdekat', Icons.schedule),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String id, String title, IconData icon) {
    bool isSelected = _sortOption == id;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: isSelected ? _primaryBlue.withOpacity(0.1) : Colors.transparent,
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? _primaryBlue : Colors.black87)),
      trailing: Icon(icon, color: isSelected ? _primaryBlue : Colors.grey),
      onTap: () { setState(() => _sortOption = id); Navigator.pop(context); },
    );
  }

  Future<void> _fetchBatch() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.from('stok_batch').select('*, produk(nama_produk, gambar)').order('tanggal_masuk', ascending: false);
      setState(() { _batchList = List<Map<String, dynamic>>.from(response); _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data batch: $e')));
    }
  }

  Future<void> _deleteBatch(int idBatch, String namaProduk) async {
    final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), title: const Text('Peringatan', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)), content: Text('Yakin ingin menghapus batch stok "$namaProduk"?', textAlign: TextAlign.center), actions: [Row(children: [Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, false), style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Batal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))), const SizedBox(width: 10), Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: _dangerRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))])]));
    if (confirm == true) {
      try {
        await Supabase.instance.client.from('stok_batch').delete().eq('id_batch', idBatch);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch berhasil dihapus'), backgroundColor: Colors.green));
        _fetchBatch();
      } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e'))); }
    }
  }

  void _showAddStockDialog() {
    showDialog(context: context, builder: (context) => Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: _AddStockForm(onSuccess: _fetchBatch)));
  }

  Widget _buildFilterChip(String id, {required String label, Color? activeColor, Color? activeTextColor}) {
    bool isSelected = _selectedFilter == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        selected: isSelected,
        selectedColor: (activeColor ?? _primaryBlue).withOpacity(0.15),
        backgroundColor: Colors.white,
        side: BorderSide(color: isSelected ? (activeColor ?? _primaryBlue) : Colors.grey.shade300, width: 1),
        labelStyle: TextStyle(color: isSelected ? (activeTextColor ?? _primaryBlue) : Colors.grey.shade600),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? id : 'all';
            if (_selectedFilter != 'date') _selectedDatePreset = 'Semua Tanggal';
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int expiredCount = _batchList.where((b) => _safeParseDate(b['tanggal_exp']).isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))).length;
    int emptyCount = _batchList.where((b) => (int.tryParse(b['jumlah_stok'].toString()) ?? 0) == 0).length;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 241, 241, 241),
      appBar: AppBar(
        title: const Text('Batch Produk', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: _fetchBatch)],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(decoration: BoxDecoration(color: _primaryBlue), accountName: const Text('ADMIN'), accountEmail: const Text('role@example.com'), currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Colors.blue))),
            ListTile(leading: const Icon(Icons.dashboard_outlined), title: const Text('Beranda Admin'), onTap: () { Navigator.pop(context); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AdminDashboardPage()), (route) => false); }),
            const Divider(),
            ListTile(leading: const Icon(Icons.inventory_2_outlined), title: const Text('Daftar Produk'), onTap: () { Navigator.pop(context); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const DaftarProduk()), (route) => false); }),
            ListTile(leading: const Icon(Icons.batch_prediction_outlined), title: const Text('Batch Produk'), selected: true, selectedColor: _primaryBlue, onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.category_outlined), title: const Text('Kategori Produk'), onTap: () { Navigator.pop(context); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const KategoriProduk()), (route) => false); }),
            const Divider(),
            ListTile(leading: const Icon(Icons.people_outline), title: const Text('Manajemen User'), onTap: () { Navigator.pop(context); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ManajemenUser()), (route) => false); }),
            const Spacer(), const Divider(),
            SizedBox(width: 280, height: 40, child: ElevatedButton(onPressed: () { showDialog(context: context, builder: (BuildContext context) { return AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), title: const Text('Peringatan', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)), content: const Text('Apakah Anda yakin ingin logout?', textAlign: TextAlign.center), actions: [Row(children: [Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Batal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))), const SizedBox(width: 10), Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MyApp()), (route) => false); }, style: ElevatedButton.styleFrom(backgroundColor: _dangerRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))])]); }); }, style: ElevatedButton.styleFrom(backgroundColor: _dangerRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))), child: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)))),
            const SizedBox(height: 20),
          ],
        ),
      ),
      
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))]),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(hintText: 'Cari nama produk...', prefixIcon: Icon(Icons.search_outlined, color: Colors.grey), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14)),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
          
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('all', label: 'Semua'),
                _buildFilterChip('empty', label: 'Stok Habis ($emptyCount)', activeColor: Colors.red, activeTextColor: Colors.red),
                _buildFilterChip('expired', label: 'Kadaluarsa ($expiredCount)', activeColor: Colors.red, activeTextColor: Colors.red),
                _buildFilterChip('near_exp', label: 'Exp < 30 Hari', activeColor: Colors.orange, activeTextColor: Colors.orange),
                InkWell(
                  onTap: () { setState(() => _selectedFilter = 'date'); _showDateFilterSheet(); },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: _selectedFilter == 'date' ? _primaryBlue.withOpacity(0.15) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _selectedFilter == 'date' ? _primaryBlue : Colors.grey.shade300)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.calendar_today, size: 14, color: _selectedFilter == 'date' ? _primaryBlue : Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(_selectedFilter == 'date' ? _selectedDatePreset : 'Filter Tanggal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _selectedFilter == 'date' ? _primaryBlue : Colors.grey.shade600)),
                      if (_selectedFilter == 'date') ...[const SizedBox(width: 4), GestureDetector(onTap: () => setState(() { _selectedFilter = 'all'; _selectedDatePreset = 'Semua Tanggal'; }), child: const Icon(Icons.close, size: 14, color: Colors.blue))]
                    ]),
                  ),
                ),
                // TOMBAOL SORTIR BARU DITAMBAHKAN DI SINI
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: InkWell(
                    onTap: _showSortBottomSheet,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.swap_vert, size: 16, color: Colors.blue), SizedBox(width: 4), Text('Urutkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue))]),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBatchList.isEmpty
                    ? const Center(child: Text('Tidak ada data sesuai filter'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredBatchList.length,
                        itemBuilder: (context, index) {
                          final batch = _filteredBatchList[index];
                          final produk = batch['produk'] as Map<String, dynamic>?;
                          final namaProduk = produk?['nama_produk'] ?? 'Unknown';
                          final gambarProduk = produk?['gambar'];
                          final tanggalMasuk = _safeParseDate(batch['tanggal_masuk']);
                          final tanggalExp = _safeParseDate(batch['tanggal_exp']);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), spreadRadius: 1, blurRadius: 3)]),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: (gambarProduk != null && gambarProduk.toString().isNotEmpty) ? Image.network(gambarProduk, fit: BoxFit.cover, loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)), errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 20, color: Colors.grey)) : const Icon(Icons.inventory_2_outlined, size: 20, color: Colors.grey))),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(namaProduk, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _deleteBatch(batch['id_batch'], namaProduk), padding: EdgeInsets.zero, constraints: const BoxConstraints())),
                                  ],
                                ),
                                const Divider(color: Colors.grey, thickness: 0.5),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Jumlah', style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                                          const SizedBox(height: 2),
                                          Text('${batch['jumlah_stok']} pcs', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 12),
                                          const Text('Tanggal Masuk', style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                                          const SizedBox(height: 2),
                                          Text(DateFormat('d MMM yyyy').format(tanggalMasuk), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueAccent)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text('Harga Beli', style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                                          const SizedBox(height: 2),
                                          Text('Rp ${NumberFormat('#,###').format(batch['harga_beli_satuan'])}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 12),
                                          const Text('Kadaluarsa', style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                                          const SizedBox(height: 2),
                                          Text(DateFormat('d MMM yyyy').format(tanggalExp), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tanggalExp.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)) ? Colors.red : Colors.black87)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStockDialog,
        backgroundColor: _primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// --- WIDGET FORM TAMBAH STOK ---
class _AddStockForm extends StatefulWidget {
  final VoidCallback onSuccess;
  const _AddStockForm({required this.onSuccess});

  @override
  State<_AddStockForm> createState() => _AddStockFormState();
}

class _AddStockFormState extends State<_AddStockForm> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController();
  final _hargaBeliController = TextEditingController();

  List<Map<String, dynamic>> _produkList = [];
  int? _selectedProductId;
  String? _selectedProductName; 
  DateTime _tanggalMasuk = DateTime.now();
  DateTime _tanggalExp = DateTime.now().add(const Duration(days: 30));
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
      final response = await Supabase.instance.client.from('produk').select('id_produk, nama_produk').eq('is_active', true).order('nama_produk', ascending: true);
      setState(() {
        _produkList = List<Map<String, dynamic>>.from(response);
        _isLoadingProduk = false;
        if (_produkList.isNotEmpty) {
          _selectedProductId = _produkList.first['id_produk'];
          _selectedProductName = _produkList.first['nama_produk']; 
        }
      });
    } catch (e) {
      setState(() => _isLoadingProduk = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat produk: $e')));
    }
  }

  void _showProductPicker() {
    final TextEditingController searchCtrl = TextEditingController(); 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            String query = searchCtrl.text.toLowerCase();
            List<Map<String, dynamic>> filteredList = _produkList.where((p) {
              return (p['nama_produk'] ?? '').toString().toLowerCase().contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.65, 
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Column(
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const Text('Pilih Produk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchCtrl,
                    autofocus: true, 
                    decoration: InputDecoration(hintText: 'Ketik nama produk...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 0)),
                    onChanged: (value) => setModalState(() {}), 
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredList.isEmpty
                        ? const Center(child: Text('Produk tidak ditemukan', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final product = filteredList[index];
                              bool isSelected = _selectedProductId == product['id_produk'];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  tileColor: isSelected ? _primaryBlue.withOpacity(0.1) : Colors.transparent,
                                  title: Text(product['nama_produk'], style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? _primaryBlue : Colors.black87)),
                                  trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                                  onTap: () {
                                    setState(() { _selectedProductId = product['id_produk']; _selectedProductName = product['nama_produk']; });
                                    Navigator.pop(context); 
                                  },
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
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('stok_batch').insert({
        'id_produk': _selectedProductId,
        'jumlah_stok': int.parse(_jumlahController.text),
        'harga_beli_satuan': int.parse(_hargaBeliController.text),
        'tanggal_masuk': _tanggalMasuk.toIso8601String(),
        'tanggal_exp': _tanggalExp.toIso8601String().split('T').first,
      });
      widget.onSuccess();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok berhasil ditambahkan'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Text('Tambah Stok Masuk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryBlue))),
              const SizedBox(height: 20),
              if (_isLoadingProduk)
                const Center(child: CircularProgressIndicator())
              else
                InkWell(
                  onTap: _showProductPicker,
                  borderRadius: BorderRadius.circular(10),
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: 'Produk', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), suffixIcon: const Icon(Icons.search, color: Colors.grey)), 
                    child: Text(_selectedProductName ?? 'Pilih Produk', style: TextStyle(color: _selectedProductName != null ? Colors.black : Colors.grey, fontSize: 16)),
                  ),
                ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _jumlahController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Jumlah', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)), validator: (v) => v!.isEmpty ? 'Wajib' : null)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _hargaBeliController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Harga Beli', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)), validator: (v) => v!.isEmpty ? 'Wajib' : null)),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: InkWell(onTap: () async { final picked = await showDatePicker(context: context, initialDate: _tanggalMasuk, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (picked != null) { setState(() => _tanggalMasuk = picked); } }, child: InputDecorator(decoration: InputDecoration(labelText: 'Tgl Masuk', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)), child: Text(DateFormat('d MMM yyyy').format(_tanggalMasuk))))),
                  const SizedBox(width: 10),
                  Expanded(child: InkWell(onTap: () async { final picked = await showDatePicker(context: context, initialDate: _tanggalExp, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (picked != null) { setState(() => _tanggalExp = picked); } }, child: InputDecorator(decoration: InputDecoration(labelText: 'Tgl EXP', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)), child: Text(DateFormat('d MMM yyyy').format(_tanggalExp))))),
                ],
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity, height: 45,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Tambah Stok', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}