# Decentralized Chat Application

This is a decentralized, secure, and cross-platform chat application.

## Technology Stack

*   **Frontend:** [Flutter](https://flutter.dev/) - A UI toolkit for building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase.
*   **Networking:** [libp2p](https://libp2p.io/) - A modular networking stack for building peer-to-peer applications.
*   **Database:** [SQLite](https://www.sqlite.org/index.html) - A C-language library that implements a small, fast, self-contained, high-reliability, full-featured, SQL database engine. We'll use the `sqflite` package for Flutter.
*   **Cryptography:** The `libp2p` library provides a secure channel for communication, and we will use a standard, well-vetted cryptography library for end-to-end encryption of messages.

## Project Goals

*   **Decentralized:** No central server or authority.
*   **Cross-Platform:** Android, iOS, Windows, Linux, and macOS.
*   **Secure:** End-to-end encryption for all messages.
*   **Anonymous:** Usernames are encrypted on the network.
*   **Free and Open Source:** The application will be free to use and the source code will be open.
*   **No Data Collection:** User data is not collected.
*   **Local Address Book:** The address book is stored locally on the user's device.
