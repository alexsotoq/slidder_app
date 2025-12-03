import 'package:flutter/material.dart';

/// Provider global para el fondo animado compartido
class GlobalBackgroundProvider extends InheritedWidget {
  final AnimationController controller;

  const GlobalBackgroundProvider({
    super.key,
    required this.controller,
    required super.child,
  });

  static GlobalBackgroundProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GlobalBackgroundProvider>();
  }

  @override
  bool updateShouldNotify(GlobalBackgroundProvider oldWidget) {
    return controller != oldWidget.controller;
  }
}

/// Widget que mantiene el AnimationController vivo durante toda la app
class GlobalBackgroundWrapper extends StatefulWidget {
  final Widget child;

  const GlobalBackgroundWrapper({
    super.key,
    required this.child,
  });

  @override
  State<GlobalBackgroundWrapper> createState() => _GlobalBackgroundWrapperState();
}

class _GlobalBackgroundWrapperState extends State<GlobalBackgroundWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    print("🎮 GlobalBackgroundWrapper: Controlador creado"); // DEBUG
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    print("🎮 GlobalBackgroundWrapper: Controlador eliminado"); // DEBUG
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalBackgroundProvider(
      controller: _backgroundController,
      child: widget.child,
    );
  }
}

/// Widget reutilizable para renderizar el fondo scrolling
class ScrollingBackground extends StatelessWidget {
  final Color? overlayColor;

  const ScrollingBackground({
    super.key,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    // Busca el provider
    final provider = GlobalBackgroundProvider.of(context);

    print("🎨 ScrollingBackground: Provider encontrado? ${provider != null}"); // DEBUG

    if (provider == null) {
      print("❌ ScrollingBackground: NO SE ENCONTRÓ PROVIDER - Mostrando fallback azul"); // DEBUG
      return Stack(
        children: [
          Container(color: const Color(0xFF1565C0)),
          Container(
            color: (overlayColor ?? Colors.blueAccent).withOpacity(0.75),
          ),
        ],
      );
    }

    print("✅ ScrollingBackground: Provider encontrado - Mostrando fondo animado"); // DEBUG

    return Stack(
      children: [
        // Fondo animado
        AnimatedBuilder(
          animation: provider.controller,
          builder: (context, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                const patternHeight = 1000.0;
                final offset = (provider.controller.value * patternHeight) % patternHeight;

                return ClipRect(
                  child: Stack(
                    children: [
                      for (var i = -1; i <= 0; i++)
                        Positioned(
                          left: 0,
                          top: offset + (i * patternHeight),
                          child: Container(
                            width: constraints.maxWidth,
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
        ),
        // Overlay de color
        Container(
          color: (overlayColor ?? Colors.blueAccent).withOpacity(0.75),
        ),
      ],
    );
  }
}