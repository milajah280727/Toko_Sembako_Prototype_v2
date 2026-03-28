import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:tokosembakolatihan/admin/product/barcode_scanner_page.dart'; // IMPORT FILE SCANNER BARU

class DaftarProdukTambah extends StatefulWidget {
  const DaftarProdukTambah({super.key});

  @override
  State<DaftarProdukTambah> createState() => _DaftarProdukTambahState();
}

class _DaftarProdukTambahState extends State<DaftarProdukTambah> {
  final _namaController = TextEditingController();
  final _hargaController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _hargaBeliController = TextEditingController();

  bool _isLoading = false;

  // Variabel untuk Kategori
  List<String> _kategoriList = [];
  String? _selectedKategori;
  bool _isLoadingKategori = true;

  // Variabel untuk Gambar
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _barcodeController.text = _generateRandomBarcode();
    _hargaBeliController.text = '0';
    _fetchKategori();
  }

  Future<void> _fetchKategori() async {
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select('nama_kategori');

      final List<String> loadedKategori = [];
      for (var item in response) {
        loadedKategori.add(item['nama_kategori'] as String);
      }

      setState(() {
        _kategoriList = loadedKategori;
        _isLoadingKategori = false;
        if (_kategoriList.isNotEmpty) {
          _selectedKategori = _kategoriList.first;
        }
      });
    } catch (e) {
      setState(() => _isLoadingKategori = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat kategori: $e')));
      }
    }
  }

  String _generateRandomBarcode() {
    final random = Random();
    var barcode = '';
    for (int i = 0; i < 8; i++) {
      barcode += random.nextInt(10).toString();
    }
    return barcode;
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library,color: Colors.blueAccent,),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera,color: Colors.blueAccent),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);

    if (image != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        File compressedImage = await _compressImage(File(image.path));

        if (mounted) {
          Navigator.pop(context);
          setState(() {
            _imageFile = compressedImage;
          });
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal memproses gambar: $e')));
        }
      }
    }
  }

  Future<File> _compressImage(File file) async {
    final path = file.absolute.path;
    final lastIndex = path.lastIndexOf(RegExp(r'\.'));
    final split = path.substring(0, (lastIndex + 1));
    final outPath =
        '${split}compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outPath,
      quality: 70,
      minWidth: 800,
      minHeight: 600,
    );

    if (result == null) return file;
    return File(result.path);
  }

  Future<String?> _uploadImage(String fileName) async {
    if (_imageFile == null) return null;

    try {
      String bucketName = 'products-image';
      final path = '$fileName-${DateTime.now().millisecondsSinceEpoch}';

      await Supabase.instance.client.storage
          .from(bucketName)
          .upload(path, _imageFile!);

      final imageUrl = Supabase.instance.client.storage
          .from(bucketName)
          .getPublicUrl(path);

      return imageUrl;
    } catch (e) {
      print("GAGAL Upload Image: $e");
      return null;
    }
  }

  // --- FUNGSI SCAN BARCODE YANG SUDAH JALAN ---
  void _startScan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
    );

    if (result != null && result is String) {
      setState(() {
        _barcodeController.text = result;
      });
    }
  }

  Future<void> _generateAndPrintBarcode() async {
    final pdf = pw.Document();
    String productName = _namaController.text.isEmpty
        ? 'Produk Baru'
        : _namaController.text;
    String price = _hargaController.text.isEmpty ? '0' : _hargaController.text;
    String barcodeData = _barcodeController.text;
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  productName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Rp $price',
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.orange800),
                ),
                pw.SizedBox(height: 10),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: barcodeData,
                  width: 200,
                  height: 80,
                  drawText: false,
                ),
                pw.SizedBox(height: 5),
                pw.Text(barcodeData, style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Barcode_$productName.pdf',
    );
  }

  Future<void> _saveProduct() async {
    if (_namaController.text.isEmpty || _hargaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan Harga wajib diisi!')),
      );
      return;
    }

    if (_selectedKategori == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kategori wajib dipilih!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? finalImageUrl = await _uploadImage(_namaController.text);

      final data = {
        'nama_produk': _namaController.text,
        'kategori': _selectedKategori,
        'harga_jual': int.parse(_hargaController.text),
        'barcode': _barcodeController.text,
        'gambar': finalImageUrl,
        'harga_beli': int.parse(
          _hargaBeliController.text.isEmpty ? '0' : _hargaBeliController.text,
        ),
        'is_active': true,
      };

      await Supabase.instance.client.from('produk').insert(data);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil ditambahkan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal Menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Tambah Produk',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showPicker(context),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _imageFile != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              _imageFile!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: CircleAvatar(
                              backgroundColor: Colors.red,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () =>
                                    setState(() => _imageFile = null),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 50,
                            color: Colors.blueAccent
                          ),

                          SizedBox(height: 30),

                          Padding(
                            padding: EdgeInsets.only(left: 15, right: 15),
                            child: Text(
                              'Tap untuk menagmbil foto atau tambahkan melalui galeri',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey,fontFamily: 'Poppins', fontSize: 12),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Barcode Produk',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.qr_code_scanner,
                                color: Colors.blueAccent,
                              ),
                              onPressed: _startScan, // Memanggil fungsi scan
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.print,
                                color: Colors.blueAccent,
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : _generateAndPrintBarcode,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: _barcodeController.text,
                      color: Colors.black,
                      height: 50,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildInputField(
              _namaController,
              'Nama Produk',
              Icons.inventory_2_outlined,
              false,
            ),
            const SizedBox(height: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kategori',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedKategori,
                    decoration: InputDecoration(
                      // prefixIcon dihapus
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      // Outline saat tidak ditekan
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      // Outline saat ditekan
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 95, 133, 218),
                          width: 2,
                        ),
                      ),
                    ),
                    hint: const Text('Pilih Kategori'),
                    items: _kategoriList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedKategori = newValue;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInputField(
              _hargaController,
              'Harga Jual',
              Icons.sell_outlined,
              true,
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 95, 133, 218),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Tambah Produk',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isNumber,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            // Ikon dihapus dari sini
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 10,
            ),
            // Outline saat tidak ditekan
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            // Outline saat ditekan (Focus)
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color.fromARGB(255, 95, 133, 218),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
