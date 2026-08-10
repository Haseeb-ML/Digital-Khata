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
    final formatCurrency = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy');
    final timeFormatter = DateFormat('hh:mm a');

    // Create PDF page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MY KHATA',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      'Scrap & Rice Dealer',
                      style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('LEDGER STATEMENT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.SizedBox(height: 4),
                    pw.Text('Date: ${dateFormatter.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 12)),
                    pw.Text('Time: ${timeFormatter.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 20),

            // Client Details
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Billed To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    pw.Text(client.name, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    if (client.phone.isNotEmpty)
                      pw.Text('Phone: ${client.phone}', style: const pw.TextStyle(fontSize: 12)),
                    if (client.address != null && client.address!.isNotEmpty)
                      pw.Text('Address: ${client.address}', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
                // Summary Balance in Header
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: pw.BoxDecoration(
                    color: client.isReceivable ? PdfColors.green50 : PdfColors.red50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                    border: pw.Border.all(
                      color: client.isReceivable ? PdfColors.green200 : PdfColors.red200,
                      width: 2,
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Net Balance', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        formatCurrency.format(client.netBalance.abs()),
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: client.isReceivable ? PdfColors.green800 : PdfColors.red800,
                        ),
                      ),
                      pw.Text(
                        client.isReceivable ? '(RECEIVABLE)' : '(PAYABLE)',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: client.isReceivable ? PdfColors.green800 : PdfColors.red800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Transactions Table
            pw.Text('Transaction History', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Type', 'Details (Weight/Item)', 'Amount'],
              data: transactions.map((tx) {
                String itemDetails = '-';
                if (tx.isMaal && tx.weight != null && tx.unit != null && tx.itemCategory != null) {
                  itemDetails = '${tx.weight} ${tx.unit} ${tx.itemCategory}';
                }
                
                final isGave = tx.isGave;
                final sign = isGave ? '+' : '-';

                return [
                  tx.date != null ? DateFormat('dd MMM yyyy').format(tx.date!) : '-',
                  tx.type,
                  itemDetails,
                  '$sign ${formatCurrency.format(tx.amount)}',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
              ),
              cellHeight: 35,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
              },
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated by My Khata App', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
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
