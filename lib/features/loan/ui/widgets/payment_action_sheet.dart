import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../models/emi_schedule_model.dart';
import '../../../../shared/widgets/lm_button.dart';

class PaymentActionSheet extends StatefulWidget {
  final EmiScheduleModel emi;
  final void Function(File? proof) onConfirm;

  const PaymentActionSheet({
    super.key,
    required this.emi,
    required this.onConfirm,
  });

  @override
  State<PaymentActionSheet> createState() => _PaymentActionSheetState();
}

class _PaymentActionSheetState extends State<PaymentActionSheet> {
  File? _proof;
  bool  _loading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) setState(() => _proof = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final tt  = Theme.of(context).textTheme;
    final fmt = RegExp(r'(\d)(?=(\d{2})+\d$)');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text('Mark EMI as Paid',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'EMI #${widget.emi.emiNumber}  •  '
            '₹${widget.emi.emiAmount.toStringAsFixed(0).replaceAllMapped(fmt, (m) => '${m[1]},')}',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),

          const SizedBox(height: 20),

          Text('Payment Proof (optional but recommended)',
              style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _proof != null ? cs.primary : cs.outlineVariant,
                ),
              ),
              child: _proof != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_proof!, fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _proof = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined,
                            color: cs.onSurfaceVariant, size: 32),
                        const SizedBox(height: 8),
                        Text('Tap to upload screenshot',
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),

          LmButton(
            label: 'Confirm Payment',
            loading: _loading,
            onPressed: () {
              setState(() => _loading = true);
              widget.onConfirm(_proof);
              Navigator.pop(context);
            },
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
