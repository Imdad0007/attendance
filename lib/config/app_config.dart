class AppConfig {
  const AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fkvybbyrbktpetdyqymt.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZrdnliYnlyYmt0cGV0ZHlxeW10Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxMTMwMTIsImV4cCI6MjA4NTY4OTAxMn0.W_5TT4lmAGoCck61kP36xJDRJSsLl5HOpITvRGEiwmA',
  );

  // --- VARIABLES META API (peuvent être surchargées par Supabase) ---
  static String whatsappPhoneNumberId = const String.fromEnvironment(
    'WHATSAPP_PHONE_NUMBER_ID',
    defaultValue: '1001899229676106',
  );

  static String whatsappToken = const String.fromEnvironment(
    'WHATSAPP_TOKEN',
    defaultValue:
        'EAAWdK9IJdl8BQo1WrzXiIQCcDugIKqOopK0cvZCOxYZC9uc3Y2hVLNgEubhlxEQE0PqywPfu2atGbpP5ZB7q3umuUh1uKfuJNl5Yioojub0luqOETXFnzJ2nyrZBn2LwgdeELD2XzGb5nAB2tFzCtaN7JYgCx3oah3xKNgishUmBQrye9ORySGun3fDtY89S0gZDZD',
  );

  // --- VARIABLES SERVEUR LOCAL
  static String localGatewayUrl = 'http://localhost:3000';

  /// Met à jour les configurations depuis la base de données
  static void updateFromMap(Map<String, String> config) {
    
    if (config.containsKey('local_gateway_url')) {
      localGatewayUrl = config['local_gateway_url']!;
      print("Passerelle Locale URL : $localGatewayUrl");
    }
    // Meta API
    if (config.containsKey('whatsapp_phone_id')) {
      whatsappPhoneNumberId = config['whatsapp_phone_id']!;
    }
    if (config.containsKey('whatsapp_token')) {
      whatsappToken = config['whatsapp_token']!;
    }

    
  }
}
