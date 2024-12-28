import 'package:flutter/material.dart';
import 'package:image_search/albums_gridview.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<AssetPathEntity>? paths;
  @override
  void initState() {
    initPackages();
    super.initState();
  }

  void initPackages() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      paths = await PhotoManager.getAssetPathList();
      print(paths);
      setState(() {});
    } else if (ps.hasAccess) {
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(8),
        child: Center(
          child:
              (paths == null) ? Text("loading") : AlbumsGridview(paths: paths!),
        ),
      ),
    );
  }
}
