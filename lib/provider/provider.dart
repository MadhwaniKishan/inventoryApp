import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:inventory_app/model/item_model.dart';
import 'package:inventory_app/model/room_model.dart';

class ProviderBaseClass with ChangeNotifier {
  List<RoomModel> _roomList = new List();
  HashMap<String, Item> _itemMap = new HashMap();

  List<Item> _itemList = new List();

  List<RoomModel> get roomList => _roomList;

  List<Item> get itemList => _itemList;

  HashMap<String, Item> get itemMap => _itemMap;

  set roomList(List<RoomModel> value) {
    _roomList = value;
    notifyListeners();
  }

  set itemList(List<Item> value) {
    _itemList = value;
    notifyListeners();
  }

  set itemMap(itemMap) {
    _itemMap = itemMap;
    notifyListeners();
  }
}
