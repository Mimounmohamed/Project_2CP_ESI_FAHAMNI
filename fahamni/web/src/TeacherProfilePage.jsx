import { useState, useEffect } from "react";
import { doc, updateDoc, collection, query, where, getDocs, addDoc, serverTimestamp, getDoc } from "firebase/firestore";
import { ref as storageRef, listAll, getDownloadURL } from "firebase/storage";
import { db, storage } from "./firebase";

const REJECTION_CAUSES = [
  "Invalid or fake identity documents",
  "Name mismatch between profile and documents",
  "Unclear / unreadable uploaded files",
  "Qualifications not relevant to the subject taught",
  "Insufficient academic level",
];

const MONTHS = ["January","February","March","April","May","June",
                 "July","August","September","October","November","December"];

function formatBirthday(val) {
  if (!val) return "—";
  const d = val.toDate ? val.toDate() : new Date(val);
  if (isNaN(d)) return "—";
  return `${MONTHS[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}`;
}

function capitalize(str) {
  if (!str) return "—";
  return str.charAt(0).toUpperCase() + str.slice(1);
}

function formatLevel(levels) {
  if (!levels?.length) return "—";
  return levels.map(l => l.replace(/_/g, " ").replace(/\b\w/g, c => c.toUpperCase())).join(", ");
}

function fileNameFromUrl(url) {
  if (!url) return "Certificate";
  try {
    const path = decodeURIComponent(new URL(url).pathname);
    return path.split("/").pop()?.split("?")[0] || "Certificate";
  } catch {
    return url.split("/").pop()?.split("?")[0] || "Certificate";
  }
}

function certificateUrl(cert) {
  return cert.url || cert.file_url || cert.media_url || cert.link_url || cert.download_url || cert.certification_url || "";
}

function downloadUrl(url, title = "certificate") {
  if (!url) return "";
  try {
    const next = new URL(url);
    next.searchParams.set("response-content-disposition", `attachment; filename="${title}"`);
    return next.toString();
  } catch {
    return url;
  }
}

async function listStorageCertificates(path) {
  const list = await listAll(storageRef(storage, path));
  const files = await Promise.all(list.items.map(async item => ({
    id: item.fullPath,
    title: item.name,
    url: await getDownloadURL(item),
    fullPath: item.fullPath,
  })));
  const nested = await Promise.all(list.prefixes.map(prefix => listStorageCertificates(prefix.fullPath)));
  return files.concat(...nested);
}

export default function TeacherProfilePage({ teacher: initial, adminUser, onBack, onStatusChange }) {
  const [teacher, setTeacher] = useState(initial);
  const [certified, setCertified] = useState(initial.certified ?? false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [certificates, setCertificates] = useState([]);
  const [showRejectModal, setShowRejectModal] = useState(false);
  const [selectedCause, setSelectedCause] = useState(null);
  const teacherUid = teacher.uid || teacher.id || initial.uid || initial.id;

  useEffect(() => {
    if (!teacherUid) return;
    let cancelled = false;

    async function loadCertificates() {
      const seen = new Set();
      const next = [];
      const addCert = (cert) => {
        const url = certificateUrl(cert);
        const key = url || cert.fullPath || cert.id || cert.title;
        if (!key || seen.has(key)) return;
        seen.add(key);
        next.push(cert);
      };

      if (teacher.certification_url) {
        addCert({
          id: "certification_url",
          title: fileNameFromUrl(teacher.certification_url),
          url: teacher.certification_url,
        });
      }

      const extraUrls = teacher.certification_urls || teacher.certificationUrls || [];
      if (Array.isArray(extraUrls)) {
        extraUrls.forEach((url, index) => addCert({
          id: `certification_url_${index}`,
          title: fileNameFromUrl(url),
          url,
        }));
      }

      try {
        const snap = await getDocs(query(collection(db, "resources"), where("tutor_id", "==", teacherUid)));
        snap.docs.forEach(d => addCert({ id: d.id, ...d.data() }));
      } catch (e) {
        console.error("Certificate resources load failed:", e);
      }

      try {
        const storageCerts = await listStorageCertificates(`tutor_certifications/${teacherUid}`);
        storageCerts.forEach(addCert);
      } catch (e) {
        console.error("Storage certificates load failed:", e);
      }

      if (!cancelled) setCertificates(next);
    }

    loadCertificates();
    return () => { cancelled = true; };
  }, [teacherUid, teacher.certification_url]);

  async function updateAccountStatus(status) {
    const updates = { account_status: status };
    await updateDoc(doc(db, "tutors", teacher.id), updates);

    if (teacherUid) {
      const userRef = doc(db, "users", teacherUid);
      const userSnap = await getDoc(userRef);
      if (userSnap.exists()) await updateDoc(userRef, updates);
    }

    // create a notification document for the teacher about this status change
    try {
      const notifTitle = updates.account_status === "validated" ? "Account Approved" : "Account Rejected";
      const notifContent = updates.account_status === "validated"
        ? "Congratulations! Your account has been verified by admin. You now have full access to all features."
        : "Your account review was updated by admin. Please check your profile for details.";
      await addDoc(collection(db, "notifications"), {
        title: notifTitle,
        content: notifContent,
        date_time: serverTimestamp(),
        receiver_id: teacherUid || null,
        sender_id: adminUser?.uid ?? 'admin',
        type: updates.account_status === "validated" ? "teacher_approved" : "teacher_rejected",
        metadata: {},
        is_read: false,
      });
    } catch (e) {
      console.error("Failed to write approval notification:", e);
    }
  }

  async function handleStatus(status) {
    setSaving(true);
    setError(null);
    try {
      await updateAccountStatus(status);
      onStatusChange?.(teacher.id, status);
      onBack();
    } catch (e) {
      console.error(e);
      setError("Failed to update status. Check Firestore rules.");
    } finally {
      setSaving(false);
    }
  }

  async function handleConfirmReject() {
    if (!selectedCause) return;
    setSaving(true);
    setError(null);
    try {
      await Promise.all([
        updateAccountStatus("rejected"),
        addDoc(collection(db, "rejections"), {
          teacher_id: teacher.id,
          admin_id: adminUser?.uid ?? null,
          cause: selectedCause,
          rejected_at: serverTimestamp(),
        }),
      ]);
      // ensure teacher gets a rejection notification with cause (in case updateAccountStatus didn't run notification yet)
      try {
        await addDoc(collection(db, "notifications"), {
          title: "Account Rejected",
          content: `Your account review was rejected: ${selectedCause}`,
          date_time: serverTimestamp(),
          receiver_id: teacherUid || null,
          sender_id: adminUser?.uid ?? 'admin',
          type: "teacher_rejected",
          metadata: { cause: selectedCause },
          is_read: false,
        });
      } catch (e) {
        console.error("Failed to write rejection notification:", e);
      }
      onStatusChange?.(teacher.id, "rejected");
      setShowRejectModal(false);
      onBack();
    } catch (e) {
      console.error(e);
      setError("Failed to reject. Check Firestore rules.");
    } finally {
      setSaving(false);
    }
  }

  async function toggleCertified() {
    const next = !certified;
    setCertified(next);
    await updateDoc(doc(db, "tutors", teacher.id), { certified: next }).catch(console.error);
  }

  const fullName = `${teacher.first_name ?? ""} ${teacher.last_name ?? ""}`.trim();

  return (
    <div style={s.page}>

      {/* Breadcrumb + title */}
      <div style={s.breadcrumb}>
        <span style={s.breadLink}>Teachers</span>
        <span style={s.breadSep}>›</span>
        <span style={s.breadCurrent}>Teacher Profile</span>
      </div>
      <h1 style={s.pageTitle}>Teacher Profile</h1>

      {/* Body */}
      <div style={s.body}>

        {/* ── Left card ── */}
        <div style={s.leftCard}>
          {teacher.picture
            ? <img src={teacher.picture} alt="avatar" style={s.bigAvatar} />
            : <div style={s.bigAvatarFallback}>
                <svg width="44" height="44" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="1.4">
                  <circle cx="12" cy="8" r="4" /><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" />
                </svg>
              </div>
          }
          <div style={{ display: "flex", alignItems: "center", gap: 7, marginBottom: 8 }}>
            <div style={s.teacherName}>{fullName}</div>
            {certified && <VerifiedBadge size={18} />}
          </div>
          <span style={s.teacherBadge}>Teacher</span>

          <div style={s.contactRow}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="2">
              <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
              <polyline points="22,6 12,13 2,6"/>
            </svg>
            <div>
              <div style={s.contactLabel}>Email Address</div>
              <div style={s.contactValue}>{teacher.email || "—"}</div>
            </div>
          </div>

          <div style={s.contactRow}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="2">
              <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12 19.79 19.79 0 0 1 1.61 3.38 2 2 0 0 1 3.58 1.18h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 8.73a16 16 0 0 0 6 6l.92-.92a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 21.73 16l.19.92z"/>
            </svg>
            <div>
              <div style={s.contactLabel}>Phone Number</div>
              <div style={s.contactValue}>{teacher.phone || "—"}</div>
            </div>
          </div>

          <div style={s.descSection}>
            <div style={s.descTitle}>Personal Description</div>
            <div style={s.descText}>{teacher.pedagogical_description || "—"}</div>
          </div>
        </div>

        {/* ── Middle ── */}
        <div style={{ display: "flex", flexDirection: "column", flex: 1, gap: 16, minWidth: 0 }}>

          {/* Detailed info card */}
          <div style={s.infoCard}>
            <div style={s.infoHeader}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="#6366f1" stroke="none">
                <circle cx="12" cy="12" r="10"/><text x="12" y="17" textAnchor="middle" fill="#fff" fontSize="13" fontWeight="bold">i</text>
              </svg>
              <span style={s.infoTitle}>Detailed Information</span>
            </div>
            <div style={s.infoGrid}>
              <div style={s.infoField}>
                <div style={s.fieldLabel}>Full Name</div>
                <div style={s.fieldValue}>{fullName || "—"}</div>
              </div>
              <div style={s.infoField}>
                <div style={s.fieldLabel}>Gender</div>
                <div style={s.fieldValue}>{capitalize(teacher.gender)}</div>
              </div>
              <div style={s.infoField}>
                <div style={s.fieldLabel}>Level</div>
                <div style={s.fieldValue}>{formatLevel(teacher.levels_taught)}</div>
              </div>
              <div style={s.infoField}>
                <div style={s.fieldLabel}>Expertise Domain</div>
                <div style={s.fieldValue}>{teacher.expertise_domain || "—"}</div>
              </div>
              <div style={s.infoField}>
                <div style={s.fieldLabel}>Birthday Date</div>
                <div style={s.fieldValue}>{formatBirthday(teacher.birthday)}</div>
              </div>
              <div style={s.infoField}>
                <div style={s.fieldLabel}>Experience</div>
                <div style={s.fieldValue}>{teacher.years_of_experience != null ? `${teacher.years_of_experience} years` : "—"}</div>
              </div>
              <div style={{ ...s.infoField, gridColumn: "1 / -1" }}>
                <div style={s.fieldLabel}>Academic Description</div>
                <div style={s.fieldValue}>{teacher.academic_description || "—"}</div>
              </div>
            </div>
          </div>

          {/* Certificates */}
          <div style={s.certSection}>
            <div style={s.certTitle}>Teacher Certificates</div>
            <div style={s.certList}>
              {certificates.length === 0 ? (
                <div style={{ fontSize: 13, color: "#94a3b8" }}>No certificates uploaded.</div>
              ) : certificates.map(c => {
                const url = certificateUrl(c);
                const title = c.title || c.name || fileNameFromUrl(url) || "Certificate";
                const CardTag = url ? "a" : "div";
                return (
                <CardTag
                  key={c.id}
                  href={url ? downloadUrl(url, title) : undefined}
                  download={url ? title : undefined}
                  target={url ? "_blank" : undefined}
                  rel={url ? "noopener noreferrer" : undefined}
                  style={s.certCard}
                >
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#6366f1" strokeWidth="1.8">
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                    <polyline points="14 2 14 8 20 8"/>
                  </svg>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 12, fontWeight: 600, color: "#1F2937", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                      {title}
                    </div>
                  </div>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="2">
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                    <polyline points="7 10 12 15 17 10"/>
                    <line x1="12" y1="15" x2="12" y2="3"/>
                  </svg>
                </CardTag>
                );
              })}
            </div>
          </div>

          <div style={s.certSection}>
            <div style={s.certTitle}>Uploaded Certification</div>
            {teacher.certification_url ? (
              <a
                href={teacher.certification_url}
                target="_blank"
                rel="noopener noreferrer"
                style={s.certLink}
              >
                View uploaded certification document
              </a>
            ) : (
              <div style={{ fontSize: 13, color: "#94a3b8" }}>
                No certification uploaded.
              </div>
            )}
          </div>
        </div>

        {/* ── Right actions ── */}
        <div style={s.actions}>
          <label style={s.certifiedRow}>
            <div
              style={{ ...s.certCircle, ...(certified ? s.certCircleOn : {}) }}
              onClick={toggleCertified}
            >
              {certified && <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="3"><path d="M20 6L9 17l-5-5"/></svg>}
            </div>
            <span style={{ fontSize: 13, color: "#1F2937", cursor: "pointer" }} onClick={toggleCertified}>
              Make as Certified
            </span>
          </label>

          {error && <div style={{ fontSize: 11, color: "#ef4444", textAlign: "center" }}>{error}</div>}

          {teacher.account_status !== "validated" && (
            <button
              style={{ ...s.actionBtn, background: "#22c55e", opacity: saving ? 0.6 : 1 }}
              disabled={saving}
              onClick={() => handleStatus("validated")}
            >
              {saving ? "Saving…" : "Validate"}
            </button>
          )}
          {teacher.account_status !== "rejected" && (
            <button
              style={{ ...s.actionBtn, background: "#ef4444", opacity: saving ? 0.6 : 1 }}
              disabled={saving}
              onClick={() => { setSelectedCause(null); setShowRejectModal(true); }}
            >
              Reject
            </button>
          )}
        </div>

      </div>

      {showRejectModal && (
        <div style={s.overlay}>
          <div style={s.modal}>
            <div style={s.modalHeader}>
              <span style={s.modalTitle}>Rejection Cause</span>
              <button style={s.closeBtn} onClick={() => setShowRejectModal(false)}>✕</button>
            </div>
            <p style={s.modalSub}>Choose the main cause of rejection</p>
            <div style={s.causeList}>
              {REJECTION_CAUSES.map(cause => (
                <div
                  key={cause}
                  style={{ ...s.causeRow, ...(selectedCause === cause ? s.causeRowSelected : {}) }}
                  onClick={() => setSelectedCause(cause)}
                >
                  <span style={s.causeLabel}>{cause}</span>
                  <div style={{ ...s.radio, ...(selectedCause === cause ? s.radioSelected : {}) }} />
                </div>
              ))}
            </div>
            {error && <div style={{ fontSize: 11, color: "#ef4444", marginTop: 8 }}>{error}</div>}
            <button
              style={{ ...s.actionBtn, background: "#ef4444", marginTop: 20, opacity: (!selectedCause || saving) ? 0.5 : 1 }}
              disabled={!selectedCause || saving}
              onClick={handleConfirmReject}
            >
              {saving ? "Saving…" : "Reject"}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

function VerifiedBadge({ size = 16 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" title="Certified">
      <path
        d="M12 1.5L14.74 4.01L18.27 3.27L18.96 6.82L22.05 8.5L20.5 12L22.05 15.5L18.96 17.18L18.27 20.73L14.74 19.99L12 22.5L9.26 19.99L5.73 20.73L5.04 17.18L1.95 15.5L3.5 12L1.95 8.5L5.04 6.82L5.73 3.27L9.26 4.01Z"
        fill="#2196f3"
      />
      <path
        d="M8 12.5L10.5 15L16 9"
        stroke="#fff"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

const s = {
  page: { display: "flex", flexDirection: "column", height: "100%", minHeight: 0 },
  breadcrumb: { display: "flex", alignItems: "center", gap: 6, marginBottom: 6 },
  breadLink: { fontSize: 12, color: "#94a3b8", cursor: "pointer" },
  breadSep: { fontSize: 12, color: "#cbd5e1" },
  breadCurrent: { fontSize: 12, color: "#000080", fontWeight: 600 },
  pageTitle: { fontSize: 24, fontWeight: 700, color: "#1F2937", margin: "0 0 20px" },
  body: { display: "flex", gap: 20, flex: 1, minHeight: 0, alignItems: "flex-start" },

  /* left card */
  leftCard: {
    width: 240, flexShrink: 0,
    background: "#fff", borderRadius: 16, border: "1px solid #f1f5f9",
    padding: "24px 20px", display: "flex", flexDirection: "column", alignItems: "center",
    boxShadow: "0 2px 8px rgba(0,0,0,0.04)",
  },
  bigAvatar: { width: 80, height: 80, borderRadius: "50%", objectFit: "cover", marginBottom: 14 },
  bigAvatarFallback: {
    width: 80, height: 80, borderRadius: "50%", background: "#000080",
    display: "flex", alignItems: "center", justifyContent: "center", marginBottom: 14,
  },
  teacherName: { fontSize: 15, fontWeight: 700, color: "#1F2937", textAlign: "center" },
  teacherBadge: {
    fontSize: 11, fontWeight: 600, color: "#6366f1", background: "#eef2ff",
    borderRadius: 20, padding: "3px 12px", marginBottom: 20,
  },
  contactRow: {
    display: "flex", alignItems: "flex-start", gap: 10, width: "100%", marginBottom: 14,
  },
  contactLabel: { fontSize: 10, color: "#94a3b8", textTransform: "uppercase", letterSpacing: "0.04em", marginBottom: 2 },
  contactValue: { fontSize: 12, fontWeight: 600, color: "#1F2937" },
  descSection: { width: "100%", marginTop: 6 },
  descTitle: { fontSize: 12, fontWeight: 700, color: "#1F2937", marginBottom: 6 },
  descText: { fontSize: 12, color: "#64748b", lineHeight: 1.6 },

  /* info card */
  infoCard: {
    background: "#fff", borderRadius: 16, border: "1px solid #f1f5f9",
    padding: "20px 24px", boxShadow: "0 2px 8px rgba(0,0,0,0.04)",
  },
  infoHeader: { display: "flex", alignItems: "center", gap: 8, marginBottom: 18 },
  infoTitle: { fontSize: 15, fontWeight: 700, color: "#1F2937" },
  infoGrid: { display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px 32px" },
  infoField: {},
  fieldLabel: { fontSize: 10, color: "#94a3b8", textTransform: "uppercase", letterSpacing: "0.05em", marginBottom: 4 },
  fieldValue: { fontSize: 13, fontWeight: 600, color: "#1F2937" },

  /* certificates */
  certSection: {
    background: "#fff", borderRadius: 16, border: "1px solid #f1f5f9",
    padding: "16px 20px", boxShadow: "0 2px 8px rgba(0,0,0,0.04)",
  },
  certTitle: { fontSize: 14, fontWeight: 700, color: "#1F2937", marginBottom: 12 },
  certLink: { display: "inline-block", color: "#2563eb", textDecoration: "none", fontSize: 13, fontWeight: 600 },
  certList: { display: "flex", gap: 10, flexWrap: "wrap" },
  certCard: {
    display: "flex", alignItems: "center", gap: 8, padding: "10px 14px",
    background: "#f8fafc", borderRadius: 10, border: "1px solid #e2e8f0", width: 160,
    textDecoration: "none",
  },

  /* actions */
  actions: { display: "flex", flexDirection: "column", gap: 12, paddingTop: 4, flexShrink: 0, width: 140 },
  certifiedRow: { display: "flex", alignItems: "center", gap: 8, cursor: "pointer" },
  certCircle: {
    width: 18, height: 18, borderRadius: "50%", border: "2px solid #cbd5e1",
    display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", flexShrink: 0,
  },
  certCircleOn: { background: "#000080", borderColor: "#000080" },
  actionBtn: {
    width: "100%", padding: "10px 0", borderRadius: 10, border: "none",
    color: "#fff", fontSize: 14, fontWeight: 700, cursor: "pointer",
  },

  /* rejection modal */
  overlay: {
    position: "fixed", inset: 0, background: "rgba(0,0,0,0.45)",
    display: "flex", alignItems: "center", justifyContent: "center", zIndex: 1000,
  },
  modal: {
    background: "#fff", borderRadius: 16, padding: "28px 28px 24px",
    width: 480, maxWidth: "90vw", boxShadow: "0 8px 32px rgba(0,0,0,0.18)",
  },
  modalHeader: { display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 6 },
  modalTitle: { fontSize: 18, fontWeight: 700, color: "#1F2937" },
  closeBtn: {
    background: "none", border: "none", fontSize: 16, cursor: "pointer", color: "#94a3b8", lineHeight: 1,
  },
  modalSub: { fontSize: 13, color: "#64748b", margin: "0 0 16px" },
  causeList: { display: "flex", flexDirection: "column", gap: 10 },
  causeRow: {
    display: "flex", alignItems: "center", justifyContent: "space-between",
    padding: "12px 14px", borderRadius: 8, border: "1px solid #e2e8f0",
    cursor: "pointer", background: "#fff", transition: "border-color 0.15s",
  },
  causeRowSelected: { borderColor: "#000080" },
  causeLabel: { fontSize: 13, color: "#1F2937" },
  radio: {
    width: 18, height: 18, borderRadius: "50%", border: "2px solid #cbd5e1",
    flexShrink: 0, boxSizing: "border-box",
    display: "flex", alignItems: "center", justifyContent: "center",
  },
  radioSelected: { border: "5px solid #000080" },
};
