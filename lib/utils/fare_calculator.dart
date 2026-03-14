class FareCalculator {
  static const double bikeBaseFare = 30.0;
  static const double bikeRatePerKm = 8.0;

  static const double autoBaseFare = 40.0;
  static const double autoRatePerKm = 10.0;

  static const double cabBaseFare = 60.0;
  static const double cabRatePerKm = 15.0;

  static const double ambulanceBaseFare = 100.0;
  static const double ambulanceRatePerKm = 20.0;

  static double calculateFare(String vehicleType, double distance) {
    double baseFare = 0.0;
    double ratePerKm = 0.0;

    switch (vehicleType) {
      case 'Bike':
        baseFare = bikeBaseFare;
        ratePerKm = bikeRatePerKm;
        break;
      case 'Auto':
        baseFare = autoBaseFare;
        ratePerKm = autoRatePerKm;
        break;
      case 'Car':
      case 'Cab':
        baseFare = cabBaseFare;
        ratePerKm = cabRatePerKm;
        break;
      case 'Ambulance':
        baseFare = ambulanceBaseFare;
        ratePerKm = ambulanceRatePerKm;
        break;
      default:
        baseFare = 50.0;
        ratePerKm = 12.0;
    }

    return baseFare + (distance * ratePerKm);
  }

  static Map<String, double> getAllFares(double distance) {
    return {
      'Bike': calculateFare('Bike', distance),
      'Auto': calculateFare('Auto', distance),
      'Cab': calculateFare('Cab', distance),
      'Ambulance': calculateFare('Ambulance', distance),
    };
  }
}
