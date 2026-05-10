import { useState, useEffect } from "react";
import { User, Mail, Phone, FileText, Download, Check, Info, Eye, X } from "lucide-react";
import { doc, updateDoc, collection, query, where, getDocs, addDoc, serverTimestamp, getDoc } from "firebase/firestore";
import { ref as storageRef, listAll, getDownloadURL } from "firebase/storage";
import { db, storage } from "./firebase";

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

async function handleDownload(url, title = "certificate") {
  if (!url) return;
  try {
    const res = await fetch(url);
    const blob = await res.blob();
    const objUrl = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = objUrl;
    a.download = title;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(objUrl);
  } catch {
    window.open(url, "_blank");
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

const REJECTION_CAUSES = [
  "Incomplete or missing credentials",
  "Unverifiable identity documents",
  "Insufficient teaching qualifications",
  "Duplicate or fraudulent account",
  "Does not meet platform requirements",
];

export default function TeacherProfilePage({ teacher: initial, adminUser, onBack, onStatusChange }) {
  const [teacher, setTeacher] = useState(initial);
  const [certified, setCertified] = useState(initial.certified ?? false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [certificates, setCertificates] = useState([]);
  const [quotes, setQuotes] = useState(null);
  const [selectedQuote, setSelectedQuote] = useState(null);
  const [showRejectModal, setShowRejectModal] = useState(false);
  const [selectedCause, setSelectedCause] = useState(REJECTION_CAUSES[0]);
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

  useEffect(() => {
    if (!teacherUid) return;
    let cancelled = false;
    async function loadQuotes() {
      try {
        const [quotesSnap, requestsSnap, estimatesSnap] = await Promise.all([
          getDocs(query(collection(db, "quotes"),         where("tutor_id",   "==", teacherUid))),
          getDocs(query(collection(db, "quote_requests"), where("tutor_id",   "==", teacherUid))),
          getDocs(query(collection(db, "estimates"),      where("sender_uid", "==", teacherUid))),
        ]);

        // quote_requests covered by an estimate (matched by quote_id field on estimate)
        const coveredByEstimate = new Set(
          estimatesSnap.docs.map(d => d.data().quote_id).filter(Boolean)
        );

        const docsMap = new Map();

        // 1. Estimates win — include all of them
        estimatesSnap.docs.forEach(d => {
          const data = { id: d.id, _source: "estimates", ...d.data() };
          if (!data.quote_number && data.invoice_number) data.quote_number = data.invoice_number;
          if (!data.client_name  && data.student_name)   data.client_name  = data.student_name;
          if (!data.status) data.status = "sent";
          docsMap.set(`estimates:${d.id}`, data);
        });

        // 2. quote_requests not covered by an estimate
        requestsSnap.docs.forEach(d => {
          if (coveredByEstimate.has(d.id)) return;
          const data = { id: d.id, _source: "quote_requests", ...d.data() };
          if (!data.status) data.status = "pending";
          docsMap.set(`quote_requests:${d.id}`, data);
        });

        // 3. quotes: suppress those whose student|tutor|service key already exists
        const existingKeys = new Set(
          [...docsMap.values()]
            .map(d => {
              const sid = d.student_id || "";
              const tid = d.tutor_id || d.sender_uid || "";
              const svc = d.service_id || "";
              return sid && tid ? `${sid}|${tid}|${svc}` : null;
            })
            .filter(Boolean)
        );

        quotesSnap.docs.forEach(d => {
          const raw = d.data();
          const k = raw.student_id && raw.tutor_id
            ? `${raw.student_id}|${raw.tutor_id}|${raw.service_id || ""}`
            : null;
          if (k && existingKeys.has(k)) return;
          const data = { id: d.id, _source: "quotes", ...raw };
          if (!data.status) data.status = "pending";
          docsMap.set(`quotes:${d.id}`, data);
        });

        const merged = [...docsMap.values()].sort((a, b) => {
          const aT = a.sent_at?.toDate?.() ?? a.created_at?.toDate?.() ?? (a.created_at ? new Date(a.created_at) : null);
          const bT = b.sent_at?.toDate?.() ?? b.created_at?.toDate?.() ?? (b.created_at ? new Date(b.created_at) : null);
          if (!aT && !bT) return 0;
          if (!aT) return 1;
          if (!bT) return -1;
          return bT - aT;
        });

        if (!cancelled) setQuotes(merged);
      } catch (e) {
        console.error("Failed to load quotes:", e);
        if (!cancelled) setQuotes([]);
      }
    }
    loadQuotes();
    return () => { cancelled = true; };
  }, [teacherUid]);

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
    setSaving(true);
    setError(null);
    try {
      await updateDoc(doc(db, "tutors", teacher.id), { account_status: "rejected" });
      try {
        await addDoc(collection(db, "notifications"), {
          title: "Account Rejected",
          content: `Your account application was not approved. Reason: ${selectedCause}`,
          date_time: serverTimestamp(),
          receiver_id: teacherUid || null,
          sender_id: adminUser?.uid ?? "admin",
          type: "teacher_rejected",
          metadata: { cause: selectedCause },
          is_read: false,
        });
        await addDoc(collection(db, "rejections"), {
          tutor_id: teacherUid,
          cause: selectedCause,
          rejected_at: serverTimestamp(),
          admin_id: adminUser?.uid ?? "admin",
        });
      } catch (e) {
        console.error("Failed to write rejection records:", e);
      }
      onStatusChange?.(teacher.id, "rejected");
      onBack();
    } catch (e) {
      console.error(e);
      setError("Failed to reject. Check Firestore rules.");
    } finally {
      setSaving(false);
      setShowRejectModal(false);
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
                <User size={44} color="#fff" strokeWidth={1.4} />
              </div>
          }
          <div style={{ display: "flex", alignItems: "center", gap: 7, marginBottom: 8 }}>
            <div style={s.teacherName}>{fullName}</div>
            {certified && <VerifiedBadge size={18} />}
          </div>
          <span style={s.teacherBadge}>Teacher</span>

          <div style={s.contactRow}>
            <Mail size={14} color="#94a3b8" strokeWidth={2} />
            <div>
              <div style={s.contactLabel}>Email Address</div>
              <div style={s.contactValue}>{teacher.email || "—"}</div>
            </div>
          </div>

          <div style={s.contactRow}>
            <Phone size={14} color="#94a3b8" strokeWidth={2} />
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
              <Info size={16} color="#6366f1" />
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
                return (
                <div
                  key={c.id}
                  onClick={() => url && handleDownload(url, title)}
                  style={{ ...s.certCard, cursor: url ? "pointer" : "default" }}
                >
                  <FileText size={20} color="#6366f1" strokeWidth={1.8} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 12, fontWeight: 600, color: "#1F2937", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                      {title}
                    </div>
                  </div>
                  <Download size={14} color="#94a3b8" strokeWidth={2} />
                </div>
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

          {/* Quotes & Invoices */}
          <div style={s.certSection}>
            <div style={s.certTitle}>Quotes &amp; Invoices</div>
            {quotes === null ? (
              <div style={{ fontSize: 13, color: "#94a3b8" }}>Loading…</div>
            ) : quotes.length === 0 ? (
              <div style={{ fontSize: 13, color: "#94a3b8" }}>No quotes issued yet.</div>
            ) : (
              <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
                {quotes.map(q => <QuoteRow key={`${q._source}:${q.id}`} quote={q} onView={() => setSelectedQuote(q)} />)}
              </div>
            )}
          </div>
        </div>

        {/* ── Right actions ── */}
        <div style={s.actions}>
          {teacher.account_status === "validated" ? (
            <label style={s.certifiedRow}>
              <div
                style={{ ...s.certCircle, ...(certified ? s.certCircleOn : {}) }}
                onClick={toggleCertified}
              >
                {certified && <Check size={10} color="#fff" strokeWidth={3} />}
              </div>
              <span style={{ fontSize: 13, color: "#1F2937", cursor: "pointer" }} onClick={toggleCertified}>
                Make as Certified
              </span>
            </label>
          ) : (
            <div style={{ ...s.certifiedRow, opacity: 0.4, cursor: "not-allowed" }}>
              <div style={s.certCircle} />
              <span style={{ fontSize: 13, color: "#94a3b8" }}>Make as Certified</span>
            </div>
          )}

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

          {teacher.account_status === "pending" && (
            <button
              style={{ ...s.actionBtn, background: "#ef4444", opacity: saving ? 0.6 : 1 }}
              disabled={saving}
              onClick={() => setShowRejectModal(true)}
            >
              Reject
            </button>
          )}
        </div>

      </div>

      {/* ── Quote detail modal ── */}
      {selectedQuote && (() => {
        const isInvoice = selectedQuote._source === "estimates";
        const rawDate   = isInvoice ? (selectedQuote.sent_at || selectedQuote.created_at) : selectedQuote.created_at;
        const modalDate = rawDate?.toDate
          ? rawDate.toDate().toLocaleDateString("en-GB")
          : (rawDate ? new Date(rawDate).toLocaleDateString("en-GB") : "—");
        const st = (selectedQuote.status || "draft").toLowerCase();
        const SC = { pending:{bg:"#fef9c3",color:"#854d0e"}, sent:{bg:"#dbeafe",color:"#1d4ed8"}, accepted:{bg:"#dcfce7",color:"#166534"}, rejected:{bg:"#fee2e2",color:"#991b1b"}, paid:{bg:"#d1fae5",color:"#065f46"}, expired:{bg:"#f1f5f9",color:"#64748b"}, draft:{bg:"#f1f5f9",color:"#64748b"} };
        const sc = SC[st] ?? SC.draft;
        const fields = [
          ["Student",            selectedQuote.client_name || selectedQuote.student_name || "—"],
          ...(isInvoice && selectedQuote.student_email ? [["Student Email", selectedQuote.student_email]] : []),
          ["Teacher",            selectedQuote.teacher_name || "—"],
          ...(isInvoice && selectedQuote.teacher_email ? [["Teacher Email", selectedQuote.teacher_email]] : []),
          ["Subject",            selectedQuote.subject || "—"],
          ["Sessions",           selectedQuote.sessions_count != null ? `${selectedQuote.sessions_count} session(s)` : "—"],
          ["Duration / Session", selectedQuote.session_duration || "—"],
          ["Price / Session",    selectedQuote.price_per_session != null ? `${Number(selectedQuote.price_per_session).toLocaleString()} DA` : "—"],
          ["Total",              selectedQuote.total != null ? `${Number(selectedQuote.total).toLocaleString()} DA` : "—"],
          ["Teaching Mode",      selectedQuote.teaching_mode || selectedQuote.teachingMode || "—"],
        ];
        return (
          <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.45)", zIndex:1000, display:"flex", alignItems:"center", justifyContent:"center" }}
               onClick={() => setSelectedQuote(null)}>
            <div style={{ background:"#fff", borderRadius:16, padding:28, width:500, maxWidth:"92vw", maxHeight:"85vh", overflowY:"auto", boxShadow:"0 20px 60px rgba(0,0,0,0.2)" }}
                 onClick={e => e.stopPropagation()}>
              {/* header */}
              <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", marginBottom:20 }}>
                <div>
                  <div style={{ display:"flex", alignItems:"center", gap:8 }}>
                    <div style={{ fontSize:16, fontWeight:800, color:"#1F2937" }}>
                      {selectedQuote.quote_number || selectedQuote.reference || (isInvoice ? "Invoice" : "Estimate")}
                    </div>
                    {isInvoice && <span style={{ fontSize:10, fontWeight:700, background:"#dcfce7", color:"#166534", borderRadius:4, padding:"2px 7px", letterSpacing:"0.04em" }}>INVOICE</span>}
                  </div>
                  <div style={{ fontSize:11, color:"#94a3b8", marginTop:2 }}>{modalDate}</div>
                </div>
                <button onClick={() => setSelectedQuote(null)} style={{ background:"none", border:"none", cursor:"pointer", padding:4 }}>
                  <X size={20} color="#94a3b8" />
                </button>
              </div>

              {/* status badge */}
              <span style={{ fontSize:11, fontWeight:700, borderRadius:4, padding:"3px 10px", background:sc.bg, color:sc.color, letterSpacing:"0.04em" }}>{st.toUpperCase()}</span>

              {/* fields */}
              <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:14, marginTop:18 }}>
                {fields.map(([label, value]) => (
                  <div key={label} style={{ background:"#f8fafc", borderRadius:10, padding:"10px 14px" }}>
                    <div style={{ fontSize:10, fontWeight:700, color:"#94a3b8", textTransform:"uppercase", letterSpacing:"0.06em", marginBottom:4 }}>{label}</div>
                    <div style={{ fontSize:13, fontWeight:600, color:"#1F2937", wordBreak:"break-all" }}>{value}</div>
                  </div>
                ))}
              </div>

              {/* description */}
              {selectedQuote.description && (
                <div style={{ background:"#f8fafc", borderRadius:10, padding:"10px 14px", marginTop:14 }}>
                  <div style={{ fontSize:10, fontWeight:700, color:"#94a3b8", textTransform:"uppercase", letterSpacing:"0.06em", marginBottom:4 }}>Description</div>
                  <div style={{ fontSize:13, color:"#374151", lineHeight:1.6 }}>{selectedQuote.description}</div>
                </div>
              )}

              {/* invoice sent notice / PDF download */}
              {isInvoice ? (
                <div style={{ display:"flex", alignItems:"center", gap:10, marginTop:20, padding:"12px 16px", background:"#f0fdf4", border:"1px solid #bbf7d0", borderRadius:10 }}>
                  <div style={{ width:28, height:28, borderRadius:"50%", background:"#dcfce7", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                    <Check size={14} color="#166534" strokeWidth={2.5} />
                  </div>
                  <div>
                    <div style={{ fontSize:12, fontWeight:700, color:"#166534" }}>Invoice sent</div>
                    <div style={{ fontSize:11, color:"#4ade80" }}>
                      Delivered to {selectedQuote.student_email || selectedQuote.client_name || "student"} on {modalDate}
                    </div>
                  </div>
                </div>
              ) : selectedQuote.pdf_url ? (
                <button
                  onClick={() => handleDownload(selectedQuote.pdf_url, `${selectedQuote.quote_number || "estimate"}.pdf`)}
                  style={{ display:"flex", alignItems:"center", gap:8, marginTop:20, width:"100%", padding:"12px 16px", background:"#000080", color:"#fff", border:"none", borderRadius:10, cursor:"pointer", fontWeight:700, fontSize:13, justifyContent:"center" }}
                >
                  <Download size={16} />
                  Download Estimate PDF
                </button>
              ) : null}
            </div>
          </div>
        );
      })()}

      {/* ── Rejection modal ── */}
      {showRejectModal && (
        <div style={s.overlay} onClick={() => setShowRejectModal(false)}>
          <div style={s.modal} onClick={e => e.stopPropagation()}>
            <div style={s.modalHeader}>
              <span style={s.modalTitle}>Reject Teacher</span>
              <button style={s.modalClose} onClick={() => setShowRejectModal(false)}>✕</button>
            </div>
            <div style={{ fontSize: 13, color: "#64748b", marginBottom: 16 }}>
              Select a reason for rejecting <strong>{`${teacher.first_name ?? ""} ${teacher.last_name ?? ""}`.trim()}</strong>:
            </div>
            <div style={s.causeList}>
              {REJECTION_CAUSES.map(cause => (
                <label key={cause} style={s.causeRow}>
                  <input
                    type="radio"
                    name="cause"
                    value={cause}
                    checked={selectedCause === cause}
                    onChange={() => setSelectedCause(cause)}
                    style={s.radio}
                  />
                  <span style={{ fontSize: 13, color: "#374151" }}>{cause}</span>
                </label>
              ))}
            </div>
            <div style={{ display: "flex", gap: 10, marginTop: 20 }}>
              <button
                style={{ ...s.actionBtn, background: "#f1f5f9", color: "#374151", flex: 1 }}
                onClick={() => setShowRejectModal(false)}
              >
                Cancel
              </button>
              <button
                style={{ ...s.actionBtn, background: "#ef4444", flex: 1, opacity: saving ? 0.6 : 1 }}
                disabled={saving}
                onClick={handleConfirmReject}
              >
                {saving ? "Rejecting…" : "Confirm Reject"}
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}

function QuoteRow({ quote, onView }) {
  const isInvoice = quote._source === "estimates";
  const num       = quote.quote_number || quote.reference || `#${String(quote.id).slice(0, 8).toUpperCase()}`;
  const rawDate   = isInvoice ? (quote.sent_at || quote.created_at) : quote.created_at;
  const d         = rawDate?.toDate ? rawDate.toDate() : (rawDate ? new Date(rawDate) : null);
  const date      = d && !isNaN(d) ? `${String(d.getDate()).padStart(2,"0")}/${String(d.getMonth()+1).padStart(2,"0")}/${d.getFullYear()}` : "—";
  const amount    = quote.total != null ? `${Number(quote.total).toLocaleString()} DA` : (quote.amount != null ? `${Number(quote.amount).toLocaleString()} DA` : "—");
  const status    = (quote.status || "draft").toLowerCase();
  const SC = { pending:{bg:"#fef9c3",color:"#854d0e"}, sent:{bg:"#dbeafe",color:"#1d4ed8"}, accepted:{bg:"#dcfce7",color:"#166534"}, rejected:{bg:"#fee2e2",color:"#991b1b"}, paid:{bg:"#d1fae5",color:"#065f46"}, expired:{bg:"#f1f5f9",color:"#64748b"}, draft:{bg:"#f1f5f9",color:"#64748b"} };
  const sc = SC[status] ?? SC.draft;
  return (
    <div style={{ display:"flex", alignItems:"center", gap:10, padding:"10px 14px", background:"#f8fafc", borderRadius:10, border:"1px solid #e2e8f0" }}>
      <FileText size={16} color={isInvoice ? "#166534" : "#6366f1"} strokeWidth={1.8} style={{ flexShrink:0 }} />
      <div style={{ flex:1, minWidth:0 }}>
        <div style={{ display:"flex", alignItems:"center", gap:5 }}>
          <span style={{ fontSize:13, fontWeight:600, color:"#1F2937" }}>{num}</span>
          {isInvoice && <span style={{ fontSize:9, fontWeight:700, background:"#dcfce7", color:"#166534", borderRadius:3, padding:"1px 5px", letterSpacing:"0.04em" }}>INVOICE</span>}
        </div>
        {(quote.client_name || quote.student_name) && (
          <div style={{ fontSize:11, color:"#94a3b8" }}>{quote.client_name || quote.student_name}</div>
        )}
      </div>
      <span style={{ fontSize:12, color:"#64748b", flexShrink:0 }}>{amount}</span>
      <span style={{ fontSize:10, fontWeight:700, borderRadius:4, padding:"2px 7px", background:sc.bg, color:sc.color, letterSpacing:"0.04em", flexShrink:0 }}>{status.toUpperCase()}</span>
      <span style={{ fontSize:11, color:"#94a3b8", flexShrink:0 }}>{date}</span>
      <button onClick={onView} title="View details"
        style={{ background:"none", border:"none", cursor:"pointer", padding:4, display:"flex", alignItems:"center", flexShrink:0 }}>
        <Eye size={15} color="#6366f1" strokeWidth={2} />
      </button>
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
  contactValue: { fontSize: 12, fontWeight: 600, color: "#1F2937", wordBreak: "break-all" },
  descSection: { width: "100%", marginTop: 6 },
  descTitle: { fontSize: 12, fontWeight: 700, color: "#1F2937", marginBottom: 6 },
  descText: { fontSize: 12, color: "#64748b", lineHeight: 1.6, wordBreak: "break-word", overflowWrap: "break-word" },

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
  fieldValue: { fontSize: 13, fontWeight: 600, color: "#1F2937", wordBreak: "break-word", overflowWrap: "break-word" },

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
    position: "fixed", inset: 0, background: "rgba(0,0,0,0.4)",
    display: "flex", alignItems: "center", justifyContent: "center", zIndex: 100,
  },
  modal: {
    background: "#fff", borderRadius: 18, padding: "28px 28px 24px",
    width: 440, maxWidth: "90vw", boxShadow: "0 20px 60px rgba(0,0,0,0.18)",
    display: "flex", flexDirection: "column",
  },
  modalHeader: { display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 16 },
  modalTitle: { fontSize: 17, fontWeight: 700, color: "#1F2937" },
  modalClose: {
    width: 28, height: 28, borderRadius: "50%", border: "none",
    background: "#f1f5f9", cursor: "pointer", fontSize: 13, color: "#64748b",
    display: "flex", alignItems: "center", justifyContent: "center",
  },
  causeList: { display: "flex", flexDirection: "column", gap: 10 },
  causeRow: { display: "flex", alignItems: "center", gap: 10, cursor: "pointer" },
  radio: { accentColor: "#ef4444", width: 15, height: 15, cursor: "pointer", flexShrink: 0 },

};
