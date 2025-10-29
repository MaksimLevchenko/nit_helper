class ErrorHandler {
  Future<int> handleErrors(Future<int> Function() action) async {
    try {
      final result = await action();
      // Если команда вернула ненулевой код, это уже обработано в ProcessService
      return result;
    } on ArgumentError catch (e) {
      print('\x1B[31mError: ${e.message}\x1B[0m');
      return 1;
    } on Exception catch (e) {
      // Для других исключений выводим чистое сообщение
      print(
          '\x1B[31mError: ${e.toString().replaceFirst('Exception: ', '')}\x1B[0m');
      return 1;
    } catch (e) {
      print('\x1B[31mUnexpected error occurred\x1B[0m');
      return 1;
    }
  }
}
