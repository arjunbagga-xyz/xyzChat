import 'dart:io';

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('Signaling server listening on ${server.address}:${server.port}');

  await for (final request in server) {
    if (request.uri.path == '/') {
      final socket = await WebSocketTransformer.upgrade(request);
      print('Client connected');
      socket.listen((message) {
        print('Received message: $message');
        for (final client in clients) {
          if (client != socket) {
            client.add(message);
          }
        }
      }, onDone: () {
        print('Client disconnected');
        clients.remove(socket);
      });
      clients.add(socket);
    }
  }
}

final clients = <WebSocket>{};
