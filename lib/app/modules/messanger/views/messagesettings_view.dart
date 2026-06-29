import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class Messagesettingsview extends StatelessWidget {
  const Messagesettingsview({super.key});

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: Get.height * 0.017,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xff8044f8),
        title: Text("Message Settings",
            style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // 🔹 Notifications
          buildSectionTitle("Notifications"),
          Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  value: true,
                  onChanged: (val) {},
                  activeThumbColor: Colors.purple,
                  title: Text("Mute Notifications",
                      style: GoogleFonts.roboto(fontSize: Get.height * 0.018)),
                  secondary: const Icon(Icons.notifications_off),
                ),

              ],
            ),
          ),

          // 🔹 Privacy
          buildSectionTitle("Privacy"),
          Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.redAccent),
                  title: Text("Blocked Words",
                      style: GoogleFonts.roboto(fontSize: Get.height * 0.018)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Get.to(() => const BlockedWordsPage()),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.privacy_tip, color: Colors.blue),
                  title: Text("Message Privacy",
                      style: GoogleFonts.roboto(fontSize: Get.height * 0.018)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Get.to(() => const MessagePrivacyPage()),
                ),
              ],
            ),
          ),

          // 🔹 Appearance
          buildSectionTitle("Appearance"),
          Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.color_lens, color: Colors.purple),
              title: Text("Change Theme",
                  style: GoogleFonts.roboto(fontSize: Get.height * 0.018)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.to(() => const ChangeThemePage()),
            ),
          ),
        ],
      ),
    );
  }
}

//
// 🔹 Blocked Words Page
//
class BlockedWordsPage extends StatefulWidget {
  const BlockedWordsPage({super.key});

  @override
  State<BlockedWordsPage> createState() => _BlockedWordsPageState();
}

class _BlockedWordsPageState extends State<BlockedWordsPage> {
  final List<String> blockedWords = ["badword1", "spam", "troll"];
  final TextEditingController controller = TextEditingController();

  void addWord() {
    if (controller.text.trim().isNotEmpty) {
      setState(() {
        blockedWords.add(controller.text.trim());
      });
      controller.clear();
    }
  }

  void removeWord(int index) {
    setState(() {
      blockedWords.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Blocked Words")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: "Add a word",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: addWord,
                ),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: blockedWords.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(blockedWords[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => removeWord(index),
                      ),
                    ),
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

//
// 🔹 Message Privacy Page
//
class MessagePrivacyPage extends StatefulWidget {
  const MessagePrivacyPage({super.key});

  @override
  State<MessagePrivacyPage> createState() => _MessagePrivacyPageState();
}

class _MessagePrivacyPageState extends State<MessagePrivacyPage> {
  String whoCanMessage = "Everyone";
  String lastSeen = "Friends";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Message Privacy")),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Who can message you?"),
            subtitle: Text(whoCanMessage),
            trailing: DropdownButton<String>(
              value: whoCanMessage,
              items: const [
                DropdownMenuItem(value: "Everyone", child: Text("Everyone")),
                DropdownMenuItem(value: "Friends", child: Text("Friends")),
                DropdownMenuItem(value: "No one", child: Text("No one")),
              ],
              onChanged: (val) {
                setState(() {
                  whoCanMessage = val!;
                });
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text("Who can see your Last Seen?"),
            subtitle: Text(lastSeen),
            trailing: DropdownButton<String>(
              value: lastSeen,
              items: const [
                DropdownMenuItem(value: "Everyone", child: Text("Everyone")),
                DropdownMenuItem(value: "Friends", child: Text("Friends")),
                DropdownMenuItem(value: "No one", child: Text("No one")),
              ],
              onChanged: (val) {
                setState(() {
                  lastSeen = val!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

//
// 🔹 Change Theme Page
//
class ChangeThemePage extends StatefulWidget {
  const ChangeThemePage({super.key});

  @override
  State<ChangeThemePage> createState() => _ChangeThemePageState();
}

class _ChangeThemePageState extends State<ChangeThemePage> {
  String theme = "Light";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Theme")),
      body: ListView(
        children: [
          RadioListTile<String>(
            value: "Light",
            groupValue: theme,
            title: const Text("Light Theme"),
            onChanged: (val) {
              setState(() => theme = val!);
            },
          ),
          RadioListTile<String>(
            value: "Dark",
            groupValue: theme,
            title: const Text("Dark Theme"),
            onChanged: (val) {
              setState(() => theme = val!);
            },
          ),
          RadioListTile<String>(
            value: "Purple",
            groupValue: theme,
            title: const Text("Purple Theme"),
            onChanged: (val) {
              setState(() => theme = val!);
            },
          ),
        ],
      ),
    );
  }
}
