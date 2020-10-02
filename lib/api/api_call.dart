import 'package:http/http.dart' as http;

Future<http.Response> fetchRoomDetails(apiString) async {
  return await http.get(apiString);
}
