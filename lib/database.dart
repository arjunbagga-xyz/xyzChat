import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Contact {
  final int id;
  final String name;
  final String peerId;

  Contact({required this.id, required this.name, required this.peerId});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'peerId': peerId,
    };
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('contacts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(path, version: 1, onCreate: _createDB);
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future _createDB(Database db, int version) async {
    try {
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';

      await db.execute('''
CREATE TABLE contacts (
  id $idType,
  name $textType,
  peerId $textType
  )
''');
    } catch (e) {
      print('Error creating database: $e');
      rethrow;
    }
  }

  Future<Contact> create(Contact contact) async {
    try {
      final db = await instance.database;
      final id = await db.insert('contacts', contact.toMap());
      return contact;
    } catch (e) {
      print('Error creating contact: $e');
      rethrow;
    }
  }

  Future<Contact> readContact(int id) async {
    try {
      final db = await instance.database;

      final maps = await db.query(
        'contacts',
        columns: ['id', 'name', 'peerId'],
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Contact(
          id: maps.first['id'] as int,
          name: maps.first['name'] as String,
          peerId: maps.first['peerId'] as String,
        );
      } else {
        throw Exception('ID $id not found');
      }
    } catch (e) {
      print('Error reading contact: $e');
      rethrow;
    }
  }

  Future<List<Contact>> readAllContacts() async {
    try {
      final db = await instance.database;

      final result = await db.query('contacts');

      return result.map((json) => Contact(
        id: json['id'] as int,
        name: json['name'] as String,
        peerId: json['peerId'] as String,
      )).toList();
    } catch (e) {
      print('Error reading all contacts: $e');
      rethrow;
    }
  }

  Future<int> update(Contact contact) async {
    try {
      final db = await instance.database;

      return db.update(
        'contacts',
        contact.toMap(),
        where: 'id = ?',
        whereArgs: [contact.id],
      );
    } catch (e) {
      print('Error updating contact: $e');
      rethrow;
    }
  }

  Future<int> delete(int id) async {
    try {
      final db = await instance.database;

      return await db.delete(
        'contacts',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting contact: $e');
      rethrow;
    }
  }

  Future close() async {
    try {
      final db = await instance.database;

      db.close();
    } catch (e) {
      print('Error closing database: $e');
    }
  }
}
