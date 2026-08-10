# Digital Khata (میرا کھاتہ)

Digital Khata is a robust offline-first Flutter application designed for shopkeepers, traders, and businesses to manage their daily transactions, customer ledgers, and cash flow with ease. The app tracks all the money you need to "Give" (Payables) and the money you will "Get" (Receivables), maintaining a perfect digital ledger for your customers.

## Features ✨

- **Dashboard Summary:** A clean dashboard displaying total receivables, total payables, and a list of all your customers.
- **Customer Management:** Easily add, update, and remove customers. Includes details like Phone Number, Address, City, and CNIC.
- **Transaction Ledger:** Maintain a detailed history for every customer. Record "Cash Given", "Cash Received", "Purchased Goods", and "Sold Goods".
- **Advanced Goods Tracking:** Support for item categories (e.g., Rice, Scrap) along with exact weight and unit tracking.
- **PDF Invoices & Receipts:** Automatically generate highly professional PDF ledgers and individual transaction receipts.
- **Sharing & Printing:** Share the generated PDF directly to WhatsApp or print it from your device.
- **Bilingual Support (English & Urdu):** Fully translated UI. Switch instantly between English and Urdu (اردو) seamlessly for maximum accessibility.
- **Offline First:** Fast, reliable, and completely offline database ensures you can use the app anywhere without needing the internet.

## Tech Stack 🛠️

This project was built with a highly optimized, modern Flutter technology stack:

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **State Management:** [Riverpod](https://riverpod.dev/) (`flutter_riverpod`) - For robust and scalable reactive state.
- **Database:** [Isar Database](https://isar.dev/) - A blazingly fast, local NoSQL database perfect for Flutter.
- **PDF Generation:** [`pdf`](https://pub.dev/packages/pdf) and [`printing`](https://pub.dev/packages/printing) - For creating and exporting beautiful invoices.
- **Sharing:** [`share_plus`](https://pub.dev/packages/share_plus) - To share files and text across other apps.
- **Localization:** [`flutter_localizations`](https://docs.flutter.dev/ui/accessibility-and-localization/internationalization) & [`intl`](https://pub.dev/packages/intl) - For comprehensive English & Urdu support.

## Getting Started 🚀

1. Ensure you have the Flutter SDK installed on your machine.
2. Clone this repository:
   ```bash
   git clone https://github.com/Haseeb-ML/Digital-Khata.git
   ```
3. Navigate to the project directory:
   ```bash
   cd Digital-Khata
   ```
4. Get all dependencies:
   ```bash
   flutter pub get
   ```
5. Run the app:
   ```bash
   flutter run
   ```

---
*Developed with ❤️ using Flutter.*
