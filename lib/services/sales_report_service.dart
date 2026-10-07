import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/sale_order.dart';
import '../models/sales_analytics.dart';

class SalesReportService {
  const SalesReportService();

  Future<void> printPdfReport({
    required List<SaleOrder> orders,
    required double totalCost,
    required double grossProfit,
    required bool hasIncompleteCostData,
    required List<ProductSales> topProducts,
    required String periodLabel,
    required String fileName,
  }) async {
    final document = pw.Document();
    final total = orders.fold<int>(
      0,
      (revenueTotal, order) => revenueTotal + order.total,
    );
    final itemCount = orders.fold<int>(
      0,
      (itemsTotal, order) => itemsTotal + order.itemCount,
    );
    final now = DateTime.now();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'GearTrack Sales Report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '$periodLabel report - Generated '
            '${now.year}-${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}',
          ),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: ['Summary', 'Value'],
            data: [
              ['Transactions', '${orders.length}'],
              ['Items sold', '$itemCount'],
              ['Sales total', 'PHP $total'],
              ['Batch cost', 'PHP ${totalCost.round()}'],
              [
                'Gross profit (sales - cost)',
                '${hasIncompleteCostData ? 'Partial · ' : ''}PHP ${grossProfit.round()}',
              ],
              if (hasIncompleteCostData)
                ['Note', 'Orders without batch-cost records are excluded from profit.'],
              [
                'Average sale',
                'PHP ${orders.isEmpty ? 0 : total ~/ orders.length}',
              ],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFFEDD5),
            ),
            cellPadding: const pw.EdgeInsets.all(7),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Top-selling products (by units sold)',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Rank', 'Product', 'Units', 'Sales (PHP)'],
            data: [
              for (var index = 0; index < topProducts.length; index++)
                [
                  '${index + 1}',
                  topProducts[index].name,
                  '${topProducts[index].quantity}',
                  '${topProducts[index].revenue}',
                ],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFFEDD5),
            ),
            cellPadding: const pw.EdgeInsets.all(6),
          ),
          pw.SizedBox(height: 22),
          pw.Text(
            'Transactions',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Order', 'Date', 'Payment', 'Items', 'Total (PHP)'],
            data: [
              for (final order in orders)
                [
                  '#${_shortOrderId(order.id)}',
                  _dateTimeLabel(order.createdAt),
                  order.paymentMethod,
                  '${order.itemCount}',
                  order.total.toString(),
                ],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF1E293B),
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.all(6),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: fileName,
      onLayout: (_) => document.save(),
    );
  }

  String _shortOrderId(String id) => id.substring(0, id.length.clamp(0, 6));

  String _dateTimeLabel(DateTime? date) => date == null
      ? 'Date unavailable'
      : '${date.month}/${date.day}/${date.year} '
            '${date.hour.toString().padLeft(2, '0')}:'
            '${date.minute.toString().padLeft(2, '0')}';
}
