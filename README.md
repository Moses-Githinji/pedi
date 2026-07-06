# Pedi - The African Lifestyle Super App

**Discover • Shop • Connect** — The ultimate social commerce and lifestyle platform for East Africa.

![Pedi Banner](https://via.placeholder.com/800x400?text=Pedi+Hero+Banner) <!-- Replace with actual banner when available -->

## Overview

**Pedi** is a Flutter-powered **social commerce super-app** built for the African market. Inspired by the success of Xiaohongshu (Little Red Book), Pedi combines immersive short-form video discovery, structured product information, geo-localized experiences, and frictionless mobile payments (starting with M-Pesa) into one seamless experience.

**Initial Launch**: Kenya  
**Vision**: Become the definitive lifestyle, discovery, and commerce operating system for African consumers.

---

## Core Features

### A. Content & Discovery
- **TikTok-style Vertical Video Feed** — Smooth 60fps full-screen vertical swipe experience
- **Dual View Mode** — Seamless toggle between immersive video feed and Pinterest-style double-column grid
- **Geo-Fenced Discovery** — Location-aware feed showing nearby spots, thrift stores, pop-ups, and hidden gems (Nairobi, Mombasa, Diani, Naivasha, etc.)
- **"Pedi wa Boda" Metadata** — Standardized logistics tags for matatus, boda boda riders, fares, and contacts
- **Offline Support** — Saved itineraries, guides, and contacts accessible without internet

### B. Structured Social Commerce
- **Wiki-Style Product Infoboxes** — No more "DM for price". Every listing includes stall location, price, inventory, and delivery info
- **Interactive Video Tagging** — Tap hotspots on videos to instantly view full product specifications
- **Smart Search** — Typo-tolerant, multi-tag search with predictive autocomplete
- **Creator "Notes"** — Rich multi-image carousels with detailed lifestyle reviews

### C. Payments & Transactions
- **M-Pesa STK Push** — One-tap checkout with instant Safaricom prompt
- **Multi-Channel Gateways** — Paystack & Flutterwave support (cards)
- **Escrow Protection** — Funds held until delivery is confirmed

### D. AI-Powered Assistant — "The Bestie"
- **Multilingual Conversational AI** — English, Swahili & Sheng
- **Intent Understanding** — Turns natural queries ("Niko Eldoret, nishow cheap shoes in CBD") into instant product results
- **Visual Search** — Snap a photo → AI finds matching products and stall locations

---

## Technology Stack

- **Frontend**: Flutter (Cross-platform Mobile)
- **Backend**: Firebase + Firestore (Real-time Database)
- **Payments**: Safaricom Daraja (M-Pesa), Paystack, Flutterwave
- **AI**: Gemini 1.5 Flash (via Vertex AI)
- **Search**: Algolia / Meilisearch (planned)
- **Location**: Geolocator + Firestore GeoHashing
- **Video**: media_kit / Custom ExoPlayer integration

---

## Target Market

- **Primary**: Kenya (Nairobi, Coast, Rift Valley)
- **Expansion**: Uganda, Tanzania, Rwanda, and broader East & West Africa
- **Core Users**: Young urban consumers, fashion & lifestyle enthusiasts, small business owners, and travelers

---

## Competitive Advantage

| Feature                    | Xiaohongshu (RED)     | Pedi (Africa)                  |
|---------------------------|-----------------------|--------------------------------|
| Payment Integration       | WeChat/Alipay        | M-Pesa + Regional Gateways    |
| Trust Mechanism           | Reviews              | Structured Infobox + Escrow   |
| Local Relevance           | China-focused        | African logistics & slang     |
| AI Assistant              | Diandian             | "The Bestie" (Swahili/Sheng)  |
| Offline Capability        | Limited              | Strong (Firestore persistence)|

---

## Getting Started (For Developers)

```bash
git clone <repository-url>
cd pedi-app
flutter pub get
flutter run