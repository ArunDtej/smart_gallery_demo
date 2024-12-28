import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_search/search_sort.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img; // For resizing the image data
import 'package:photo_manager/photo_manager.dart';

class ImageGridView extends StatefulWidget {
  AssetPathEntity path;
  ImageGridView({super.key, required this.path});

  @override
  State<ImageGridView> createState() => _ImageGridViewState();
}

class _ImageGridViewState extends State<ImageGridView> {
  List<AssetEntity>? entities;
  Map<dynamic, dynamic> rawEmbeddings = {};
  dynamic interpreter;
  @override
  void initState() {
    initImages();
    super.initState();
  }

  void initImages() async {
    entities = await widget.path.getAssetListRange(start: 0, end: 50);
    interpreter = await Interpreter.fromAsset(
        'assets/models/mobilenet_v3_embedder.tflite');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return (entities == null)
        ? Text('Loading')
        : Container(
            padding: EdgeInsets.all(8),
            child: Scaffold(
              appBar: AppBar(
                title: Row(
                  spacing: 10,
                  children: [
                    GestureDetector(
                        onTap: () {
                          generateEmbeddings();
                          print('generating embeddings');
                        },
                        child: Icon(Icons.image)),
                    GestureDetector(
                        onTap: () {
                          print(rawEmbeddings);
                          print('print embeddings');
                        },
                        child: Icon(Icons.abc))
                  ],
                ),
              ),
              body: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Number of columns in the grid
                  mainAxisSpacing: 10.0, // Space between rows
                  crossAxisSpacing: 10.0, // Space between columns
                ),
                itemBuilder: (context, index) {
                  return InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SearchSort(
                                    images: entities!,
                                    searchVector: rawEmbeddings[
                                        '${entities![index].title}'],
                                    rawEmbeddings: rawEmbeddings)));
                        print('on image clicked');
                      },
                      child: imageItem(index));
                },
                itemCount: 50,
              ),
            ),
          );
  }

  Widget imageItem(int index) {
    AssetEntity item = entities![index];

    return FutureBuilder<Uint8List?>(
      future: item.thumbnailData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Container(
            color: Colors.red,
            child: const Center(
              child: Icon(
                Icons.error,
                color: Colors.white,
              ),
            ),
          );
        }
        return Container(
          color: Colors.black,
          child: Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  void generateEmbeddings() async {
    var inputs = await generateModelInputs(entities!);
    var output = List.filled(1024 * 50, 0).reshape([50, 1024]);
    print(output.shape);
    interpreter.run(inputs, output);

    for (int i = 0; i < output.length; i++) {
      rawEmbeddings['${entities![i].title}'] = output[i];
    }
    print('embeddings updated');
  }

  Future<List<List<List<List<double>>>>> generateModelInputs(
      List<AssetEntity> entities) async {
    const int modelHeight = 224;
    const int modelWidth = 224;
    const int modelChannels = 3;

    List<List<List<List<double>>>> inputs = [];

    for (AssetEntity entity in entities) {
      Uint8List? thumbnailData = await entity.thumbnailDataWithSize(
        ThumbnailSize(modelWidth, modelHeight),
      );

      if (thumbnailData != null) {
        // Decode the thumbnail data to manipulate pixel values
        img.Image? image = img.decodeImage(thumbnailData);

        if (image != null) {
          // Normalize image to the model input range and reshape
          List<List<List<double>>> normalizedImage = List.generate(
            modelHeight,
            (y) => List.generate(
              modelWidth,
              (x) {
                final pixel = image.getPixel(x, y);
                return [
                  pixel.r.toDouble() / 255.0, // Normalize red channel
                  pixel.g.toDouble() / 255.0, // Normalize green channel
                  pixel.b.toDouble() / 255.0, // Normalize blue channel
                ];
              },
            ),
          );
          inputs.add(normalizedImage);
        }
      }
    }

    print(inputs.shape);

    return inputs;
  }
}
