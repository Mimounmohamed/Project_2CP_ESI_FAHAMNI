import { useState, useRef } from "react";
import { getAuth, reauthenticateWithCredential, EmailAuthProvider, updatePassword, updateEmail, sendEmailVerification } from "firebase/auth";
import { doc, updateDoc, collection, query, where, getDocs, setDoc, getDoc, deleteDoc, Timestamp } from "firebase/firestore";
import { ref as storageRef, uploadBytes, getDownloadURL } from "firebase/storage";
import { httpsCallable } from "firebase/functions";
import { db, storage, functions } from "./firebase";
import { useTranslation } from "react-i18next";
import { applyAdminLanguage } from "./i18n";

const TABS_KEYS = ["Account", "Security", "Notifications", "Support"];

export default function SettingsPage({ user, adminData, onAdminDataChange }) {
  const { t } = useTranslation();
  const [tab, setTab] = useState("Account");

  const TAB_LABELS = {
    Account:       t("settings.tabs.account"),
    Security:      t("settings.tabs.security"),
    Notifications: t("settings.tabs.notifications"),
    Support:       t("settings.tabs.support"),
  };

  return (
    <div style={s.wrap}>
      <div style={s.header}>
        <div style={s.headerTitle}>{t("settings.title")}</div>
        <div style={s.headerSub}>{t("settings.subtitle")}</div>
      </div>
      <div className="settings-body">
        <aside style={s.sidebar} className="settings-sidebar-nav">
          {TABS_KEYS.map(key => (
            <button
              key={key}
              onClick={() => setTab(key)}
              style={{ ...s.tabBtn, ...(tab === key ? s.tabActive : {}) }}
            >
              <TabIcon name={key} active={tab === key} />
              {TAB_LABELS[key]}
              {tab === key && <span style={s.tabArrow}>›</span>}
            </button>
          ))}
        </aside>
        <div className="thin-scroll settings-panel" style={s.panel}>
          {tab === "Account"       && <AccountTab user={user} adminData={adminData} onAdminDataChange={onAdminDataChange} />}
          {tab === "Security"      && <SecurityTab user={user} />}
          {tab === "Notifications" && <NotificationsTab user={user} adminData={adminData} />}
          {tab === "Support"       && <SupportTab />}
        </div>
      </div>
    </div>
  );
}

// ── Account Tab ──────────────────────────────────────────────────────────────
function AccountTab({ user, adminData, onAdminDataChange }) {
  const { t } = useTranslation();
  const [form, setForm] = useState({
    firstName: adminData?.firstName ?? "",
    lastName:  adminData?.lastName  ?? "",
    birthday:  adminData?.birthday  ?? "",
    email:     adminData?.email     ?? user?.email ?? "",
    phone:     adminData?.phone     ?? "",
    language:  adminData?.language  ?? "Eng",
  });
  const [saving, setSaving] = useState(false);
  const [msg,    setMsg]    = useState(null);
  const fileRef = useRef();

  function set(k, v) { setForm(f => ({ ...f, [k]: v })); }

  async function handlePictureChange(e) {
    const file = e.target.files[0];
    if (!file) return;
    if (file.size > 800 * 1024) { setMsg({ type: "err", text: t("account.imageTooLarge") }); return; }
    setSaving(true); setMsg(null);
    try {
      const imgRef = storageRef(storage, `admin-pictures/${user.email}`);
      await uploadBytes(imgRef, file);
      const url  = await getDownloadURL(imgRef);
      const snap = await getDocs(query(collection(db, "admins"), where("email", "==", user.email)));
      if (!snap.empty) await updateDoc(doc(db, "admins", snap.docs[0].id), { picture: url });
      onAdminDataChange?.({ ...adminData, picture: url });
      setMsg({ type: "ok", text: t("account.pictureUpdated") });
    } catch (e) {
      setMsg({ type: "err", text: t("account.pictureUploadFailed") });
      console.error(e);
    }
    setSaving(false);
  }

  async function handleSave() {
    setSaving(true);
    setMsg(null);
    try {
      const snap = await getDocs(query(collection(db, "admins"), where("email", "==", user.email)));
      if (!snap.empty) {
        await updateDoc(doc(db, "admins", snap.docs[0].id), {
          firstName: form.firstName,
          lastName:  form.lastName,
          birthday:  form.birthday,
          phone:     form.phone,
          language:  form.language,
        });
        onAdminDataChange?.({ ...adminData, ...form });
        applyAdminLanguage(form.language);
        try { localStorage.setItem("fahamni_lang", { Eng: "en", Fr: "fr", Ar: "ar" }[form.language] ?? "en"); } catch {}
        setMsg({ type: "ok", text: t("account.profileUpdated") });
      }
    } catch (e) {
      setMsg({ type: "err", text: e.message });
    }
    setSaving(false);
  }

  return (
    <div>
      <div style={s.panelTitle}>{t("account.profileInfo")}</div>
      <div style={s.panelSub}>{t("account.updatePhotoDetails")}</div>
      <div style={s.profileCard}>
        <div className="settings-profile-inner">
          <div style={s.avatarWrap}>
            <div style={s.avatarCircle} onClick={() => fileRef.current?.click()}>
              {adminData?.picture
                ? <img src={adminData.picture} alt="avatar" style={{ width: "100%", height: "100%", objectFit: "cover", borderRadius: "50%" }} />
                : <span style={{ fontSize: 28, fontWeight: 700, color: "#fff" }}>
                    {(form.firstName?.[0] ?? "") + (form.lastName?.[0] ?? "")}
                  </span>
              }
              <div style={s.avatarOverlay}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2">
                  <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/>
                  <circle cx="12" cy="13" r="4"/>
                </svg>
              </div>
            </div>
            <input ref={fileRef} type="file" accept="image/*" style={{ display: "none" }} onChange={handlePictureChange} />
            <div style={s.avatarHint}>{t("account.imageHint")}</div>
          </div>
          <div style={{ flex: 1 }}>
            <div className="settings-fields-grid">
              <Field label={t("account.firstName")}    value={form.firstName} onChange={v => set("firstName", v)} />
              <Field label={t("account.lastName")}     value={form.lastName}  onChange={v => set("lastName",  v)} />
              <Field label={t("account.birthday")}     value={form.birthday}  onChange={v => set("birthday",  v)} placeholder={t("account.birthdayPlaceholder")} />
              <Field label={t("account.email")}        value={form.email}     onChange={() => {}} disabled />
              <Field label={t("account.phone")}        value={form.phone}     onChange={() => {}} disabled />
              <div>
                <div style={s.fieldLabel}>{t("account.language")}</div>
                <select
                  value={form.language}
                  onChange={e => set("language", e.target.value)}
                  style={{ ...s.input, cursor: "pointer", appearance: "auto" }}
                >
                  <option value="Eng">{t("account.languageEn")}</option>
                  <option value="Fr">{t("account.languageFr")}</option>
                  <option value="Ar">{t("account.languageAr")}</option>
                </select>
              </div>
            </div>
            {msg && <MsgBox msg={msg} />}
            <div style={{ display: "flex", justifyContent: "flex-end", marginTop: 16 }}>
              <button style={s.saveBtn} onClick={handleSave} disabled={saving}>
                {saving ? t("account.saving") : t("account.saveChanges")}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function Field({ label, value, onChange, disabled, placeholder }) {
  return (
    <div>
      <div style={s.fieldLabel}>{label}</div>
      <input
        style={{ ...s.input, ...(disabled ? s.inputDisabled : {}) }}
        value={value}
        onChange={e => onChange(e.target.value)}
        disabled={disabled}
        placeholder={placeholder ?? ""}
      />
    </div>
  );
}

// ── Security Tab ─────────────────────────────────────────────────────────────
function SecurityTab({ user }) {
  const { t } = useTranslation();
  const [view, setView] = useState("menu");
  return (
    <div>
      {view === "menu"           && <SecurityMenu onSelect={setView} />}
      {view === "changePassword" && <ChangePassword user={user} onBack={() => setView("menu")} />}
      {view === "updateEmail"    && <UpdateEmail    user={user} onBack={() => setView("menu")} />}
      {view === "updatePhone"    && <UpdatePhone    user={user} onBack={() => setView("menu")} />}
    </div>
  );
}

function SecurityMenu({ onSelect }) {
  const { t } = useTranslation();
  const items = [
    { key: "changePassword", label: t("security.changePassword") },
    { key: "updateEmail",    label: t("security.updateEmail") },
    { key: "updatePhone",    label: t("security.updatePhone") },
  ];
  return (
    <div style={s.menuList}>
      {items.map(it => (
        <button key={it.key} style={s.menuItem} onClick={() => onSelect(it.key)}>
          <span>{it.label}</span>
          <span style={s.menuArrow}>›</span>
        </button>
      ))}
    </div>
  );
}

function ChangePassword({ user, onBack }) {
  const { t } = useTranslation();
  const [current, setCurrent] = useState("");
  const [next,    setNext]    = useState("");
  const [confirm, setConfirm] = useState("");
  const [msg,     setMsg]     = useState(null);
  const [loading, setLoading] = useState(false);

  async function handleConfirm() {
    if (next !== confirm) return setMsg({ type: "err", text: t("security.passwordMismatch") });
    if (next.length < 6)  return setMsg({ type: "err", text: t("security.passwordTooShort") });
    setLoading(true);
    setMsg(null);
    try {
      const auth = getAuth();
      const cred = EmailAuthProvider.credential(auth.currentUser.email, current);
      await reauthenticateWithCredential(auth.currentUser, cred);
      await updatePassword(auth.currentUser, next);
      setMsg({ type: "ok", text: t("security.passwordUpdated") });
      setCurrent(""); setNext(""); setConfirm("");
    } catch (e) {
      setMsg({ type: "err", text: e.code === "auth/wrong-password" ? t("security.incorrectPassword") : e.message });
    }
    setLoading(false);
  }

  return (
    <div>
      <div style={s.subHeader}>
        <button style={s.backBtn} onClick={onBack}>‹</button>
        <span style={s.subTitle}>{t("security.changePassword")}</span>
      </div>
      <div style={s.formCard}>
        <PwField label={t("security.currentPassword")} value={current} onChange={setCurrent} />
        <PwField label={t("security.newPassword")}     value={next}    onChange={setNext} />
        <PwField label={t("security.confirmPassword")} value={confirm} onChange={setConfirm} />
        {msg && <MsgBox msg={msg} />}
        <button style={s.confirmBtn} onClick={handleConfirm} disabled={loading}>
          {loading ? t("security.confirming") : t("security.confirm")}
        </button>
      </div>
    </div>
  );
}

function UpdateEmail({ user, onBack }) {
  const { t } = useTranslation();
  const [step,         setStep]         = useState(1);
  const [password,     setPassword]     = useState("");
  const [newEmail,     setNewEmail]     = useState("");
  const [confirmEmail, setConfirmEmail] = useState("");
  const [code,         setCode]         = useState(["", "", "", "", "", ""]);
  const [msg,          setMsg]          = useState(null);
  const [loading,      setLoading]      = useState(false);
  const inputs = useRef([]);

  async function stepOneConfirm() {
    setLoading(true); setMsg(null);
    try {
      const auth = getAuth();
      const cred = EmailAuthProvider.credential(auth.currentUser.email, password);
      await reauthenticateWithCredential(auth.currentUser, cred);
      setStep(2);
    } catch {
      setMsg({ type: "err", text: t("security.incorrectPassword2") });
    }
    setLoading(false);
  }

  async function stepTwoContinue() {
    if (newEmail !== confirmEmail) return setMsg({ type: "err", text: t("security.emailMismatch") });
    setLoading(true); setMsg(null);
    try {
      const auth = getAuth();
      await updateEmail(auth.currentUser, newEmail);
      await sendEmailVerification(auth.currentUser);
      setStep(3);
    } catch (e) {
      setMsg({ type: "err", text: e.message });
    }
    setLoading(false);
  }

  function handleCodeInput(i, val) {
    const v = val.replace(/\D/, "");
    const next = [...code];
    next[i] = v;
    setCode(next);
    if (v && i < 5) inputs.current[i + 1]?.focus();
  }

  return (
    <div>
      <div style={s.subHeader}>
        <button style={s.backBtn} onClick={onBack}>‹</button>
        <span style={s.subTitle}>{t("security.updateEmail")}</span>
      </div>
      <div style={s.formCard}>
        {step === 1 && <>
          <div style={s.fieldLabel}>{t("security.enterPassword")}</div>
          <PwInput value={password} onChange={setPassword} />
          {msg && <MsgBox msg={msg} />}
          <button style={s.confirmBtn} onClick={stepOneConfirm} disabled={loading}>
            {loading ? t("security.verifying") : t("security.confirm")}
          </button>
        </>}
        {step === 2 && <>
          <Field label={t("security.newEmail")}     value={newEmail}     onChange={setNewEmail} />
          <div style={{ marginTop: 12 }} />
          <Field label={t("security.confirmEmail")} value={confirmEmail} onChange={setConfirmEmail} />
          {msg && <MsgBox msg={msg} />}
          <button style={s.confirmBtn} onClick={stepTwoContinue} disabled={loading}>
            {loading ? t("security.sending") : t("security.continue")}
          </button>
        </>}
        {step === 3 && <>
          <div style={{ textAlign: "center", marginBottom: 8 }}>
            <div style={{ fontWeight: 600, fontSize: 16, color: "#1F2937" }}>{t("security.emailVerification")}</div>
            <div style={{ fontSize: 13, color: "#64748b", marginTop: 4 }}>{t("security.enterCodeSent")}</div>
          </div>
          <div style={s.codeRow}>
            {code.map((c, i) => (
              <input
                key={i}
                ref={el => inputs.current[i] = el}
                style={s.codeInput}
                maxLength={1}
                value={c}
                onChange={e => handleCodeInput(i, e.target.value)}
                onKeyDown={e => { if (e.key === "Backspace" && !code[i] && i > 0) inputs.current[i - 1]?.focus(); }}
              />
            ))}
          </div>
          {msg && <MsgBox msg={msg} />}
          <button style={s.confirmBtn} onClick={() => setMsg({ type: "ok", text: t("security.emailUpdated") })}>
            {t("security.confirm")}
          </button>
          <button style={s.resendBtn} onClick={stepTwoContinue}>{t("security.resendCode")}</button>
        </>}
      </div>
    </div>
  );
}

function UpdatePhone({ user, onBack }) {
  const { t } = useTranslation();
  const [step,         setStep]         = useState(1);
  const [password,     setPassword]     = useState("");
  const [newPhone,     setNewPhone]     = useState("");
  const [confirmPhone, setConfirmPhone] = useState("");
  const [code,         setCode]         = useState(["","","","","",""]);
  const [msg,          setMsg]          = useState(null);
  const [loading,      setLoading]      = useState(false);
  const inputs = useRef([]);

  async function stepOneConfirm() {
    setLoading(true); setMsg(null);
    try {
      const auth = getAuth();
      const cred = EmailAuthProvider.credential(auth.currentUser.email, password);
      await reauthenticateWithCredential(auth.currentUser, cred);
      setStep(2);
    } catch {
      setMsg({ type: "err", text: t("security.incorrectPassword2") });
    }
    setLoading(false);
  }

  async function sendEmailCode() {
    if (!newPhone || !confirmPhone) return setMsg({ type: "err", text: t("security.fillBothFields") });
    const phone        = newPhone.replace(/\s+/g, "");
    const phoneConfirm = confirmPhone.replace(/\s+/g, "");
    if (phone !== phoneConfirm) return setMsg({ type: "err", text: t("security.phoneMismatch") });
    if (!/^\+\d{7,15}$/.test(phone)) return setMsg({ type: "err", text: t("security.invalidPhoneFormat") });
    setLoading(true); setMsg(null);
    try {
      const auth  = getAuth();
      const email = auth.currentUser.email;
      const otp   = (100000 + Math.floor(Math.random() * 900000)).toString();
      const expiry = Timestamp.fromDate(new Date(Date.now() + 10 * 60 * 1000));
      await setDoc(doc(db, "email_otps", email), { code: otp, expiresAt: expiry, type: "phone_update", verified: false });
      await httpsCallable(functions, "sendOtpEmail")({ email, firstName: "", code: otp, isReset: false });
      setNewPhone(phone);
      setCode(["","","","","",""]);
      setStep(3);
    } catch (e) {
      setMsg({ type: "err", text: t("security.failedToSendCode") });
      console.error(e);
    }
    setLoading(false);
  }

  async function stepThreeConfirm() {
    const otp = code.join("");
    if (otp.length < 6) return setMsg({ type: "err", text: t("security.enterComplete6Digit") });
    setLoading(true); setMsg(null);
    try {
      const auth  = getAuth();
      const email = auth.currentUser.email;
      const snap  = await getDoc(doc(db, "email_otps", email));
      if (!snap.exists()) throw new Error(t("security.codeNotFound"));
      const { code: stored, expiresAt } = snap.data();
      if (new Date() > expiresAt.toDate()) {
        await deleteDoc(doc(db, "email_otps", email));
        throw new Error(t("security.codeExpired"));
      }
      if (stored !== otp) throw new Error(t("security.incorrectCode"));
      await deleteDoc(doc(db, "email_otps", email));
      const admSnap = await getDocs(query(collection(db, "admins"), where("email", "==", user.email)));
      if (!admSnap.empty) await updateDoc(doc(db, "admins", admSnap.docs[0].id), { phone: newPhone });
      setMsg({ type: "ok", text: t("security.phoneUpdated") });
    } catch (e) {
      setMsg({ type: "err", text: e.message ?? t("security.verificationFailed") });
    }
    setLoading(false);
  }

  function handleCodeInput(i, val) {
    const v = val.replace(/\D/, "");
    const next = [...code]; next[i] = v;
    setCode(next);
    if (v && i < 5) inputs.current[i + 1]?.focus();
  }

  return (
    <div>
      <div style={s.subHeader}>
        <button style={s.backBtn} onClick={onBack}>‹</button>
        <span style={s.subTitle}>{t("security.updatePhone")}</span>
      </div>
      <div style={s.formCard}>
        {step === 1 && <>
          <div style={s.fieldLabel}>{t("security.enterPassword")}</div>
          <PwInput value={password} onChange={setPassword} />
          {msg && <MsgBox msg={msg} />}
          <button style={s.confirmBtn} onClick={stepOneConfirm} disabled={loading}>
            {loading ? t("security.verifying") : t("security.confirm")}
          </button>
        </>}

        {step === 2 && <>
          <Field label={t("security.newPhone")}     value={newPhone}     onChange={setNewPhone}     placeholder={t("security.phonePlaceholder")} />
          <div style={{ marginTop: 12 }} />
          <Field label={t("security.confirmPhone")} value={confirmPhone} onChange={setConfirmPhone} placeholder={t("security.phonePlaceholder")} />
          <div style={{ fontSize: 11, color: "#94a3b8", marginTop: 6 }}>{t("security.phoneHint")}</div>
          {msg && <MsgBox msg={msg} />}
          <button style={s.confirmBtn} onClick={sendEmailCode} disabled={loading}>
            {loading ? t("security.sending") : t("security.sendVerificationCode")}
          </button>
        </>}

        {step === 3 && <>
          <div style={{ textAlign: "center", marginBottom: 16 }}>
            <div style={{ fontWeight: 600, fontSize: 16, color: "#1F2937" }}>{t("security.emailVerification")}</div>
            <div style={{ fontSize: 13, color: "#64748b", marginTop: 4 }}>
              {t("security.sentCodeTo")} <strong>{getAuth().currentUser?.email}</strong>
            </div>
          </div>
          <div style={s.codeRow}>
            {code.map((c, i) => (
              <input
                key={i}
                ref={el => inputs.current[i] = el}
                style={s.codeInput}
                maxLength={1}
                value={c}
                onChange={e => handleCodeInput(i, e.target.value)}
                onKeyDown={e => { if (e.key === "Backspace" && !code[i] && i > 0) inputs.current[i - 1]?.focus(); }}
              />
            ))}
          </div>
          {msg && <MsgBox msg={msg} />}
          <button style={s.confirmBtn} onClick={stepThreeConfirm} disabled={loading}>
            {loading ? t("security.verifying") : t("security.confirm")}
          </button>
          <button style={s.resendBtn} onClick={sendEmailCode} disabled={loading}>{t("security.resendCode")}</button>
        </>}
      </div>
    </div>
  );
}

// ── Notifications Tab ────────────────────────────────────────────────────────
function NotificationsTab({ user, adminData }) {
  const { t } = useTranslation();

  const ALERT_ITEMS = [
    {
      key:   "teacherValidation",
      label: t("notifications.teacherValidation"),
      desc:  t("notifications.teacherValidationDesc"),
      icon:  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/><path d="M9 16l2 2 4-4"/></svg>,
    },
    {
      key:   "newMessages",
      label: t("notifications.newMessages"),
      desc:  t("notifications.newMessagesDesc"),
      icon:  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>,
    },
    {
      key:   "newReports",
      label: t("notifications.newReports"),
      desc:  t("notifications.newReportsDesc"),
      icon:  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="9" y1="13" x2="15" y2="13"/><line x1="9" y1="17" x2="15" y2="17"/></svg>,
    },
    {
      key:   "emailNotifications",
      label: t("notifications.emailNotifications"),
      desc:  t("notifications.emailNotificationsDesc"),
      icon:  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>,
    },
  ];

  const [prefs, setPrefs] = useState(() => ({
    teacherValidation:   adminData?.notificationPrefs?.teacherValidation   ?? true,
    newMessages:         adminData?.notificationPrefs?.newMessages          ?? true,
    newReports:          adminData?.notificationPrefs?.newReports           ?? false,
    emailNotifications:  adminData?.notificationPrefs?.emailNotifications   ?? true,
  }));

  async function toggle(key) {
    const next = { ...prefs, [key]: !prefs[key] };
    setPrefs(next);
    try {
      const snap = await getDocs(query(collection(db, "admins"), where("email", "==", user.email)));
      if (!snap.empty) await updateDoc(doc(db, "admins", snap.docs[0].id), { notificationPrefs: next });
    } catch (e) { console.error("Failed to save prefs:", e); }
  }

  return (
    <div>
      <div style={s.notifGroupLabel}>{t("notifications.alertPrefs")}</div>
      <div style={s.notifCard}>
        {ALERT_ITEMS.map((item, idx) => (
          <div
            key={item.key}
            style={{ ...s.toggleRow, borderBottom: idx < ALERT_ITEMS.length - 1 ? "1px solid #f1f5f9" : "none" }}
          >
            <div style={s.notifIconWrap}>{item.icon}</div>
            <div style={s.toggleInfo}>
              <div style={s.toggleLabel}>{item.label}</div>
              <div style={s.toggleDesc}>{item.desc}</div>
            </div>
            <Toggle checked={prefs[item.key]} onChange={() => toggle(item.key)} />
          </div>
        ))}
      </div>
    </div>
  );
}

// ── Support Tab ───────────────────────────────────────────────────────────────
function SupportTab() {
  const { t } = useTranslation();
  return (
    <div>
      <div style={s.panelTitle}>{t("support.title")}</div>
      <div style={s.panelSub}>{t("support.subtitle")}</div>
      <div className="settings-support-card">
        <a href="mailto:fahamni.app@gmail.com" style={s.supportItem}>
          <div style={s.supportIconWrap}>
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="1.8">
              <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
              <polyline points="22,6 12,13 2,6"/>
            </svg>
          </div>
          <div style={s.supportLabel}>fahamni.app@gmail.com</div>
        </a>
        <a href="tel:+213555895555" style={s.supportItem}>
          <div style={s.supportIconWrap}>
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="1.8">
              <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12 19.79 19.79 0 0 1 1.61 3.4 2 2 0 0 1 3.6 1.22h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 8.81a16 16 0 0 0 6.29 6.29l.95-.95a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z"/>
            </svg>
          </div>
          <div style={s.supportLabel}>+213 555 89 55 55</div>
        </a>
      </div>
    </div>
  );
}

// ── Toggle Switch Component ───────────────────────────────────────────────────
function Toggle({ checked, onChange }) {
  return (
    <div
      onClick={onChange}
      style={{
        width: 48,
        height: 26,
        borderRadius: 50,
        background: checked ? "#000080" : "#e2e8f0",
        position: "relative",
        cursor: "pointer",
        flexShrink: 0,
        marginLeft: 16,
        transition: "background 0.25s ease",
      }}
    >
      <div
        style={{
          position: "absolute",
          top: 3,
          left: checked ? 25 : 3,
          width: 20,
          height: 20,
          borderRadius: "50%",
          background: "#fff",
          boxShadow: "0 1px 4px rgba(0,0,0,0.18)",
          transition: "left 0.25s ease",
        }}
      />
    </div>
  );
}

// ── Small helpers ─────────────────────────────────────────────────────────────
function PwField({ label, value, onChange }) {
  const [show, setShow] = useState(false);
  return (
    <div style={{ marginBottom: 14 }}>
      <div style={s.fieldLabel}>{label}</div>
      <div style={{ position: "relative" }}>
        <input
          type={show ? "text" : "password"}
          style={{ ...s.input, paddingRight: 38 }}
          value={value}
          onChange={e => onChange(e.target.value)}
        />
        <EyeBtn show={show} onToggle={() => setShow(v => !v)} />
      </div>
    </div>
  );
}

function PwInput({ value, onChange }) {
  const [show, setShow] = useState(false);
  return (
    <div style={{ position: "relative", marginBottom: 14 }}>
      <input
        type={show ? "text" : "password"}
        style={{ ...s.input, paddingRight: 38 }}
        value={value}
        onChange={e => onChange(e.target.value)}
      />
      <EyeBtn show={show} onToggle={() => setShow(v => !v)} />
    </div>
  );
}

function EyeBtn({ show, onToggle }) {
  return (
    <button
      type="button"
      onClick={onToggle}
      style={{ position: "absolute", right: 10, top: "50%", transform: "translateY(-50%)", background: "none", border: "none", cursor: "pointer", color: "#94a3b8", padding: 0 }}
    >
      {show
        ? <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
        : <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
      }
    </button>
  );
}

function MsgBox({ msg }) {
  return (
    <div style={{
      ...s.msgBox,
      background: msg.type === "ok" ? "#f0fdf4" : "#fef2f2",
      color:      msg.type === "ok" ? "#166534" : "#991b1b",
      border:    `1px solid ${msg.type === "ok" ? "#bbf7d0" : "#fecaca"}`,
    }}>
      {msg.text}
    </div>
  );
}

function TabIcon({ name, active }) {
  const col = active ? "#000080" : "#64748b";
  const p = { width: 16, height: 16, viewBox: "0 0 24 24", fill: "none", stroke: col, strokeWidth: 2 };
  if (name === "Account")       return <svg {...p}><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/></svg>;
  if (name === "Security")      return <svg {...p}><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>;
  if (name === "Notifications") return <svg {...p}><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>;
  if (name === "Support")       return <svg {...p}><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>;
  return null;
}

// ── Styles ────────────────────────────────────────────────────────────────────
const s = {
  wrap:        { display: "flex", flexDirection: "column", flex: 1, minHeight: 0 },
  header:      { marginBottom: 20 },
  headerTitle: { fontSize: 22, fontWeight: 700, color: "#000080" },
  headerSub:   { fontSize: 13, color: "#64748b", marginTop: 2 },
  body:        { display: "flex", gap: 0, flex: 1, background: "#fff", borderRadius: 14, border: "1px solid #e8edf5", overflow: "hidden" },

  sidebar:   { width: 180, minWidth: 180, borderRight: "1px solid #e8edf5", padding: "8px 0", display: "flex", flexDirection: "column" },
  tabBtn:    { display: "flex", alignItems: "center", gap: 8, width: "100%", padding: "11px 16px", background: "none", border: "none", cursor: "pointer", fontSize: 13.5, color: "#374151", fontWeight: 500, textAlign: "left", position: "relative" },
  tabActive: { color: "#000080", background: "#f0f4ff", fontWeight: 600 },
  tabArrow:  { marginLeft: "auto", fontSize: 16, color: "#94a3b8" },

  panel:      { flex: 1, padding: "28px 32px", overflowY: "auto", scrollbarWidth: "thin", scrollbarColor: "rgba(0,0,0,0.1) transparent" },
  panelTitle: { fontSize: 17, fontWeight: 700, color: "#1F2937", marginBottom: 2 },
  panelSub:   { fontSize: 13, color: "#64748b", marginBottom: 20 },

  profileCard:  { background: "#fff", borderRadius: 10, padding: "24px 28px", border: "1px solid #e8edf5" },
  avatarWrap:   { display: "flex", flexDirection: "column", alignItems: "center", minWidth: 100 },
  avatarCircle: { width: 80, height: 80, borderRadius: "50%", background: "#000080", display: "flex", alignItems: "center", justifyContent: "center", position: "relative", cursor: "pointer", overflow: "hidden" },
  avatarOverlay:{ position: "absolute", bottom: 0, left: 0, right: 0, height: 26, background: "rgba(0,0,0,0.45)", display: "flex", alignItems: "center", justifyContent: "center" },
  avatarHint:   { fontSize: 11, color: "#94a3b8", marginTop: 8, textAlign: "center", lineHeight: 1.5 },
  fieldsGrid:   { display: "grid", gridTemplateColumns: "1fr 1fr", gap: "14px 20px", marginBottom: 4 },

  fieldLabel:   { fontSize: 12, color: "#64748b", fontWeight: 500, marginBottom: 5 },
  input:        { width: "100%", padding: "9px 12px", border: "1px solid #e2e8f0", borderRadius: 8, fontSize: 13, color: "#1F2937", background: "#fff", outline: "none", boxSizing: "border-box" },
  inputDisabled:{ background: "#f1f5f9", color: "#94a3b8", cursor: "not-allowed" },
  saveBtn:      { padding: "9px 24px", background: "#000080", color: "#fff", border: "none", borderRadius: 20, fontWeight: 600, fontSize: 13, cursor: "pointer" },
  msgBox:       { borderRadius: 8, padding: "9px 14px", fontSize: 13, marginBottom: 10 },

  menuList:  { display: "flex", flexDirection: "column", gap: 0 },
  menuItem:  { display: "flex", alignItems: "center", justifyContent: "space-between", padding: "16px 20px", background: "#fff", border: "none", borderBottom: "1px solid #f1f5f9", cursor: "pointer", fontSize: 14, color: "#1F2937", fontWeight: 500, textAlign: "left" },
  menuArrow: { fontSize: 20, color: "#94a3b8" },

  subHeader: { display: "flex", alignItems: "center", gap: 12, marginBottom: 24 },
  backBtn:   { background: "none", border: "none", cursor: "pointer", fontSize: 22, color: "#1F2937", lineHeight: 1, padding: 0 },
  subTitle:  { fontSize: 18, fontWeight: 700, color: "#1F2937" },
  formCard:  { maxWidth: 520, display: "flex", flexDirection: "column" },
  confirmBtn:{ padding: "11px 0", background: "#000080", color: "#fff", border: "none", borderRadius: 24, fontWeight: 600, fontSize: 14, cursor: "pointer", marginTop: 16, width: "100%" },

  codeRow:   { display: "flex", gap: 10, justifyContent: "center", margin: "16px 0 8px" },
  codeInput: { width: 44, height: 48, textAlign: "center", fontSize: 20, fontWeight: 600, border: "1.5px solid #e2e8f0", borderRadius: 8, outline: "none", color: "#1F2937" },
  resendBtn: { background: "none", border: "none", color: "#000080", fontSize: 13, fontWeight: 600, cursor: "pointer", textDecoration: "underline", marginTop: 10, alignSelf: "center" },

  // Notifications-specific
  notifGroupLabel: { fontSize: 11, fontWeight: 700, color: "#94a3b8", letterSpacing: "0.08em", textTransform: "uppercase", marginBottom: 12 },
  notifCard:       { background: "#fff", borderRadius: 10, border: "1px solid #e8edf5", padding: "0 20px" },
  notifIconWrap:   { width: 40, height: 40, borderRadius: 10, background: "#f0f4ff", display: "flex", alignItems: "center", justifyContent: "center", color: "#000080", flexShrink: 0, marginRight: 14 },
  toggleRow:       { display: "flex", alignItems: "center", justifyContent: "space-between", padding: "14px 0" },
  toggleInfo:      { flex: 1 },
  toggleLabel:     { fontSize: 14, fontWeight: 600, color: "#1F2937", marginBottom: 2 },
  toggleDesc:      { fontSize: 12, color: "#94a3b8" },

  // Support-specific
  supportCard:    { display: "flex", gap: 40, marginTop: 8 },
  supportItem:    { display: "flex", flexDirection: "column", alignItems: "center", gap: 12, textDecoration: "none" },
  supportIconWrap:{ width: 72, height: 72, borderRadius: "50%", background: "#000080", display: "flex", alignItems: "center", justifyContent: "center" },
  supportLabel:   { fontSize: 13, color: "#1F2937", fontWeight: 500 },
};
