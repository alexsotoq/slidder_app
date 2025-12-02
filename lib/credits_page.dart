import 'package:flutter/material.dart';

class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50), // Fondo oscuro para créditos
      body: Stack(
        children: [
          // Fondo de partículas o estrellas (simulado con opacidad)
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/seamless-pokeball-pattern-vector-11290309.png'),
                repeat: ImageRepeat.repeat,
                colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.8),
                    BlendMode.dstATop
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "CREDITOS",
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 30,
                      color: Colors.yellow,
                      shadows: [
                        Shadow(color: Colors.red, offset: Offset(2, 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),

                  _CreditSection(title: "PROGRAMACION", name: "TU NOMBRE"),
                  const SizedBox(height: 30),
                  _CreditSection(title: "ARTE", name: "ASSETS LIBRES"),
                  const SizedBox(height: 30),
                  _CreditSection(title: "MUSICA", name: "8-BIT SOUNDS"),

                  const Spacer(),

                  const Text(
                    "Gracias por jugar!",
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 10,
                      color: Colors.white54,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botón flotante estilo retro para volver
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 40),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditSection extends StatelessWidget {
  final String title;
  final String name;

  const _CreditSection({required this.title, required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 12,
            color: Colors.lightBlueAccent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}