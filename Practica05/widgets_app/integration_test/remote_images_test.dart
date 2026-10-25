import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:widgets_app/presentation/widgets/remote_image.dart';

void main() {
  // Optional test-only DNS recovery for an emulator whose DNS is unavailable.
  // Socket transport remains real and HttpClient still verifies TLS host names.
  const dnsJSON = String.fromEnvironment('REMOTE_DNS_JSON', defaultValue: '{}');
  final dns = Map<String, String>.from(jsonDecode(dnsJSON) as Map);
  if (dns.isNotEmpty) HttpOverrides.global = _TestDnsOverrides(dns);
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> waitFor(WidgetTester tester, bool Function() ready) async {
    final deadline = DateTime.now().add(const Duration(seconds: 45));
    while (!ready() && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 100));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(ready(), isTrue, reason: 'Image state did not arrive within 45s');
  }

  bool photoDecoded() => find.byType(RawImage).evaluate().any((element) {
    final image = (element.widget as RawImage).image;
    return image != null && image.width == 600 && image.height == 350;
  });

  testWidgets('Gallery and card photos load from real HTTPS', (tester) async {
    for (final url in [
      'https://picsum.photos/seed/widgets-1/600/350',
      'https://picsum.photos/id/1/600/350',
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteImage(key: ValueKey(url), url: url),
          ),
        ),
      );
      await waitFor(tester, photoDecoded);
      expect(find.text('Reintentar'), findsNothing);
      // Gives ADB time to capture the actual downloaded image during this test.
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  });

  testWidgets('Real HTTP 503 changes to a decoded photo after retry', (
    tester,
  ) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    addTearDown(() => client.close(force: true));
    final request = await client.getUrl(
      Uri.parse('https://picsum.photos/seed/widgets-retry/600/350'),
    );
    final response = await request.close().timeout(const Duration(seconds: 30));
    expect(response.statusCode, HttpStatus.ok);
    final bytes = BytesBuilder();
    await for (final chunk in response.timeout(const Duration(seconds: 15))) {
      bytes.add(chunk);
    }
    final photo = bytes.takeBytes();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var requests = 0;
    server.listen((request) async {
      requests++;
      if (requests == 1) {
        request.response.statusCode = HttpStatus.serviceUnavailable;
      } else {
        request.response.headers.contentType = ContentType('image', 'jpeg');
        request.response.add(photo);
      }
      await request.response.close();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RemoteImage(url: 'http://127.0.0.1:${server.port}/photo'),
        ),
      ),
    );
    await waitFor(tester, () => find.text('Reintentar').evaluate().isNotEmpty);
    await Future<void>.delayed(const Duration(seconds: 2));
    await tester.tap(find.text('Reintentar'));
    await waitFor(tester, photoDecoded);
    expect(requests, 2);
    expect(find.text('Reintentar'), findsNothing);
    await Future<void>.delayed(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
  });
}

class _TestDnsOverrides extends HttpOverrides {
  final Map<String, String> addresses;
  _TestDnsOverrides(this.addresses);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionFactory = (uri, proxyHost, proxyPort) =>
        Socket.startConnect(addresses[uri.host] ?? uri.host, uri.port);
    return client;
  }
}
