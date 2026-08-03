import { analytics, database, ref, onValue, incrementDownloadCount } from './firebase-config.js';

// Dictionary of translations (English & Arabic)
const i18n = {
  en: {
    dir: 'ltr',
    badge: '⚡ Developer Edition 3.2 • macOS Native App',
    heroTitle: 'Deep PHP, Node.js & Developer Cache Cleaner for macOS',
    heroSubtitle: 'Reclaim tens of gigabytes on your Mac. Safely purge PHP Composer, Node.js npm/yarn/bun, Python virtualenvs, and Xcode DerivedData.',
    downloadDmgBtn: 'Download for macOS (.dmg) ',
    downloadZipBtn: 'Download Mac App (.zip) 📦',
    exploreFeaturesBtn: 'Explore Features',
    featuresTitle: 'macOS Developer Suite Features',
    featuresSubtitle: 'Built natively for macOS to optimize storage, clear heavy developer build artifacts, and accelerate system performance.',
    
    // Live Stats
    liveStatsTitle: 'Live Realtime Community Stats',
    liveStatsSubtitle: 'Powered by Firebase Realtime Database',
    visitCountLabel: 'Total Site Visits',
    downloadCountLabel: 'Mac App Downloads',
    
    // Feature Cards
    phpTitle: 'PHP & Composer Cache Purger',
    phpDesc: 'Scans ~/.composer/cache, PHP temp session files, Laravel storage caches, compiled Blade views, and project vendor directories.',
    nodeTitle: 'Node.js & JS Build Stores',
    nodeDesc: 'Cleans global ~/.npm, ~/.yarn/cache, ~/.pnpm-store, ~/.bun caches, heavy node_modules, and Next.js / Nuxt .next build outputs.',
    pyTitle: 'Python & Tool Caches',
    pyDesc: 'Cleans pip cache (~/.cache/pip), PyPoetry, __pycache__ bytecode, CocoaPods, SwiftPM build stores, Cargo, and Go module caches.',
    xcodeTitle: 'Xcode & iOS Dev Junk',
    xcodeDesc: 'Removes Xcode DerivedData (~/Library/Developer/Xcode/DerivedData), device logs, old archives, and iOS Simulator caches.',
    sysTitle: 'System & User Caches',
    sysDesc: 'Scans macOS system caches (/Library/Caches), user caches, log files, and empties system trash safely.',
    customTitle: 'Custom Folder Deep Scanner',
    customDesc: 'Allows targeting any directory on your Mac to scan hidden files, locate large build folders, and free up space.',

    // Showcase
    showcaseTitle: 'macOS Application Interface',
    showcaseSubtitle: 'Native Swift & SwiftUI user interface designed seamlessly for macOS Dark Mode.',
    macScreenLabel: 'MacCleaner Pro - Developer Edition UI on macOS',
    
    // About Us
    aboutTitle: 'About MacCleaner Pro',
    aboutSubtitle: 'Created by Ahmed Elmwafy for software engineers & macOS power users.',
    aboutBody: 'MacCleaner Pro was engineered to solve a major pain point for developers: hidden build artifacts (node_modules, composer vendor, Xcode DerivedData, venvs) silently consuming tens of gigabytes. Built with native Swift performance and privacy first, MacCleaner Pro puts you in full control of your Mac storage.',
    contactLabel: 'Contact Developer:',
    
    // Download section
    dlSectionTitle: 'Download MacCleaner for macOS',
    dlSectionSubtitle: 'Compatible with macOS Monterey, Ventura, Sonoma, and Sequoia (Apple Silicon & Intel).',
    dlDmgCardTitle: 'Universal DMG Installer',
    dlDmgCardDesc: 'v3.2.1 • Universal Binary (M1/M2/M3 & Intel) • Drag & Drop Install',
    dlZipCardTitle: 'Standalone Zip App',
    dlZipCardDesc: 'v3.2.1 • Portable Mac App Bundle • No Installer Required',
    
    // FAQ AEO
    faqTitle: 'Frequently Asked Questions (macOS AEO)',
    faq1Q: 'How does MacCleaner Pro clean PHP and Node.js developer caches on Mac?',
    faq1A: 'MacCleaner Pro scans system paths (~/.composer/cache, ~/.npm, ~/.yarn/cache, ~/.pnpm-store) and recursively inspects developer workspace directories up to 3 levels deep to locate heavy node_modules, Laravel caches, and virtualenvs.',
    faq2Q: 'Is MacCleaner Pro compatible with Apple Silicon (M1/M2/M3) Macs?',
    faq2A: 'Yes! MacCleaner Pro is built natively for macOS as a Universal Binary, offering full native support for M1, M2, M3, and M4 Macs as well as Intel processors.',
    
    footerText: '© 2026 MacCleaner Pro Developer Edition for macOS. Developed by Ahmed Elmwafy (ahmedelmwafy@gmail.com). All rights reserved.'
  },
  ar: {
    dir: 'rtl',
    badge: '⚡ إصدار المطورين 3.2 • تطبيق macOS ناتيف',
    heroTitle: 'تنظيف كاش البرمجة الشامل وحزم PHP و Node.js لنظام الماك',
    heroSubtitle: 'استرجع عشرات الجيجابايت على جهاز الماك الخاص بك. قم بتنظيف مؤقتات PHP Composer و Node.js npm/yarn/bun وبيئات Python الافتراضية ومؤقتات Xcode DerivedData بسرعة وأمان.',
    downloadDmgBtn: 'تنزيل لنظام الماك (.dmg) ',
    downloadZipBtn: 'تنزيل تطبيق الماك (.zip) 📦',
    exploreFeaturesBtn: 'استكشاف الميزات',
    featuresTitle: 'ميزات حزمة مطوري macOS',
    featuresSubtitle: 'مبني خصيصاً لنظام macOS لتحسين المساحة وتنظيف مخلفات المشاريع الثقيلة وتسريع أداء الجهاز.',
    
    // Live Stats
    liveStatsTitle: 'إحصائيات فورية للمستخدمين',
    liveStatsSubtitle: 'مرتبط بقاعدة بيانات Firebase Realtime المباشرة',
    visitCountLabel: 'إجمالي زيارات الموقع',
    downloadCountLabel: 'إجمالي تنزيلات التطبيق',
    
    // Feature Cards
    phpTitle: 'منظف كاش PHP و Composer',
    phpDesc: 'يفحص مؤقتات ~/.composer/cache وملفات جلسات PHP ومؤقتات Laravel وقوالب Blade ومجلدات vendor للمشاريع.',
    nodeTitle: 'كاش Node.js وملفات بناء JS',
    nodeDesc: 'ينظف مؤقتات npm و Yarn و pnpm و Bun العامة ومجلدات node_modules ومخرجات بناء Next.js و Nuxt.',
    pyTitle: 'كاش Python وأدوات التطوير',
    pyDesc: 'يمسح مؤقتات pip و PyPoetry وملفات __pycache__ بالإضافة إلى مؤقتات CocoaPods و SwiftPM و Rust Cargo و Go.',
    xcodeTitle: 'مخلفات Xcode ومحاكي iOS',
    xcodeDesc: 'يزيل ملفات Xcode DerivedData وسجلات الأجهزة وسجلات المحاكاة وأرشيفات البناء القديمة.',
    sysTitle: 'كاش النظام والسجلات',
    sysDesc: 'يفحص مؤقتات نظام الماك (/Library/Caches) ومؤقتات المستخدم وسجلات اللوج وسلة المهملات بأمان.',
    customTitle: 'فحص المجلدات المخصصة',
    customDesc: 'يتيح لك اختيار أي مجلد على الماك لفحصه بعمق واستخراج الملفات المخفية وتحديد المجلدات الكبيرة.',

    // Showcase
    showcaseTitle: 'واجهة تطبيق الماك',
    showcaseSubtitle: 'واجهة مستخدم سريعة مصممة بلغة Swift & SwiftUI لتعمل بسلاسة مع الوضع الداكن على macOS.',
    macScreenLabel: 'واجهة تطبيق MacCleaner Pro على نظام macOS',
    
    // About Us
    aboutTitle: 'من نحن - عن تطبيق MacCleaner Pro',
    aboutSubtitle: 'تطوير المهندس أحمد الموافي لمطوري البرمجيات ومستخدمي الماك.',
    aboutBody: 'تم تطوير MacCleaner Pro لحل مشكلة رئيسية تواجه المطورين وهي تراكم ملفات البناء المؤقتة (node_modules, composer vendor, Xcode DerivedData, venvs) التي تستهلك عشرات الجيجابايت في الخفاء. يمنحك التطبيق تحكماً كاملاً وأماناً تاماً في إدارة مساحة التخزين.',
    contactLabel: 'للتواصل مع المطور:',

    // Download section
    dlSectionTitle: 'تنزيل MacCleaner لنظام الماك',
    dlSectionSubtitle: 'متوافق مع إصدارات macOS Monterey و Ventura و Sonoma و Sequoia (معالجات Apple Silicon و Intel).',
    dlDmgCardTitle: 'حزمة تثبيت DMG الشاملة',
    dlDmgCardDesc: 'الإصدار 3.2.1 • حزمة شاملة (M1/M2/M3 & Intel) • تثبيت مباشر',
    dlZipCardTitle: 'تطبيق الماك المضغوط ZIP',
    dlZipCardDesc: 'الإصدار 3.2.1 • تطبيق محمول جاهز للتشغيل • لا يتطلب تثبيت',
    
    // FAQ AEO
    faqTitle: 'الأسئلة الشائعة والمعلومات التقنية (AEO)',
    faq1Q: 'كيف يقوم MacCleaner Pro بتنظيف مؤقتات PHP و Node.js على الماك؟',
    faq1A: 'يقوم MacCleaner Pro بفحص المسارات الرئيسية في النظام (~/.composer/cache, ~/.npm, ~/.yarn/cache) بالإضافة إلى فحص مجلدات مشاريع البرمجة بعمق يصل إلى 3 مستويات لرصد وتحديد مجلدات node_modules الثقيلة وكاش Laravel.',
    faq2Q: 'هل يتوافق MacCleaner Pro مع معالجات Apple Silicon (M1/M2/M3)؟',
    faq2A: 'نعم! تم بناء وتجميع MacCleaner Pro خصيصاً كـ Universal Binary ليعطي أعلى أداء وفحص متعدد الخيوط Multithreaded على أجهزة الماك بمعالجات Apple Silicon و Intel.',
    
    footerText: '© 2026 MacCleaner Pro Developer Edition لنظام macOS. تطوير أحمد الموافي (ahmedelmwafy@gmail.com). جميع الحقوق محفوظة.'
  }
};

let currentLang = 'en';

// Initialize UI strings
function updateLanguage(lang) {
  currentLang = lang;
  const t = i18n[lang];
  document.body.setAttribute('dir', t.dir);
  document.documentElement.setAttribute('lang', lang);
  
  // Toggle button text
  document.getElementById('langBtnText').textContent = lang === 'en' ? 'العربية 🇸🇦' : 'English 🇺🇸';

  // Iterate over data-i18n attributes
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (t[key]) {
      el.textContent = t[key];
    }
  });
}

document.addEventListener('DOMContentLoaded', () => {
  const langToggleBtn = document.getElementById('langToggleBtn');
  if (langToggleBtn) {
    langToggleBtn.addEventListener('click', () => {
      const nextLang = currentLang === 'en' ? 'ar' : 'en';
      updateLanguage(nextLang);
    });
  }

  // Realtime Database Listeners for Visit Count & Download Count
  try {
    const visitCountEl = document.getElementById('visitCountDisplay');
    const downloadCountEl = document.getElementById('downloadCountDisplay');

    onValue(ref(database, 'stats/visitCount'), (snapshot) => {
      const val = snapshot.val() || 0;
      if (visitCountEl) visitCountEl.textContent = val.toLocaleString();
    });

    onValue(ref(database, 'stats/downloadCount'), (snapshot) => {
      const val = snapshot.val() || 0;
      if (downloadCountEl) downloadCountEl.textContent = val.toLocaleString();
    });
  } catch(e) {
    console.log("Realtime Database listener error:", e);
  }

  // Handle DMG Download click
  const dmgButtons = document.querySelectorAll('.download-dmg-btn');
  dmgButtons.forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      incrementDownloadCount('DMG');
      alert(currentLang === 'en' 
        ? 'Downloading MacCleanerPro.dmg package for macOS...' 
        : 'جاري تنزيل حزمة MacCleanerPro.dmg لنظام الماك...');
    });
  });

  // Handle ZIP Download click
  const zipButtons = document.querySelectorAll('.download-zip-btn');
  zipButtons.forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      incrementDownloadCount('ZIP');
      alert(currentLang === 'en' 
        ? 'Downloading MacCleanerPro.zip application bundle for macOS...' 
        : 'جاري تنزيل تطبيق MacCleanerPro.zip لنظام الماك...');
    });
  });
});
