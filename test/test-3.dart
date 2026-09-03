class Temperature {
  final double celsius;
  final double fahrenheit;

  Temperature.fromFahrenheit(double f)
      : assert(f >= -459.67, '温度不能低于绝对零度'),
        celsius = (f - 32) * 5 / 9,
        fahrenheit = f;
}
void main() {
  final temp = Temperature.fromFahrenheit(200);
  print(temp.celsius);

}