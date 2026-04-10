class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.mapStyleUrl,
    required this.graphHopperBaseUrl,
  });

  factory AppConfig.fromEnvironment() => const AppConfig(
        supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
        supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
        mapStyleUrl: String.fromEnvironment(
          'MAP_STYLE_URL',
          defaultValue: 'https://demotiles.maplibre.org/style.json',
        ),
        graphHopperBaseUrl: String.fromEnvironment(
          'GRAPHHOPPER_BASE_URL',
          defaultValue: 'https://graphhopper.com/api/1',
        ),
      );

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String mapStyleUrl;
  final String graphHopperBaseUrl;

  bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
