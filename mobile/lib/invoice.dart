import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'domain.dart';
import 'ui.dart';

String pdfMoney(num value) => money(value).replaceAll('₹', 'INR ');
String pdfText(String value) => value.replaceAll(RegExp(r'[^\x20-\x7E]'), ' ');

Future<pw.ImageProvider?> _invoiceImage(String source) async {
  if (source.isEmpty) return null;
  try {
    late Uint8List bytes;
    if (source.startsWith('data:image/')) {
      final separator = source.indexOf(',');
      if (separator < 0) return null;
      bytes = base64Decode(source.substring(separator + 1));
    } else if (source.startsWith('assets/')) {
      final data = await rootBundle.load(source);
      bytes = data.buffer.asUint8List();
    } else {
      final uri = Uri.tryParse(source);
      if (uri == null ||
          uri.scheme != 'https' ||
          !uri.host.endsWith('.supabase.co')) {
        return null;
      }
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200 || response.bodyBytes.length > (5 << 20)) {
        return null;
      }
      bytes = response.bodyBytes;
    }
    return pw.MemoryImage(bytes);
  } catch (_) {
    return null;
  }
}

Future<Uint8List> invoiceBytes(Sale sale) async {
  final doc = pw.Document();
  final images = await Future.wait([
    _invoiceImage(sale.vehicleImage),
    _invoiceImage(sale.customerImage),
  ]);
  final vehicleImage = images[0], customerImage = images[1];
  final unitPrice = sale.unitPrice > 0
      ? sale.unitPrice
      : sale.quantity > 0
      ? (sale.subtotal - sale.extras - sale.repairCost) / sale.quantity
      : 0;
  final vehicleAmount = rounded(unitPrice * sale.quantity);
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(38),
      build: (_) => [
        pw.Text(
          'MotorStock',
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'PROVISIONAL INVOICE - VERIFY TAX DETAILS',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.Divider(),
        pw.Text(sale.id),
        pw.Text('Date: ${dateLabel(sale.date)}'),
        pw.Text('Showroom: ${pdfText(sale.branch)}'),
        if (vehicleImage != null) ...[
          pw.SizedBox(height: 14),
          pw.Container(
            height: 115,
            alignment: pw.Alignment.centerLeft,
            child: pw.Image(vehicleImage, fit: pw.BoxFit.contain),
          ),
        ],
        pw.SizedBox(height: 20),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'BILL TO',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(pdfText(sale.customer)),
                  pw.Text(sale.phone),
                  pw.Text(pdfText(sale.address)),
                ],
              ),
            ),
            if (customerImage != null) ...[
              pw.SizedBox(width: 18),
              pw.Container(
                width: 82,
                height: 82,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                padding: const pw.EdgeInsets.all(3),
                child: pw.ClipRRect(
                  horizontalRadius: 6,
                  verticalRadius: 6,
                  child: pw.Image(customerImage, fit: pw.BoxFit.cover),
                ),
              ),
            ],
          ],
        ),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headers: ['Motorcycle', 'Quantity', 'Unit price', 'Vehicle amount'],
          data: [
            [
              pdfText(sale.bike),
              '${sale.quantity}',
              pdfMoney(unitPrice),
              pdfMoney(vehicleAmount),
            ],
          ],
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
          cellPadding: const pw.EdgeInsets.all(10),
        ),
        pw.SizedBox(height: 20),
        ...[
          ('Registration / insurance / extras', sale.extras),
          ('Repair cost', sale.repairCost),
          ('Subtotal', sale.subtotal),
          ('Discount', sale.discount),
          ('GST (${sale.taxRate.toStringAsFixed(2)}%)', sale.tax),
          ('Total', sale.total),
          ('Amount received', sale.paid),
          ('Balance payable', sale.balance),
        ].map(
          (row) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 5),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [pw.Text(row.$1), pw.Text(pdfMoney(row.$2))],
            ),
          ),
        ),
        pw.Divider(),
        pw.Text('Payment method: ${pdfText(sale.mode)}'),
        pw.Text('Status: ${pdfText(sale.status)}'),
        pw.Text('Executive: ${pdfText(sale.employee)}'),
        if (sale.finance)
          pw.Text(
            'Estimated EMI: ${pdfMoney(sale.installment)} / month for ${sale.months} months',
          ),
        pw.SizedBox(height: 30),
        pw.Text(
          'Generated by MotorStock Mobile. Verify statutory and tax details before accounting use.',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    ),
  );
  return doc.save();
}

Future<void> viewInvoice(BuildContext context, Sale sale) async {
  final data = await invoiceBytes(sale);
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Invoice preview')),
        body: PdfPreview(
          build: (_) => data,
          pdfFileName: '${sale.id}.pdf',
          canChangePageFormat: false,
          canChangeOrientation: false,
          allowPrinting: true,
          allowSharing: true,
        ),
      ),
    ),
  );
}

Future<void> shareInvoice(BuildContext context, Sale sale) async {
  try {
    await Printing.sharePdf(
      bytes: await invoiceBytes(sale),
      filename: '${sale.id}.pdf',
    );
  } catch (e) {
    if (context.mounted) notice(context, 'Unable to share PDF: $e');
  }
}

Future<void> exportLedger(BuildContext context, List<Sale> sales) async {
  try {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (_) => [
          pw.Text(
            'MotorStock - Sales ledger',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: [
              'Invoice',
              'Customer',
              'Motorcycle',
              'Total',
              'Paid',
              'Balance',
              'Status',
            ],
            data: sales
                .map(
                  (s) => [
                    s.id,
                    pdfText(s.customer),
                    pdfText(s.bike),
                    pdfMoney(s.total),
                    pdfMoney(s.paid),
                    pdfMoney(s.balance),
                    s.status,
                  ],
                )
                .toList(),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'motorstock-sales-ledger.pdf',
    );
  } catch (e) {
    if (context.mounted) notice(context, 'Unable to export: $e');
  }
}
