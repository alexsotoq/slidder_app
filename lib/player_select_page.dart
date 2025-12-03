import 'package:flutter/material.dart';
import 'global_background.dart';

class PlayerSelectPage extends StatefulWidget {
  final String currentPlayer;
  final Color? backgroundColor;

  const PlayerSelectPage({
    super.key,
    required this.currentPlayer,
    this.backgroundColor,
  });

  @override
  State<PlayerSelectPage> createState() => _PlayerSelectPageState();
}

class _PlayerSelectPageState extends State<PlayerSelectPage> with TickerProviderStateMixin {
  late String _selectedPlayer;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _selectedPlayer = widget.currentPlayer;

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // USA EL FONDO GLOBAL COMPARTIDO
          const ScrollingBackground(),

          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _BackButton(
                      onPressed: () => Navigator.pop(context, _selectedPlayer),
                    ),
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Text(
                                  "ELIGE TU",
                                  style: const TextStyle(
                                    fontFamily: 'PressStart2P',
                                    fontSize: 28,
                                    color: Colors.black,
                                    height: 1,
                                  ),
                                ),
                              ),
                              const Text(
                                "ELIGE TU",
                                style: TextStyle(
                                  fontFamily: 'PressStart2P',
                                  fontSize: 28,
                                  color: Color(0xFFFDD835),
                                  height: 1,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE57373),
                              border: Border.all(color: const Color(0xFFD35D5D), width: 3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "JUGADOR",
                              style: TextStyle(
                                fontFamily: 'PressStart2P',
                                fontSize: 14,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 20,
                            runSpacing: 20,
                            children: [
                              _PlayerCard(
                                playerName: "RED",
                                imagePath: "assets/players/red_player.png",
                                isSelected: _selectedPlayer == 'red',
                                floatAnimation: _floatAnimation,
                                onTap: () {
                                  setState(() {
                                    _selectedPlayer = 'red';
                                  });
                                },
                              ),
                              _PlayerCard(
                                playerName: "GREEN",
                                imagePath: "assets/players/player_green.png",
                                isSelected: _selectedPlayer == 'green',
                                floatAnimation: _floatAnimation,
                                onTap: () {
                                  setState(() {
                                    _selectedPlayer = 'green';
                                  });
                                },
                              ),
                              _PlayerCard(
                                playerName: "BRENDAN",
                                imagePath: "assets/players/brendan_player.png",
                                isSelected: _selectedPlayer == 'brendan',
                                floatAnimation: _floatAnimation,
                                onTap: () {
                                  setState(() {
                                    _selectedPlayer = 'brendan';
                                  });
                                },
                              ),
                              _PlayerCard(
                                playerName: "MAY",
                                imagePath: "assets/players/may_player.png",
                                isSelected: _selectedPlayer == 'may',
                                floatAnimation: _floatAnimation,
                                onTap: () {
                                  setState(() {
                                    _selectedPlayer = 'may';
                                  });
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          _PixelButton(
                            text: "CONFIRMAR",
                            color: const Color(0xFF81C784),
                            darkColor: const Color(0xFF519657),
                            onPressed: () => Navigator.pop(context, _selectedPlayer),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final String playerName;
  final String imagePath;
  final bool isSelected;
  final Animation<double> floatAnimation;
  final VoidCallback onTap;

  const _PlayerCard({
    required this.playerName,
    required this.imagePath,
    required this.isSelected,
    required this.floatAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: floatAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, floatAnimation.value),
            child: child,
          );
        },
        child: Column(
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                border: Border.all(
                  color: isSelected ? const Color(0xFF81C784) : const Color(0xFFB7B7BD),
                  width: isSelected ? 6 : 4,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? const Color(0xFF519657) : const Color(0xFF818185)).withOpacity(0.3),
                    blurRadius: isSelected ? 15 : 10,
                    spreadRadius: isSelected ? 3 : 2,
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  imagePath,
                  height: 100,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF81C784) : const Color(0xFFB7B7BD),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? const Color(0xFF519657) : const Color(0xFF818185),
                  width: 2,
                ),
              ),
              child: Text(
                playerName,
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 12,
                  color: Colors.white,
                  height: 1,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isHovered && !_isPressed ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                margin: EdgeInsets.only(
                  top: _isPressed ? 3 : 0,
                  left: _isPressed ? 3 : 0,
                ),
                decoration: BoxDecoration(
                  color: _isHovered && !_isPressed
                      ? Color.lerp(const Color(0xFF64B5F6), Colors.white, 0.15)
                      : const Color(0xFF64B5F6),
                  border: Border.all(color: const Color(0xFF2286C3), width: 3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
                      left: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "< VOLVER",
                        style: const TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 10,
                          color: Colors.white,
                          height: 1,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PixelButton extends StatefulWidget {
  final String text;
  final Color color;
  final Color darkColor;
  final VoidCallback onPressed;

  const _PixelButton({
    required this.text,
    required this.color,
    required this.darkColor,
    required this.onPressed,
  });

  @override
  State<_PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<_PixelButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isHovered && !_isPressed ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 220,
                height: 48,
                margin: EdgeInsets.only(
                  top: _isPressed ? 4 : 0,
                  left: _isPressed ? 4 : 0,
                ),
                decoration: BoxDecoration(
                  color: _isHovered && !_isPressed
                      ? Color.lerp(widget.color, Colors.white, 0.15)
                      : widget.color,
                  border: Border.all(color: widget.darkColor, width: 3),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isHovered && !_isPressed
                      ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
                      : [],
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
                      left: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.text,
                      style: const TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 12,
                        color: Colors.white,
                        height: 1,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}