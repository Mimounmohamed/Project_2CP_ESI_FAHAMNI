import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import en from "./locales/en.json";
import fr from "./locales/fr.json";
import ar from "./locales/ar.json";

const LANG_MAP = { Eng: "en", Fr: "fr", Ar: "ar" };

export function applyLanguage(langCode) {
  i18n.changeLanguage(langCode);
  document.documentElement.dir = langCode === "ar" ? "rtl" : "ltr";
  document.documentElement.lang = langCode;
}

export function applyAdminLanguage(adminLang) {
  const code = LANG_MAP[adminLang] ?? "en";
  applyLanguage(code);
}

const savedLang = (() => {
  try { return localStorage.getItem("fahamni_lang") ?? "en"; } catch { return "en"; }
})();

i18n.use(initReactI18next).init({
  resources: {
    en: { translation: en },
    fr: { translation: fr },
    ar: { translation: ar },
  },
  lng: savedLang,
  fallbackLng: "en",
  interpolation: { escapeValue: false },
});

document.documentElement.dir = savedLang === "ar" ? "rtl" : "ltr";
document.documentElement.lang = savedLang;

export default i18n;
