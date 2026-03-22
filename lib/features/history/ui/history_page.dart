import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:duckmouth/core/di/service_locator.dart';
import 'package:duckmouth/core/services/clipboard_service.dart';
import 'package:duckmouth/features/history/domain/transcription_entry.dart';
import 'package:duckmouth/features/history/ui/history_cubit.dart';
import 'package:duckmouth/features/history/ui/history_state.dart';

/// Page that displays the transcription history list.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear history',
            onPressed: () => _confirmClear(context),
          ),
        ],
      ),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HistoryError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          final entries = (state as HistoryLoaded).entries;
          if (entries.isEmpty) {
            return const Center(child: Text('No transcriptions yet.'));
          }
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) =>
                _EntryTile(entry: entries[index]),
          );
        },
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear history'),
        content: const Text(
          'This will permanently delete all transcription history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<HistoryCubit>().clearHistory();
              Navigator.pop(dialogContext);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final TranscriptionEntry entry;

  static final _dateFormat = DateFormat('MMM d, yyyy  HH:mm');

  @override
  Widget build(BuildContext context) {
    final preview = entry.displayText.length > 100
        ? '${entry.displayText.substring(0, 100)}...'
        : entry.displayText;
    final formattedDate = _dateFormat.format(entry.timestamp);

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        context.read<HistoryCubit>().deleteEntry(entry.id);
      },
      child: ListTile(
        title: Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(formattedDate),
        trailing: entry.processedText != null
            ? const Tooltip(
                message: 'Post-processed',
                child: Icon(Icons.auto_fix_high, size: 16),
              )
            : null,
        onTap: () {
          sl<ClipboardService>().copyToClipboard(entry.displayText);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Copied to clipboard'),
              duration: Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}
