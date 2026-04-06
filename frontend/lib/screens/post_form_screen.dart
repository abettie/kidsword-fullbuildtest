import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class PostFormScreen extends ConsumerStatefulWidget {
  const PostFormScreen({super.key});

  @override
  ConsumerState<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends ConsumerState<PostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mispronouncedController = TextEditingController();
  final _intendedController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _mispronouncedController.dispose();
    _intendedController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(apiServiceProvider).createPost(
            mispronounced: _mispronouncedController.text.trim(),
            intended: _intendedController.text.trim(),
            description: _descriptionController.text.trim(),
          );
      if (mounted) {
        ref.invalidate(feedPostsProvider);
        ref.invalidate(myPostsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('投稿しました！')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('投稿に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('言い間違いを投稿')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _mispronouncedController,
                decoration: const InputDecoration(
                  labelText: '言い間違った言葉 *',
                  hintText: 'トウモコロシ',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return '言い間違った言葉を入力してください';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _intendedController,
                decoration: const InputDecoration(
                  labelText: '伝えたかった言葉 *',
                  hintText: 'トウモロコシ',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return '伝えたかった言葉を入力してください';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '説明（任意）',
                  hintText: '3歳の娘が言いました',
                  border: OutlineInputBorder(),
                ),
                maxLength: 500,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('投稿する'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
