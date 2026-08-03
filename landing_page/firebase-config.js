// Firebase App, Analytics & Realtime Database SDKs
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js";
import { getAnalytics, logEvent } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-analytics.js";
import { 
  getDatabase, 
  ref, 
  onValue, 
  runTransaction,
  increment 
} from "https://www.gstatic.com/firebasejs/10.12.0/firebase-database.js";

// Firebase Configuration for project screenshot-bed18
const firebaseConfig = {
  apiKey: "AIzaSyCiVYU5zpSrCfTekOwPGaXin3eDsOoKAYY",
  authDomain: "screenshot-bed18.firebaseapp.com",
  projectId: "screenshot-bed18",
  storageBucket: "screenshot-bed18.firebasestorage.app",
  messagingSenderId: "75203749216",
  appId: "1:75203749216:web:056c502937c10692d2ea05",
  measurementId: "G-6YQ05XQ4LG",
  databaseURL: "https://screenshot-bed18-default-rtdb.firebaseio.com/"
};

// Initialize Firebase App
const app = initializeApp(firebaseConfig);

// Initialize Analytics safely
let analytics = null;
try {
  analytics = getAnalytics(app);
  logEvent(analytics, 'page_view', { page_title: 'MacCleaner Pro Landing Page' });
} catch(e) {
  console.log("Firebase Analytics init:", e);
}

// Initialize Realtime Database with explicit URL
const database = getDatabase(app, "https://screenshot-bed18-default-rtdb.firebaseio.com/");

// Increment Visitor Count on Page Load
const visitsRef = ref(database, 'stats/visitCount');
try {
  runTransaction(visitsRef, (currentValue) => {
    return (currentValue || 0) + 1;
  });
} catch(e) {
  console.log("Visit count transaction error:", e);
}

// Function to increment download counter in Realtime Database
function incrementDownloadCount(fileType) {
  const downloadsRef = ref(database, 'stats/downloadCount');
  try {
    runTransaction(downloadsRef, (currentValue) => {
      return (currentValue || 0) + 1;
    });
    if (analytics) {
      logEvent(analytics, 'download_click', { file_type: fileType });
    }
  } catch(e) {
    console.log("Download count transaction error:", e);
  }
}

export { app, analytics, database, ref, onValue, incrementDownloadCount };
