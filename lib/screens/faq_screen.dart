import 'package:flutter/material.dart';

class FaqItem {
  final String question;
  final String answer;

  const FaqItem({required this.question, required this.answer});
}

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  final List<FaqItem> _faqItems = const [
    FaqItem(
      question: 'How do I create an account?',
      answer:
      'To create an account, tap on the "Sign Up" button on the welcome screen. You can register using your email address, Google account, or Apple ID. Follow the on-screen instructions to complete your profile setup.',
    ),
    FaqItem(
      question: 'How can I reset my password?',
      answer:
      'If you forget your password, go to the login screen and tap the "Forgot Password" link. Enter your registered email address, and we will send you instructions to reset your password.',
    ),
    FaqItem(
      question: 'Is my personal information secure?',
      answer:
      'Yes, we take your privacy and security very seriously. All your data is encrypted and stored securely. Please refer to our Privacy Policy for more details on how we handle your information.',
    ),
    FaqItem(
      question: 'How do I update my profile information?',
      answer:
      'You can update your profile information by navigating to the "Profile" tab and selecting "Edit Profile". From there, you can change your name, contact details, and other personal information.',
    ),
    FaqItem(
      question: 'What payment methods do you accept?',
      answer:
      'We accept various payment methods, including credit/debit cards (Visa, MasterCard), UPI, and popular digital wallets. All transactions are processed through a secure payment gateway.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'FAQ',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Find answers to the most common questions about our app and services below.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 32),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _faqItems.length,
            itemBuilder: (context, index) {
              final item = _faqItems[index];
              return ExpansionTile(
                title: Text(
                  item.question,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                collapsedIconColor: Colors.blue,
                iconColor: Colors.black,
                shape: const Border(),
                childrenPadding:
                const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                children: <Widget>[
                  Text(
                    item.answer,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              );
            },
            separatorBuilder: (context, index) => const Divider(),
          ),
        ],
      ),
    );
  }
}