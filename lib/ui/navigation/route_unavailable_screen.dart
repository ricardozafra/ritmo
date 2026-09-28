import 'package:flutter/material.dart';

class RouteUnavailableScreen extends StatelessWidget {
  const RouteUnavailableScreen({super.key});

  static const screenKey = ValueKey<String>('route-unavailable-screen');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: screenKey,
      appBar: AppBar(title: const Text('Destino indisponível')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Este destino não está disponível nesta fase.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
