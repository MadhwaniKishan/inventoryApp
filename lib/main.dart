import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_app/constants.dart' as Constants;
import 'package:inventory_app/provider/provider.dart';
import 'package:provider/provider.dart';

import 'api/api_call.dart';
import 'db/database_provider.dart';
import 'model/item_model.dart';
import 'model/room_model.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      builder: (_) => ProviderBaseClass(),
      child: MaterialApp(
        title: 'Room Items',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: MyHomePage(title: 'Rooms'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _showIndicator = false;
  int _selectedIndex = -1;
  int _itemSelectedIndex = -1;
  List<RoomModel> _roomList;
  List<Item> _itemList;
  LinkedHashMap<String, HashSet<Item>> _chipsMap = new LinkedHashMap();
  HashSet<Item> _allRooms = new HashSet();
  String _selectedChip = "";
  int _selectedChipIndex = -1;
  String _searchFilter = "";

  final _searchController = TextEditingController(text: "");
  final FocusNode _searchFocusNode = FocusNode();

  HashMap<String, TextEditingController> _textEditingController = new HashMap();
  HashMap _focusNode = new HashMap();

  @override
  void initState() {
    super.initState();
    DatabaseProvider.db.getRooms().then((roomList) => {
          if (roomList.length <= 0)
            {_getNewData(context)}
          else
            Provider.of<ProviderBaseClass>(context).roomList = roomList,
        });
  }

  @override
  Widget build(BuildContext context) {
    _roomList = Provider.of<ProviderBaseClass>(context).roomList;
    _itemList = Provider.of<ProviderBaseClass>(context).itemList;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: (_showIndicator)
          ? Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => _searchFocusNode.unfocus(),
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    _buildListViews(_roomList, _itemList, context),
                    Divider(
                      color: Colors.grey,
                      thickness: 1,
                      height: 0,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: _chipsMap.isEmpty
                          ? Center(child: Text("Add Items First"))
                          : Card(elevation: 5, child: _buildChipsView()),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildChipsView() {
    return Column(
      children: <Widget>[
        Container(
          height: 30,
          margin: EdgeInsets.all(15),
          child: ListView(
            // This next line does the trick.
            scrollDirection: Axis.horizontal,
            children: _getChips(),
          ),
        ),
        Divider(
          color: Colors.grey,
          thickness: 1,
          height: 10,
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: _getTableRows(),
          ),
        )
      ],
    );
  }

  _getTableRows() {
    List<TableRow> _list = new List<TableRow>();
    HashSet<Item> _itemList = _chipsMap[_selectedChip];
    if (_itemList != null) {
      _itemList.forEach((element) {
        if (!_textEditingController.containsKey(element.itemName))
          _textEditingController[element.itemName] =
              new TextEditingController(text: "1");
        _focusNode[element.itemName] = new FocusNode();
      });
    }
    _list.add(TableRow(children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text("Item"),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text("Qty"),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text("Calculated (LBS)"),
      ),
    ]));
    if (_itemList != null) {
      if (_itemList.length >= 0) {
        _itemList.forEach((element) {
          _list.add(TableRow(children: [
            Text(element.itemName),
            Container(
              height: 20,
              width: 10,
              child: TextField(
                showCursor: false,
                focusNode: _focusNode[element.itemName],
                inputFormatters: [
                  BlacklistingTextInputFormatter(RegExp('[, -]')),
                ],
                enableInteractiveSelection: false,
                onChanged: (String value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 1.0),
                    borderRadius: BorderRadius.all(Radius.zero),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                    borderRadius: BorderRadius.all(Radius.zero),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                controller: _textEditingController[element.itemName],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text((double.parse(
                              ((_textEditingController[element.itemName]
                                          .text
                                          .trim()
                                          .length) <=
                                      0
                                  ? "1"
                                  : _textEditingController[element.itemName]
                                      .text
                                      .trim())) *
                          double.parse(element.itemWeight.trim()))
                      .toString()),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                      onTap: () => _removeItemFromChip(element),
                      child: Icon(Icons.delete, color: Colors.red)),
                ),
              ],
            ),
          ]));
        });
      }
    }

    return _list;
  }

  _getChips() {
    List<Widget> _list = new List<Widget>();
    List<String> _chipsName = _chipsMap.keys.toList().toList();
    for (int i = 0; i < _chipsName.length; i++) {
      _list.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: new FlatButton(
            textColor: Colors.black,
            onPressed: () => _changeChip(_chipsName[i], i),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            color: _selectedChipIndex == i ? Colors.green : Colors.white,
            child: Text(_chipsName[i] +
                " (" +
                _chipsMap[_chipsName[i]].length.toString() +
                ")"),
          ),
        ),
      );
    }
    return _list;
  }

  _changeChip(roomName, index) {
    setState(() {
      _selectedChip = roomName;
      _selectedChipIndex = index;
    });
  }

  Widget _buildListViews(roomList, itemList, context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildRoomView(roomList)),
        Container(
          height: MediaQuery.of(context).size.height * 0.5,
          child: VerticalDivider(
            indent: 0,
            endIndent: 0,
            width: 2,
            thickness: 2,
          ),
        ),
        Container(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildItemsView(itemList)),
      ],
    );
  }

  Widget _buildItemsView(List<Item> itemListPassed) {
    final List<Item> _itemList = itemListPassed
        .where((element) => element.itemName
            .toLowerCase()
            .replaceAll(" ", "")
            .contains(_searchFilter.toLowerCase().trim().replaceAll(" ", "")))
        .toList();
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            'Items',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.search,
                color: Colors.black,
                size: 20,
              ),
              Container(
                width: 150,
                height: 30,
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                      hintText: 'Search', border: InputBorder.none),
                  onChanged: (String value) {
                    setState(() {
                      _searchFilter = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Divider(thickness: 2, color: Colors.black),
        Container(
          height: 250,
          width: 200,
          child: _itemList.length <= 0
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('No Items'),
                )
              : ListView.separated(
                  separatorBuilder: (BuildContext context, int index) =>
                      Divider(height: 1, color: Colors.grey),
                  itemBuilder: (ctx, index) {
                    return Container(
                      color: _itemSelectedIndex == index
                          ? Colors.grey
                          : Colors.white,
                      child: GestureDetector(
                        onTap: () => _addItemToChip(_itemList[index], index),
                        child: Row(
                          children: <Widget>[
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  _itemList[index].itemName,
                                  softWrap: false,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  itemCount: _itemList.length,
                ),
        ),
      ],
    );
  }

  Widget _buildRoomView(roomList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            'Rooms',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          height: 300,
          width: 200,
          child: ListView.separated(
            separatorBuilder: (BuildContext context, int index) =>
                Divider(height: 1, color: Colors.grey),
            itemBuilder: (ctx, index) {
              return GestureDetector(
                onTap: () =>
                    _changeItemList(roomList[index].roomName, context, index),
                child: Container(
                  color: _selectedIndex == index ? Colors.grey : Colors.white,
                  child: Row(
                    children: <Widget>[
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            roomList[index].roomName,
                            softWrap: false,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            itemCount: roomList.length,
          ),
        ),
      ],
    );
  }

  _addItemToChip(Item item, index) {
    setState(() {
      _itemSelectedIndex = index;
      _allRooms.add(item);
      _chipsMap["All rooms"] = _allRooms;
      if (!_chipsMap.containsKey(item.roomName)) {
        HashSet<Item> itemList = new HashSet();
        itemList.add(item);
        _chipsMap[item.roomName] = itemList;
      } else {
        HashSet<Item> itemList = new HashSet();
        itemList = _chipsMap[item.roomName];
        itemList.add(item);
        _chipsMap[item.roomName] = itemList;
      }
    });
  }

  _removeItemFromChip(Item item) {
    setState(() {
      _allRooms.remove(item);
      if (_chipsMap.containsKey(item.roomName)) {
        HashSet<Item> itemList = _chipsMap[item.roomName];
        itemList.remove(item);
        if (itemList.isEmpty) {
          _chipsMap.remove(item.roomName);
        } else
          _chipsMap[item.roomName] = itemList;
      }
    });
  }

  _changeItemList(roomName, context, index) {
    setState(() {
      _itemSelectedIndex = -1;
    });
    setState(() => _selectedIndex = index);
    DatabaseProvider.db.getItems(roomName).then((itemList) => {
          Provider.of<ProviderBaseClass>(context).itemList = itemList,
        });
  }

  _getNewData(context) async {
    _startIndicator();
    DatabaseProvider.db.deleteAllData().then((value) {
      fetchRoomDetails(Constants.roomDetailsApi).then((value) async {
        if (value.statusCode == 200) {
          var body = json.decode(value.body);
          (body['data']['itemslist'] as List)
              .map((resultRoom) => RoomModel.fromJson(resultRoom, context))
              .toList();
          DatabaseProvider.db.getRooms().then((roomList) => {
                Provider.of<ProviderBaseClass>(context).roomList = roomList,
                _stopIndicator()
              });
        } else {
          _stopIndicator();
          throw Exception('Failed to load rooms');
        }
      });
    });
  }

  _startIndicator() {
    setState(() {
      _showIndicator = true;
    });
  }

  _stopIndicator() {
    setState(() {
      _showIndicator = false;
    });
  }
}
