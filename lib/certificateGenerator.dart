import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'dart:typed_data';


class CertificateGenerator extends StatefulWidget {
  @override
  _CertificateGeneratorState createState() => _CertificateGeneratorState();
}

class _CertificateGeneratorState extends State<CertificateGenerator> {
  List<Map<String, dynamic>> csvData = [];
  bool isLoading = false;

  Future<void> pickCSVFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        setState(() {
          isLoading = true;
        });

        File file = File(result.files.single.path!);
        String csvString = await file.readAsString();

        List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);

        if (csvTable.isNotEmpty) {
          List<String> headers = csvTable[0].map((e) => e.toString().toLowerCase().trim()).toList();

          csvData = [];
          for (int i = 1; i < csvTable.length; i++) {
            Map<String, dynamic> row = {};
            for (int j = 0; j < headers.length && j < csvTable[i].length; j++) {
              row[headers[j]] = csvTable[i][j].toString();
            }
            csvData.add(row);
          }
        }

        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV file loaded successfully! ${csvData.length} records found.')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading CSV file: $e')),
      );
    }
  }
  Future<Uint8List> fetchImageBytes(String shareUrl) async {
    // Extract file ID and convert to direct download URL
    RegExp regExp = RegExp(r'/file/d/([a-zA-Z0-9-_]+)');
    Match? match = regExp.firstMatch(shareUrl);

    if (match != null) {
      String fileId = match.group(1)!;
      print(shareUrl);
      print(fileId);
      final downloadUrl = 'https://drive.google.com/uc?export=download&id=$fileId';

      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download image');
      }
    } else {
      throw Exception('Invalid Google Drive link');
    }
  }



  Future<pw.Document> generateCertificatePDF(Map<String, dynamic> data) async {

    final fontRegular = pw.Font.ttf(await rootBundle.load('assets/fonts/Cinzel-Regular.ttf'));
    final fontBold = pw.Font.ttf(await rootBundle.load('assets/fonts/Cinzel-Bold.ttf'));

    final bytesFromAsset = await rootBundle.load('assets/images/logo.png');
    final institutionLogo = bytesFromAsset.buffer.asUint8List();

    final imageBytes = await rootBundle.load('assets/images/background.png');
    final backgroundImage = pw.MemoryImage(imageBytes.buffer.asUint8List());

    final barcodeBytes = await rootBundle.load('assets/images/barcode.png');
    final barcodeImage = pw.MemoryImage(barcodeBytes.buffer.asUint8List());

    final signatureBytes = await rootBundle.load('assets/images/certificateSignature.png');
    final signatureImage = pw.MemoryImage(signatureBytes.buffer.asUint8List());

    final Uint8List studetnImageBytes = await fetchImageBytes(data['photo']);
    final pw.MemoryImage studentImage = pw.MemoryImage(studetnImageBytes.buffer.asUint8List());


    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
      ),
    );
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return

          pw.Container(
          width: double.infinity,
            height: double.infinity,
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
                colors: [
                  PdfColor.fromHex('#FFC0CB'), // Cornsilk
                  PdfColor.fromHex('#F5F5DC'), // Beige
                  PdfColor.fromHex('#E6E6FA'), // Lavender
                  PdfColor.fromHex('#F0F8FF'), // Alice Blue
                  PdfColor.fromHex('#F0F8FF'), // Alice Blue
                  PdfColor.fromHex('#FFC0CB'), // Cornsilk
                ],
                stops: [0.0, 0.2, 0.3, 0.7, 0.9, 1.0],
              ),
            ),
            child: pw.Stack(
              children: [
                pw.Positioned.fill(
                    child: pw.Opacity(opacity: 0.3,
                      child:  pw.Image(
                        backgroundImage,
                        fit: pw.BoxFit.cover,
                      ),)
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.all(30),
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColor.fromHex('#DAA520'), width: 4),
                    ),
                    child: pw.Stack(
                      children: [
                        // Corner decorations
                        pw.Positioned(
                          top: 0,
                          left: 0,
                          child: _buildCornerDecoration(),
                        ),
                        pw.Positioned(
                          top: 0,
                          right: 0,
                          child: pw.Transform.rotate(
                            angle: -1.5708, // 90 degrees
                            child: _buildCornerDecoration(),
                          ),
                        ),
                        pw.Positioned(
                          bottom: 0,
                          left: 0,
                          child: pw.Transform.rotate(
                            angle: 1.5708, // -90 degrees
                            child: _buildCornerDecoration(),
                          ),
                        ),
                        pw.Positioned(
                          bottom: 0,
                          right: 0,
                          child: pw.Transform.rotate(
                            angle: 3.14159, // 180 degrees
                            child: _buildCornerDecoration(),
                          ),
                        ),

                        // Main content
                        pw.Padding(
                          padding: pw.EdgeInsets.all(40),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Align(
                                alignment: pw.Alignment.topLeft,
                                child: pw.Text(
                                  'Serial No: ${data['serial no'] ?? data['serialno'] ?? data['serial_no'] ?? 'N/A'}',
                                  style: pw.TextStyle(fontSize: 9, color: PdfColors.black),
                                ),
                              ),
                              // Header with Serial Number and Photo
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [


                                      pw.SizedBox(width: 70),

                                  // University Logo
                                  pw.Container(
                                    width: 140,
                                    height: 140,

                                    child: pw.Center(
                                        child: pw.Image(
                                            pw.MemoryImage(institutionLogo)
                                        )
                                    ),
                                  ),
                                  pw.Container(
                                    width: 70,
                                    height: 90,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(color: PdfColors.black, width: 1),
                                    ),
                                    child: pw.Center(
                                      child: pw.Image(studentImage),
                                    ),
                                  ),

                                ],
                              ),




                              pw.SizedBox(height: 10),
                              pw.Text(
                                'www.jnanadeepuniversity.org',
                                style: pw.TextStyle(fontSize: 10, color: PdfColors.black,),
                              ),

                              pw.SizedBox(height: 35),

                              // Certificate Text
                              pw.Text(
                                'UPON THE RECOMMENDATION OF THE',
                                style: pw.TextStyle(fontSize: 12, color: PdfColors.black),
                                textAlign: pw.TextAlign.center,
                              ),
                              pw.SizedBox(height: 5),

                              pw.Text(
                                'ACADEMIC COUNCIL',
                                style: pw.TextStyle(fontSize: 12, color: PdfColors.black),
                                textAlign: pw.TextAlign.center,
                              ),
                              pw.SizedBox(height: 5),

                              pw.Text(
                                'THE UNIVERSITY HEREBY CONFERS THE',
                                style: pw.TextStyle(fontSize: 12, color: PdfColors.black),
                                textAlign: pw.TextAlign.center,
                              ),

                              pw.SizedBox(height: 20),
                              pw.Text(
                                data['subject'],
                                style: pw.TextStyle(
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),

                              pw.SizedBox(height: 15),

                              pw.Text(
                                'FROM ${data['department']?.toString().toUpperCase() ?? 'DEPARTMENT OF EDUCATION'} TO',
                                style: pw.TextStyle(fontSize: 12, color: PdfColors.black),
                                textAlign: pw.TextAlign.center,
                              ),

                              pw.SizedBox(height: 20),

                              pw.Text(
                                (data['name'] ?? 'STUDENT NAME').toString().toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 20,

                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),

                              pw.SizedBox(height: 15),

                              pw.Text(
                                'BEARING ENROLLMENT NUMBER ${data['enrollment number'] ?? data['enrollmentnumber'] ?? data['enrollment_number'] ?? 'N/A'}',
                                style: pw.TextStyle(fontSize: 12, color: PdfColors.black),
                                textAlign: pw.TextAlign.center,
                              ),

                              pw.SizedBox(height: 20),

                              pw.Text(
                                'HAS SUCCESSFULLY COMPLETED IN THE YEAR ${data['completed year'] ?? data['completedyear'] ?? data['completed_year'] ?? 'N/A'} THE',
                                style: pw.TextStyle(fontSize: 12, color: PdfColors.black),
                                textAlign: pw.TextAlign.center,
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                'REQUIREMENTS PRESCRIBED UNDER THE ORDINANCE FOR',
                                style: pw.TextStyle(fontSize: 12, color: PdfColors.black),
                                textAlign: pw.TextAlign.center,
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                'THIS AWARD.',
                                style: pw.TextStyle(fontSize: 12, color: PdfColors.black),
                                textAlign: pw.TextAlign.center,
                              ),

                              pw.SizedBox(height: 25),

                              pw.Text(
                                'DIVISION: FIRST',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),

                              pw.Spacer(),

                              // Footer with date and signature
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: pw.CrossAxisAlignment.end,
                                children: [
                                  pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        'DATE: ${data['date'] ?? '02.12.2022'}',
                                        style: pw.TextStyle(fontSize: 12, color: PdfColors.black),
                                      ),
                                    ],
                                  ),
                                  pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                                    children: [
                                      pw.Container(
                                        width: 100,
                                        height: 100,
                                        child: pw.Image(signatureImage),
                                      ),
                                      pw.SizedBox(height: 5),
                                      pw.Container(
                                        height: 1,
                                        width: 120, // Match your image width or desired line width
                                        color: PdfColors.black,
                                      ),
                                      pw.SizedBox(height: 5),
                                      pw.Text(
                                        'VICE CHANCELLOR',
                                        style: pw.TextStyle(fontSize: 12, color: PdfColors.black),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              pw.SizedBox(height: 20),

                              // Barcode
                              pw.Container(
                                width: 240,
                                height: 200,
                                child: pw.Image(barcodeImage)
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]
            )
          );
        },
      ),
    );

    return pdf;
  }


  pw.Widget _buildCornerDecoration() {
    return pw.Container(
      width: 40,
      height: 40,
      child: pw.Stack(
        children: [
          // Main corner pattern using containers
          pw.Positioned(
            top: 0,
            left: 0,
            child: pw.Container(
              width: 25,
              height: 3,
              color: PdfColor.fromHex('#DAA520'),
            ),
          ),
          pw.Positioned(
            top: 0,
            left: 0,
            child: pw.Container(
              width: 3,
              height: 25,
              color: PdfColor.fromHex('#DAA520'),
            ),
          ),
          pw.Positioned(
            top: 5,
            left: 5,
            child: pw.Container(
              width: 15,
              height: 2,
              color: PdfColor.fromHex('#DAA520'),
            ),
          ),
          pw.Positioned(
            top: 5,
            left: 5,
            child: pw.Container(
              width: 2,
              height: 15,
              color: PdfColor.fromHex('#DAA520'),
            ),
          ),
          pw.Positioned(
            top: 10,
            left: 10,
            child: pw.Container(
              width: 8,
              height: 1,
              color: PdfColor.fromHex('#DAA520'),
            ),
          ),
          pw.Positioned(
            top: 10,
            left: 10,
            child: pw.Container(
              width: 1,
              height: 8,
              color: PdfColor.fromHex('#DAA520'),
            ),
          ),
          // Additional decorative elements
          pw.Positioned(
            top: 3,
            left: 15,
            child: pw.Container(
              width: 5,
              height: 1,
              color: PdfColor.fromHex('#DAA520'),
            ),
          ),
          pw.Positioned(
            top: 15,
            left: 3,
            child: pw.Container(
              width: 1,
              height: 5,
              color: PdfColor.fromHex('#DAA520'),
            ),
          ),
        ],
      ),
    );
  }

  String timeRemainingText = "";

  Future<void> generateAllCertificates() async {
    if (csvData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please load a CSV file first')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      timeRemainingText = "Calculating...";

    });

    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      int total = csvData.length;
      Stopwatch stopwatch = Stopwatch();
      for (int i = 0; i < csvData.length; i++) {
        stopwatch.reset();
        stopwatch.start();
        final pdf = await generateCertificatePDF(csvData[i]);
        final bytes = await pdf.save();

        String fileName = 'certificate_${csvData[i]['name'] ?? 'student_${i + 1}'}.pdf';
        fileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');

        final file = File('$selectedDirectory/$fileName');
        print("File Saved in ${file.path}");
        await file.writeAsBytes(await pdf.save());
        stopwatch.stop();

        final timeTaken = stopwatch.elapsedMilliseconds;
        final remaining = total - i - 1;
        final estimatedMsRemaining = timeTaken * remaining;

        final minutes = (estimatedMsRemaining ~/ 60000);
        final seconds = ((estimatedMsRemaining % 60000) ~/ 1000);

        setState(() {
          timeRemainingText = "Estimated time left: ${minutes}m ${seconds}s";
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating certificates: $e')),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> previewCertificate(int index) async {
    if (index >= csvData.length) return;

    final pdf = await generateCertificatePDF(csvData[index]);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Certificate Preview'),
          ),
          body: PdfPreview(
            build: (format) => pdf.save(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Certificate Generator'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.upload_file, size: 48, color: Colors.brown),
                    SizedBox(height: 16),
                    Text(
                      'Upload CSV File',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'CSV should contain: name, serial no, subject, department, enrollment number, completed year, date',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : pickCSVFile,
                      icon: Icon(Icons.folder_open),
                      label: Text('Select CSV File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            if (csvData.isNotEmpty) ...[
              Text(
                'Loaded ${csvData.length} records',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: isLoading ? null : generateAllCertificates,
                icon: Icon(Icons.picture_as_pdf),
                label: Text('Generate All Certificates'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),

              SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  itemCount: csvData.length,
                  itemBuilder: (context, index) {
                    final data = csvData[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.brown,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(data['name'] ?? 'N/A'),
                        subtitle: Text(
                          'Enrollment: ${data['enrollment number'] ?? data['enrollmentnumber'] ?? data['enrollment_number'] ?? 'N/A'}\n'
                              'Department: ${data['department'] ?? 'N/A'}',
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.preview),
                          onPressed: () => previewCertificate(index),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ],

            if (isLoading)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(timeRemainingText, style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}