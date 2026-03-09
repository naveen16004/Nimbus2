import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(const NimbusApp());

class NimbusApp extends StatelessWidget {
  const NimbusApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E14), // Deep Space Blue
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.2),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF00D2FF), // Neon Cyan
          foregroundColor: Colors.white,
        ),
      ),
      home: const AlbumOverviewPage(),
    );
  }
}

// --- 1. ALBUM LIST SCREEN ---
class AlbumOverviewPage extends StatefulWidget {
  const AlbumOverviewPage({super.key});
  @override
  State<AlbumOverviewPage> createState() => _AlbumOverviewPageState();
}

class _AlbumOverviewPageState extends State<AlbumOverviewPage> {
  List<Directory> _albums = [];

  @override
  void initState() { super.initState(); _refreshAlbums(); }

  Future<void> _refreshAlbums() async {
    final directory = await getApplicationDocumentsDirectory();
    final folders = directory.listSync().whereType<Directory>().toList();
    setState(() => _albums = folders);
  }

  Future<void> _createNewAlbum(String name) async {
    final directory = await getApplicationDocumentsDirectory();
    final newPath = p.join(directory.path, name);
    final newDir = Directory(newPath);
    if (!await newDir.exists()) {
      await newDir.create();
      _refreshAlbums();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(title: Text("N I M B U S"), floating: true, pinned: true),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _albums.isEmpty
                ? const SliverFillRemaining(child: Center(child: Text("Start your collection.", style: TextStyle(color: Colors.white38))))
                : SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.9,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => SingleAlbumPage(albumDir: _albums[i])
                          )).then((_) => _refreshAlbums()),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.01)],
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00D2FF).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.folder_rounded, size: 40, color: Color(0xFF00D2FF)),
                                ),
                                const SizedBox(height: 12),
                                Text(p.basename(_albums[i].path), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: _albums.length,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNameDialog(),
        label: const Text("New Album"),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showNameDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Create Album"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Album Name",
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D2FF), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              if (controller.text.isNotEmpty) _createNewAlbum(controller.text);
              Navigator.pop(ctx);
            }, 
            child: const Text("Create")
          ),
        ],
      ),
    );
  }
}

// --- 2. SINGLE ALBUM VIEW ---
class SingleAlbumPage extends StatefulWidget {
  final Directory albumDir;
  const SingleAlbumPage({super.key, required this.albumDir});
  @override
  State<SingleAlbumPage> createState() => _SingleAlbumPageState();
}

class _SingleAlbumPageState extends State<SingleAlbumPage> {
  List<File> _files = [];

  @override
  void initState() { super.initState(); _loadFiles(); }

  void _loadFiles() {
    setState(() {
      _files = widget.albumDir.listSync().whereType<File>().toList();
    });
  }

  Future<void> _importMedia() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.media, allowMultiple: true);
    if (result != null) {
      for (var path in result.paths) {
        if (path != null) {
          final newPath = p.join(widget.albumDir.path, p.basename(path));
          await File(path).copy(newPath);
        }
      }
      _loadFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(p.basename(widget.albumDir.path).toUpperCase())),
      body: _files.isEmpty
          ? const Center(child: Text("Empty Folder", style: TextStyle(color: Colors.white24)))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: _files.length,
              itemBuilder: (context, i) {
                bool isVideo = p.extension(_files[i].path).toLowerCase() == '.mp4';
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MediaDetailView(file: _files[i], isVideo: isVideo))),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        isVideo 
                          ? Container(color: Colors.white.withOpacity(0.05), child: const Icon(Icons.play_arrow_rounded, size: 40, color: Color(0xFF00D2FF)))
                          : Image.file(_files[i], fit: BoxFit.cover),
                        if (isVideo) const Positioned(top: 8, right: 8, child: Icon(Icons.videocam_rounded, size: 16, color: Colors.white70)),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(onPressed: _importMedia, child: const Icon(Icons.add_rounded)),
    );
  }
}

// --- 3. DETAIL VIEW ---
class MediaDetailView extends StatefulWidget {
  final File file;
  final bool isVideo;
  const MediaDetailView({super.key, required this.file, required this.isVideo});
  @override
  State<MediaDetailView> createState() => _MediaDetailViewState();
}

class _MediaDetailViewState extends State<MediaDetailView> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _controller = VideoPlayerController.file(widget.file)..initialize().then((_) { setState(() {}); _controller!.play(); });
    }
  }

  @override
  void dispose() { _controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(
        child: widget.isVideo
            ? (_controller != null && _controller!.value.isInitialized ? AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!)) : const CircularProgressIndicator())
            : InteractiveViewer(child: Image.file(widget.file)),
      ),
    );
  }
}