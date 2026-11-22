import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Test PdfGoogleFonts and font fallback', () async {
    final font = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final pdf = pw.Document(theme: pw.ThemeData.withFont(base: font, bold: bold));
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Text('Test with bullet • and unicode ₹ 500 — worked!'),
      ),
    );
    final bytes = await pdf.save();
    expect(bytes.isNotEmpty, true);
  });
}
