import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../features/stock_check/domain/entities/check_status.dart';
import '../features/stock_check/domain/entities/stock_check_item.dart';

class WarehousePdfService {
  static Future<Uint8List> generate({
    required int quotationId,
    required List<StockCheckItem> items,
  }) async {
    final pdf      = pw.Document();
    final dateFmt  = DateFormat('dd/MM/yyyy HH:mm');
    final now      = dateFmt.format(DateTime.now());
    final qtyFmt   = NumberFormat('#,##0.##');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _buildHeader(quotationId, now, ctx),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          _buildTable(items, qtyFmt),
          pw.SizedBox(height: 20),
          _buildSummary(items),
        ],
      ),
    );

    return pdf.save();
  }

  // ── Header ───────────────────────────────────────────────────────────────

  static pw.Widget _buildHeader(int id, String date, pw.Context ctx) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Flower Center',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('D49D37'),
                  ),
                ),
                pw.Text(
                  'Stock Transfer Verification',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Quotation #$id',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Generated: $date',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(color: PdfColor.fromHex('D49D37'), thickness: 1.5),
      ],
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────

  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Flower Center — Confidential',
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey500)),
        pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey500)),
      ],
    );
  }

  // ── Table ─────────────────────────────────────────────────────────────────

  static pw.Widget _buildTable(
      List<StockCheckItem> items, NumberFormat qtyFmt) {
    const headers = [
      '#',
      'Item',
      'Code',
      'Qty Needed',
      'Status',
      'Qty Avail.',
      'Location',
      'Notes',
    ];

    final headerStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 9,
      color: PdfColors.white,
    );

    final cellStyle = const pw.TextStyle(fontSize: 9);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(22),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(48),
        4: const pw.FixedColumnWidth(56),
        5: const pw.FixedColumnWidth(48),
        6: const pw.FlexColumnWidth(2),
        7: const pw.FlexColumnWidth(3),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey800),
          children: headers.map((h) => _cell(h, headerStyle)).toList(),
        ),
        // Data rows
        ...items.asMap().entries.map((e) {
          final i    = e.key;
          final item = e.value;
          final statusLabel = _statusLabel(item.status);
          final statusColor = _statusColor(item.status);
          final qtyAvail = item.quantityAvailable != null
              ? qtyFmt.format(item.quantityAvailable)
              : '—';
          final notes = _notes(item);

          final bg = i.isOdd ? PdfColors.grey100 : PdfColors.white;

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              _cell('${i + 1}', cellStyle),
              _cell(item.productName, cellStyle),
              _cell(item.itemCode, cellStyle),
              _cell(qtyFmt.format(item.quantityNeeded), cellStyle, center: true),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    color: PdfColor(statusColor.red, statusColor.green, statusColor.blue, 0.15),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  child: pw.Text(
                    statusLabel,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: statusColor,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ),
              _cell(qtyAvail, cellStyle, center: true),
              _cell(item.warehouseLocation ?? '—', cellStyle),
              _cell(notes, cellStyle),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _cell(String text, pw.TextStyle style,
      {bool center = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        style: style,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  // ── Summary ───────────────────────────────────────────────────────────────

  static pw.Widget _buildSummary(List<StockCheckItem> items) {
    final available  = items.where((i) => i.status == CheckStatus.available).length;
    final partial    = items.where((i) => i.status == CheckStatus.partial).length;
    final outOfStock = items.where((i) => i.status == CheckStatus.outOfStock).length;
    final pending    = items.where((i) => i.status == CheckStatus.pending).length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Summary',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              _summaryItem('Total Items',  '${items.length}',   PdfColors.grey700),
              _summaryItem('Available',    '$available',         PdfColor.fromHex('4CAF50')),
              _summaryItem('Partial',      '$partial',           PdfColor.fromHex('FF9800')),
              _summaryItem('Out of Stock', '$outOfStock',        PdfColor.fromHex('EF5350')),
              if (pending > 0)
                _summaryItem('Pending', '$pending', PdfColors.grey600),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryItem(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: color)),
          pw.Text(label,
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _statusLabel(CheckStatus s) => switch (s) {
        CheckStatus.available   => 'Available',
        CheckStatus.partial     => 'Partial',
        CheckStatus.outOfStock  => 'Out of Stock',
        CheckStatus.pending     => 'Pending',
      };

  static PdfColor _statusColor(CheckStatus s) => switch (s) {
        CheckStatus.available   => PdfColor.fromHex('4CAF50'),
        CheckStatus.partial     => PdfColor.fromHex('FF9800'),
        CheckStatus.outOfStock  => PdfColor.fromHex('EF5350'),
        CheckStatus.pending     => PdfColors.grey600,
      };

  static String _notes(StockCheckItem item) {
    final parts = <String>[];
    if (item.shortageReason?.isNotEmpty == true) {
      parts.add('Reason: ${item.shortageReason}');
    }
    if (item.suggestion?.isNotEmpty == true) {
      parts.add('Suggestion: ${item.suggestion}');
    }
    return parts.join(' | ');
  }
}
