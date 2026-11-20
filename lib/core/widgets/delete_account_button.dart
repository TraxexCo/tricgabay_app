import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../config/backend_config.dart';
import '../session/app_session.dart';
import '../services/error_messages.dart';

class DeleteAccountButton extends StatefulWidget {
  const DeleteAccountButton({super.key});
  @override
  State<DeleteAccountButton> createState() => _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends State<DeleteAccountButton> {
  bool _busy = false;
  Future<void> _delete() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context
                  .l10n
                  .thisRemovesYourLoginProfileDetailsDocumentsAndAvatarsRetainedTripAndFinancial,
            ),
            TextField(
              controller: controller,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              scrollPadding: const EdgeInsets.all(96),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.keepAccount),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text == 'DELETE') Navigator.pop(ctx, true);
            },
            child: Text(context.l10n.permanentlyDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      const storage = FlutterSecureStorage();
      final userId = BackendConfig.client.auth.currentUser!.id;
      final key = 'account_deletion_$userId';
      final requestId = await storage.read(key: key) ?? const Uuid().v4();
      await storage.write(key: key, value: requestId);
      final response = await BackendConfig.client.functions.invoke(
        'delete-account',
        body: {'confirmation': 'DELETE', 'request_id': requestId},
      );
      if (response.status != 200 || response.data?['deleted'] != true) {
        throw StateError(MessageCode.deletionPending);
      }
      await storage.delete(key: key);
      await AppSession.signOut();
      if (mounted) context.go('/login');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.message(ErrorMessages.forError(error))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: _busy ? null : _delete,
    icon: const Icon(Icons.delete_forever),
    label: Text(
      context.message(
        _busy ? MessageCode.deletingAccount : MessageCode.deleteMyAccount,
      ),
    ),
  );
}
