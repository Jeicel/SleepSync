import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/card_container.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  String _formatDeletedDate(DateTime deleted) {
    final diff = DateTime.now().difference(deleted);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatSleepDate(DateTime date) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${monthNames[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final trash = [...state.deletedEntries]..sort((a, b) =>
        (b.deletedAt ?? DateTime.now())
            .compareTo(a.deletedAt ?? DateTime.now()));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text(
          'Trash',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: context.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: CardContainer(
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Items in Trash are permanently deleted after 7 days. You can restore items or permanently delete them now.',
                        style: TextStyle(
                            color: context.textSecondary, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: trash.isEmpty
                          ? null
                          : () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Empty trash now?'),
                                  content: const Text(
                                      'This will permanently delete all items in Trash. This cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text('Empty',
                                          style:
                                              TextStyle(color: AppColors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                for (final e in List.of(trash)) {
                                  await state.permanentlyDeleteEntry(e.id);
                                }
                              }
                            },
                      child: const Text('Empty'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: trash.isEmpty
                  ? Center(
                      child: Text(
                        'No deleted entries',
                        style: TextStyle(
                            color: context.textSecondary, fontSize: 14),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
                      child: Column(
                        children: trash.map((e) {
                          final deletedAt = e.deletedAt ?? DateTime.now();
                          final expiryDate =
                              deletedAt.add(const Duration(days: 7));
                          final willExpireIn =
                              expiryDate.difference(DateTime.now()).inDays;
                          final isExpiringSoon = willExpireIn <= 3;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CardContainer(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _formatSleepDate(e.bedtime),
                                              style: TextStyle(
                                                color: context.textPrimary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Deleted ${_formatDeletedDate(deletedAt)}',
                                              style: TextStyle(
                                                color: isExpiringSoon
                                                    ? AppColors.red
                                                    : context.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (isExpiringSoon)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 4),
                                                child: Text(
                                                  willExpireIn <= 0
                                                      ? 'Expires today'
                                                      : 'Expires in $willExpireIn day${willExpireIn == 1 ? '' : 's'}',
                                                  style: const TextStyle(
                                                    color: AppColors.red,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        e.durationLabel,
                                        style: TextStyle(
                                          color: context.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.restore),
                                          label: const Text('Restore'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.purple,
                                            side: const BorderSide(
                                                color: AppColors.purple),
                                          ),
                                          onPressed: () async {
                                            final entryId = e.id;
                                            await state
                                                .restoreFromTrash(entryId);

                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: const Text(
                                                      'Entry restored'),
                                                  backgroundColor:
                                                      AppColors.remGreen,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  duration: const Duration(
                                                      seconds: 2),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.delete_outline,
                                              size: 20),
                                          label: const Text('Delete'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.red,
                                            side: const BorderSide(
                                                color: AppColors.red),
                                          ),
                                          onPressed: () async {
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text(
                                                    'Permanently delete?'),
                                                content: const Text(
                                                    'This cannot be undone.'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(true),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (ok == true) {
                                              await state
                                                  .permanentlyDeleteEntry(e.id);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
