import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/contact_providers.dart';
import '../../core/limits.dart';
import '../../domain/people/contact.dart';
import '../../domain/time/operational_calendar.dart';

/// Lista reativa de contatos na ordem semanal de carência (RF-07.5, RF-07.6).
///
/// Componente reutilizável, sem rota própria: a tela Pessoas que o hospeda é
/// habilitada apenas na tarefa 20.9.
class ContactList extends ConsumerWidget {
  const ContactList({super.key});

  static const listKey = ValueKey<String>('contact-list');
  static const emptyKey = ValueKey<String>('contact-list-empty');
  static const addButtonKey = ValueKey<String>('contact-add-button');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactWeeklyOrderProvider);
    return contacts.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('Não foi possível carregar os contatos.'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(contactRowsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
      data: (ordered) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (ordered.isEmpty)
            const _EmptyContacts()
          else
            Column(
              key: listKey,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final contact in ordered) ...<Widget>[
                  _ContactCard(contact: contact),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          const SizedBox(height: 4),
          FilledButton.tonalIcon(
            key: addButtonKey,
            onPressed: () => _openEditor(context, ref),
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Adicionar contato'),
          ),
        ],
      ),
    );
  }
}

class _EmptyContacts extends StatelessWidget {
  const _EmptyContacts();

  @override
  Widget build(BuildContext context) => const Card(
    key: ContactList.emptyKey,
    child: ListTile(
      leading: Icon(Icons.group_outlined),
      title: Text('Nenhum contato cadastrado'),
      subtitle: Text('Cadastre um contato para acompanhar suas pontes.'),
    ),
  );
}

class _ContactCard extends ConsumerWidget {
  const _ContactCard({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final note = contact.contextNote;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(contact.name, style: textTheme.titleMedium),
            if (note != null && note.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(note),
            ],
            const SizedBox(height: 4),
            Text(
              contact.lastTouchDate == null
                  ? 'Sem toque registrado'
                  : 'Último toque: ${_formatDate(contact.lastTouchDate!)}',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => _openEditor(context, ref, existing: contact),
                child: const Text('Editar contato'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openEditor(
  BuildContext context,
  WidgetRef ref, {
  Contact? existing,
}) async {
  final nameController = TextEditingController(text: existing?.name ?? '');
  final noteController = TextEditingController(
    text: existing?.contextNote ?? '',
  );
  final submitted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(existing == null ? 'Adicionar contato' : 'Editar contato'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: nameController,
              maxLength: Limits.editableNameMaxRunes,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(Limits.editableNameMaxRunes),
              ],
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              maxLength: Limits.shortTextMaxRunes,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(Limits.shortTextMaxRunes),
              ],
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Contexto (opcional)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Salvar'),
        ),
      ],
    ),
  );

  final name = nameController.text;
  final note = noteController.text;
  nameController.dispose();
  noteController.dispose();

  if (submitted != true || !context.mounted) return;

  final controller = ref.read(contactControllerProvider);
  final result = existing == null
      ? await controller.create(name: name, contextNote: note)
      : await controller.edit(existing.id, name: name, contextNote: note);

  if (!context.mounted) return;
  result.fold<void>(
    onSuccess: (_) {},
    onFailure: (failure) => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure.message))),
  );
}

String _formatDate(OperationalDate date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
