enum VideoSource {
  random('Aleatoria'),
  coverr('Coverr'),
  pixabay('Pixabay'),
  archive('Internet Archive'),
  local('Videos locales');

  final String label;
  const VideoSource(this.label);
  static VideoSource parse(Object? name) =>
      values.firstWhere((v) => v.name == name, orElse: () => random);
}
