import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../utils/app_fonts.dart';
import '../utils/text_normalization.dart';

/// Irreversible account deletion confirmation.
///
/// The user must type the localized confirmation word (or "DELETE") before the
/// destructive action is enabled. [onDelete] runs while the dialog stays open
/// with a progress indicator; the dialog pops `true` only after it succeeds and
/// shows an inline error otherwise.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({
    super.key,
    required this.onDelete,
    required this.surfaceColor,
    required this.itemColor,
    required this.borderColor,
  });

  final Future<void> Function() onDelete;
  final Color surfaceColor;
  final Color itemColor;
  final Color borderColor;

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  static const _destructiveColor = Color(0xFFEF4444);

  final _controller = TextEditingController();
  bool _isDeleting = false;
  bool _hasError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isConfirmed => matchesDeleteConfirmation(
        _controller.text,
        'delete_account_confirm_word'.tr(),
      );

  Future<void> _delete() async {
    if (_isDeleting || !_isConfirmed) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isDeleting = true;
      _hasError = false;
    });

    try {
      await widget.onDelete();
      if (mounted) Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      debugPrint('Account deletion failed: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemColor = widget.itemColor;
    final bodyStyle = AppFonts.poppins(
      context: context,
      color: itemColor.withValues(alpha: 0.72),
      fontSize: 13.5,
      height: 1.45,
    );
    final confirmWord = 'delete_account_confirm_word'.tr();

    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        backgroundColor: widget.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: widget.borderColor),
        ),
        icon: const Icon(
          Icons.delete_forever_rounded,
          color: _destructiveColor,
          size: 34,
        ),
        title: Text(
          'delete_account_title'.tr(),
          textAlign: TextAlign.center,
          style: AppFonts.poppins(
            context: context,
            color: itemColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('delete_account_body'.tr(), style: bodyStyle),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'delete_account_purchase_note'.tr(),
                        style: bodyStyle.copyWith(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'delete_account_type_prompt'.tr(args: [confirmWord]),
                style: AppFonts.poppins(
                  context: context,
                  color: itemColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('delete_account_confirm_field'),
                controller: _controller,
                enabled: !_isDeleting,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() => _hasError = false),
                onSubmitted: (_) => _delete(),
                style: AppFonts.poppins(
                  context: context,
                  color: itemColor,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: confirmWord,
                  hintStyle: TextStyle(
                    color: itemColor.withValues(alpha: 0.30),
                  ),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _destructiveColor),
                  ),
                ),
              ),
              if (_hasError) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: _destructiveColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'delete_account_error'.tr(),
                        key: const ValueKey('delete_account_error'),
                        style: bodyStyle.copyWith(
                          color: _destructiveColor,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                _isDeleting ? null : () => Navigator.of(context).pop(false),
            child: Text(
              'cancel'.tr(),
              style: AppFonts.poppins(
                context: context,
                color: itemColor.withValues(alpha: 0.65),
              ),
            ),
          ),
          FilledButton(
            key: const ValueKey('delete_account_confirm_button'),
            style: FilledButton.styleFrom(
              backgroundColor: _destructiveColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  _destructiveColor.withValues(alpha: 0.30),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.70),
            ),
            onPressed: _isConfirmed && !_isDeleting ? _delete : null,
            child: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text('delete_account_confirm'.tr()),
          ),
        ],
      ),
    );
  }
}
