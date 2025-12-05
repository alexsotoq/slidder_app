class Obstacle {
  final String id;
  final String imagePath; 
  double x;
  double y;
  final double width;
  final double height;
  final bool isAnimated;
  final int frameCount;     
  final int animationSpeed;  

  Obstacle({
    required this.id,
    required this.imagePath,
    required this.x,
    required this.y,
    this.width = 50,
    this.height = 50,
    this.isAnimated = false,
    this.frameCount = 1,
    this.animationSpeed = 150,
  });
}