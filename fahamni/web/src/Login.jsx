import { useState, useRef } from "react";
import {
  signInWithEmailAndPassword,
  setPersistence,
  browserLocalPersistence,
  browserSessionPersistence,
  getAuth,
} from "firebase/auth";
import { httpsCallable } from "firebase/functions";
import { doc, getDoc, setDoc, deleteDoc, Timestamp } from "firebase/firestore";
import app from "./firebase";
import { db, functions } from "./firebase";
import { useTranslation } from "react-i18next";

const auth = getAuth(app);

export default function Login() {
  const { t } = useTranslation();
  const [email,       setEmail]       = useState("");
  const [password,    setPassword]    = useState("");
  const [error,       setError]       = useState("");
  const [loading,     setLoading]     = useState(false);
  const [showPw,      setShowPw]      = useState(false);
  const [rememberMe,  setRememberMe]  = useState(false);

  // forgot-password multi-step: null | "otp" | "setPassword" | "done"
  const [forgotStep,    setForgotStep]    = useState(null);
  const [forgotLoading, setForgotLoading] = useState(false);
  const [otpCodes,      setOtpCodes]      = useState(["","","","","",""]);
  const [newPw,         setNewPw]         = useState("");
  const [confirmPw,     setConfirmPw]     = useState("");
  const [showNewPw,     setShowNewPw]     = useState(false);
  const [showConfirmPw, setShowConfirmPw] = useState(false);
  const otpRefs = useRef([]);

  // ── Login ──
  async function handleLogin(e) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      await setPersistence(auth, rememberMe ? browserLocalPersistence : browserSessionPersistence);
      await signInWithEmailAndPassword(auth, email, password);
    } catch {
      setError(t("login.invalidCredentials"));
    } finally {
      setLoading(false);
    }
  }

  // ── Forgot password: step 1 – send OTP ──
  async function handleSendOtp() {
    if (!email) { setError(t("login.enterEmailFirst")); return; }
    setError(""); setForgotLoading(true);
    try {
      const code   = (100000 + Math.floor(Math.random() * 900000)).toString();
      const expiry = Timestamp.fromDate(new Date(Date.now() + 10 * 60 * 1000));
      await setDoc(doc(db, "email_otps", email), {
        code, expiresAt: expiry, type: "password_reset", verified: false,
      });
      await httpsCallable(functions, "sendOtpEmail")({ email, firstName: "", code, isReset: true });
      setOtpCodes(["","","","","",""]);
      setForgotStep("otp");
    } catch (e) {
      setError(t("login.failedToSendCode"));
      console.error(e);
    }
    setForgotLoading(false);
  }

  // ── Forgot password: step 2 – verify OTP ──
  async function handleVerifyOtp() {
    const code = otpCodes.join("");
    if (code.length < 6) { setError(t("login.enterComplete6Digit")); return; }
    setError(""); setForgotLoading(true);
    try {
      const snap = await getDoc(doc(db, "email_otps", email));
      if (!snap.exists()) throw new Error(t("login.codeNotFound"));
      const { code: stored, expiresAt } = snap.data();
      if (new Date() > expiresAt.toDate()) {
        await deleteDoc(doc(db, "email_otps", email));
        throw new Error(t("login.codeExpired"));
      }
      if (stored !== code) throw new Error(t("login.incorrectCode"));
      await deleteDoc(doc(db, "email_otps", email));
      setNewPw(""); setConfirmPw("");
      setForgotStep("setPassword");
    } catch (e) {
      setError(e.message ?? "Verification failed.");
    }
    setForgotLoading(false);
  }

  // ── Forgot password: step 3 – reset password ──
  async function handleResetPassword() {
    if (newPw !== confirmPw) { setError(t("login.passwordMismatch")); return; }
    if (newPw.length < 6)   { setError(t("login.passwordTooShort")); return; }
    setError(""); setForgotLoading(true);
    try {
      await httpsCallable(functions, "resetPassword")({ email, newPassword: newPw });
      setForgotStep("done");
    } catch (e) {
      setError(t("login.failedToReset"));
      console.error(e);
    }
    setForgotLoading(false);
  }

  function handleOtpInput(i, val) {
    const v = val.replace(/\D/, "");
    const next = [...otpCodes]; next[i] = v;
    setOtpCodes(next);
    if (v && i < 5) otpRefs.current[i + 1]?.focus();
  }

  function resetForgot() {
    setForgotStep(null); setError("");
    setOtpCodes(["","","","","",""]); setNewPw(""); setConfirmPw("");
  }

  return (
    <div style={styles.page}>
      <nav style={styles.navbar}>
        <span style={styles.navBrand}>{t("login.brand")}</span>
      </nav>

      <main style={styles.main}>
        <div style={styles.card}>
          {/* Logo – always visible */}
          <div style={styles.logoWrap}>
            <svg width="114" height="87" viewBox="0 0 114 87" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path fillRule="evenodd" clipRule="evenodd" d="M54.0173 0.835334C51.1821 2.11215 46.6832 4.01423 44.0559 5.04652C42.9377 5.48586 41.0394 6.30352 39.8375 6.86372C38.6352 7.42351 36.9609 8.12437 36.1168 8.42023C35.2723 8.71649 33.6029 9.41573 32.4067 9.97472C29.7387 11.2208 25.0483 13.2543 19.6606 15.5003C15.7715 17.1215 12.2054 18.6424 6.44644 21.135C4.99289 21.7643 3.1051 22.4975 2.25167 22.7643C1.26976 23.0714 0.527335 23.626 0.230525 24.2739C-0.195173 25.2031 -0.109386 25.4056 1.15714 26.4569C1.92478 27.0939 2.78349 27.6153 3.06526 27.6153C3.34662 27.6153 4.61558 28.072 5.88495 28.6298C7.15391 29.1879 8.39441 29.6208 8.6408 29.5925C9.98132 29.4369 10.8896 29.7154 11.0921 30.3435C11.2178 30.7327 12.1907 31.3928 13.2544 31.8107C18.416 33.8381 24.3754 36.2931 26.5726 37.2971C27.9143 37.9102 29.4236 38.5411 29.9269 38.6992C30.6917 38.9397 30.8417 39.2763 30.8417 40.7504C30.8417 42.4847 30.8234 42.5082 29.7236 42.1824C29.1089 42.0001 27.4162 41.2855 25.9627 40.594C24.5091 39.9028 23.0914 39.337 22.8116 39.337C22.4315 39.3366 22.3034 40.6445 22.3034 44.5303C22.3034 49.6432 22.3221 49.7495 23.5061 51.3743C24.8645 53.2384 26.8226 54.4865 31.2483 56.3098C32.9255 57.0006 34.6637 57.7269 35.1109 57.9241C37.7964 59.1072 37.7533 59.1544 37.757 55.0257C37.7651 44.7413 40.9654 38.1915 47.7274 34.6185C51.9026 32.4125 55.2765 32.0342 69.6734 32.1563L82.2752 32.2634L82.3959 35.0219C82.5219 37.894 81.4181 43.1387 80.1918 45.4967C79.2184 47.3673 76.3731 50.2414 74.8805 50.8614L73.5335 51.4208V55.2407V59.0611L74.8549 58.9176C77.0127 58.6832 77.6161 58.496 81.8698 56.7419C87.1335 54.5718 90.0963 52.6245 90.8448 50.844C91.5572 49.1493 91.6645 40.341 90.9782 39.919C90.733 39.7686 90.1386 39.8406 89.6568 40.079C88.459 40.6724 83.7734 42.57 83.5071 42.57C83.3888 42.57 83.2916 41.8457 83.2916 40.9602C83.2916 39.4368 83.3998 39.2957 85.3006 38.3382C86.4053 37.7817 88.7379 36.7623 90.4846 36.0724C92.2309 35.3828 94.4273 34.471 95.3653 34.0462C96.3033 33.6214 97.1839 33.2738 97.3218 33.2738C97.4596 33.2738 98.5216 32.8288 99.682 32.2848C102.343 31.0371 107.273 28.9875 109.923 28.0275C111.041 27.6221 112.471 26.8283 113.101 26.2629C114.076 25.3874 114.177 25.1093 113.788 24.3863C113.302 23.4829 112.971 23.3115 106.698 20.7171C104.477 19.7984 101.732 18.6258 100.599 18.1109C96.2228 16.1223 91.1758 13.9652 90.2036 13.6677C89.6446 13.4968 88.1028 12.8367 86.7773 12.2005C85.4518 11.5644 84.2252 11.0438 84.0511 11.0438C83.8771 11.0438 82.5829 10.5147 81.1753 9.86801C76.528 7.73312 73.7864 6.56543 69.5758 4.92728C67.2871 4.03646 65.3094 3.13877 65.181 2.93183C65.0525 2.72529 64.6349 2.55594 64.2535 2.55594C63.8722 2.55594 62.4036 1.99494 60.9903 1.30944C57.6448 -0.312947 56.7077 -0.376406 54.0173 0.835334ZM53.5517 37.3039C51.2285 38.0024 47.4143 40.3531 46.2649 41.7956C45.5997 42.6306 44.6474 44.1924 44.149 45.2659C43.2679 47.164 43.2394 47.6603 43.1191 63.1061C42.9756 81.606 43.0532 82.1848 46.0595 84.9393C48.0933 86.803 49.0207 87.1397 51.6103 86.9557L53.4074 86.828L53.5168 77.835L53.6261 68.8419H57.0008C61.433 68.8419 64.1714 68.0125 66.0559 66.0999C67.8966 64.2318 69.1387 61.4555 68.9793 59.5675L68.8577 58.1311L61.2342 58.1796L53.6107 58.2281V53.061V47.8939L62.2507 47.7581C71.5156 47.6126 71.564 47.6025 74.2853 45.2235C76.0649 43.6682 77.8832 39.246 77.3851 37.6855C77.1493 36.9462 76.6305 36.9131 65.8827 36.9462C59.692 36.9652 54.1433 37.1265 53.5517 37.3039Z" fill="url(#paint0_linear_1546_1032)"/>
              <defs>
                <linearGradient id="paint0_linear_1546_1032" x1="20.3945" y1="19.3916" x2="57.1255" y2="86.9317" gradientUnits="userSpaceOnUse">
                  <stop stopColor="#000080"/>
                  <stop offset="1" stopColor="#00001A"/>
                </linearGradient>
              </defs>
            </svg>
          </div>

          {/* ── NORMAL LOGIN ── */}
          {forgotStep === null && <>
            <h1 style={styles.title}>{t("login.title")}</h1>
            <p style={styles.subtitle}>{t("login.subtitle")}</p>

            <form onSubmit={handleLogin} style={styles.form}>
              <div style={styles.fieldGroup}>
                <label style={styles.label}>{t("login.email")}</label>
                <div style={styles.inputWrap}>
                  <span style={styles.icon}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.8"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="M2 7l10 7 10-7"/></svg>
                  </span>
                  <input type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder={t("login.emailPlaceholder")} required style={styles.input} />
                </div>
              </div>

              <div style={styles.fieldGroup}>
                <label style={styles.label}>{t("login.password")}</label>
                <div style={styles.inputWrap}>
                  <span style={styles.icon}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.8"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/><circle cx="12" cy="16" r="1.5" fill="#94a3b8"/></svg>
                  </span>
                  <input type={showPw ? "text" : "password"} value={password} onChange={e => setPassword(e.target.value)} placeholder="••••••••" required style={styles.input} />
                  <button type="button" onClick={() => setShowPw(v => !v)} style={styles.eyeBtn}>
                    {showPw
                      ? <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.8"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                      : <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.8"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                    }
                  </button>
                </div>
              </div>

              <div style={styles.rememberRow}>
                <label style={styles.rememberLabel} onClick={() => setRememberMe(v => !v)}>
                  <div style={{ ...styles.checkbox, background: rememberMe ? "#000080" : "#fff", borderColor: rememberMe ? "#000080" : "#c7d2fe" }}>
                    {rememberMe && <svg width="9" height="7" viewBox="0 0 9 7" fill="none"><path d="M1 3.5L3.5 6L8 1" stroke="#fff" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/></svg>}
                  </div>
                  {t("login.rememberMe")}
                </label>
                <button type="button" onClick={handleSendOtp} disabled={forgotLoading} style={styles.forgotBtn}>
                  {forgotLoading ? t("login.sending") : t("login.forgotPassword")}
                </button>
              </div>

              {error && <ErrBox msg={error} />}

              <button type="submit" disabled={loading} style={{ ...styles.loginBtn, opacity: loading ? 0.7 : 1 }}>
                {loading ? t("login.loggingIn") : t("login.logIn")}
              </button>
            </form>

            <div style={styles.cardFooter}>
              <hr style={styles.divider} />
              <p style={styles.secureText}>{t("login.secureText")}</p>
              <p style={styles.ipText}>IP: 127.0.0.1 <span style={styles.authBadge}>(Authenticated)</span></p>
            </div>
          </>}

          {/* ── OTP STEP ── */}
          {forgotStep === "otp" && <>
            <button onClick={resetForgot} style={styles.backLink}>{t("login.backToLogin")}</button>
            <div style={styles.stepRow}>
              <div style={{ ...styles.stepDot, ...styles.stepDotActive }} />
              <div style={styles.stepDot} />
            </div>
            <div style={styles.stepIconWrap}>
              <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#000080" strokeWidth="1.8">
                <rect x="2" y="4" width="20" height="16" rx="2"/><path d="M2 7l10 7 10-7"/>
              </svg>
            </div>
            <h1 style={{ ...styles.title, fontSize: 22, marginTop: 0, marginBottom: 4 }}>{t("login.checkYourEmail")}</h1>
            <p style={{ ...styles.subtitle, marginBottom: 24, fontSize: 14 }}>
              {t("login.sentCodeTo")}<br /><strong style={{ color: "#1F2937" }}>{email}</strong>
            </p>
            <div style={styles.otpRow}>
              {otpCodes.map((c, i) => (
                <input
                  key={i}
                  ref={el => otpRefs.current[i] = el}
                  style={styles.otpBox}
                  maxLength={1}
                  value={c}
                  onChange={e => handleOtpInput(i, e.target.value)}
                  onKeyDown={e => { if (e.key === "Backspace" && !otpCodes[i] && i > 0) otpRefs.current[i - 1]?.focus(); }}
                />
              ))}
            </div>
            {error && <ErrBox msg={error} />}
            <button onClick={handleVerifyOtp} disabled={forgotLoading} style={{ ...styles.loginBtn, marginTop: 4, opacity: forgotLoading ? 0.7 : 1 }}>
              {forgotLoading ? t("login.verifying") : t("login.verifyCode")}
            </button>
            <p style={{ textAlign: "center", fontSize: 13, color: "#64748b", margin: "14px 0 0" }}>
              {t("login.didntReceiveCode")}{" "}
              <button onClick={handleSendOtp} disabled={forgotLoading} style={styles.inlineLink}>
                {t("login.resend")}
              </button>
            </p>
          </>}

          {/* ── SET PASSWORD STEP ── */}
          {forgotStep === "setPassword" && <>
            <div style={styles.stepRow}>
              <div style={styles.stepDot} />
              <div style={{ ...styles.stepDot, ...styles.stepDotActive }} />
            </div>
            <div style={styles.stepIconWrap}>
              <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#000080" strokeWidth="1.8">
                <rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                <circle cx="12" cy="16" r="1.5" fill="#000080"/>
              </svg>
            </div>
            <h1 style={{ ...styles.title, fontSize: 22, marginTop: 0, marginBottom: 4 }}>{t("login.createNewPassword")}</h1>
            <p style={{ ...styles.subtitle, marginBottom: 20, fontSize: 14 }}>{t("login.mustBe6Chars")}</p>

            <div style={styles.fieldGroup}>
              <label style={styles.label}>{t("login.newPassword")}</label>
              <div style={styles.inputWrap}>
                <span style={styles.icon}>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.8"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                </span>
                <input type={showNewPw ? "text" : "password"} value={newPw} onChange={e => setNewPw(e.target.value)} placeholder="••••••••" style={styles.input} />
                <button type="button" onClick={() => setShowNewPw(v => !v)} style={styles.eyeBtn}>
                  {showNewPw
                    ? <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.8"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                    : <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.8"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                  }
                </button>
              </div>
            </div>

            <div style={{ ...styles.fieldGroup, marginBottom: 16 }}>
              <label style={styles.label}>{t("login.confirmPassword")}</label>
              <div style={styles.inputWrap}>
                <span style={styles.icon}>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.8"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                </span>
                <input type={showConfirmPw ? "text" : "password"} value={confirmPw} onChange={e => setConfirmPw(e.target.value)} placeholder="••••••••" style={styles.input} />
                <button type="button" onClick={() => setShowConfirmPw(v => !v)} style={styles.eyeBtn}>
                  {showConfirmPw
                    ? <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.8"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                    : <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.8"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                  }
                </button>
              </div>
            </div>

            {error && <ErrBox msg={error} />}
            <button onClick={handleResetPassword} disabled={forgotLoading} style={{ ...styles.loginBtn, opacity: forgotLoading ? 0.7 : 1 }}>
              {forgotLoading ? t("login.resetting") : t("login.resetPassword")}
            </button>
          </>}

          {/* ── DONE STEP ── */}
          {forgotStep === "done" && (
            <div style={{ textAlign: "center", padding: "12px 0 8px" }}>
              <div style={{ width: 56, height: 56, borderRadius: "50%", background: "#f0fdf4", border: "2px solid #bbf7d0", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 16px" }}>
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#16a34a" strokeWidth="2.5"><path d="M20 6L9 17l-5-5"/></svg>
              </div>
              <h1 style={{ ...styles.title, fontSize: 22 }}>{t("login.passwordReset")}</h1>
              <p style={{ ...styles.subtitle, marginBottom: 24 }}>{t("login.passwordUpdated").split("\n").map((line, i) => <span key={i}>{line}{i === 0 && <br />}</span>)}</p>
              <button onClick={resetForgot} style={styles.loginBtn}>{t("login.backToLoginBtn")}</button>
            </div>
          )}
        </div>
      </main>

      <footer style={styles.footer} className="login-footer">
        <div style={styles.footerLeft}>
          <span style={styles.footerBrand}>Fahamni</span>
          <span style={styles.footerCopy}>{t("login.copyright")}</span>
        </div>
        <div style={styles.footerRight}>
          <a href="#" style={styles.footerLink}>{t("login.privacyPolicy")}</a>
          <a href="#" style={styles.footerLink}>{t("login.termsOfService")}</a>
        </div>
      </footer>
    </div>
  );
}

function ErrBox({ msg }) {
  return (
    <div style={styles.errorBox}>
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#dc2626" strokeWidth="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
      {msg}
    </div>
  );
}

const styles = {
  page: { height: "100vh", background: "#FAFAFA", display: "flex", flexDirection: "column", fontFamily: "system-ui, 'Segoe UI', Roboto, sans-serif", overflow: "hidden" },
  navbar: { padding: "20px 32px", display: "flex", alignItems: "center", flexShrink: 0 },
  navBrand: { color: "#000080", fontFamily: "'Inter', system-ui, sans-serif", fontSize: 24, fontStyle: "normal", fontWeight: 900, lineHeight: "32px", letterSpacing: "-1.2px" },
  main: { flex: 1, display: "flex", alignItems: "center", justifyContent: "center", padding: "12px 16px 88px", overflow: "visible" },
  card: { background: "#fff", borderRadius: 28, width: "100%", maxWidth: 420, padding: "28px clamp(18px, 6vw, 36px)", boxShadow: "0 4px 32px rgba(0,0,80,0.08)", border: "1px solid rgba(0,0,128,0.06)", boxSizing: "border-box", position: "relative", zIndex: 20 },
  logoWrap: { display: "flex", justifyContent: "center", marginBottom: 8 },
  title: { color: "#1F2937", textAlign: "center", fontFamily: "'Inter', system-ui, sans-serif", fontSize: 30, fontWeight: 700, lineHeight: "36px", letterSpacing: "-0.75px", margin: "0 0 4px" },
  subtitle: { color: "#464653", textAlign: "center", fontFamily: "'Plus Jakarta Sans', system-ui, sans-serif", fontSize: 16, fontWeight: 400, lineHeight: "24px", margin: "0 0 20px" },
  form: { display: "flex", flexDirection: "column" },
  fieldGroup: { marginBottom: 10 },
  label: { display: "block", color: "#1F2937", fontFamily: "'Plus Jakarta Sans', system-ui, sans-serif", fontSize: 14, fontWeight: 600, lineHeight: "20px", marginBottom: 5 },
  inputWrap: { position: "relative", display: "flex", alignItems: "center" },
  icon: { position: "absolute", left: 13, display: "flex", alignItems: "center", pointerEvents: "none" },
  input: { width: "100%", height: 40, paddingLeft: 38, paddingRight: 38, border: "1.5px solid #c7d2fe", borderRadius: 8, background: "#fff", color: "#64748B", fontFamily: "'Plus Jakarta Sans', system-ui, sans-serif", fontSize: 16, fontWeight: 400, outline: "none", boxSizing: "border-box", transition: "border-color 0.2s, box-shadow 0.2s" },
  eyeBtn: { position: "absolute", right: 13, background: "none", border: "none", cursor: "pointer", display: "flex", alignItems: "center", padding: 0 },
  rememberRow: { display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 14, marginTop: 2 },
  rememberLabel: { display: "flex", alignItems: "center", gap: 6, fontSize: 12, color: "#374151", cursor: "pointer", userSelect: "none" },
  checkbox: { width: 16, height: 16, borderRadius: 6, border: "1.5px solid #c7d2fe", display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", flexShrink: 0, transition: "background 0.15s, border-color 0.15s" },
  forgotBtn: { background: "none", border: "none", padding: 0, fontSize: 12, color: "#000080", fontWeight: 500, cursor: "pointer", fontFamily: "inherit" },
  backLink: { background: "none", border: "none", padding: "0 0 12px", fontSize: 13, color: "#64748b", fontWeight: 500, cursor: "pointer", fontFamily: "inherit", display: "block" },
  errorBox: { display: "flex", alignItems: "center", gap: 8, background: "#fef2f2", border: "1px solid #fecaca", borderRadius: 8, padding: "9px 13px", fontSize: 13, color: "#dc2626", marginBottom: 12 },
  loginBtn: { width: "100%", height: 42, background: "#000080", color: "#fff", border: "none", borderRadius: 21, fontSize: 14, fontWeight: 600, cursor: "pointer", letterSpacing: "0.2px", transition: "opacity 0.2s", fontFamily: "inherit" },
  otpRow: { display: "flex", gap: 8, justifyContent: "center", margin: "0 0 16px" },
  otpBox: { width: 44, height: 52, textAlign: "center", fontSize: 22, fontWeight: 700, border: "1.5px solid #c7d2fe", borderRadius: 10, outline: "none", color: "#1F2937", fontFamily: "inherit", background: "#fafbff" },
  stepRow: { display: "flex", gap: 6, justifyContent: "center", marginBottom: 20 },
  stepDot: { height: 6, width: 6, borderRadius: 3, background: "#e2e8f0", transition: "all 0.2s" },
  stepDotActive: { width: 22, background: "#000080", borderRadius: 3 },
  stepIconWrap: { width: 60, height: 60, borderRadius: "50%", background: "#f0f4ff", border: "2px solid #c7d2fe", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 16px" },
  inlineLink: { background: "none", border: "none", padding: 0, fontSize: 13, color: "#000080", fontWeight: 600, cursor: "pointer", fontFamily: "inherit", textDecoration: "underline" },
  cardFooter: { marginTop: 16, textAlign: "center" },
  divider: { border: "none", borderTop: "1px solid #e2e8f0", margin: "0 0 8px" },
  secureText: { fontSize: 11, color: "#94a3b8", margin: "0 0 3px" },
  ipText: { fontSize: 11, color: "#94a3b8", margin: 0 },
  authBadge: { color: "#000080", fontWeight: 500 },
  footer: { position: "fixed", bottom: 0, left: 0, right: 0, display: "flex", alignItems: "center", justifyContent: "space-between", padding: "18px 32px", flexWrap: "wrap", gap: 12, background: "#FAFAFA", zIndex: 10 },
  footerLeft: { display: "flex", flexDirection: "column", gap: 2 },
  footerBrand: { fontSize: 14, fontWeight: 700, color: "#000080" },
  footerCopy: { fontSize: 11, color: "#94a3b8" },
  footerRight: { display: "flex", gap: 20 },
  footerLink: { fontSize: 12, color: "#64748b", textDecoration: "none" },
};
