import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../models/profile_model.dart';
import '../../bloc/create_loan_cubit.dart';
import '../../bloc/create_loan_state.dart';

class BorrowerSearchSheet extends StatefulWidget {
  final void Function(ProfileModel) onSelected;
  const BorrowerSearchSheet({super.key, required this.onSelected});

  @override
  State<BorrowerSearchSheet> createState() => _BorrowerSearchSheetState();
}

class _BorrowerSearchSheetState extends State<BorrowerSearchSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Borrower',
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ctrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone…',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) =>
                        context.read<CreateLoanCubit>().searchBorrowers(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: BlocBuilder<CreateLoanCubit, CreateLoanState>(
                builder: (_, state) {
                  if (state is BorrowerSearchLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is BorrowerSearchResult) {
                    if (state.results.isEmpty) {
                      return Center(
                        child: Text('No users found',
                            style: tt.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      );
                    }
                    return ListView.builder(
                      controller: scrollCtrl,
                      itemCount: state.results.length,
                      itemBuilder: (_, i) {
                        final u = state.results[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Text(u.name[0].toUpperCase(),
                                style: TextStyle(color: cs.primary)),
                          ),
                          title: Text(u.name),
                          subtitle: Text(u.phone ?? u.upiId ?? ''),
                          onTap: () {
                            widget.onSelected(u);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  }
                  return Center(
                    child: Text('Type to search users',
                        style: tt.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
