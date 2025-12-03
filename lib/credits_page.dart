import 'package:flutter/material.dart';

class CreditsPage extends StatefulWidget {
  final Color? backgroundColor; // Nuevo parámetro opcional para color de fondo

  const CreditsPage({
    super.key,
    this.backgroundColor, // Parámetro opcional
  });

  @override
  State<CreditsPage> createState() => _CreditsPageState();
}

class _CreditsPageState extends State<CreditsPage> with TickerProviderStateMixin {
  late AnimationController _backgroundController; // Nuevo controlador para scroll del fondo

  @override
  void initState() {
    super.initState();

    // Configura scroll continuo del fondo (igual que en menu_page)
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _backgroundController.dispose(); // Limpiar controlador
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo scrolling con animación (igual que menu_page)
          _buildScrollingBackground(),

          // Overlay con color personalizado o azul por defecto
          Container(
            color: widget.backgroundColor?.withOpacity(0.75) ?? Colors.blueAccent.withOpacity(0.75),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Título CRÉDITOS (mismo estilo que menú)
                    Stack(
                      children: [
                        // Sombra
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Text(
                            "CREDITOS",
                            style: const TextStyle(
                              fontFamily: 'PressStart2P',
                              fontSize: 32,
                              color: Colors.black,
                              height: 1,
                            ),
                          ),
                        ),
                        // Texto principal
                        const Text(
                          "CREDITOS",
                          style: TextStyle(
                            fontFamily: 'PressStart2P',
                            fontSize: 32,
                            color: Color(0xFFFDD835), // Amarillo Pokémon
                            height: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 60),

                    // Título equipo (mismo estilo)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF81C784),
                        border: Border.all(color: const Color(0xFF519657), width: 3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "EQUIPO",
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 14,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Lista de desarrolladores (más minimalista)
                    _DeveloperItem(name: "ELDA BERENICE MATUS VALENCIA"),
                    const SizedBox(height: 12),
                    _DeveloperItem(name: "ADRIANA LEON CAMACHO"),
                    const SizedBox(height: 12),
                    _DeveloperItem(name: "ALEX EDUARDO SOTO QUIÑONEZ"),

                    const SizedBox(height: 40),

                    // Disclaimer (más breve)
                    Container(
                      width: 320,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        border: Border.all(color: Color(0xFFB7B7BD), width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "PROYECTO ACADEMICO — DESARROLLO DE APLICACIONES MOVILES (2025-2)\n"
                            "SIN FINES DE LUCRO. CREDITOS DE IMAGENES Y MUSICA A SUS AUTORES.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 8, // más pequeño
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                    ),


                    const SizedBox(height: 40),

                    // Botón de regreso (mismo estilo que player_select_page)
                    _PixelButton(
                      text: "< VOLVER",
                      color: const Color(0xFF64B5F6),
                      darkColor: const Color(0xFF2286C3),
                      onPressed: () => Navigator.pop(context),
                    ),

                    const SizedBox(height: 30),

                    // Versión (mismo estilo)
                    const Text(
                      "VERSION 1.0",
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 8,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Método para construir el fondo con scroll (copiado de menu_page)
  Widget _buildScrollingBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Altura del patrón original en píxeles
            const patternHeight = 1000.0;

            // Calcula offset actual usando módulo para loop infinito
            final offset = (_backgroundController.value * patternHeight) % patternHeight;

            return ClipRect(
              child: Stack(
                children: [
                  // Genera dos capas: una en offset actual, otra en offset - altura
                  for (var i = -1; i <= 0; i++)
                    Positioned(
                      left: 0,
                      top: offset + (i * patternHeight),
                      child: Container(
                        width: constraints.maxWidth,
                        // Altura extra para cubrir durante transición
                        height: constraints.maxHeight + patternHeight,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/seamless-pokeball-pattern-vector-11290309.png'),
                            repeat: ImageRepeat.repeat,
                            fit: BoxFit.none,
                            scale: 2.0,
                            filterQuality: FilterQuality.none,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CreditCard extends StatelessWidget {
  final String title;
  final String content;

  const _CreditCard({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border.all(color: const Color(0xFFB7B7BD), width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 12,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 10,
              color: Color(0xFFFDD835), // Amarillo Pokémon
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeveloperItem extends StatelessWidget {
  final String name;

  const _DeveloperItem({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: const Color(0xFF64B5F6), width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'PressStart2P',
          fontSize: 10,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// Botón pixel art idéntico al de player_select_page
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
                    ),
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