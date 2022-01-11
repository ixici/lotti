import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lotti/classes/journal_entities.dart';
import 'package:lotti/utils/image_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';

class EntryImageWidget extends StatefulWidget {
  final JournalImage journalImage;
  final int height;

  const EntryImageWidget({
    Key? key,
    required this.journalImage,
    required this.height,
  }) : super(key: key);

  @override
  State<EntryImageWidget> createState() => _EntryImageWidgetState();
}

class _EntryImageWidgetState extends State<EntryImageWidget> {
  Directory? docDir;

  @override
  void initState() {
    super.initState();

    getApplicationDocumentsDirectory().then((value) {
      setState(() {
        docDir = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (docDir != null) {
      File file =
          File(getFullImagePathWithDocDir(widget.journalImage, docDir!));

      return Container(
        color: Colors.black,
        height: widget.height.toDouble(),
        child: PhotoView(
          imageProvider: FileImage(file),
        ),
      );
    } else {
      return Container();
    }
  }
}
