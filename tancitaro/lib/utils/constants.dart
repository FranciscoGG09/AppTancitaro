class AppConstants {
  static const String appName = 'Gestión Municipal Tancítaro';
  static const String apiBaseUrl = 'https://api.tancitaro.gob.mx';

  // Rutas de API
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String newsEndpoint = '/news';
  static const String reportsEndpoint = '/reports';
  static const String usersEndpoint = '/users';

  // Configuración de base de datos
  static const String dbName = 'municipal_app.db';
  static const int dbVersion = 2;

  // Mensajes
  static const String networkError = 'Error de conexión. Verifica tu internet.';
  static const String serverError = 'Error del servidor. Intenta más tarde.';
  static const String invalidCredentials = 'Credenciales incorrectas.';
  static const String registrationSuccess =
      'Registro exitoso. Ya puedes iniciar sesión.';

  // Categorías de reportes
  static const List<String> reportCategories = [
    'Obras Públicas',
    'Seguridad',
    'Servicios Municipales',
    'Tránsito y Vialidad',
    'Alumbrado Público',
    'Recolección de Basura',
    'Parques y Jardines',
    'Otro',
  ];

  // Correos departamentales
  static const Map<String, String> departmentEmails = {
    'Obras Públicas': 'obraspublicas@tancitaro.gob.mx',
    'Seguridad': 'seguridad@tancitaro.gob.mx',
    'Servicios Municipales': 'servicios@tancitaro.gob.mx',
    'Tránsito y Vialidad': 'transito@tancitaro.gob.mx',
    'Alumbrado Público': 'alumbrado@tancitaro.gob.mx',
    'Recolección de Basura': 'basura@tancitaro.gob.mx',
    'Parques y Jardines': 'parques@tancitaro.gob.mx',
    'Otro': 'contacto@tancitaro.gob.mx',
  };
}
