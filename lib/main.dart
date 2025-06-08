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
import 'package:marksheetchanger/certificateGenerator.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'markSheetGenerator.dart';


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
      home:  Scaffold(
        body: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  tabs: [
                    Tab(
                      text: "Mark Sheet Generator",
                    ),
                    Tab(
                      text: "Certificate Generator",
                    ),
                  ],
                ),
                Expanded(
                    child:  TabBarView(children: <Widget>[
                      MarkStatementGenerator(),
                      CertificateGenerator()
                    ]))
              ],
            )),
      ),
    );
  }
}
