import 'package:flutter/material.dart';

import '../models/admin_account.dart';
import '../services/admin_service.dart';

class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends State<AdminAccountsScreen> {
  final _service = AdminService();
  late Future<List<AdminAccount>> _admins;

  @override
  void initState() {
    super.initState();
    _admins = _service.fetchAdmins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Accounts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add admin'),
      ),
      body: FutureBuilder<List<AdminAccount>>(
        future: _admins,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final admins = snapshot.data ?? [];
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: admins.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final admin = admins[index];
              return Card(
                child: SwitchListTile(
                  value: admin.isActive,
                  onChanged: (value) async {
                    await _service.setActive(admin.id, value);
                    setState(() => _admins = _service.fetchAdmins());
                  },
                  title: Text(admin.fullName),
                  subtitle: Text(admin.email),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add admin'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) => value == null || value.trim().length < 2 ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => value == null || !value.contains('@') ? 'Enter valid email' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Temporary password'),
                  validator: (value) => value == null || value.length < 10 ? 'Minimum 10 characters' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await _service.createAdmin(
                fullName: nameController.text.trim(),
                email: emailController.text.trim(),
                password: passwordController.text,
              );
              if (context.mounted) Navigator.of(context).pop();
              setState(() => _admins = _service.fetchAdmins());
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
  }
}
