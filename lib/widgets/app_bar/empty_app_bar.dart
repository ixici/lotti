import 'package:flutter/material.dart';

class EmptyAppBar extends StatelessWidget with PreferredSizeWidget {
  EmptyAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(0);

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
