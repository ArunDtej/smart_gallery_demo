import 'package:flutter/material.dart';
import 'package:image_search/image_grid_view.dart';
import 'package:photo_manager/photo_manager.dart';

class AlbumsGridview extends StatefulWidget {
  List<AssetPathEntity> paths;
  AlbumsGridview({super.key, required this.paths});

  @override
  State<AlbumsGridview> createState() => _AlbumsGridviewState();
}

class _AlbumsGridviewState extends State<AlbumsGridview> {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Number of columns in the grid
        mainAxisSpacing: 10.0, // Space between rows
        crossAxisSpacing: 10.0, // Space between columns
      ),
      itemBuilder: (context, index) {
        return albumItem(index);
      },
      itemCount: widget.paths.length,
    );
  }

  Widget albumItem(int index) {
    var item = widget.paths[index];
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => ImageGridView(path: item)));
      },
      child: Container(
        color: Colors.blueAccent,
        child: Center(
          child: Text(
            item.name,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
