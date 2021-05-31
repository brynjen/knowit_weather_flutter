import 'package:weather/features/weather_loader/presentation/widgets/basic_dialog.dart';

class NeedGpsServiceDialog extends BasicDialog {
  NeedGpsServiceDialog({required Function onConfirm})
      : super(
          texts: ['Du ser ut til å ha skrudd av GPS.', 'Den trengs for å vise posisjonen din'],
          okButton: 'Ta meg til GPS',
          onConfirm: onConfirm,
        );
}
