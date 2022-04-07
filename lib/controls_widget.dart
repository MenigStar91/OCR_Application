import 'package:flutter/material.dart';

class ControlsWidget extends StatelessWidget {
  final VoidCallback onClickedPickImage;
  final VoidCallback onClickedScanText;
  final VoidCallback onClickedClear;

  const ControlsWidget({
    required this.onClickedPickImage,
    required this.onClickedScanText,
    required this.onClickedClear,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RaisedButton(
            // onPressed: onClickedPickImage,
            onPressed: () {},
            child: Text('Text to Audio', style: TextStyle(color: Colors.white)),
            color: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15.0))),
          ),
          const SizedBox(width: 12),
          RaisedButton(
            onPressed: onClickedScanText,
            child: Text('Scan for Text', style: TextStyle(color: Colors.white)),
            color: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15.0))),
          ),
          const SizedBox(width: 12),
          // RaisedButton(
          //   onPressed: onClickedClear,
          //   child: Text('Clear'),
          // )
        ],
      );
}
