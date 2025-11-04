import 'package:flutter/material.dart';

// Модель для представления узла дерева папок
class FolderNode {
  final String name;
  bool isProcessed;
  final List<FolderNode> children;
  bool isExpanded;

  FolderNode({
    required this.name,
    this.isProcessed = false,
    this.children = const [],
    this.isExpanded = false,
  });
}

// Основной виджет дерева папок
class FolderTreeWidget extends StatefulWidget {
  final List<FolderNode> folders;
  final Function(FolderNode)? onFolderTap;
  final EdgeInsets? padding;

  const FolderTreeWidget({
    Key? key,
    required this.folders,
    this.onFolderTap,
    this.padding,
  }) : super(key: key);

  @override
  State<FolderTreeWidget> createState() => _FolderTreeWidgetState();
}

class _FolderTreeWidgetState extends State<FolderTreeWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? const EdgeInsets.all(8.0),
      child: ListView(
        children: widget.folders
            .map((folder) => _buildFolderItem(folder, 0))
            .toList(),
      ),
    );
  }

  Widget _buildFolderItem(FolderNode folder, int depth) {
    final hasChildren = folder.children.isNotEmpty;
    final indentWidth = depth * 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: indentWidth),
          child: InkWell(
            onTap: () {
              if (hasChildren) {
                setState(() {
                  folder.isExpanded = !folder.isExpanded;
                });
              }
              widget.onFolderTap?.call(folder);
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 4.0,
                horizontal: 8.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Стрелка разворачивания (только если есть дочерние папки)
                  if (hasChildren)
                    AnimatedRotation(
                      turns: folder.isExpanded ? 0.25 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.arrow_right,
                        size: 16,
                        color: Colors.grey,
                      ),
                    )
                  else
                    const SizedBox(width: 16),
                  
                  const SizedBox(width: 4),
                  
                  // Индикатор состояния папки
                  Text(
                    folder.isProcessed ? '✅' : '📁',
                    style: const TextStyle(fontSize: 16),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Название папки
                  Flexible(
                    child: Text(
                      folder.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: hasChildren ? FontWeight.w500 : FontWeight.normal,
                        color: folder.isProcessed 
                            ? Colors.green.shade700 
                            : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Дочерние папки (если развернуты)
        if (hasChildren && folder.isExpanded)
          ...folder.children.map(
            (child) => _buildFolderItem(child, depth + 1),
          ),
      ],
    );
  }
}

// Пример использования
class FolderTreeExample extends StatefulWidget {
  @override
  State<FolderTreeExample> createState() => _FolderTreeExampleState();
}

class _FolderTreeExampleState extends State<FolderTreeExample> {
  late List<FolderNode> folders;

  @override
  void initState() {
    super.initState();
    folders = _createSampleData();
  }

  List<FolderNode> _createSampleData() {
    return [
      FolderNode(
        name: 'src',
        isProcessed: true,
        children: [
          FolderNode(
            name: 'widgets',
            isProcessed: false,
            children: [
              FolderNode(name: 'buttons', isProcessed: true),
              FolderNode(name: 'forms', isProcessed: false),
            ],
          ),
          FolderNode(name: 'models', isProcessed: true),
          FolderNode(
            name: 'services',
            isProcessed: false,
            children: [
              FolderNode(name: 'api', isProcessed: false),
              FolderNode(name: 'storage', isProcessed: true),
            ],
          ),
        ],
      ),
      FolderNode(
        name: 'assets',
        isProcessed: false,
        children: [
          FolderNode(name: 'images', isProcessed: false),
          FolderNode(name: 'fonts', isProcessed: true),
        ],
      ),
      FolderNode(name: 'docs', isProcessed: true),
      FolderNode(name: 'tests', isProcessed: false),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Дерево папок'),
        backgroundColor: Colors.blue.shade100,
      ),
      body: Column(
        children: [
          // Легенда
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Легенда:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text('📁', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Text('Папка не обработана'),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text('✅', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Text('Папка обработана'),
                  ],
                ),
              ],
            ),
          ),
          
          // Дерево папок
          Expanded(
            child: FolderTreeWidget(
              folders: folders,
              onFolderTap: (folder) {
                // Обработка нажатия на папку
                setState(() {
                  folder.isProcessed = !folder.isProcessed;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${folder.name}: ${folder.isProcessed ? "обработано" : "не обработано"}',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Главная функция для запуска примера
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Folder Tree Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FolderTreeExample(),
      debugShowCheckedModeBanner: false,
    );
  }
}