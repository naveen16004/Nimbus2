import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart'; 
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

void main() => runApp(const NimbusApp());

class NimbusApp extends StatelessWidget {
  const NimbusApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        // NEW BACKGROUND THEME
        scaffoldBackgroundColor: const Color(0xFF0D1117), 
        primaryColor: const Color(0xFF58A6FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161B22),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 22, 
            fontWeight: FontWeight.w800, 
            // NEW ACCENT COLOR
            color: Color(0xFF58A6FF),
            letterSpacing: 1.5
          ),
        ),
        // Modern Card styling
        cardTheme: CardThemeData(
          color: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white10, width: 1),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF58A6FF),
          foregroundColor: Color(0xFF0D1117),
        ),
      ),
      home: const AlbumOverviewPage(),
    );
  }
}

// --- 1. HOME SCREEN: ALBUM OVERVIEW ---
class AlbumOverviewPage extends StatefulWidget {
  const AlbumOverviewPage({super.key});
  @override
  State<AlbumOverviewPage> createState() => _AlbumOverviewPageState();
}

class _AlbumOverviewPageState extends State<AlbumOverviewPage> {
  List<Directory> _albums = [];
  List<Directory> _filteredAlbums = [];
  final Set<int> _selectedIndices = {};
  bool _isSelectionMode = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshAlbums();
    _searchController.addListener(_filterAlbums);
  }

  Future<void> _refreshAlbums() async {
    final directory = await getApplicationDocumentsDirectory();
    final folders = directory.listSync().whereType<Directory>().toList();
    setState(() {
      _albums = folders;
      _filteredAlbums = folders;
      _selectedIndices.clear();
      _isSelectionMode = false;
    });
  }

  void _filterAlbums() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAlbums = _albums.where((dir) {
        return p.basename(dir.path).toLowerCase().contains(query);
      }).toList();
    });
  }

  String _getFolderSize(Directory dir) {
    int totalSize = 0;
    try {
      if (dir.existsSync()) {
        dir.listSync(recursive: true).forEach((entity) {
          if (entity is File) totalSize += entity.lengthSync();
        });
      }
    } catch (e) { return "0 MB"; }
    return "${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        if (_selectedIndices.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIndices.add(index);
        _isSelectionMode = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode ? Text("${_selectedIndices.length} Selected", style: const TextStyle(color: Colors.white)) : const Text("NIMBUS"),
        actions: _isSelectionMode ? [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            onPressed: () => _confirmBatchDeleteFolders(),
          )
        ] : [
          // SEARCH BAR IN CENTRE (STAYED)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search folders...",
                  prefixIcon: const Icon(Icons.search, size: 20, color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF0D1117), // Theme background
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFF58A6FF))),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _filteredAlbums.isEmpty 
        ? const Center(child: Text("No folders found", style: TextStyle(color: Colors.white24)))
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12
            ),
            itemCount: _filteredAlbums.length,
            itemBuilder: (context, i) {
              final isSelected = _selectedIndices.contains(i);
              return GestureDetector(
                onLongPress: () => _toggleSelection(i),
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelection(i);
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SingleAlbumPage(albumDir: _filteredAlbums[i]))).then((_) => _refreshAlbums());
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF58A6FF).withOpacity(0.1) : const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF58A6FF) : Colors.white10, 
                      width: 1.5
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open_rounded, 
                        size: 48, 
                        color: isSelected ? const Color(0xFF58A6FF) : Colors.white30
                      ),
                      const SizedBox(height: 12),
                      Text(
                        p.basename(_filteredAlbums[i].path).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      Text(
                        _getFolderSize(_filteredAlbums[i]), 
                        style: const TextStyle(fontSize: 11, color: Colors.white24)
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      floatingActionButton: _isSelectionMode ? null : FloatingActionButton(
        onPressed: () => _showNameDialog(),
        child: const Icon(Icons.create_new_folder_outlined, size: 28),
      ),
    );
  }

  // --- HOME SCREEN DELETE FOLDERS ---
  void _confirmBatchDeleteFolders() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF161B22),
      title: const Text("Purge Vaults?"),
      content: Text("Delete ${_selectedIndices.length} folders and all media permanently?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.white38))),
        TextButton(onPressed: () async { 
          Navigator.pop(ctx); 
          for (var index in _selectedIndices) { _filteredAlbums[index].deleteSync(recursive: true); }
          _refreshAlbums();
        }, child: const Text("PURGE", style: TextStyle(color: Colors.redAccent))),
      ],
    ));
  }

  void _showNameDialog() {
    final controller = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF161B22),
      title: const Text("New Vault"),
      content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: "Vault name...")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF58A6FF)),
          onPressed: () async { 
            if (controller.text.isNotEmpty) {
              final directory = await getApplicationDocumentsDirectory();
              await Directory(p.join(directory.path, controller.text)).create();
              _refreshAlbums();
            }
            Navigator.pop(ctx); 
          }, 
          child: const Text("Create", style: TextStyle(color: Color(0xFF0D1117)))
        ),
      ],
    ));
  }
}

// --- 2. INSIDE FOLDER: MEDIA GRID (THEMED) ---
class SingleAlbumPage extends StatefulWidget {
  final Directory albumDir;
  const SingleAlbumPage({super.key, required this.albumDir});
  @override
  State<SingleAlbumPage> createState() => _SingleAlbumPageState();
}

class _SingleAlbumPageState extends State<SingleAlbumPage> {
  List<File> _files = [];
  final Set<int> _selectedIndices = {};
  bool _isSelectionMode = false;

  @override
  void initState() { super.initState(); _loadFiles(); }

  void _loadFiles() {
    if (!mounted) return;
    setState(() {
      _files = widget.albumDir.listSync().whereType<File>().toList();
      _selectedIndices.clear();
      _isSelectionMode = false;
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        if (_selectedIndices.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIndices.add(index);
        _isSelectionMode = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode ? Text("${_selectedIndices.length} Selected") : Text(p.basename(widget.albumDir.path).toUpperCase()),
        actions: _isSelectionMode ? [
          IconButton(icon: const Icon(Icons.share), onPressed: () async {
            final paths = _selectedIndices.map((i) => XFile(_files[i].path)).toList();
            await Share.shareXFiles(paths);
          }),
          // FIXED: Use batch confirm logic
          IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _confirmBatchDeleteFiles()),
        ] : [],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: _files.length,
        itemBuilder: (context, i) {
          final isSelected = _selectedIndices.contains(i);
          final isVideo = ['.mp4', '.mov', '.avi'].contains(p.extension(_files[i].path).toLowerCase());
          return GestureDetector(
            onLongPress: () => _toggleSelection(i),
            onTap: () {
              if (_isSelectionMode) {
                _toggleSelection(i);
              } else {
                // FIXED: Use the Swipe (PageView) Navigator
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => MediaDetailSwipeView(allFiles: _files, initialIndex: i)
                )).then((_) => _loadFiles());
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              // ADDED modern card effect
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    !isVideo ? Image.file(_files[i], fit: BoxFit.cover)
                        : FutureBuilder<Uint8List?>(
                            future: VideoThumbnail.thumbnailData(video: _files[i].path, maxWidth: 150, quality: 25),
                            builder: (context, snap) => snap.hasData ? Image.memory(snap.data!, fit: BoxFit.cover) : Container(color: Colors.white10),
                          ),
                    if (isSelected) Container(color: const Color(0xFF58A6FF).withOpacity(0.4)),
                    if (isSelected) const Icon(Icons.check_circle, color: Colors.white, size: 28),
                    if (isVideo && !isSelected) const Center(child: Icon(Icons.play_circle_fill, size: 40, color: Color(0xFF58A6FF))),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: _isSelectionMode ? null : FloatingActionButton(
        onPressed: () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.media, allowMultiple: true);
          if (result != null) {
            for (var path in result.paths) {
              if (path != null) await File(path).copy(p.join(widget.albumDir.path, p.basename(path)));
            }
            _loadFiles();
          }
        },
        child: const Icon(Icons.add_to_photos_outlined, size: 28),
      ),
    );
  }

  // --- BATCH CONFIRM DELETE (FILES) ---
  void _confirmBatchDeleteFiles() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF161B22),
      title: Text("Delete ${_selectedIndices.length} items permanently?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.white38))),
        TextButton(onPressed: () async { 
          Navigator.pop(ctx); 
          for (var i in _selectedIndices) { _files[i].deleteSync(); }
          _loadFiles();
        }, child: const Text("DELETE ALL", style: TextStyle(color: Colors.redAccent))),
      ],
    ));
  }
}

// --- 3. FULL VIEW: MEDIA DETAIL (THEMED & SWIPE) ---
class MediaDetailSwipeView extends StatefulWidget {
  final List<File> allFiles;
  final int initialIndex;
  const MediaDetailSwipeView({super.key, required this.allFiles, required this.initialIndex});
  @override
  State<MediaDetailSwipeView> createState() => _MediaDetailSwipeViewState();
}

class _MediaDetailSwipeViewState extends State<MediaDetailSwipeView> {
  late PageController _pageController;
  late int _currentIndex;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _setupMedia(_currentIndex);
  }

  void _setupMedia(int index) {
    _videoController?.dispose();
    _videoController = null;
    final file = widget.allFiles[index];
    if (['.mp4', '.mov', '.avi'].contains(p.extension(file.path).toLowerCase())) {
      _videoController = VideoPlayerController.file(file)..initialize().then((_) { if (mounted) setState(() {}); _videoController!.play(); });
    }
  }

  @override
  void dispose() { _pageController.dispose(); _videoController?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final currentFile = widget.allFiles[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.black, // Immersive black
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Immersive appbar
        title: Text("${_currentIndex + 1} / ${widget.allFiles.length}", style: const TextStyle(fontSize: 14, color: Colors.white70)),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline, color: Colors.white70), onPressed: () => _showProperties(currentFile)),
          IconButton(icon: const Icon(Icons.share_outlined, color: Colors.white70), onPressed: () => Share.shareXFiles([XFile(currentFile.path)])),
          // FIXED: Remove Icon & Logic
          IconButton(icon: const Icon(Icons.playlist_remove, color: Colors.orangeAccent), onPressed: () => _removeFromAlbum(currentFile)),
          // FIXED: Single Confirm Delete Popup
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _confirmSingleDelete(currentFile)),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.allFiles.length,
        onPageChanged: (index) { setState(() => _currentIndex = index); _setupMedia(index); },
        itemBuilder: (context, index) {
          final file = widget.allFiles[index];
          bool isVideo = ['.mp4', '.mov', '.avi'].contains(p.extension(file.path).toLowerCase());
          return Center(child: isVideo ? (_videoController != null && _videoController!.value.isInitialized ? AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!)) : const CircularProgressIndicator()) : InteractiveViewer(child: Image.file(file)));
        },
      ),
    );
  }

  // --- CONFIRM SINGLE DELETE POPUP ---
  void _confirmSingleDelete(File file) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF161B22),
      title: const Text("Delete permanently from phone?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.white38))),
        TextButton(onPressed: () { 
          file.deleteSync(); 
          Navigator.pop(ctx); // Close Popup
          Navigator.pop(context, true); // Close Detail and return true to refresh grid
        }, child: const Text("DELETE", style: TextStyle(color: Colors.redAccent))),
      ],
    ));
  }

  Future<void> _removeFromAlbum(File file) async {
    final docDir = await getApplicationDocumentsDirectory();
    await file.rename(p.join(docDir.path, p.basename(file.path))); 
    if (mounted) Navigator.pop(context);
  }

  void _showProperties(File file) {
    final stats = file.statSync();
    final sizeMb = (file.lengthSync() / (1024 * 1024)).toStringAsFixed(2);
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF161B22), builder: (ctx) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("PROPERTIES", style: TextStyle(color: Color(0xFF58A6FF), fontWeight: FontWeight.bold)),
        const Divider(color: Colors.white10),
        Text("Size: $sizeMb MB", style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Text("Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(stats.changed)}", style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Text("Path: ${file.path}", style: const TextStyle(fontSize: 12, color: Colors.white30)),
      ]),
    ));
  }
}