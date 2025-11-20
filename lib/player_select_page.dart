import 'package:flutter/material.dart';

class PlayerSelectPage extends StatelessWidget {
  final String currentPlayer;
  
  const PlayerSelectPage({super.key, required this.currentPlayer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elige tu Jugador'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _PlayerCard(
              playerName: 'red',
              imagePath: 'assets/players/red_player.png',
              isSelected: currentPlayer == 'red',
              onTap: () {
                Navigator.pop(context, 'red');
              },
            ),

            _PlayerCard(
              playerName: 'green',
              imagePath: 'assets/players/player_green.png',
              isSelected: currentPlayer == 'green',
              onTap: () {
                Navigator.pop(context, 'green');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final String playerName;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlayerCard({
    required this.playerName,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: Colors.blue, width: 4)
              : Border.all(color: Colors.grey.shade300, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              imagePath,
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),
            Text(
              playerName.toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}