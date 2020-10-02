import 'package:inventory_app/db/database_provider.dart';

class Item {
  String itemName;
  String itemId;
  String itemWeight;
  String roomName;

  Item({this.itemId, this.itemName, this.itemWeight, this.roomName});

  factory Item.fromJson(Map<String, dynamic> json, String room) {
    DatabaseProvider.db.insertItem(Item(
        itemName: json['c_field_name'],
        itemWeight: json['c_weight'],
        roomName: room));
    return Item(
      itemName: json['c_field_name'],
      itemWeight: json['c_weight'],
      roomName: room,
    );
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      DatabaseProvider.ITEM_NAME: itemName,
      DatabaseProvider.ITEM_WEIGHT: itemWeight,
      DatabaseProvider.ROOM_NAME: roomName,
    };
    return map;
  }

  Item.fromMap(Map<String, dynamic> map) {
    itemName = map[DatabaseProvider.ITEM_NAME];
    itemWeight = map[DatabaseProvider.ITEM_WEIGHT];
    roomName = map[DatabaseProvider.ROOM_NAME];
  }
}
