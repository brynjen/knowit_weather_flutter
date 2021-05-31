import 'basic_dialog.dart';

class NeedPermissionDialog extends BasicDialog {
  NeedPermissionDialog({required Function onConfirm})
      : super(
          texts: ['GPS er ikke tillat', 'Du må tillate GPS'],
          okButton: 'Skru på GPS',
          onConfirm: onConfirm,
        );
}
