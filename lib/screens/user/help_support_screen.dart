import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bantuan & Dukungan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // FAQ Section
          const Text(
            'Pertanyaan Umum (FAQ)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            context,
            question: 'Bagaimana cara memesan produk?',
            answer: 'Pilih produk yang ingin dibeli, tambahkan ke keranjang, lalu lanjutkan ke pembayaran. Anda dapat memilih metode pembayaran yang tersedia dan alamat pengiriman.',
          ),
          _buildFAQItem(
            context,
            question: 'Berapa lama proses pengiriman?',
            answer: 'Waktu pengiriman bervariasi tergantung lokasi, biasanya 2-5 hari kerja untuk Jawa dan 5-7 hari kerja untuk luar Jawa.',
          ),
          _buildFAQItem(
            context,
            question: 'Bagaimana cara melacak pesanan saya?',
            answer: 'Buka menu "Pesanan", pilih pesanan yang ingin dilacak, dan lihat status terkini beserta nomor resi pengiriman jika sudah tersedia.',
          ),
          _buildFAQItem(
            context,
            question: 'Apakah bisa membatalkan pesanan?',
            answer: 'Ya, pesanan dapat dibatalkan selama statusnya masih "Pending". Buka detail pesanan dan pilih tombol "Batalkan Pesanan".',
          ),
          _buildFAQItem(
            context,
            question: 'Bagaimana cara mengembalikan produk?',
            answer: 'Hubungi customer service kami melalui WhatsApp atau email dengan nomor pesanan Anda. Produk dapat dikembalikan dalam 7 hari dengan kondisi masih baru.',
          ),
          const SizedBox(height: 32),

          // Contact Section
          const Text(
            'Hubungi Kami',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            context,
            icon: Icons.phone,
            title: 'Telepon',
            value: '+62 895-1334-2070',
              onTap: () async {
              final url = Uri.parse('https://tel:+6289513342070');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            context,
            icon: Icons.message,
            title: 'WhatsApp',
            value: '+62 895-1334-2070',
            onTap: () async {
              final url = Uri.parse('https://wa.me/6289513342070');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            context,
            icon: Icons.email,
            title: 'Email',
            value: 'ussycntka@gmail.com',
            onTap: () async {
              final url = Uri.parse('mailto:ussycntka@gmail.com');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 32),

          // Working Hours
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Jam Operasional',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Senin - Jumat: 08:00 - 17:00 WIB'),
                  const Text('Sabtu: 08:00 - 14:00 WIB'),
                  const Text('Minggu & Libur: Tutup'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, {required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title),
        subtitle: Text(value),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
