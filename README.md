# IslamicZone (Flutter)

মূল native Android (Java) অ্যাপ `IslamicZone-v8-Final.zip` থেকে Flutter-এ কনভার্সনের skeleton।

## এখন যা আছে (Phase 1 — Skeleton)

- বটম নেভিগেশন সহ পাঁচটা মূল স্ক্রিন: হোম, কুরআন, নামাজ, দোয়া, আরো
- **তাসবিহ** — সম্পূর্ণ কার্যকর (counter, target chip 33/99/100, reset, haptic feedback)
- **কিবলা** — সম্পূর্ণ কার্যকর (compass sensor + GPS location + Kaaba bearing formula, মূল Java কোড থেকে হুবহু পোর্ট করা)
- **কুরআন PDF ভিউয়ার** — বান্ডেল করা `quran.pdf` দেখায় (Syncfusion PDF viewer)
- আসল অ্যাপের রঙ (emerald green + gold), ফন্ট (৫টা কাস্টম .ttf) হুবহু কপি করা আছে
- GitHub Actions workflow — push করলেই APK বিল্ড হয়ে যাবে

## এখনো বাকি (Phase 2 — পরের ধাপ)

- হোম স্ক্রিনের আজকের আয়াত/হাদিস — real data source
- নামাজের সময় — প্রকৃত calculation (location অনুযায়ী, `adhan` প্যাকেজ দিয়ে করা যাবে)
- কুরআন সূরা লিস্ট — ১১৪টা সূরার real তালিকা + পেজ ম্যাপিং
- দোয়া ক্যাটাগরি → বিস্তারিত দোয়ার কন্টেন্ট স্ক্রিন
- আরো মেনু আইটেম (আল্লাহর নাম, ক্যালেন্ডার, যাকাত ক্যালকুলেটর, সেটিংস, About)

## প্রজেক্ট স্ট্রাকচার

```
lib/
  main.dart              # App entry
  theme/                 # রঙ ও থিম (colors.xml/themes.xml থেকে পোর্ট করা)
  widgets/root_shell.dart # বটম নেভিগেশন শেল (MainActivity.java এর সমতুল্য)
  screens/                # প্রতিটা স্ক্রিন
assets/
  fonts/                  # ৫টা কাস্টম ফন্ট
  quran.pdf               # কুরআন PDF
  images/, data/          # পরের ধাপে যোগ হবে
```

## android/ folder কই?

ইচ্ছাকৃতভাবে `.gitignore`-এ আছে। `flutter create` দিয়ে যেসব boilerplate ফাইল (gradle-wrapper.jar ইত্যাদি) অটো-জেনারেট হয়, সেগুলো হাতে কমিট না করে GitHub Actions workflow প্রতিবার fresh scaffold করে দেয় (দেখুন `.github/workflows/build.yml`)। এতে repo ছোট থাকে আর binary ফাইল নিয়ে ঝামেলা হয় না।

Package name `com.islamiczone.org` (মূল অ্যাপের সাথে মিলিয়ে) workflow-এই সেট হয়ে যায়, যাতে Play Store-এ existing app হিসেবে আপডেট যায়।

## কিভাবে বিল্ড হবে

GitHub-এ push করলেই `main` ব্রাঞ্চে workflow অটো চলবে:
1. Flutter SDK setup
2. `android/` folder scaffold (যদি না থাকে)
3. Permissions (location, vibrate, notification) auto-add
4. `flutter build apk --release`
5. APK artifact হিসেবে আপলোড হবে — Actions ট্যাবের run থেকে ডাউনলোড করা যাবে

## Dependencies (pubspec.yaml)

| প্যাকেজ | কাজ |
|---|---|
| flutter_compass | কিবলা কম্পাস সেন্সর |
| geolocator + permission_handler | লোকেশন (কিবলা + নামাজের সময়ের জন্য) |
| syncfusion_flutter_pdfviewer | কুরআন PDF দেখানো |
| shared_preferences | পরের ধাপে তাসবিহ/সেটিংস সেভ করতে |
# Islamic
