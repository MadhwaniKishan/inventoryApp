import 'package:inventory_app/model/item_model.dart';
import 'package:inventory_app/model/room_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseProvider {
  static const String ROOMS_TABLE = "rate";
  static const String COLUMN_ID = "id";
  static const String ROOM_NAME = "name";
  static const String ROOM_ID = "roomid";

  static const String ITEMS_TABLE = "items";

  static const String ITEM_NAME = "itemname";
  static const String ITEM_WEIGHT = "itemweight";

  DatabaseProvider._();

  static final DatabaseProvider db = DatabaseProvider._();

  Database _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database;
    }
    _database = await createDatabase();
    return _database;
  }

  Future<Database> createDatabase() async {
    String dbPath = await getDatabasesPath();
    return await openDatabase(
      join(dbPath, "roomDatabase.db"),
      version: 1,
      onCreate: (Database database, int version) async {
        await database.execute(
          "Create Table $ROOMS_TABLE ("
          "$COLUMN_ID INTEGER PRIMARY KEY,"
          "$ROOM_NAME TEXT,"
          "$ROOM_ID TEXT"
          ")",
        );
        await database.execute(
          "Create Table $ITEMS_TABLE ("
          "$ITEM_NAME TEXT,"
          "$ITEM_WEIGHT TEXT,"
          "$ROOM_NAME TEXT"
          ")",
        );
      },
    );
  }

  Future<List<RoomModel>> getRooms() async {
    final db = await database;

    var rooms =
        await db.query(ROOMS_TABLE, columns: [COLUMN_ID, ROOM_NAME, ROOM_ID]);
    List<RoomModel> roomList = new List();
    rooms.forEach((rateDetail) {
      RoomModel rate = RoomModel.fromMap(rateDetail);
      roomList.add(rate);
    });
    return roomList;
  }

  Future<List<Item>> getItems(String roomName) async {
    final db = await database;
    var items = await db.query(ITEMS_TABLE,
        columns: [
          // COLUMN_ITEM_ID,
          ITEM_NAME, ITEM_WEIGHT, ROOM_NAME
        ],
        where: '$ROOM_NAME = ?',
        whereArgs: ['$roomName']);

    List<Item> itemList = new List();
    items.forEach((itemDetail) {
      Item item = Item.fromMap(itemDetail);
      itemList.add(item);
    });
    return itemList;
  }

  Future<RoomModel> insert(RoomModel room) async {
    final db = await database;
    await db.insert(ROOMS_TABLE, room.toMap());
    return room;
  }

  Future<Item> insertItem(Item item) async {
    final db = await database;
    await db.insert(ITEMS_TABLE, item.toMap());
    return item;
  }

  Future<int> deleteAllData() async {
    final db = await database;
    final res = await db.rawDelete('DELETE FROM $ROOMS_TABLE');
    return res;
  }
}
