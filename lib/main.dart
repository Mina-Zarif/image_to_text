import 'dart:io';

import 'package:animated_floating_buttons/animated_floating_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Image To Text'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  File? _croppedImage;
  bool isDone = false;
  bool isLoading = false;
  String? imagePath;
  ImagePicker? picker = ImagePicker();
  String recognizedText = "";

  Future<void> _cropImage(File imageFile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9
      ],
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Cropper',
        ),
        WebUiSettings(
          context: context,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _croppedImage = File(croppedFile.path);
        recognizeText(
          image: _croppedImage!,
        );
      });
    }
  }

  Future<void> recognizeText({required File image}) async {
    final inputImage = InputImage.fromFile(image);
    final TextRecognizer textDetector = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognisedText =
        await textDetector.processImage(inputImage);
    recognizedText = "";
    for (TextBlock block in recognisedText.blocks) {
      for (TextLine line in block.lines) {
        recognizedText += '${line.text}\n';
      }
    }
    setState(() {});
    isDone = true;
    isLoading = false;
    textDetector.close();
  }

  Future<void> getImage({required bool isCamera}) async {
    final pickedFile = await picker!.pickImage(
        source: (isCamera) ? ImageSource.camera : ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        isDone = false;
        isLoading = true;
        _cropImage(_image!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          InkWell(
            onTap: () {
              setState(() {
                _image = null;
                _croppedImage = null;
                isDone = false;
                isLoading = false;
                recognizedText = "";
              });
            },
            child: Container(
              width: 80,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.lightBlue,
                borderRadius: BorderRadiusDirectional.circular(7),
              ),
              child: const Center(
                child: Text(
                  "CE",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 20,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            (_croppedImage == null)
                ? Center(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                          top: MediaQuery.of(context).size.height * 0.4),
                      child: Text(
                        'Upload Your Image Or Take It..',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Colors.grey[700]),
                      ),
                    ),
                  )
                : Image.file(_croppedImage!),
            const SizedBox(height: 25),
            if (isDone == true) const Divider(),
            const SizedBox(height: 25),
            if (isDone == true)
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadiusDirectional.circular(25)),
                child: Column(
                  children: [
                    if (recognizedText.isNotEmpty)
                      Align(
                        alignment: AlignmentDirectional.topEnd,
                        child: IconButton(
                          tooltip: "copy to clipboard",
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: recognizedText),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.white,
                                    ),
                                    SizedBox(
                                      width: 15,
                                    ),
                                    Text("Copied To Clipboard"),
                                  ],
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
                        ),
                      ),
                    Text(
                      (recognizedText.isEmpty)
                          ? (isLoading)
                              ? "Loading.."
                              : "Text is not founded..."
                          : recognizedText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 30,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.25,
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedFloatingActionButton(
        fabButtons: <Widget>[
          FloatingActionButton(
            onPressed: () {
              getImage(isCamera: true);
            },
            heroTag: "Camera",
            tooltip: 'Camera',
            child: const Icon(Icons.camera),
          ),
          const SizedBox(
            height: 10,
          ),
          FloatingActionButton(
            onPressed: () {
              getImage(isCamera: false);
            },
            heroTag: "Gallery",
            tooltip: 'Gallery',
            child: const Icon(Icons.photo_library_outlined),
          ),
          const SizedBox(
            height: 10,
          ),
        ],
        colorStartAnimation: const Color(0xff8cccfd),
        colorEndAnimation: Colors.red,
        animatedIconData: AnimatedIcons.menu_close,
        tooltip: "", //To principal button
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
