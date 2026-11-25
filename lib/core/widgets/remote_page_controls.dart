import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import '../session/app_session.dart';
import '../services/error_messages.dart';

class RemotePageControls extends StatelessWidget {
  final bool directory;
  const RemotePageControls({super.key, this.directory = false});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: directory
        ? AppSession.hasMoreDirectory
        : AppSession.hasMoreBookings,
    builder: (context, hasMore, _) {
      if (!hasMore) return const SizedBox.shrink();
      return ValueListenableBuilder<bool>(
        valueListenable: directory
            ? AppSession.loadingMoreDirectory
            : AppSession.loadingMoreBookings,
        builder: (context, busy, _) => SafeArea(
          top: false,
          child: TextButton(
            onPressed: busy
                ? null
                : () async {
                    try {
                      await AppSession.loadMore(directory: directory);
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.message(ErrorMessages.forError(error)),
                            ),
                          ),
                        );
                      }
                    }
                  },
            child: Text(
              context.message(
                busy
                    ? MessageCode.loadingMore
                    : directory
                    ? MessageCode.loadMorePeople
                    : MessageCode.loadMoreBookings,
              ),
            ),
          ),
        ),
      );
    },
  );
}
