import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../features/stock_check/domain/entities/check_status.dart';
import '../features/stock_check/domain/entities/stock_check_item.dart';
import '../features/pending_transfers/domain/entities/pending_quotation.dart'
    show DeliveryType;

class WarehousePdfService {
  static Future<Uint8List> generate({
    required int quotationId,
    required List<StockCheckItem> items,
    String quoteNo = '',
    String salespersonName = '',
    String customerName = '',
    DeliveryType deliveryType = DeliveryType.none,
  }) async {
    // Load fonts + download images in parallel
    final results = await Future.wait([
      rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
      rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
      _downloadImages(items),
    ]);

    final regular      = pw.Font.ttf(results[0] as ByteData);
    final bold         = pw.Font.ttf(results[1] as ByteData);
    final imageMap     = results[2] as Map<String, Uint8List>;

    final pdf     = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final now     = dateFmt.format(DateTime.now());
    final qtyFmt  = NumberFormat('#,##0.##');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _buildHeader(
          quotationId, quoteNo, customerName, salespersonName,
          deliveryType, now, regular, bold),
        footer: (ctx) => _buildFooter(ctx, regular),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          _buildLegend(regular, bold),
          pw.SizedBox(height: 10),
          _buildTable(items, qtyFmt, regular, bold, imageMap),
          pw.SizedBox(height: 20),
          _buildSummary(items, regular, bold),
        ],
      ),
    );

    return pdf.save();
  }

  // ── Image download ────────────────────────────────────────────────────────

  /// Downloads all item images concurrently. Silently skips failures.
  static Future<Map<String, Uint8List>> _downloadImages(
      List<StockCheckItem> items) async {
    final result = <String, Uint8List>{};
    await Future.wait(items.map((item) async {
      final url = item.imageUrl;
      if (url == null || url.isEmpty) return;
      try {
        final client  = HttpClient()
          ..connectionTimeout = const Duration(seconds: 6);
        final request  = await client.getUrl(Uri.parse(url));
        final response = await request.close()
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final builder = BytesBuilder();
          await for (final chunk in response) {
            builder.add(chunk);
          }
          result[url] = builder.toBytes();
        }
        client.close();
      } catch (_) {
        // Non-fatal: item will show a placeholder box in the PDF.
      }
    }));
    return result;
  }

  // ── Drawn symbols (no font glyph dependency) ─────────────────────────────

  static pw.Widget _checkmarkWidget(double size) {
    return pw.SizedBox(
      width: size,
      height: size,
      child: pw.CustomPaint(
        painter: (canvas, s) {
          canvas
            ..setStrokeColor(PdfColors.black)
            ..setLineWidth(size * 0.12)
            ..moveTo(s.x * 0.12, s.y * 0.45)
            ..lineTo(s.x * 0.40, s.y * 0.18)
            ..lineTo(s.x * 0.88, s.y * 0.78)
            ..strokePath();
        },
      ),
    );
  }

  static pw.Widget _crossWidget(double size) {
    return pw.SizedBox(
      width: size,
      height: size,
      child: pw.CustomPaint(
        painter: (canvas, s) {
          canvas
            ..setStrokeColor(PdfColors.black)
            ..setLineWidth(size * 0.13)
            ..moveTo(s.x * 0.15, s.y * 0.85)
            ..lineTo(s.x * 0.85, s.y * 0.15)
            ..strokePath()
            ..moveTo(s.x * 0.85, s.y * 0.85)
            ..lineTo(s.x * 0.15, s.y * 0.15)
            ..strokePath();
        },
      ),
    );
  }

  static pw.Widget _symbolWidget(CheckStatus s, double size, pw.Font regular) {
    return switch (s) {
      CheckStatus.available  => _checkmarkWidget(size),
      CheckStatus.outOfStock => _crossWidget(size),
      CheckStatus.partial    => pw.Text('~', style: pw.TextStyle(font: regular, fontSize: size)),
      CheckStatus.pending    => pw.Text('-', style: pw.TextStyle(font: regular, fontSize: size)),
    };
  }

  // ── Header ───────────────────────────────────────────────────────────────

  static pw.Widget _buildHeader(
    int id,
    String quoteNo,
    String customerName,
    String salespersonName,
    DeliveryType deliveryType,
    String date,
    pw.Font regular,
    pw.Font bold,
  ) {
    final muted = pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700);

    // Delivery badge colours
    final (deliveryBg, deliveryFg) = switch (deliveryType) {
      DeliveryType.inside  => (PdfColors.blue100, PdfColors.blue800),
      DeliveryType.outside => (PdfColors.orange100, PdfColors.orange800),
      DeliveryType.none    => (PdfColors.grey200, PdfColors.grey700),
    };

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Left: branding + customer
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Flower Center',
                    style: pw.TextStyle(font: bold, fontSize: 20)),
                pw.Text('Stock Transfer Verification', style: muted),
                if (customerName.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3),
                    child: pw.Text(customerName,
                        style: pw.TextStyle(font: bold, fontSize: 11)),
                  ),
              ],
            ),
            // Right: quote meta + delivery badge
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(quoteNo.isNotEmpty ? quoteNo : 'Quotation #$id',
                    style: pw.TextStyle(font: bold, fontSize: 13)),
                pw.Text('Generated: $date', style: muted),
                if (salespersonName.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3),
                    child: pw.Text('Sales: $salespersonName', style: muted),
                  ),
                pw.SizedBox(height: 5),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: deliveryBg,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    deliveryType.label,
                    style: pw.TextStyle(
                        font: bold, fontSize: 9, color: deliveryFg),
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(color: PdfColors.black, thickness: 1.5),
      ],
    );
  }

  // ── Legend ────────────────────────────────────────────────────────────────

  static pw.Widget _buildLegend(pw.Font regular, pw.Font bold) {
    const symSize = 8.0;
    final entries = [
      (CheckStatus.available,  'Available'),
      (CheckStatus.partial,    'Partial'),
      (CheckStatus.outOfStock, 'Out of Stock'),
      (CheckStatus.pending,    'Pending'),
    ];

    return pw.Row(
      children: [
        pw.Text('Legend: ', style: pw.TextStyle(font: bold, fontSize: 8)),
        pw.SizedBox(width: 4),
        ...entries.map((e) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              margin: const pw.EdgeInsets.only(right: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 0.8),
              ),
              child: pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  _symbolWidget(e.$1, symSize, regular),
                  pw.SizedBox(width: 4),
                  pw.Text(e.$2,
                      style: pw.TextStyle(font: regular, fontSize: 8)),
                ],
              ),
            )),
      ],
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────

  static pw.Widget _buildFooter(pw.Context ctx, pw.Font regular) {
    final style =
        pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.grey600);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Flower Center — Confidential', style: style),
        pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: style),
      ],
    );
  }

  // ── Table ─────────────────────────────────────────────────────────────────

  static pw.Widget _buildTable(
    List<StockCheckItem> items,
    NumberFormat qtyFmt,
    pw.Font regular,
    pw.Font bold,
    Map<String, Uint8List> imageMap,
  ) {
    const headers = [
      '#', 'Photo', 'Code', 'Needed', 'Status', 'Avail.', 'Location', 'Notes',
    ];

    final headerStyle =
        pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white);
    final cellStyle = pw.TextStyle(font: regular, fontSize: 9);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(18),   // #
        1: const pw.FixedColumnWidth(42),   // Photo
        2: const pw.FlexColumnWidth(3),     // Code
        3: const pw.FixedColumnWidth(42),   // Needed
        4: const pw.FixedColumnWidth(70),   // Status
        5: const pw.FixedColumnWidth(34),   // Avail.
        6: const pw.FlexColumnWidth(2),     // Location
        7: const pw.FlexColumnWidth(3),     // Notes
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.black),
          children: headers.map((h) => _cell(h, headerStyle)).toList(),
        ),
        // Data rows
        ...items.asMap().entries.map((e) {
          final i    = e.key;
          final item = e.value;
          final label  = _statusLabel(item.status);
          final isOos  = item.status == CheckStatus.outOfStock;
          final qtyAvail = item.quantityAvailable != null
              ? qtyFmt.format(item.quantityAvailable)
              : '-';
          final imgBytes =
              item.imageUrl != null ? imageMap[item.imageUrl] : null;
          final bg = i.isOdd ? PdfColors.grey100 : PdfColors.white;

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              // #
              _cell('${i + 1}', cellStyle),
              // Photo — 40×40 thumbnail or placeholder
              pw.Padding(
                padding: const pw.EdgeInsets.all(2),
                child: imgBytes != null
                    ? pw.Image(
                        pw.MemoryImage(imgBytes),
                        width: 40,
                        height: 40,
                        fit: pw.BoxFit.contain,
                      )
                    : pw.Container(
                        width: 40,
                        height: 40,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          border: pw.Border.all(
                              color: PdfColors.grey300, width: 0.5),
                        ),
                        child: pw.Center(
                          child: pw.Text('—',
                              style: pw.TextStyle(
                                  font: regular,
                                  fontSize: 10,
                                  color: PdfColors.grey500)),
                        ),
                      ),
              ),
              // Code
              _cell(item.itemCode, cellStyle),
              // Qty Needed
              _cell(qtyFmt.format(item.quantityNeeded), cellStyle,
                  center: true),
              // Status
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border:
                        pw.Border.all(color: PdfColors.black, width: 0.8),
                  ),
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 4, vertical: 3),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      _symbolWidget(item.status, 8, regular),
                      pw.SizedBox(width: 3),
                      pw.Flexible(
                        child: pw.Text(
                          label,
                          style: pw.TextStyle(
                            font: isOos ? bold : regular,
                            fontSize: 8,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Qty Avail.
              _cell(qtyAvail, cellStyle, center: true),
              // Location
              _cell(item.warehouseLocation ?? '-', cellStyle),
              // Notes
              _cell(_notes(item), cellStyle),
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

  static pw.Widget _buildSummary(
      List<StockCheckItem> items, pw.Font regular, pw.Font bold) {
    final available  =
        items.where((i) => i.status == CheckStatus.available).length;
    final partial    =
        items.where((i) => i.status == CheckStatus.partial).length;
    final outOfStock =
        items.where((i) => i.status == CheckStatus.outOfStock).length;
    final pending    =
        items.where((i) => i.status == CheckStatus.pending).length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Summary', style: pw.TextStyle(font: bold, fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _summaryItem('Total Items', '${items.length}',
                  null, regular, bold, emphasise: false),
              _summaryItem('Available', '$available',
                  CheckStatus.available, regular, bold, emphasise: false),
              _summaryItem('Partial', '$partial',
                  CheckStatus.partial, regular, bold, emphasise: true),
              _summaryItem('Out of Stock', '$outOfStock',
                  CheckStatus.outOfStock, regular, bold, emphasise: true),
              if (pending > 0)
                _summaryItem('Pending', '$pending',
                    CheckStatus.pending, regular, bold, emphasise: false),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryItem(
    String label,
    String value,
    CheckStatus? status,
    pw.Font regular,
    pw.Font bold, {
    required bool emphasise,
  }) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          if (status != null) ...[
            _symbolWidget(status, 14, regular),
            pw.SizedBox(height: 2),
          ],
          pw.Text(value,
              style: pw.TextStyle(
                font: emphasise ? bold : regular,
                fontSize: 18,
              )),
          pw.Text(label,
              style: pw.TextStyle(
                  font: regular, fontSize: 8, color: PdfColors.grey700),
              textAlign: pw.TextAlign.center),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _statusLabel(CheckStatus s) => switch (s) {
        CheckStatus.available  => 'Available',
        CheckStatus.partial    => 'Partial',
        CheckStatus.outOfStock => 'Out of Stock',
        CheckStatus.pending    => 'Pending',
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
