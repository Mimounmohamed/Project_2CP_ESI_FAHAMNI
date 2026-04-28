import { useState, useRef } from "react";
import { getAuth, reauthenticateWithCredential, EmailAuthProvider, updatePassword, updateEmail, sendEmailVerification } from "firebase/auth";
import { doc, updateDoc, collection, query, where, getDocs } from "firebase/firestore";
import { db } from "./firebase";

const TABS = ["Account", "Security", "Notifications", "Support"];

export default function SettingsPage({ user, adminData, onAdminDataChange }) {
  const [tab, setTab] = useState("Account");

  return (
    <div style={s.wrap}>
      <div style={s.header}>
        <div style={s.headerTitle}>System Settings</div>
        <div style={s.headerSub}>Configure your workspace preferences and security protocols.</div>
      </div>
      <div style={s.body}>
        <aside style={s.sidebar}>
          {TABS.map(t => (
            <button
              key={t}
              onClick={() => setTab(t)}
              style={{ ...s.tabBtn, ...(tab === t ? s.tabActive : {}) }}
            >
              <TabIcon name={t} active={tab === t} />
              {t}
              {t === "Security" && <span style={s.tabArrow}>›</span>}
            </button>
          ))}
        </aside>
        <div className="thin-scroll" style={s.panel}>
          {tab === "Account"       && <AccountTab user={user} adminData={adminData} onAdminDataChange={onAdminDataChange} />}
          {tab === "Security"      && <SecurityTab user={user} />}
          {tab === "Notifications" && <NotificationsTab />}
          {tab === "Support"       && <SupportTab />}
        </div>
      </div>
    </div>
  );
}

// ── Account Tab ──────────────────────────────────────────────────────────────
function AccountTab({ user, adminData, onAdminDataChange }) {
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
        setMsg({ type: "ok", text: "Profile updated successfully." });
      }
    } catch (e) {
      setMsg({ type: "err", text: e.message });
    }
    setSaving(false);
  }

  return (
    <div>
      <div style={s.panelTitle}>Profile Information</div>
      <div style={s.panelSub}>Update your photo and personal details.</div>
      <div style={s.profileCard}>
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
          <input ref={fileRef} type="file" accept="image/*" style={{ display: "none" }} />
          <div style={s.avatarHint}>JPG, GIF or PNG. Max size of 800K</div>
        </div>
        <div style={s.fieldsGrid}>
          <Field label="First Name"    value={form.firstName} onChange={v => set("firstName", v)} />
          <Field label="Last Name"     value={form.lastName}  onChange={v => set("lastName",  v)} />
          <Field label="Birthday"      value={form.birthday}  onChange={v => set("birthday",  v)} placeholder="MM/DD/YYYY" />
          <Field label="Email Address" value={form.email}     onChange={() => {}} disabled />
          <Field label="Phone Number"  value={form.phone}     onChange={v => set("phone",     v)} placeholder="05XXXXXXXX" />
          <div>
            <div style={s.fieldLabel}>Language</div>
            <select
              value={form.language}
              onChange={e => set("language", e.target.value)}
              style={{ ...s.input, cursor: "pointer", appearance: "auto" }}
            >
              <option value="Eng">English</option>
              <option value="Fr">French</option>
              <option value="Ar">Arabic</option>
            </select>
          </div>
        </div>
        {msg && <MsgBox msg={msg} />}
        <div style={{ display: "flex", justifyContent: "flex-end", marginTop: 16 }}>
          <button style={s.saveBtn} onClick={handleSave} disabled={saving}>
            {saving ? "Saving…" : "Save Changes"}
          </button>
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
  const items = [
    { key: "changePassword", label: "Change Password" },
    { key: "updateEmail",    label: "Update Email" },
    { key: "updatePhone",    label: "Update Phone Number" },
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
  const [current, setCurrent] = useState("");
  const [next,    setNext]    = useState("");
  const [confirm, setConfirm] = useState("");
  const [msg,     setMsg]     = useState(null);
  const [loading, setLoading] = useState(false);

  async function handleConfirm() {
    if (next !== confirm) return setMsg({ type: "err", text: "Passwords do not match." });
    if (next.length < 6)  return setMsg({ type: "err", text: "Password must be at least 6 characters." });
    setLoading(true);
    setMsg(null);
    try {
      const auth = getAuth();
      const cred = EmailAuthProvider.credential(auth.currentUser.email, current);
      await reauthenticateWithCredential(auth.currentUser, cred);
      await updatePassword(auth.currentUser, next);
      setMsg({ type: "ok", text: "Password updated successfully." });
      setCurrent(""); setNext(""); setConfirm("");
    } catch (e) {
      setMsg({ type: "err", text: e.code === "auth/wrong-password" ? "Current password is incorrect." : e.message });
    }
    setLoading(false);
  }

  return (
    <div>
      <div style={s.subHeader}>
        <button style={s.backBtn} onClick={onBack}>‹</button>
        <span style={s.subTitle}>Change Password</span>
      </div>
      <div style={s.formCard}>
        <PwField label="Current Password" value={current} onChange={setCurrent} />
        <PwField label="New Password"     value={next}    onChange={setNext} />
        <PwField label="Confirm Password" value={confirm} onChange={setConfirm} />
        {msg && <MsgBox msg={msg} />}
        <button style={s.confirmBtn} onClick={handleConfirm} disabled={loading}>
          {loading ? "Confirming…" : "Confirm"}
        </button>
      </div>
    </div>
  );
}

function UpdateEmail({ user, onBack }) {
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
      setMsg({ type: "err", text: "Incorrect password." });
    }
    setLoading(false);
  }

  async function stepTwoContinue() {
    if (newEmail !== confirmEmail) return setMsg({ type: "err", text: "Emails do not match." });
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
        <span style={s.subTitle}>Update Email</span>
      </div>
      <div style={s.formCard}>
        {step === 1 && <>
          <div style={s.fieldLabel}>Enter Password</div>
          <PwInput value={password} onChange={setPassword} />
          {msg && <MsgBox msg={msg} />}
          <button style={s.confirmBtn} onClick={stepOneConfirm} disabled={loading}>
            {loading ? "Verifying…" : "Confirm"}
          </button>
        </>}
        {step === 2 && <>
          <Field label="New Email"     value={newEmail}     onChange={setNewEmail} />
          <div style={{ marginTop: 12 }} />
          <Field label="Confirm Email" value={confirmEmail} onChange={setConfirmEmail} />
          {msg && <MsgBox msg={msg} />}
          <button style={s.confirmBtn} onClick={stepTwoContinue} disabled={loading}>
            {loading ? "Sending…" : "Continue"}
          </button>
        </>}
        {step === 3 && <>
          <div style={{ textAlign: "center", marginBottom: 8 }}>
            <div style={{ fontWeight: 600, fontSize: 16, color: "#1F2937" }}>Email Verification</div>
            <div style={{ fontSize: 13, color: "#64748b", marginTop: 4 }}>Enter the code that we have sent you</div>
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
          <button style={s.confirmBtn} onClick={() => setMsg({ type: "ok", text: "Email updated. Please verify using the link sent to your inbox." })}>
            Confirm
          </button>
          <button style={s.resendBtn} onClick={stepTwoContinue}>Resend Code</button>
        </>}
      </div>
    </div>
  );
}

function UpdatePhone({ user, onBack }) {
  const [step,         setStep]         = useState(1);
  const [password,     setPassword]     = useState("");
  const [newPhone,     setNewPhone]     = useState("");
  const [confirmPhone, setConfirmPhone] = useState("");
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
      setMsg({ type: "err", text: "Incorrect password." });
    }
    setLoading(false);
  }

  function stepTwoContinue() {
    if (newPhone !== confirmPhone) return setMsg({ type: "err", text: "Phone numbers do not match." });
    setMsg(null);
    setStep(3);
  }

  function handleCodeInput(i, val) {
    const v = val.replace(/\D/, "");
    const next = [...code];
    next[i] = v;
    setCode(next);
    if (v && i < 5) inputs.current[i + 1]?.focus();
  }

  async function stepThreeConfirm() {
    try {
      const snap = await getDocs(query(collection(db, "admins"), where("email", "==", user.email)));
      if (!snap.empty) await updateDoc(doc(db, "admins", snap.docs[0].id), { phone: newPhone });
      setMsg({ type: "ok", text: "Phone number updated successfully." });
    } catch (e) {
      setMsg({ type: "err", text: e.message });
    }
  }

  return (
    <div>
      <div style={s.subHeader}>
        <button style={s.backBtn} onClick={onBack}>‹</button>
        <span style={s.subTitle}>Update Phone</span>
      </div>
      <div style={s.formCard}>
        {step === 1 && <>
          <div style={s.fieldLabel}>Enter Password</div>
          <PwInput value={password} onChange={setPassword} />
          {msg && <MsgBox msg={msg} />}
          <button style={s.confirmBtn} onClick={stepOneConfirm} disabled={loading}>
            {loading ? "Verifying…" : "Confirm"}
          </button>
        </>}
        {step === 2 && <>
          <Field label="New Phone"     value={newPhone}     onChange={setNewPhone}     placeholder="05XXXXXXXX" />
          <div style={{ marginTop: 12 }} />
          <Field label="Confirm Phone" value={confirmPhone} onChange={setConfirmPhone} placeholder="05XXXXXXXX" />
          {msg && <MsgBox msg={msg} />}
          <button style={s.confirmBtn} onClick={stepTwoContinue}>Continue</button>
        </>}
        {step === 3 && <>
          <div style={{ textAlign: "center", marginBottom: 8 }}>
            <div style={{ fontWeight: 600, fontSize: 16, color: "#1F2937" }}>Phone Verification</div>
            <div style={{ fontSize: 13, color: "#64748b", marginTop: 4 }}>Enter the code that we have sent you</div>
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
          <button style={s.confirmBtn} onClick={stepThreeConfirm} disabled={loading}>Confirm</button>
          <button style={s.resendBtn} onClick={() => setStep(2)}>Resend Code</button>
        </>}
      </div>
    </div>
  );
}

// ── Notifications Tab ────────────────────────────────────────────────────────
const NOTIFICATION_GROUPS = [
  {
    label: "Email Notifications",
    items: [
      { key: "newOrders",     label: "New orders",         desc: "Get notified when a new order is placed" },
      { key: "orderUpdates",  label: "Order updates",      desc: "Receive status changes for existing orders" },
      { key: "promotions",    label: "Promotions & offers", desc: "Weekly deals and discount announcements" },
      { key: "securityAlerts",label: "Security alerts",    desc: "Login attempts and account changes" },
    ],
  },
  {
    label: "Push Notifications",
    items: [
      { key: "realTime", label: "Real-time alerts", desc: "Instant push for critical system events" },
      { key: "digest",   label: "Weekly digest",    desc: "Summary of activity every Monday morning" },
    ],
  },
  {
    label: "SMS Notifications",
    items: [
      { key: "smsOrders", label: "Order confirmations", desc: "SMS when a new order is confirmed" },
      { key: "smsAlerts", label: "Critical alerts",     desc: "Emergency system-level notifications" },
    ],
  },
];

const DEFAULT_PREFS = {
  newOrders: true, orderUpdates: true, promotions: false, securityAlerts: true,
  realTime: true,  digest: false,
  smsOrders: false, smsAlerts: true,
};

function NotificationsTab() {
  const [prefs, setPrefs] = useState(DEFAULT_PREFS);
  const [saved, setSaved] = useState(false);

  function toggle(key) {
    setPrefs(p => ({ ...p, [key]: !p[key] }));
    setSaved(false);
  }

  function handleSave() {
    setSaved(true);
    setTimeout(() => setSaved(false), 2500);
  }

  return (
    <div>
      <div style={s.panelTitle}>Notifications</div>
      <div style={s.panelSub}>Choose how and when you want to be notified.</div>

      {NOTIFICATION_GROUPS.map(group => (
        <div key={group.label} style={{ marginBottom: 28 }}>
          <div style={s.notifGroupLabel}>{group.label}</div>
          <div style={s.notifCard}>
            {group.items.map((item, idx) => (
              <div
                key={item.key}
                style={{
                  ...s.toggleRow,
                  borderBottom: idx < group.items.length - 1 ? "1px solid #f1f5f9" : "none",
                }}
              >
                <div style={s.toggleInfo}>
                  <div style={s.toggleLabel}>{item.label}</div>
                  <div style={s.toggleDesc}>{item.desc}</div>
                </div>
                <Toggle checked={prefs[item.key]} onChange={() => toggle(item.key)} />
              </div>
            ))}
          </div>
        </div>
      ))}

      {saved && (
        <div style={{ ...s.msgBox, background: "#f0fdf4", color: "#166534", border: "1px solid #bbf7d0", marginBottom: 12 }}>
          Notification preferences saved.
        </div>
      )}
      <div style={{ display: "flex", justifyContent: "flex-end" }}>
        <button style={s.saveBtn} onClick={handleSave}>Save Changes</button>
      </div>
    </div>
  );
}

// ── Support Tab ───────────────────────────────────────────────────────────────
function SupportTab() {
  return (
    <div>
      <div style={s.panelTitle}>Get Support</div>
      <div style={s.panelSub}>Contact Super-Admins to get help or report an error</div>
      <div style={s.supportCard}>
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

  panel:      { flex: 1, padding: "28px 32px", overflowY: "auto", scrollbarWidth: "thin" },
  panelTitle: { fontSize: 17, fontWeight: 700, color: "#1F2937", marginBottom: 2 },
  panelSub:   { fontSize: 13, color: "#64748b", marginBottom: 20 },

  profileCard:  { background: "#f8fafc", borderRadius: 10, padding: "20px 24px", border: "1px solid #e8edf5" },
  avatarWrap:   { display: "flex", flexDirection: "column", alignItems: "center", marginBottom: 24 },
  avatarCircle: { width: 72, height: 72, borderRadius: "50%", background: "#000080", display: "flex", alignItems: "center", justifyContent: "center", position: "relative", cursor: "pointer", overflow: "hidden" },
  avatarOverlay:{ position: "absolute", bottom: 0, left: 0, right: 0, height: 26, background: "rgba(0,0,0,0.45)", display: "flex", alignItems: "center", justifyContent: "center" },
  avatarHint:   { fontSize: 11, color: "#94a3b8", marginTop: 6, textAlign: "center" },
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
  notifGroupLabel: { fontSize: 11, fontWeight: 700, color: "#94a3b8", letterSpacing: "0.08em", textTransform: "uppercase", marginBottom: 8 },
  notifCard:       { background: "#f8fafc", borderRadius: 10, border: "1px solid #e8edf5", padding: "0 20px" },
  toggleRow:       { display: "flex", alignItems: "center", justifyContent: "space-between", padding: "14px 0" },
  toggleInfo:      { flex: 1 },
  toggleLabel:     { fontSize: 14, fontWeight: 600, color: "#1F2937", marginBottom: 2 },
  toggleDesc:      { fontSize: 12, color: "#64748b" },

  // Support-specific
  supportCard:    { display: "flex", gap: 40, marginTop: 8 },
  supportItem:    { display: "flex", flexDirection: "column", alignItems: "center", gap: 12, textDecoration: "none" },
  supportIconWrap:{ width: 72, height: 72, borderRadius: "50%", background: "#000080", display: "flex", alignItems: "center", justifyContent: "center" },
  supportLabel:   { fontSize: 13, color: "#1F2937", fontWeight: 500 },
};