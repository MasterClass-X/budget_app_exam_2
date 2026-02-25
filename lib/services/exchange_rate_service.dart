import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeRateService {
  // TA VRAIE CLÉ API
  static const String _apiKey = '750fb684c451fa9a8853c397';
  static const String _baseUrl = 'https://v6.exchangerate-api.com/v6/';

  // Taux de change réels (avec support CDF)
  Future<Map<String, double>> getExchangeRates(String baseCurrency) async {
    try {
      // Construction correcte de l'URL
      final url = '$_baseUrl$_apiKey/latest/$baseCurrency';
      print('URL appelée: $url'); // Pour déboguer (à retirer plus tard)

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Vérifier que l'API a répondu avec succès
        if (data['result'] == 'success') {
          Map<String, dynamic> rates = data['conversion_rates'];

          // Convertir en Map<String, double>
          return rates.map((key, value) => MapEntry(key, value.toDouble()));
        } else {
          throw Exception('Erreur API: ${data['error-type']}');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur détaillée: $e');
      // En cas d'erreur, retourner des taux par défaut
      return _getDefaultRates(baseCurrency);
    }
  }

  // Taux par défaut en cas d'erreur (avec CDF) - MAINTENANT AVEC USD COMME BASE
  Map<String, double> _getDefaultRates(String baseCurrency) {
    Map<String, double> defaultRates = {
      'USD': 1.0, // ← MODIFIÉ : USD comme base
      'EUR': 0.92, // 1 USD = 0.92 EUR (approximatif)
      'GBP': 0.79, // 1 USD = 0.79 GBP
      'JPY': 150.0, // 1 USD = 150 JPY
      'CAD': 1.35, // 1 USD = 1.35 CAD
      'CHF': 0.88, // 1 USD = 0.88 CHF
      'CNY': 7.20, // 1 USD = 7.20 CNY
      'RUB': 92.0, // 1 USD = 92 RUB
      'BRL': 5.0, // 1 USD = 5 BRL
      'INR': 83.0, // 1 USD = 83 INR
      'CDF': 2700.0, // 1 USD = 2700 CDF (taux approximatif)
    };

    // Ajuster les taux selon la devise de base demandée
    if (baseCurrency != 'USD' && defaultRates.containsKey(baseCurrency)) {
      double baseRate = defaultRates[baseCurrency]!;
      Map<String, double> adjusted = {};
      defaultRates.forEach((key, value) {
        adjusted[key] = value / baseRate;
      });
      adjusted[baseCurrency] = 1.0;
      return adjusted;
    }

    return defaultRates;
  }

  // Convertir un montant
  Future<double> convertAmount(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    try {
      final rates = await getExchangeRates(fromCurrency);
      if (rates.containsKey(toCurrency)) {
        return amount * rates[toCurrency]!;
      } else {
        throw Exception('Devise non trouvée');
      }
    } catch (e) {
      throw Exception('Erreur de conversion: $e');
    }
  }

  // Obtenir les devises disponibles (toutes supportées par l'API)
  List<String> getAvailableCurrencies() {
    return [
      'USD', // ← MODIFIÉ : USD en premier
      'EUR', 'GBP', 'JPY', 'CAD', 'CHF', 'CNY', 'RUB', 'BRL', 'INR',
      'CDF', // Franc Congolais officiellement supporté !
    ];
  }
}
