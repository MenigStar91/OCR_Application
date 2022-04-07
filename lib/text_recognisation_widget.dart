import 'dart:io';
import 'package:clipboard/clipboard.dart';
// import 'package:firebase_ml_text_recognition/api/firebase_ml_api.dart';
// import 'package:firebase_ml_text_recognition/widget/text_area_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'text_area_widget.dart';
import 'controls_widget.dart';
import 'firebase_ml_api.dart';
import 'package:file_picker/file_picker.dart';

import 'package:cross_file/cross_file.dart';

class TextRecognitionWidget extends StatefulWidget {
  const TextRecognitionWidget(
    // required Key key,
  ) ;
  // : super(key: key)

  @override
  _TextRecognitionWidgetState createState() => _TextRecognitionWidgetState();
}

class _TextRecognitionWidgetState extends State<TextRecognitionWidget> {
  String text = '';
  File? image;
  
  Future<void> _takePicture () async{
    final imageFile= await ImagePicker.pickImage(source: ImageSource.camera, maxWidth: 600, );
    setState(() {
      image = imageFile;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body:  Column(
            children: [
              Expanded(child: buildImage()),
              const SizedBox(height: 16),
              ControlsWidget(
                onClickedPickImage: _takePicture,
                onClickedScanText: scanText,
                onClickedClear: clear, 
              ),
              const SizedBox(height: 16),
              TextAreaWidget(
                text: text,
                onClickedCopy: copyToClipboard, 
              ),
            ],
          ),
        
  );

  Widget buildImage() => Container(
        child: image != null
            ? Image.file(image!)
            : Icon(Icons.photo, size: 80, color: Colors.black),
      );




  // Future pickImage() async {
  //   // final file = await ImagePicker.pickImage(source: ImageSource.gallery);
  //   // final file = await FilePicker.platform.pickFiles(
  //   //                   type: FileType.custom,
  //   //                   allowedExtensions: ['png', 'jpg', 'jpeg']) as File;
    
  //   XFile? image = await ImagePicker()
  //                     .pickImage(source: ImageSource.gallery);
  //                 final file = File(image!.path);
  //   print(file);
  //   print("MILEGAAAA");
  //   print(File(file.path));

  //   setState(() {
  //     image = File(file.path) as XFile?;
  //   });
  //   // setImage(File(file.path));


   
  // }

  Future scanText() async {
    // showDialog(
    //   context: context,
    //   child: Center(
    //     child: CircularProgressIndicator(),
    //   ),
    // );

    final text = await FirebaseMLApi.recogniseText(image!);
    print(text);
    setText(text);

    // Navigator.of(context).pop();
  }

  void clear() {
    var jpg;
    setImage(File(jpg));
    setText('');
  }

  void copyToClipboard() {
    if (text.trim() != '') {
      FlutterClipboard.copy(text);
    }
  }

  void setImage(File newImage) {
    setState(() {
      image = newImage;
    });
  }

  void setText(String newText) {
    setState(() {
      text = newText;
    });
  }
}