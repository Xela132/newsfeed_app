import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<Map<String, dynamic>> _posts = []; //contain elements of post

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  Widget build(BuildContext context) { //main screen building
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.article, size: 30),
            const SizedBox(width: 8),
            const Text("Newsfeed"),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.green[200],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            "Welcome to NewsFeed!",
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Create your posts!",
            style: TextStyle(fontSize: 20.0, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder( //create a list for the posts
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16),
                            const SizedBox(width: 4),
                            Text(_posts[index]['username'] ?? "Unknown"),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_posts[index]['content'] ?? "No content"),
                        const SizedBox(height: 4),
                        Text(
                          _posts[index]['timestamp'] ?? "No timestamp",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_posts[index]['likes']} Likes',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton( //like button
                              icon: Icon(
                                _posts[index]['liked']
                                    ? Icons.thumb_down_alt_outlined
                                    : Icons.thumb_up_alt_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _posts[index]['liked'] = !_posts[index]['liked'];
                                  _posts[index]['likes'] += _posts[index]['liked'] ? 1 : -1;
                                });
                                _savePosts();
                              },
                            ),
                            IconButton( //comment button
                              icon: const Icon(Icons.comment),
                              onPressed: () {
                                _showCommentsDialog(index);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton( //add new post
        onPressed: () {
          _showAddPostDialog(context);
        },
        backgroundColor: Colors.green[200],
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _loadPosts() async { //persistent data
    final prefs = await SharedPreferences.getInstance();
    String? postsString = prefs.getString('posts');
    if (postsString != null) {
      setState(() {
        _posts.clear();
        _posts.addAll(List<Map<String, dynamic>>.from(jsonDecode(postsString)));
      });
    }
  }

  Future<void> _savePosts() async { //persistent data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('posts', jsonEncode(_posts));
  }

  void _showAddPostDialog(BuildContext context) { //show posts
    final TextEditingController contentController = TextEditingController();
    final TextEditingController usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("New Post"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(hintText: "Your name"),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(hintText: "Write something..."),
                maxLines: 5,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                String postContent = contentController.text;
                String username = usernameController.text;
                String timestamp =
                DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()).toString();

                setState(() {
                  _posts.insert(0, {
                    'username': username.isNotEmpty ? username : "Anonymous",
                    'content': postContent.isNotEmpty ? postContent : "No content",
                    'timestamp': timestamp,
                    'likes': 0,
                    'liked': false,
                    'comments': [],
                  });
                });
                _savePosts(); // Save posts after adding a new one
                Navigator.of(context).pop();
              },
              child: const Text("Post"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _showCommentsDialog(int postIndex) { //show comments in post
    final TextEditingController commentController = TextEditingController();
    final TextEditingController usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Comments"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: _posts[postIndex]['comments'].length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_posts[postIndex]['comments'][index]['username']),
                        subtitle: Text(_posts[postIndex]['comments'][index]['content']),
                      );
                    },
                  ),
                ),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(hintText: "Your name"),
                ),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(hintText: "Add a comment..."),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String commentContent = commentController.text;
                String username = usernameController.text;

                if (commentContent.isNotEmpty && username.isNotEmpty) {
                  setState(() {
                    _posts[postIndex]['comments'].add({
                      'username': username,
                      'content': commentContent,
                    });
                  });
                  _savePosts();
                  commentController.clear();
                  usernameController.clear();
                }

                Navigator.of(context).pop();
              },
              child: const Text("Comment"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}