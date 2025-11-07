import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Privacy Policy',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Last Updated: September 22, 2025',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '1. Introduction',
              content:
              'This Privacy Policy describes how we collect, use, and handle your personal information when you use our mobile application (the "Service"). We are committed to protecting your privacy and ensuring that your personal data is handled in a safe and responsible manner.',
            ),
            _buildSection(
              title: '2. Information We Collect',
              content:
              'We may collect information that you provide directly to us, such as your name, email address, and phone number when you create an account. We also collect information automatically as you navigate through the Service, including usage details, IP addresses, and information collected through cookies.',
            ),
            _buildSection(
              title: '3. How We Use Your Information',
              content:
              'The information we collect is used to present our Service and its contents to you, provide you with information or services that you request from us, fulfill any other purpose for which you provide it, and to carry out our obligations and enforce our rights arising from any contracts entered into between you and us.',
            ),
            _buildSection(
              title: '4. Data Security',
              content:
              'We have implemented measures designed to secure your personal information from accidental loss and from unauthorized access, use, alteration, and disclosure. The safety and security of your information also depend on you. Where we have given you a password for access to certain parts of our Service, you are responsible for keeping this password confidential.',
            ),
            _buildSection(
              title: '5. Children\'s Privacy',
              content:
              'Our Service is not intended for children under the age of 13. We do not knowingly collect personal information from children under 13. If we learn we have collected or received personal information from a child under 13 without verification of parental consent, we will delete that information.',
            ),
            _buildSection(
              title: '6. Changes to Our Privacy Policy',
              content:
              'It is our policy to post any changes we make to our privacy policy on this page. If we make material changes to how we treat our users\' personal information, we will notify you through a notice on the Service home screen. The date the privacy policy was last revised is identified at the top of the page.',
            ),
            _buildSection(
              title: '7. Contact Information',
              content:
              'To ask questions or comment about this privacy policy and our privacy practices, you can contact us at: privacy@yourapp.com.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
