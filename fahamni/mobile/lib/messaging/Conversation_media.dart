import 'package:flutter/material.dart';

class ConversationMedia extends StatefulWidget {
  const ConversationMedia({super.key});

  @override
  State<ConversationMedia> createState() => _ConversationMediaState();
}

class _ConversationMediaState extends State<ConversationMedia> {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 20,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: const DecorationImage(
              image: NetworkImage('https://picsum.photos/200'),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}