import 'package:flutter/material.dart';

class DaftarProdukEdit extends StatelessWidget {
  final Map<String, dynamic> produk;
  const DaftarProdukEdit({super.key, required this.produk});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit ${produk['nama']}')),
      body: Center(child: Text('Halaman Edit untuk ID: ${produk['id_produk']}')),
    );
  }
}