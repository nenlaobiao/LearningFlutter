class Point {
  final int x;
  final int y;

  Point(this.x, this.y);

  Point operator *(int factor) {
  return Point(x * factor, y * factor);
}


  @override
  String toString() => 'Point($x, $y)';
}

void main() {
  var p = Point(2, 3);
  print(p * 2); // Point(4, 6)
}