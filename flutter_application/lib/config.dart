// API Configuration
class ApiConfig {
  // Change this based on environment
  static const bool isProduction = false;
  
  // Production URL (deploy your backend to Render, Railway, Heroku, etc.)
  static const String productionUrl = 'https://your-backend.railway.app';
  
  // Development URL (your local machine IP)
  // Update this IP whenever it changes
  static const String developmentUrl = 'http://192.168.1.6:3000';
  
  // Use the appropriate URL
  static String get baseUrl => isProduction ? productionUrl : developmentUrl;
  
  // API Endpoints
  static String get createPaymentEndpoint => '$baseUrl/create-appointment-payment';
  static String get healthCheckEndpoint => '$baseUrl/health';
}
