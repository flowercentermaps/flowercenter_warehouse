import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart'
    show getTemporaryDirectory, getDownloadsDirectory;
import 'dart:io';
import '../../domain/entities/stock_check_item.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../services/warehouse_pdf_service.dart';
import '../../../pending_transfers/domain/entities/pending_quotation.dart'
    show DeliveryType;

class PdfPreviewScreen extends StatefulWidget {
  final int quotationId;
  final String quoteNo;
  final String salespersonName;
  final String customerName;
  final DeliveryType deliveryType;
  final List<StockCheckItem> items;

  const PdfPreviewScreen({
    super.key,
    required this.quotationId,
    this.quoteNo = '',
    this.salespersonName = '',
    this.customerName = '',
    this.deliveryType = DeliveryType.none,
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
      quoteNo: widget.quoteNo,
      salespersonName: widget.salespersonName,
      customerName: widget.customerName,
      deliveryType: widget.deliveryType,
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

  Future<void> _download(Uint8List bytes, AppLocalizations l) async {
    final dir      = await getDownloadsDirectory() ?? await getTemporaryDirectory();
    final fileName = 'stock_check_Q${widget.quotationId}.pdf';
    final file     = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l.btnDownload}: ${file.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l      = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.pdfTitle),
            Text(
              'Quotation #${widget.quotationId}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF8E8E93),
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdfFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFFD49D37),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.pdfGenerating,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_outlined,
                        size: 30,
                        color: Color(0xFFEF5350),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.pdfError,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${snap.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
            );
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
              Container(
                padding: EdgeInsets.fromLTRB(
                  16, 12, 16, 12 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141414) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _download(bytes, l),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text(l.btnDownload),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _share(bytes),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: Text(l.btnShare),
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
