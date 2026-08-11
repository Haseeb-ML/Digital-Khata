import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';

import '../models/client_model.dart';
import '../models/transaction_model.dart';

class PdfService {
  static Future<Uint8List> _buildPdf(Client client, List<TransactionModel> transactions) async {
    final pdf = pw.Document();
    final formatCurrency = NumberFormat('#,##0', 'en_US');
    final dateFormatter = DateFormat('dd MMM, yy');

    // Load Urdu-supporting font from Google Fonts
    final urduFont = await PdfGoogleFonts.notoNaskhArabicRegular();
    final urduFontBold = await PdfGoogleFonts.notoNaskhArabicBold();

    final customTheme = pw.ThemeData.withFont(
      base: urduFont,
      bold: urduFontBold,
    );

    // Sort transactions chronologically for running balance
    final chronologicalTx = List<TransactionModel>.from(transactions)
      ..sort((a, b) => (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

    String dateRange = '';
    if (chronologicalTx.isNotEmpty) {
      final firstDate = chronologicalTx.first.date ?? DateTime.now();
      final lastDate = chronologicalTx.last.date ?? DateTime.now();
      dateRange = '${dateFormatter.format(firstDate)} - ${dateFormatter.format(lastDate)}';
    } else {
      dateRange = dateFormatter.format(DateTime.now());
    }

    // Calculate Totals
    double totalDebit = 0;
    double totalCredit = 0;
    for (var tx in chronologicalTx) {
      if (tx.type == 'Sold Goods' || tx.type == 'Cash Given') {
        totalDebit += tx.amount;
      } else {
        totalCredit += tx.amount;
      }
    }
    double netBalance = totalCredit - totalDebit;
    String netBalanceText = netBalance >= 0 ? '${formatCurrency.format(netBalance.abs())}\nCredit (+)' : '${formatCurrency.format(netBalance.abs())}\nDebit (-)';
    PdfColor netBalanceColor = netBalance >= 0 ? PdfColors.green : PdfColors.red;

    // Generate Transaction Rows
    List<pw.Widget> transactionRows = [];
    double runningBal = 0;
    for (int i = 0; i < chronologicalTx.length; i++) {
      final tx = chronologicalTx[i];
      final isDebit = tx.type == 'Sold Goods' || tx.type == 'Cash Given';
      
      if (isDebit) {
        runningBal -= tx.amount;
      } else {
        runningBal += tx.amount;
      }

      String debitStr = isDebit ? formatCurrency.format(tx.amount) : '-';
      String creditStr = !isDebit ? formatCurrency.format(tx.amount) : '-';
      String balSign = runningBal >= 0 ? '(+)' : '(-)';
      
      String tafseel = tx.note ?? '';
      if (tx.isMaal && tx.weight != null && tx.unit != null && tx.itemCategory != null) {
        String itemDetails = '${tx.weight} ${tx.unit} ${tx.itemCategory}';
        tafseel = tafseel.isNotEmpty ? '$itemDetails\n$tafseel' : itemDetails;
      }
      
      // If no note was added, leave it empty (removed transaction type fallback as requested)

      transactionRows.add(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 2, child: pw.Text(tx.date != null ? dateFormatter.format(tx.date!) : '-', style: pw.TextStyle(font: urduFont))),
              pw.Expanded(flex: 3, child: pw.Text(tafseel, style: pw.TextStyle(font: urduFont), textDirection: pw.TextDirection.rtl)),
              pw.Expanded(flex: 2, child: pw.Text(debitStr, textAlign: pw.TextAlign.right, style: pw.TextStyle(font: urduFont))),
              pw.Expanded(flex: 2, child: pw.Text(creditStr, textAlign: pw.TextAlign.right, style: pw.TextStyle(font: urduFont))),
              pw.Expanded(
                flex: 3, 
                child: pw.Text(
                  '${formatCurrency.format(runningBal.abs())} $balSign', 
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(color: runningBal >= 0 ? PdfColors.green : PdfColors.red, font: urduFont)
                )
              ),
            ],
          ),
        )
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: customTheme,
        build: (pw.Context context) {
          return [
            // Top Header (App/Business Name)
            pw.Text(
              'Shah Traders',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
            ),
            pw.SizedBox(height: 20),

            // Client Info & Statement Header
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              color: PdfColors.grey50,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Statement ${client.name}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  if (client.phone.isNotEmpty) pw.Text(client.phone, style: const pw.TextStyle(fontSize: 12)),
                  pw.Text(dateRange, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Total Debit', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                          pw.Text('Rs ${formatCurrency.format(totalDebit)}', style: pw.TextStyle(fontSize: 14)),
                        ],
                      ),
                      pw.Container(width: 1, height: 30, color: PdfColors.grey300),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Total Credit', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                          pw.Text('Rs ${formatCurrency.format(totalCredit)}', style: pw.TextStyle(fontSize: 14)),
                        ],
                      ),
                      pw.Container(width: 1, height: 30, color: PdfColors.grey300),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Net Balance', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                          pw.Text(netBalanceText, style: pw.TextStyle(fontSize: 12, color: netBalanceColor)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Transactions Table Header
            pw.Row(
              children: [
                pw.Expanded(flex: 2, child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Expanded(flex: 3, child: pw.Text('Tafseel', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Expanded(flex: 2, child: pw.Text('Debit (-)', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Expanded(flex: 2, child: pw.Text('Credit (+)', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Expanded(flex: 3, child: pw.Text('Balance', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.grey300),

            // Insert all rows here seamlessly
            ...transactionRows,
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> generateAndShareInvoice(Client client, List<TransactionModel> transactions) async {
    final bytes = await _buildPdf(client, transactions);
    await Printing.sharePdf(bytes: bytes, filename: 'invoice_${client.name.replaceAll(' ', '_')}.pdf');
  }

  static Future<void> generateAndPrintInvoice(Client client, List<TransactionModel> transactions) async {
    final bytes = await _buildPdf(client, transactions);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'invoice_${client.name.replaceAll(' ', '_')}.pdf'
    );
  }
}
