import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart'
    show getTemporaryDirectory, getDownloadsDirectory;
import 'dart:io';
import '../../domain/entities/stock_check_item.dart';
import '../../../../services/warehouse_pdf_service.dart';

class PdfPreviewScreen extends StatefulWidget {
  final int quotationId;
  final List<StockCheckItem> items;

  const PdfPreviewScreen({
    super.key,
    required this.quotationId,
    required this.items,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  late Future<Uint8List> _pdfFuture;

  @override
  void initState() {
    super.initState();
    _pdfFuture = WarehousePdfService.generate(
      quotationId: widget.quotationId,
      items: widget.items,
    );
  }

  Future<void> _share(Uint8List bytes) async {
    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/stock_check_Q${widget.quotationId}.pdf');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        text: 'Stock Check — Quotation #${widget.quotationId}',
      ),
    );
  }

  Future<void> _download(Uint8List bytes) async {
    final dir = await getDownloadsDirectory() ?? await getTemporaryDirectory();
    final fileName = 'stock_check_Q${widget.quotationId}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to ${file.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Stock Check PDF — #${widget.quotationId}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdfFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('PDF error: ${snap.error}'));
          }
          final bytes = snap.data!;
          return Column(
            children: [
              Expanded(
                child: PdfPreview(
                  build: (_) async => bytes,
                  allowSharing: false,
                  allowPrinting: true,
                  canChangePageFormat: false,
                  canDebug: false,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    16, 8, 16, 12 + MediaQuery.of(context).padding.bottom),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _download(bytes),
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Download PDF'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blueGrey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _share(bytes),
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Share'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
