// import 'dart:convert';

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:clipboard/clipboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocr_application/firebase_api.dart';
import 'package:ocr_application/firebase_ml_api.dart';
import 'package:ocr_application/main.dart';
import 'package:ocr_application/temp.dart';
import 'package:ocr_application/tempharshi.dart';
import 'package:ocr_application/text_area_widget.dart';
import 'package:ocr_application/text_recognisation_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'save_file_mobile.dart' if (dart.library.html) 'save_file_web.dart';

// import 'dart:html' as html;

class ScanTextOutput extends StatefulWidget {
  String text;
  ScanTextOutput({required this.text});
  // const ScanTextOutput({Key? key}) : super(key: key);

  @override
  State<ScanTextOutput> createState() => _ScanTextOutputState();
}

class _ScanTextOutputState extends State<ScanTextOutput> {
  String path = "";

  bool _isDownloadDone = false;

  late String scannedText;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _searchValue;

  _write(String text) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    print(directory.path);
    final File file = File('${directory.path}/my_file.txt');
    print(file);
    await file.writeAsString(text);
    final destination = '${FirebaseAuth.instance.currentUser!.displayName}.txt';

    final task = FirebaseApi.uploadFile(destination, file);

    final snapshot = await task!.whenComplete(() => {
          print("done"),
        });
    final urlDownload = await snapshot.ref.getDownloadURL();
    _download(urlDownload);
    // _download('https://i.imgur.com/YhT0HJ2.jpg');

    // _download('${directory.path}/my_file.txt');
    // _download('assets/test.png');
  }
  // static var httpClient = new HttpClient();
  // Future<File> _downloadFile(String url, String filename) async {
  //   var request = await httpClient.getUrl(Uri.parse(url));
  //   var response = await request.close();
  //   var bytes = await consolidateHttpClientResponseBytes(response);
  //   String dir = (await getApplicationDocumentsDirectory()).path;
  //   File file = new File('$dir/$filename');
  //   await file.writeAsBytes(bytes);
  //   return file;
  // }

  void copyToClipboard() {
    if (widget.text.trim() != '') {
      FlutterClipboard.copy(widget.text);
    }
  }
// You need to import these 2 libraries besides another libraries to work with this code

  ReceivePort _port = ReceivePort();

  @override
  void initState() {
    super.initState();

    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      setState(() {});
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  void _download(String url) async {
    final status = await Permission.storage.request();

    if (status.isGranted) {
      final externalDir = await getExternalStorageDirectory();

      final id = await FlutterDownloader.enqueue(
        url: url,
        savedDir: externalDir!.path,
        fileName:
            "OCR_Download ${FirebaseAuth.instance.currentUser!.displayName}.txt",
        showNotification: true,
        openFileFromNotification: true,
      );
      setState(() {
        _isDownloadDone = true;
        Timer(Duration(seconds: 3), () {
          _isDownloadDone = false;
        });
      });
    } else {
      print('Permission Denied');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Container(
        child: Align(
          alignment: Alignment.bottomRight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0))),
                onPressed: copyToClipboard,
                child: Icon(Icons.copy, color: Colors.white),
              ),
              SizedBox(width: 10),
              FloatingActionButton(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0))),
                onPressed: () async {
                  _write(widget.text);
                  // final status = await Permission.storage.request();
                  // if (status.isGranted) {
                  //   final externalDir = await getExternalStorageDirectory();
                  //   final id = await FlutterDownloader.enqueue(
                  //     // url:
                  //     //     "https://firebasestorage.googleapis.com/v0/b/storage-3cff8.appspot.com/o/2020-05-29%2007-18-34.mp4?alt=media&token=841fffde-2b83-430c-87c3-2d2fd658fd41",
                  //     url: "https://i.imgur.com/YhT0HJ2.jpg",
                  //     savedDir: externalDir!.path,
                  //     fileName: "download",
                  //     showNotification: true,
                  //     openFileFromNotification: true,
                  //   );
                  // }
                },
                child: !_isDownloadDone
                    ? Icon(Icons.download, color: Colors.white)
                    : Icon(Icons.download_done, color: Colors.white),
              ),
              // FloatingActionButton(
              //   onPressed: () {},
              //   child: Icon(
              //     Icons.photo_album_rounded,
              //   ),
              // ),
            ],
          ),
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, value) {
          return [
            SliverToBoxAdapter(
                child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 60,
                  ),
                  Text(
                    "Your scanned text",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  // Container(
                  //   height: 46,
                  //   decoration: BoxDecoration(
                  //     color: Colors.grey.shade200,
                  //     borderRadius: BorderRadius.circular(8),
                  //   ),
                  //   child: Form(
                  //     key: _formKey,
                  //     child: TextFormField(
                  //       validator: (input) {
                  //         if (input != null && input.isEmpty)
                  //           return "Search Something";
                  //       },
                  //       cursorColor: Colors.black,
                  //       decoration: InputDecoration(
                  //         prefixIcon: Icon(
                  //           Icons.search,
                  //           color: Colors.grey.shade700,
                  //         ),
                  //         border: InputBorder.none,
                  //         hintText: "Search ",
                  //         hintStyle: TextStyle(color: Colors.grey.shade500),
                  //       ),
                  //       onSaved: (input) => _searchValue = input!,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ))
          ];
        },
        body: Container(
          child: TextAreaWidget(
            text: widget.text,
            onClickedCopy: copyToClipboard,
          ),
        ),
        // body: Container(
        //   child: ListView.builder(
        //     scrollDirection: Axis.vertical,
        //     shrinkWrap: true,
        //     itemCount: 1,
        //     itemBuilder: (BuildContext context, int ScanTextOutput) {
        //       return Card(
        //         elevation: 8.0,
        //         margin:
        //             new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        //         // shape: ,
        //         child: Container(
        //           decoration: BoxDecoration(
        //             color: Colors.white,
        //             borderRadius: BorderRadius.circular(
        //               10,
        //             ),
        //           ),
        //           child: ListTile(
        //             contentPadding:
        //                 EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        //             leading: Container(
        //               padding: EdgeInsets.only(right: 12.0),
        //               decoration: new BoxDecoration(
        //                   // borderRadius: BorderRadius.circular(
        //                   //           50,
        //                   //         ),
        //                   border: new Border(
        //                       right: new BorderSide(
        //                           width: 1.0, color: Colors.black))),
        //               child: Icon(Icons.autorenew, color: Colors.black),
        //             ),
        //             title: Text(
        //               "Document",
        //               style: TextStyle(
        //                   color: Colors.black, fontWeight: FontWeight.bold),
        //             ),
        //             // subtitle: Text("Intermediate", style: TextStyle(color: Colors.white)),

        //             subtitle: Row(
        //               children: <Widget>[
        //                 Icon(Icons.linear_scale, color: Colors.black),
        //                 Text("Date", style: TextStyle(color: Colors.black))
        //               ],
        //             ),
        //             trailing: Icon(Icons.keyboard_arrow_right,
        //                 color: Colors.black, size: 30.0),
        //           ),
        //         ),
        //       );
        //     },
        //   ),
        // ),
      ),
      bottomNavigationBar: Container(
        height: 55.0,
        child: BottomAppBar(
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.home, color: Colors.black),
                onPressed: () {},
              ),
              // IconButton(
              //   icon: Icon(Icons.camera_alt_rounded, color: Colors.black),
              //   onPressed: () {
              // Navigator.push(context,
              //     MaterialPageRoute(builder: (context) => HomePage()));
              //   },
              // ),
              IconButton(
                icon: Icon(Icons.photo, color: Colors.black),
                onPressed: () {
                  // Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) => TextRecognitionWidget()));
                },
              ),
              IconButton(
                icon: Icon(Icons.person, color: Colors.black),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.logout, color: Colors.black),
                onPressed: () {
                  showAlertDialog(context);
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  showAlertDialog(BuildContext context) {
    // set up the button
    // Widget logOutButton = SalomonBottomBarItem(
    //   icon: Icon(Icons.logout),
    //   title: Text("LogOut"),
    //   selectedColor: Colors.redAccent,
    // );
    Widget okButton = TextButton(
      child: Text("Logout"),
      onPressed: () {
        _auth.signOut();
        // Navigator.push(
        //     context, MaterialPageRoute(builder: (context) => HomePage()));
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LandingPage()),
            (route) => false);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Logout Alert!!"),
      content: Text("Are you sure you want to logout?"),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
