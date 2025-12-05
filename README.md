# 🍅 Pomodoro Elite

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)

  <p align="center">
    <b>Focus, Track, and Achieve.</b><br>
    <i>A professional productivity suite designed to master your time management.</i>
  </p>

  <a href="#-türkçe-proje-detayları">
    <img src="https://img.shields.io/badge/Türkçe_Açıklama_İçin_Tıklayın-TR-red?style=for-the-badge" alt="Türkçe Versiyon">
  </a>
  
  <br><br>

[Report Bug](https://github.com/HarunMercan1/pomodoro_elite/issues) · [Request Feature](https://github.com/HarunMercan1/pomodoro_elite/issues)

</div>

---

## 📱 About the Project

**Pomodoro Elite** is not just a simple timer; it is a comprehensive productivity companion engineered to help users reclaim their focus in a distracted world. Built with **Flutter**, this application leverages the scientifically proven Pomodoro Technique to break work into manageable intervals, separated by short breaks.

The app is designed with a "focus-first" philosophy. It eliminates distractions by providing an immersive environment complete with ambient background sounds (like rain, forest, or white noise) and motivational quotes that refresh with every session. Unlike standard timers, **Pomodoro Elite** emphasizes data-driven progress, offering detailed analytics to visualize your productivity trends over time.

Whether you are a student preparing for exams, a developer coding for hours, or a professional managing tight deadlines, Pomodoro Elite adapts to your workflow with fully customizable duration settings and dynamic theming that visually signals your current state.

## ✨ Key Features

- **🎯 Adaptive Timer System:** Fully customizable timers for Focus sessions, Short Breaks, and Long Breaks. You control the rhythm of your workflow.
- **📊 Comprehensive Analytics:** Visual charts (powered by `fl_chart`) track your daily focus hours, session counts, and weekly consistency to help you build lasting habits.
- **🎨 Dynamic Visual Feedback:** The UI adapts its color palette in real-time based on the timer state (Focus, Break, Paused, Completed), providing subtle visual cues.
- **🎵 Immersive Soundscapes:** Integrated audio player supporting high-quality ambient sounds (Rain, Storm, Ocean, Forest) to drown out noise and deepen concentration.
- **🌍 Localization:** Native support for both English and Turkish languages, automatically detecting or manually setting the preference.
- **🌑 Modern UI/UX:** A sleek, distraction-free interface with full Dark Mode support for late-night sessions.

## 📸 Screenshots (English)

<div align="center">
  <table>
    <tr>
      <td align="center"><b>Home Screen</b></td>
      <td align="center"><b>Focus Session</b></td>
      <td align="center"><b>Paused / Break</b></td>
      <td align="center"><b>Session Complete</b></td>
    </tr>
    <tr>
      <td align="center"><img src="screenshots/englishss/ana.png" width="200"/></td>
      <td align="center"><img src="screenshots/englishss/devamet.png" width="200"/></td>
      <td align="center"><img src="screenshots/englishss/durdur.png" width="200"/></td>
      <td align="center"><img src="screenshots/englishss/bitir.png" width="200"/></td>
    </tr>
    <tr>
      <td align="center"><b>Statistics</b></td>
      <td align="center"><b>Settings Menu</b></td>
      <td align="center"><b>Duration Config</b></td>
      <td align="center"><b>Sound Selection</b></td>
    </tr>
    <tr>
      <td align="center"><img src="screenshots/englishss/istatistik.png" width="200"/></td>
      <td align="center"><img src="screenshots/englishss/ayarlar.png" width="200"/></td>
      <td align="center"><img src="screenshots/englishss/sureayar.png" width="200"/></td>
      <td align="center"><img src="screenshots/englishss/sesayar.png" width="200"/></td>
    </tr>
  </table>
</div>

## 🛠️ Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Provider / Riverpod / Bloc _(Update based on your code)_
- **Local Storage:** Hive / SharedPreferences
- **Charting:** fl_chart
- **Audio Engine:** audioplayers

---

<div id="-türkçe-proje-detayları"></div>

## 🇹🇷 Türkçe Proje Detayları

**Pomodoro Elite**, modern dünyanın dikkat dağıtıcı unsurlarına karşı geliştirilmiş, kullanıcıların zaman yönetimi becerilerini en üst seviyeye çıkarmayı hedefleyen profesyonel bir mobil uygulamadır.

Sıradan bir sayaç uygulamasının ötesine geçen Pomodoro Elite, **Flutter** altyapısı ile geliştirilmiş olup, kullanıcıya sadece zamanı göstermekle kalmaz; aynı zamanda motive eder ve analiz sunar. Uygulama, çalışma (odaklanma) ve mola sürelerini kullanıcının ihtiyaçlarına göre optimize etmesine olanak tanır.

Özellikle sınav dönemindeki öğrenciler, yoğun çalışan yazılımcılar ve serbest zamanlı çalışanlar için tasarlanan bu uygulama; yağmur, orman gibi odak artırıcı arka plan sesleri ve her oturumda değişen motivasyon sözleri ile tam bir "çalışma asistanı" görevi görür. Ayrıca, gelişmiş grafik arayüzü sayesinde günler ve haftalar bazında ne kadar verimli çalıştığınızı somut verilerle önünüze serer.

## ✨ Temel Özellikler

- **🎯 Esnek Zamanlayıcı:** Odaklanma, Kısa Mola ve Uzun Mola sürelerini kendi çalışma disiplininize göre tamamen kişiselleştirebilirsiniz.
- **📊 Detaylı Verimlilik Analizi:** Günlük çalışma sürelerinizi, tamamlanan oturum sayısını ve haftalık performansınızı şık grafiklerle takip edin.
- **🎨 Dinamik Tema Motoru:** Uygulama o anki modunuza (Odaklanma, Mola, Bitiş) göre renk değiştirerek görsel hafızanızı tetikler.
- **🎵 Odaklanma Atmosferi:** Dış sesleri izole etmek için entegre edilmiş yüksek kaliteli ortam sesleri (Fırtına, Yağmur, Okyanus vb.).
- **🌍 Çift Dil Desteği:** Türkçe ve İngilizce dil seçenekleri ile global standartlarda kullanıcı deneyimi.
- **🌑 Karanlık Mod:** Göz yormayan, pil dostu ve estetik karanlık mod desteği.

## 📸 Ekran Görüntüleri (Türkçe)

<div align="center">
  <table>
    <tr>
      <td align="center"><b>Ana Ekran</b></td>
      <td align="center"><b>Odaklanma Modu</b></td>
      <td align="center"><b>Duraklat / Mola</b></td>
      <td align="center"><b>Tebrikler</b></td>
    </tr>
    <tr>
      <td align="center"><img src="screenshots/turkcess/ana.png" width="200"/></td>
      <td align="center"><img src="screenshots/turkcess/devamet.png" width="200"/></td>
      <td align="center"><img src="screenshots/turkcess/duraklat.png" width="200"/></td>
      <td align="center"><img src="screenshots/turkcess/bitir.png" width="200"/></td>
    </tr>
    <tr>
      <td align="center"><b>İstatistikler</b></td>
      <td align="center"><b>Ayarlar</b></td>
      <td align="center"><b>Süre Ayarları</b></td>
      <td align="center"><b>Ses Ayarları</b></td>
    </tr>
    <tr>
      <td align="center"><img src="screenshots/turkcess/istatistik.png" width="200"/></td>
      <td align="center"><img src="screenshots/turkcess/ayarlar.png" width="200"/></td>
      <td align="center"><img src="screenshots/turkcess/sureayar.png" width="200"/></td>
      <td align="center"><img src="screenshots/turkcess/arkaplanses.png" width="200"/></td>
    </tr>
  </table>
</div>

## 👤 Yazar / Author

**Harun Reşit Mercan**

- LinkedIn: [Harun Reşit Mercan](https://www.linkedin.com/in/harun-resit-mercan/)
- GitHub: [@HarunMercan1](https://github.com/HarunMercan1)

---

<div align="center">
  <sub>Built with ❤️ by Harun using Flutter</sub>
</div>
