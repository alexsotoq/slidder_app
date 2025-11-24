class Obstacle {
  final String id;
  final String imagePath;
  double x;
  double y;
  final double width;
  final double height;

  Obstacle({
    required this.id,
    required this.imagePath,
    required this.x,
    required this.y,
    this.width = 50,
    this.height = 50,
  });
}