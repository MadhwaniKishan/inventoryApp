import 'package:inventory_app/db/database_provider.dart';

import 'item_model.dart';

class RoomModel {
  List<Item> items;
  String roomName;
  String roomId;

  RoomModel({this.items, this.roomName, this.roomId});

  factory RoomModel.fromJson(Map<String, dynamic> json, context) {
    List<Item> items = (json['items'] as List)
        .map((resultItem) => Item.fromJson(resultItem, json['room_name']))
        .toList();
    DatabaseProvider.db.insert(
        RoomModel(roomName: json['room_name'], roomId: json['room_id']));
    return RoomModel(
      items: items,
      roomName: json['room_name'],
      roomId: json['room_id'],
    );
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      DatabaseProvider.ROOM_NAME: roomName,
      DatabaseProvider.ROOM_ID: roomId,
    };
    return map;
  }

  RoomModel.fromMap(Map<String, dynamic> map) {
    roomName = map[DatabaseProvider.ROOM_NAME];
    roomId = map[DatabaseProvider.ROOM_ID];
  }
}
