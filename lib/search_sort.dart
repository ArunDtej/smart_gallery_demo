import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class SearchSort extends StatefulWidget {
  final List<AssetEntity> images;
  final searchVector;
  final Map<dynamic, dynamic> rawEmbeddings;
  SearchSort(
      {super.key,
      required this.images,
      required this.searchVector,
      required this.rawEmbeddings});

  @override
  State<SearchSort> createState() => _SearchSortState();
}

class _SearchSortState extends State<SearchSort> {
  List<AssetEntity>? images;

  @override
  void initState() {
    images = widget.images;
    predict();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Number of columns in the grid
          mainAxisSpacing: 10.0, // Space between rows
          crossAxisSpacing: 10.0, // Space between columns
        ),
        itemBuilder: (context, index) {
          return InkWell(
              onTap: () {
                print('on image clicked');
              },
              child: imageItem(index));
        },
        itemCount: 50,
      ),
    );
  }

  Widget imageItem(int index) {
    AssetEntity item = images![index];

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

  void predict() async {
    dynamic similarityModel = await Interpreter.fromAsset(
        'assets/models/cosine_similarity_model.tflite');
    var inputs = [];
    for (int i = 0; i < widget.rawEmbeddings.length; i++) {
      var imageEmbedding = widget.rawEmbeddings['${widget.images[i].title}'];
      var inputTensor = [imageEmbedding, widget.searchVector];
      inputs.add(inputTensor);
    }
    print(inputs.shape);

    var output = List.filled(50 * 1, 0).reshape([50]);

    similarityModel.run(inputs, output);
    print(output.shape);
    print(output);

    var sorted_indices = getSortedIndices(output).reversed.toList();

    List<AssetEntity> sortedAssets = [];
    for (int i = 0; i < sorted_indices.length; i++) {
      sortedAssets.add(widget.images[sorted_indices[i]]);
    }
    setState(() {
      images = sortedAssets;
    });
  }

  List<int> getSortedIndices(List<dynamic> output) {
    // Pair each value with its index
    List<MapEntry<int, dynamic>> indexedOutput =
        output.asMap().entries.toList();

    // Sort the pairs based on the value, casting to double for comparison
    indexedOutput
        .sort((a, b) => (a.value as double).compareTo(b.value as double));

    // Extract the indices in sorted order
    return indexedOutput.map((entry) => entry.key).toList();
  }
}
