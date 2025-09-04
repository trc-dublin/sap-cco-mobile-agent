import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat_message.dart';
import '../models/scan_item.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'sap_cco_mobile.db';
  static const int _dbVersion = 1;

  // Table names
  static const String _chatTable = 'chat_messages';
  static const String _scanTable = 'scan_history';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create chat messages table
    await db.execute('''
      CREATE TABLE $_chatTable (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        isUser INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        metadata TEXT
      )
    ''');

    // Create scan history table
    await db.execute('''
      CREATE TABLE $_scanTable (
        id TEXT PRIMARY KEY,
        barcode TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        status INTEGER NOT NULL,
        itemName TEXT,
        description TEXT,
        errorMessage TEXT
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_chat_timestamp ON $_chatTable (timestamp DESC)');
    await db.execute('CREATE INDEX idx_scan_timestamp ON $_scanTable (timestamp DESC)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 2) {
      // Example migration
    }
  }

  Future<void> init() async {
    await database;
  }

  // Chat Message Methods
  Future<void> saveChatMessage(ChatMessage message) async {
    final db = await database;
    await db.insert(
      _chatTable,
      {
        'id': message.id,
        'content': message.content,
        'isUser': message.isUser ? 1 : 0,
        'timestamp': message.timestamp.toIso8601String(),
        'metadata': message.metadata != null ? message.metadata.toString() : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatMessage>> getChatHistory({int limit = 100}) async {
    final db = await database;
    final maps = await db.query(
      _chatTable,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.reversed.map((map) {
      return ChatMessage(
        id: map['id'] as String,
        content: map['content'] as String,
        isUser: (map['isUser'] as int) == 1,
        timestamp: DateTime.parse(map['timestamp'] as String),
        metadata: null, // Parse metadata if needed
      );
    }).toList();
  }

  Future<void> clearChatHistory() async {
    final db = await database;
    await db.delete(_chatTable);
  }

  Future<void> deleteChatMessage(String id) async {
    final db = await database;
    await db.delete(
      _chatTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Scan History Methods
  Future<void> saveScanItem(ScanItem item) async {
    final db = await database;
    await db.insert(
      _scanTable,
      {
        'id': item.id,
        'barcode': item.barcode,
        'timestamp': item.timestamp.toIso8601String(),
        'quantity': item.quantity,
        'status': item.status.index,
        'itemName': item.itemName,
        'description': item.description,
        'errorMessage': item.errorMessage,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ScanItem>> getScanHistory({int limit = 100}) async {
    final db = await database;
    final maps = await db.query(
      _scanTable,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) {
      return ScanItem(
        id: map['id'] as String,
        barcode: map['barcode'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        quantity: map['quantity'] as int,
        status: ScanStatus.values[map['status'] as int],
        itemName: map['itemName'] as String?,
        description: map['description'] as String?,
        errorMessage: map['errorMessage'] as String?,
      );
    }).toList();
  }

  Future<void> clearScanHistory() async {
    final db = await database;
    await db.delete(_scanTable);
  }

  Future<void> deleteScanItem(String id) async {
    final db = await database;
    await db.delete(
      _scanTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Export Methods
  Future<Map<String, dynamic>> exportData() async {
    final chatHistory = await getChatHistory(limit: 1000);
    final scanHistory = await getScanHistory(limit: 1000);

    return {
      'exportDate': DateTime.now().toIso8601String(),
      'version': _dbVersion,
      'chatMessages': chatHistory.map((m) => m.toJson()).toList(),
      'scanHistory': scanHistory.map((s) => s.toJson()).toList(),
    };
  }

  // Database maintenance
  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  Future<int> getDatabaseSize() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    // Implementation would check file size
    return 0;
  }
}