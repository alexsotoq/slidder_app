import 'package:flutter/material.dart';
import 'game_page.dart';
import 'player_select_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String _selectedPlayer = 'red';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon Runner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // imagen del jugador seleccionado
            Text('Jugador actual:', style: Theme.of(context).textTheme.headlineSmall),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Image.asset(
                'assets/players/${_selectedPlayer == 'red' ? 'red_player.png' : 'player_green.png'}',
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
            
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GamePage(
                      playerName: _selectedPlayer,
                    ),
                  ),
                );
              },
              child: const Text('¡Jugar!'),
            ),
            const SizedBox(height: 20),
            
            TextButton(
              onPressed: () async {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayerSelectPage(
                      currentPlayer: _selectedPlayer,
                    ),
                  ),
                );

                if (result != null) {
                  setState(() {
                    _selectedPlayer = result;
                  });
                }
              },
              child: const Text('Elegir Jugador'),
            ),
          ],
        ),
      ),
    );
  }
}