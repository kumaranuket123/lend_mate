import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AvatarPicker extends StatefulWidget {
  final String? avatarUrl;
  final String  initials;
  final void Function(File file) onPicked;

  const AvatarPicker({
    super.key,
    required this.avatarUrl,
    required this.initials,
    required this.onPicked,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  File? _local;

  Future<void> _pick() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      final file = File(picked.path);
      setState(() => _local = file);
      widget.onPicked(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: _pick,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Avatar circle
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primaryContainer,
              border: Border.all(color: cs.primary.withOpacity(0.3), width: 2),
            ),
            child: ClipOval(
              child: _local != null
                  ? Image.file(_local!, fit: BoxFit.cover)
                  : widget.avatarUrl != null
                      ? Image.network(
                          widget.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _InitialsWidget(
                            initials: widget.initials,
                            cs: cs,
                            tt: tt,
                          ),
                        )
                      : _InitialsWidget(
                          initials: widget.initials,
                          cs: cs,
                          tt: tt,
                        ),
            ),
          ),

          // Edit badge
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
              border: Border.all(color: cs.surface, width: 2),
            ),
            child: Icon(Icons.camera_alt, size: 14, color: cs.onPrimary),
          ),
        ],
      ),
    );
  }
}

class _InitialsWidget extends StatelessWidget {
  final String      initials;
  final ColorScheme cs;
  final TextTheme   tt;
  const _InitialsWidget(
      {required this.initials, required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials.isNotEmpty ? initials[0].toUpperCase() : '?',
        style: tt.headlineMedium?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
