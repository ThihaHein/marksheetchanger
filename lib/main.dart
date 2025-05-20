// main.dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Marks Statement Generator',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const MarkStatementGenerator(),
    );
  }
}

class MarkStatementGenerator extends StatefulWidget {
  const MarkStatementGenerator({Key? key}) : super(key: key);

  @override
  State<MarkStatementGenerator> createState() => _MarkStatementGeneratorState();
}

class _MarkStatementGeneratorState extends State<MarkStatementGenerator> {
  File? _csvFile;
  List<Map<String, dynamic>> _students = [];
  final _formKey = GlobalKey<FormState>();

  // Institution details
  final _institutionNameController = TextEditingController(text: 'Jamia Urdu Aligarh');
  final _examTitleController = TextEditingController(text: 'Adeeb-e-Mahir-Final Year - 2022');
  final _examSubtitleController = TextEditingController(text: '(Intermediate)');
  final _examVersionController = TextEditingController(text: 'English Version');
  DateTime? _selectedDate;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _institutionNameController.dispose();
    _examTitleController.dispose();
    _examSubtitleController.dispose();
    _examVersionController.dispose();
    super.dispose();
  }

  Future<void> _pickExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result != null) {
        setState(() {
          _csvFile = File(result.files.single.path!);
          _errorMessage = null;
        });
        _processCSVFile();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    }
  }

  Future<void> _processCSVFile() async {
    if (_csvFile == null) {
      setState(() {
        _errorMessage = 'No file selected';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final input = _csvFile!.openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(const CsvToListConverter())
          .toList();

      if (fields.isEmpty) {
        throw Exception('CSV file is empty');
      }

      final headers = fields.first.map((e) => e.toString()).toList();
      List<Map<String, dynamic>> students = [];

      for (var i = 1; i < fields.length; i++) {
        Map<String, dynamic> rowMap = {};
        for (var j = 0; j < headers.length; j++) {
          rowMap[headers[j]] = fields[i][j]?.toString() ?? '';
        }
        students.add(rowMap);
      }

      setState(() {
        _students = students;
        _isLoading = false;
      });

      if (_students.isEmpty) {
        setState(() {
          _errorMessage = 'No student data found in the CSV file';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing CSV file: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _generatePDF(Map<String, dynamic> student) async {
    final fontRegular = pw.Font.ttf(await rootBundle.load('assets/fonts/regular.ttf'));
    final fontBold = pw.Font.ttf(await rootBundle.load('assets/fonts/bold.ttf'));
    final symbol = pw.Font.ttf(await rootBundle.load('assets/fonts/symbol.ttf'));
    final imageBytes = await rootBundle.load('assets/images/background.png');
    final backgroundImage = pw.MemoryImage(imageBytes.buffer.asUint8List());



    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
      ),
    );

    // final fontData = File('assets/fonts/regular.ttf').readAsBytesSync();
    // final ttf = pw.Font.ttf(fontData.buffer.asByteData());
    // Load institution logo
    final bytesFromAsset = await rootBundle.load('assets/images/logo.png');
    final institutionLogo = bytesFromAsset.buffer.asUint8List();

    // Load stamp image
    final qrBytes = await rootBundle.load('assets/images/qr.jpg');
    final qrImage = qrBytes.buffer.asUint8List();

    // Load signature image
    final signatureBytes = await rootBundle.load('assets/images/signature.png');
    final signatureImage = signatureBytes.buffer.asUint8List();

    // Extract subjects and marks from student data
    List<Map<String, dynamic>> subjects = [];

    // In a real app, you'd map these from the Excel data
    // This is just an example based on the image provided
    subjects = [
      {
        'name': student['firstPaperName'],
        'paper': 'Ist Paper',
        'maxMarks': 100,
        'theoryMarks': student['firstPaperTheory'],
        'practMarks': student['firstPaperPract'],
        'grade': student['firstPaperGrade'],

      },
      {
        'name': student['secondPaperName'],
        'paper': 'IInd Paper',
        'maxMarks': 100,
        'theoryMarks': student['secondPaperTheory'],
        'practMarks': student['secondPaperPract'],
        'grade': student['secondPaperGrade'],
        'distinction': true,
      },
      {
        'name': student['thirdPaperName'],
        'paper': 'IIIrd Paper',
        'maxMarks': 100,
        'theoryMarks': student['thirdPaperTheory'],
        'practMarks': student['thirdPaperPract'],
        'grade': student['thirdPaperGrade'],
      },
      {
        'name': student['fourthPaperName'],
        'paper': 'IVth Paper',
        'maxMarks': 100,
        'theoryMarks': student['fourthPaperTheory'],
        'practMarks': student['fourthPaperPract'],
        'grade': student['fourthPaperGrade'],
      },
      {
        'name': student['fifthPaperName'],
        'paper': 'Vth Paper',
        'maxMarks': 100,
        'theoryMarks': student['fifthPaperTheory'],
        'practMarks': student['fifthPaperPract'],
        'grade': student['fifthPaperGrade'],
      },
      {
        'name': student['sixthPaperName'],
        'paper': 'VIth Paper',
        'maxMarks': 100,
        'theoryMarks': student['sixthPaperTheory'],
        'practMarks': student['sixthPaperPract'],
        'grade': student['sixthPaperGrade'],
      },
      {
        'name': student['optionalPaperName'],
        'paper': '(Optional)',
        'maxMarks': 100,
        'theoryMarks': student['optionalPaperTheory'],
        'practMarks': student['optionalPaperPract'],
        'grade': student['optionalPaperGrade'],
      },
    ];

    String theoryTotal = student['totalTheory'];  // Calculate from actual subjects
    String practTotal = student['totalPract'];    // Calculate from actual subjects
    String grandTotal = student['grandTotal'];   // theoryTotal + practTotal
    String result = student['result'];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a3,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.Opacity(opacity: 0.3,
                child:  pw.Image(
                  backgroundImage,
                  fit: pw.BoxFit.cover,
                ),)
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Image(pw.MemoryImage(institutionLogo), width: 60, height: 60),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      _institutionNameController.text.toUpperCase(),
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 20,
                      ),
                    ),
                    pw.Text(
                      'STATEMENT OF MARKS',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 12,
                      ),
                    ),
                    pw.Text(
                      _examTitleController.text,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 16,
                      ),
                    ),
                    pw.Text(
                      _examSubtitleController.text,
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 12,
                      ),
                    ),
                    pw.Text(
                      _examVersionController.text,
                      style: pw.TextStyle(
                        font: fontRegular, // italic
                        fontSize: 12,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Row(
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              children: [
                                pw.Text('S.No.', style: pw.TextStyle(font: fontBold,)),
                                pw.SizedBox(width: 30),
                                pw.Text(': ${student['serial'] ?? '220419321-2'}'),
                              ],
                            ),
                            pw.SizedBox(height: 5),
                            pw.Row(
                              children: [
                                pw.Text('Name', style: pw.TextStyle(font: fontBold,)),
                                pw.SizedBox(width: 20),
                                pw.Text(': ${student['name'] ?? 'Sanjib Kalita'}'),
                              ],
                            ),
                            pw.SizedBox(height: 5),
                            pw.Row(
                              children: [
                                pw.Text('Father\'s Name', style: pw.TextStyle(font: fontBold)),
                                pw.SizedBox(width: 5),
                                pw.Text(': ${student['fatherName'] ?? 'Dinesh Kalita'}'),
                              ],
                            ),
                          ],
                        ),
                        pw.Spacer(),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              children: [
                                pw.Text('Roll No.', style: pw.TextStyle(font: fontBold)),
                                pw.SizedBox(width: 30),
                                pw.Text(': ${student['rollNo'] ?? 'ADBM-F/2119'}'),
                              ],
                            ),
                            pw.SizedBox(height: 5),
                            pw.Row(
                              children: [
                                pw.Text('Enrollment No.:', style: pw.TextStyle(font: fontBold)),
                                pw.SizedBox(width: 10),
                                pw.Text('${student['enrollmentNo'] ?? '5712/W'}'),
                              ],
                            ),
                            pw.SizedBox(height: 5),
                            pw.Row(
                              children: [
                                pw.Text('Centre', style: pw.TextStyle(font: fontBold)),
                                pw.SizedBox(width: 30),
                                pw.Text(': ${student['center'] ?? 'JUA-947'}'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),

                    _createMarksTable(subjects, theoryTotal, practTotal, grandTotal, fontBold, fontRegular, result, symbol),
                    pw.SizedBox(height: 10),

                    pw.SizedBox(height: 10),
                    _createNotesSection(fontBold, fontRegular, symbol),
                    pw.Spacer(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text('Checked By'),
                            pw.Text('Date :- ${ DateFormat('dd / MMM / yyyy').format(_selectedDate!)}'),
                          ],
                        ),
                        pw.Image(pw.MemoryImage(qrImage), width: 50, height: 50),

                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text('Registrar Examinations'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
    print(subjects);
    // Save PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/${student['name']}_marks_statement.pdf');
    print("File Saved in ${file.path}");
    await file.writeAsBytes(await pdf.save());

    await OpenFile.open(file.path);

  }

  pw.Widget _createMarksTable(List<Map<String, dynamic>> subjects, String theoryTotal, String practTotal, String grandTotal, dynamic fontBold, dynamic fontRegular, String result, dynamic symbol) {

    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(0.8),
        6: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Code', style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Subject', style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Max. Marks', style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Min. Marks', style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Marks Pract.', style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Total Marks', style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Result', style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.center),
            ),
          ],
        ),
        // Subject rows
        ...subjects.map((subject) => pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(subject['paper'] ?? '', textAlign: pw.TextAlign.left),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(subject['name'] ?? '', textAlign: pw.TextAlign.left),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('${subject['maxMarks'] ?? ''}', textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('${subject['theoryMarks'] ?? ''}', textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('${subject['practMarks'] ?? ''}', textAlign: pw.TextAlign.center),
            ),

            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('${subject['grade'] ?? ''}', textAlign: pw.TextAlign.center),
            ), pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('$result', textAlign: pw.TextAlign.center),
            ),


          ],
        )),
        // Total row
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('TOTAL', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('', textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('600', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('$theoryTotal', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('$practTotal', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('', textAlign: pw.TextAlign.center),
            ),

            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('$result', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontBold)),
            ),
          ],
        ),
        // Grand total row
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('GRAND TOTAL', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('', textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('$grandTotal/600', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('', textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('', textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('', textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('', textAlign: pw.TextAlign.center),
            ),

          ],
        ),
      ],
    );
  }

  pw.Widget _createNotesSection(dynamic fontBold, dynamic fontRegular, dynamic symbol) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('NOTE :', style: pw.TextStyle(font: fontBold)),
        pw.Text('1. This Statement of Marks is issued for information purposes only and is not a certificate.', style:  pw.TextStyle(fontSize: 9, font: fontRegular, fontFallback: [symbol])),
        pw.Text('2. The total marks and percentage are calculated based on the marks obtained in all subjects listed above.', style: const pw.TextStyle(fontSize: 9)),
        pw.Text('3. Grades (if applicable) are assigned based on the following scale: \n A: 85 – 100% \nB: 70 – 84% \nC: 55 – 69% \nD: 40 – 54% \nF: Below 40% (Fail)', style: const pw.TextStyle(fontSize: 9)),
        pw.Text('4. Any correction or discrepancy in this statement must be reported to the examination cell within 7 working days.', style: const pw.TextStyle(fontSize: 9)),
        pw.Text('5. Tampering with this document is a punishable offense and renders the statement invalid.', style: const pw.TextStyle(fontSize: 9)),
        pw.Text('6. Passing marks in each subject are 40%.', style: const pw.TextStyle(fontSize: 9)),
        pw.Text('7. This document is valid only with the signature of the authorized officer and the institution seal.', style: const pw.TextStyle(fontSize: 9)),
        pw.Text('8. Electronic versions of this statement are valid only if downloaded from the official portal by paying fees.', style: const pw.TextStyle(fontSize: 9)),
        pw.Text('9. For online verification: verify@ jnanadeepuniversity.org / website: www. jnanadeepuniversity.org', style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text('Student Marks Statement Generator'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Title
              const Text(
                'Institution Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 12),

              // First Row
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      controller: _institutionNameController,
                      label: 'Institution Name',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      controller: _examTitleController,
                      label: 'Exam Title',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Second Row
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      controller: _examSubtitleController,
                      label: 'Exam Subtitle',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      controller: _examVersionController,
                      label: 'Exam Version',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _selectedDate == null
                            ? ''
                            : "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}",
                      ),
                      decoration: InputDecoration(
                        labelText: 'Select Checked Date',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          _selectedDate = picked;
                          // Call setState if inside a stateful widget
                          (context as Element).markNeedsBuild();
                        }
                      },
                    )
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // File Upload Section
              const Text(
                'Upload Student Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _pickExcelFile,
                    icon: const Icon(Icons.upload_file, color: Colors.white),
                    label: const Text(
                      'Select Excel File',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_csvFile != null)
                    Expanded(
                      child: Text(
                        'File: ${_csvFile!.path.split('/').last}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),

              // Student List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _students.isEmpty
                    ? const Center(
                  child: Text(
                    'No student data available. Please upload an Excel file.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(
                          student['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Roll No: ${student['rollNo'] ?? 'N/A'} | S.No: ${student['serial'] ?? 'N/A'}',
                        ),
                        trailing: FilledButton(
                          onPressed: () => _generatePDF(student),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.indigo.shade600,
                          ),
                          child: const Text('Generate'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }
}
Widget _buildInputField({
  required TextEditingController controller,
  required String label,
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.white,
    ),
  );
}
