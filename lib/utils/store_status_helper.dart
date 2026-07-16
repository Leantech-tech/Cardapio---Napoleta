class StoreStatus {
  final bool isOpen;
  final String statusText;
  final String nextChangeText;
  final bool isClosingSoon;

  const StoreStatus({
    required this.isOpen,
    required this.statusText,
    required this.nextChangeText,
    this.isClosingSoon = false,
  });
}

class StoreStatusHelper {
  static StoreStatus checkStatus(DateTime now) {
    final weekday = now.weekday; // 1=Seg, 5=Sexta, 6=Sáb, 7=Dom
    final time = now.hour * 60 + now.minute;

    // Domingo(7) à Quinta(4) -> 13:00 (780) às 21:00 (1260)
    // Sexta(5) à Sábado(6) -> 13:05 (785) às 22:00 (1320)
    final isFriSat = weekday == 5 || weekday == 6;
    final openMinutes = isFriSat ? 785 : 780;
    final closeMinutes = isFriSat ? 1320 : 1260;

    final isOpen = time >= openMinutes && time < closeMinutes;
    final minutesUntilClose = closeMinutes - time;
    final closingSoon = isOpen && minutesUntilClose <= 30;

    if (isOpen) {
      return StoreStatus(
        isOpen: true,
        statusText: 'Aberto agora',
        nextChangeText: 'Fecha às ${isFriSat ? '22h00' : '21h00'}',
        isClosingSoon: closingSoon,
      );
    } else {
      String nextOpenText;
      if (time < openMinutes) {
        nextOpenText = 'Abre hoje às ${isFriSat ? '13h05' : '13h00'}';
      } else {
        // Já fechou, calcular próxima abertura
        final nextDay = now.add(const Duration(days: 1));
        final nextWeekday = nextDay.weekday;
        final nextIsFriSat = nextWeekday == 5 || nextWeekday == 6;
        nextOpenText =
            'Abre amanhã às ${nextIsFriSat ? '13h05' : '13h00'}';
      }
      return StoreStatus(
        isOpen: false,
        statusText: 'Fechado',
        nextChangeText: nextOpenText,
        isClosingSoon: false,
      );
    }
  }
}
