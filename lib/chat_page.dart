import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();

  // Dummy conversation between doctor and parent
  List<Map<String, String>> messages = [
    {'sender': 'Doctor', 'message': 'The baby seems fine, but a bit fussy.'},
    {'sender': 'Parent', 'message': 'How is my baby doing today?'},
    {'sender': 'Doctor', 'message': 'Hello!'},
    {'sender': 'Parent', 'message': 'Hello Doctor!'},
  ];

  // Method to add a message to the list
  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        messages.add({
          'sender': 'Parent',
          'message': _controller.text
        }); // Sent by Parent
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1B18),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Chat Support",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Navigator.pop(context); // Close the chat page
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Display the chat messages
          Expanded(
            child: ListView.builder(
              reverse: true, // To show the most recent message at the bottom
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Align(
                    alignment: messages[index]['sender'] == 'Parent'
                        ? Alignment
                            .centerRight // Align messages sent by parent to the right
                        : Alignment
                            .centerLeft, // Align messages from doctor to the left
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        color: messages[index]['sender'] == 'Parent'
                            ? const Color(
                                0xFF00B686) // Parent's messages bubble
                            : const Color(
                                0xFF333333), // Doctor's messages bubble
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        messages[index]['message']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Text input and send button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[800],
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: Color(0xFF00B686),
                    size: 30,
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
