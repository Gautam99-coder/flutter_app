import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Terms of Service',
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
              'Terms of Service',
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
              title: '1. Acceptance of Terms',
              content:
              'By accessing and using this application (the "Service"), you accept and agree to be bound by the terms and provision of this agreement. In addition, when using this Service, you shall be subject to any posted guidelines or rules applicable to such services. Any participation in this service will constitute acceptance of this agreement.',
            ),
            _buildSection(
              title: '2. User Accounts',
              content:
              'To access some features of the app, you may be required to create an account. You are responsible for safeguarding your account details and for any activities or actions under your password. You agree not to disclose your password to any third party and to notify us immediately upon becoming aware of any breach of security or unauthorized use of your account.',
            ),
            _buildSection(
              title: '3. Prohibited Activities',
              content:
              'You agree not to use the Service for any purpose that is illegal or prohibited by these Terms. You are prohibited from violating or attempting to violate the security of the Service, including, without limitation, accessing data not intended for you or logging into a server or account which you are not authorized to access.',
            ),
            _buildSection(
              title: '4. Termination',
              content:
              'We may terminate or suspend your account and bar access to the Service immediately, without prior notice or liability, under our sole discretion, for any reason whatsoever and without limitation, including but not limited to a breach of the Terms.',
            ),
            _buildSection(
              title: '5. Governing Law',
              content:
              'These Terms shall be governed and construed in accordance with the laws of India, without regard to its conflict of law provisions. Any legal suit, action, or proceeding arising out of or related to these Terms or the Services shall be instituted exclusively in the courts of Rajkot, Gujarat.',
            ),
            _buildSection(
              title: '6. Changes to Terms',
              content:
              'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. We will provide at least 30 days\' notice prior to any new terms taking effect. By continuing to access or use our Service after those revisions become effective, you agree to be bound by the revised terms.',
            ),
            _buildSection(
              title: '7. Contact Us',
              content:
              'If you have any questions about these Terms, please contact us at support@urmedio.com.',
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