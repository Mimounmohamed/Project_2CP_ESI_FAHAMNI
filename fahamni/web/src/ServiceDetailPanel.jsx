import { useState, useEffect } from "react";
import {
  collection, query, where, getDocs, updateDoc, doc, documentId,
} from "firebase/firestore";
import { db } from "./firebase";

const DAYS  = ["SUN","MON","TUE","WED","THU","FRI","SAT"];
const MONTH = ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"];

const STATUS_STYLE = {
  pending:   { label: "PENDING",   color: "#fff",    bg: "#000080" },
  reviewed:  { label: "REVIEWED",  color: "#fff",    bg: "#22c55e" },
  resolved:  { label: "RESOLVED",  color: "#fff",    bg: "#06b6d4" },
  dismissed: { label: "DISMISSED", color: "#64748b", bg: "#f1f5f9" },
};

function formatShortDate(val) {
  if (!val) return "—";
  const d = val.toDate ? val.toDate() : new Date(val);
  if (isNaN(d)) return "—";
  return `${String(d.getDate()).padStart(2,"0")}/${String(d.getMonth()+1).padStart(2,"0")}/${d.getFullYear()}`;
}

function ts(val) {
  if (!val) return null;
  return val.toDate ? val.toDate() : new Date(val);
}
function fmtTime(val) {
  const d = ts(val);
  if (!d) return "—";
  return `${String(d.getHours()).padStart(2,"0")}:${String(d.getMinutes()).padStart(2,"0")}`;
}
function fmtDayDate(val) {
  const d = ts(val);
  if (!d) return { day:"—", date:"—" };
  return { day: DAYS[d.getDay()], date: `${d.getDate()} ${MONTH[d.getMonth()]}` };
}
function fmtResourceDate(val) {
  const d = ts(val);
  if (!d) return "—";
  return `${MONTH[d.getMonth()]} ${d.getDate()}`;
}

const TOP_TABS = ["General Info","Activity","Reports"];
const SUB_TABS = ["Overview","Resources","Members","Sessions"];

function ResourceIcon({ type, docType }) {
  const color = type === "link" ? "#f59e0b" : type === "media" ? "#8b5cf6" : docType === "pdf" ? "#3b82f6" : "#6366f1";
  if (type === "link") return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2">
      <path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/>
      <path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>
    </svg>
  );
  if (type === "media") return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2">
      <rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/>
      <polyline points="21 15 16 10 5 21"/>
    </svg>
  );
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2">
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
      <polyline points="14 2 14 8 20 8"/>
    </svg>
  );
}

function EmptyRow({ text }) {
  return (
    <div style={s.emptyRow}>
      <div style={s.emptyIcon}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="2">
          <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
        </svg>
      </div>
      <span style={{ fontSize:13, color:"#94a3b8" }}>{text}</span>
    </div>
  );
}

export default function ServiceDetailPanel({ service: init, tutorUid, onBack, onViewUser }) {
  const [service,        setService]        = useState(init);
  const [topTab,         setTopTab]         = useState("Activity");
  const [subTab,         setSubTab]         = useState("Overview");
  const [resources,      setResources]      = useState(null);
  const [members,        setMembers]        = useState(null);
  const [sessions,       setSessions]       = useState(null);
  const [toggling,       setToggling]       = useState(false);
  const [reports,        setReports]        = useState(null);
  const [selectedReport, setSelectedReport] = useState(null);
  const [updatingReport, setUpdatingReport] = useState(false);

  // Resources
  useEffect(() => {
    if (topTab !== "Activity" || subTab !== "Resources" || resources !== null || !tutorUid) return;
    getDocs(query(collection(db, "resources"), where("tutor_id", "==", tutorUid)))
      .then(snap => setResources(snap.docs.map(d => ({ id: d.id, ...d.data() }))))
      .catch(() => setResources([]));
  }, [topTab, subTab, tutorUid, resources]);

  // Members — batch by 30 (Firestore "in" limit)
  useEffect(() => {
    if (topTab !== "Activity" || subTab !== "Members" || members !== null) return;
    const ids = service.student_ids ?? [];
    if (!ids.length) { setMembers([]); return; }
    const chunks = [];
    for (let i = 0; i < ids.length; i += 30) chunks.push(ids.slice(i, i + 30));
    Promise.all(
      chunks.map(chunk =>
        getDocs(query(collection(db, "students"), where("uid", "in", chunk)))
      )
    )
      .then(snaps => setMembers(snaps.flatMap(s => s.docs.map(d => ({ id: d.id, ...d.data() })))))
      .catch(() => setMembers([]));
  }, [topTab, subTab, service.student_ids, members]);

  // Sessions
  useEffect(() => {
    if (topTab !== "Activity" || subTab !== "Sessions" || sessions !== null) return;
    getDocs(query(collection(db, "sessions"), where("service_id", "==", service.id ?? service.service_id)))
      .then(snap => {
        const list = snap.docs
          .map(d => ({ id: d.id, ...d.data() }))
          .sort((a, b) => (a.date?.seconds ?? 0) - (b.date?.seconds ?? 0));
        setSessions(list);
      })
      .catch(() => setSessions([]));
  }, [topTab, subTab, service.id, sessions]);

  // Reports
  useEffect(() => {
    if (topTab !== "Reports" || reports !== null) return;
    const svcId = service.id ?? service.service_id;
    getDocs(query(collection(db, "reports"), where("service_id", "==", svcId)))
      .then(snap => {
        const list = snap.docs
          .map(d => ({ id: d.id, ...d.data() }))
          .sort((a, b) => (b.created_at?.seconds ?? 0) - (a.created_at?.seconds ?? 0));
        setReports(list);
      })
      .catch(() => setReports([]));
  }, [topTab, service.id, reports]);

  async function markReviewed(report) {
    setUpdatingReport(true);
    try {
      await updateDoc(doc(db, "reports", report.id), { status: "reviewed" });
      setReports(prev => prev.map(r => r.id === report.id ? { ...r, status: "reviewed" } : r));
      setSelectedReport(r => r ? { ...r, status: "reviewed" } : r);
    } catch (e) {
      console.error(e);
    } finally {
      setUpdatingReport(false);
    }
  }

  async function toggleActive() {
    setToggling(true);
    try {
      const next = !service.is_active;
      await updateDoc(doc(db, "services", service.id ?? service.service_id), { is_active: next });
      setService(prev => ({ ...prev, is_active: next }));
    } catch (e) { console.error(e); }
    finally { setToggling(false); }
  }

  return (
    <>
    <div style={s.wrap}>

      {/* Back arrow */}
      {onBack && (
        <button style={s.backBtn} onClick={onBack}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <polyline points="15 18 9 12 15 6"/>
          </svg>
          Back
        </button>
      )}

      {/* Top tabs + deactivate */}
      <div style={s.topRow}>
        <div style={s.tabsRow}>
          {TOP_TABS.map(t => (
            <button key={t} style={{ ...s.tab, ...(topTab === t ? s.tabActive : {}) }}
              onClick={() => setTopTab(t)}>
              {t}
            </button>
          ))}
        </div>
        <button
          style={{ ...s.deactivateBtn, opacity: toggling ? 0.6 : 1 }}
          disabled={toggling}
          onClick={toggleActive}
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="12" cy="12" r="10"/><line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/>
          </svg>
          {toggling ? "Saving…" : service.is_active ? "Deactivate Service" : "Activate Service"}
        </button>
      </div>

      {/* ── General Info ── */}
      {topTab === "General Info" && (
        <div style={s.infoCard}>
          <div style={s.cardHeader}>
            <div style={s.infoIcon}>i</div>
            <span style={s.cardTitle}>Detailed Information</span>
          </div>
          <div style={s.infoGrid}>
            <Field label="SERVICE NAME" value={service.name || "—"} />
            <Field label="LEVEL"        value={service.level || "—"} />
            <Field label="DOMAIN"       value={service.subject || "—"} />
            <Field label="MODE"         value={capitalize(service.mode)} />
            <Field label="PRICE"        value={service.price ? `${service.price} DA` : "—"} />
            <Field label="SESSIONS"     value={service.sessions_num ? `${service.sessions_num} (${service.duration}min/Session)` : "—"} />
            <Field label="ENROLLED"     value={`${service.enrolled_num ?? 0} / ${service.maxstudents ?? "—"}`} />
            <Field label="STATUS"       value={service.is_active ? "Active" : "Inactive"} />
          </div>
          {service.description && (
            <div style={s.aboutCard}>
              <div style={s.cardTitle}>About this service</div>
              <div style={s.aboutText}>{service.description}</div>
            </div>
          )}
        </div>
      )}

      {/* ── Activity ── */}
      {topTab === "Activity" && (
        <div style={s.activityWrap}>

          {/* Sub-tabs */}
          <div style={s.subTabsRow}>
            {SUB_TABS.map(t => (
              <button key={t} style={{ ...s.subTab, ...(subTab === t ? s.subTabActive : {}) }}
                onClick={() => setSubTab(t)}>
                {t}
              </button>
            ))}
          </div>

          {/* Overview */}
          {subTab === "Overview" && (
            <div style={{ display:"flex", flexDirection:"column", gap:14 }}>
              <div style={s.infoCard}>
                <div style={s.cardHeader}>
                  <div style={s.infoIcon}>i</div>
                  <span style={s.cardTitle}>Detailed Information</span>
                </div>
                <div style={s.infoGrid}>
                  <Field label="FULL NAME" value={service.name || "—"} />
                  <Field label="LEVEL"     value={service.level || "—"} />
                  <Field label="DOMAINE"   value={service.subject || "—"} />
                  <Field label="MODE"      value={capitalize(service.mode)} />
                  <Field label="PRICE"     value={service.price ? `${service.price} DA` : "—"} />
                  <Field label="SESSIONS"  value={service.sessions_num ? `${service.sessions_num} (${service.duration}min/Session)` : "—"} />
                </div>
              </div>
              {service.description && (
                <div style={s.aboutCard}>
                  <div style={s.cardTitle}>About this service</div>
                  <div style={s.aboutText}>{service.description}</div>
                </div>
              )}
            </div>
          )}

          {/* Resources */}
          {subTab === "Resources" && (
            <div style={s.list}>
              {resources === null
                ? <EmptyRow text="Loading resources…" />
                : resources.length === 0
                  ? <EmptyRow text="No resources uploaded for this service." />
                  : resources.map(r => (
                    <div key={r.id} style={s.resourceRow}>
                      <div style={s.resourceIcon}>
                        <ResourceIcon type={r.content_type} docType={r.doc_type} />
                      </div>
                      <div style={s.resourceMid}>
                        <div style={s.resourceName}>{r.title || "Untitled"}</div>
                        <div style={s.resourceMeta}>
                          {fmtResourceDate(r.added_at)}
                          {r.file_size && <><span style={{ margin:"0 4px", color:"#cbd5e1" }}>•</span>{r.file_size}</>}
                        </div>
                      </div>
                      {r.content_type === "link"
                        ? (
                          <a href={r.link_url} target="_blank" rel="noreferrer" style={s.dlBtn}>
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="2">
                              <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/>
                              <polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/>
                            </svg>
                          </a>
                        ) : (
                          <a href={r.file_url ?? r.media_url} target="_blank" rel="noreferrer" style={s.dlBtn}>
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="2">
                              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                              <polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/>
                            </svg>
                          </a>
                        )
                      }
                    </div>
                  ))
              }
            </div>
          )}

          {/* Members */}
          {subTab === "Members" && (
            <div style={s.list}>
              {members === null
                ? <EmptyRow text="Loading members…" />
                : members.length === 0
                  ? <EmptyRow text="No students enrolled in this service." />
                  : members.map(m => {
                    const name = `${m.first_name ?? ""} ${m.last_name ?? ""}`.trim() || "Unknown";
                    return (
                      <div key={m.id} style={s.memberRow}>
                        {m.picture
                          ? <img src={m.picture} alt="avatar" style={s.memberAvatar} />
                          : <div style={s.memberAvatarFallback}>
                              {name.split(" ").map(w => w[0]).join("").slice(0,2).toUpperCase()}
                            </div>
                        }
                        <div style={{ flex:1, minWidth:0 }}>
                          <div style={s.memberName}>{name}</div>
                          <div style={s.memberRole}>Student</div>
                        </div>
                        <button
                          style={s.eyeBtn}
                          title="View student profile"
                          onClick={() => onViewUser?.({ ...m, col: "students", role: "student", id: m.id })}
                        >
                          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#000080" strokeWidth="1.8">
                            <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                            <circle cx="12" cy="12" r="3"/>
                          </svg>
                        </button>
                      </div>
                    );
                  })
              }
            </div>
          )}

          {/* Sessions */}
          {subTab === "Sessions" && (
            <div>
              {sessions === null
                ? <EmptyRow text="Loading sessions…" />
                : sessions.length === 0
                  ? <EmptyRow text="No sessions scheduled for this service." />
                  : (
                    <div style={s.sessionsGrid}>
                      {sessions.map(sess => {
                        const { day, date } = fmtDayDate(sess.date ?? sess.start_time);
                        const start = fmtTime(sess.start_time);
                        const end   = fmtTime(sess.end_time);
                        const mode  = (sess.modality ?? sess.mode ?? "").toLowerCase();
                        const online = mode === "online";
                        return (
                          <div key={sess.id} style={s.sessionCard}>
                            <div style={s.sessionDayDate}>
                              <span style={s.sessionDay}>{day},</span>
                              <span style={s.sessionDate}> {date}</span>
                            </div>
                            <div style={s.sessionTime}>{start} – {end}</div>
                            <div style={{ ...s.sessionBadge, background: online ? "#dcfce7" : "#fef3c7", color: online ? "#16a34a" : "#d97706" }}>
                              <span style={{ width:6, height:6, borderRadius:"50%", background: online ? "#22c55e" : "#f59e0b", flexShrink:0 }} />
                              {online ? "Online" : "Onsite"}
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  )
              }
            </div>
          )}

        </div>
      )}

      {/* ── Reports ── */}
      {topTab === "Reports" && (
        <div style={s.reportsWrap}>

          {/* Report list */}
          <div style={s.reportList}>
            {reports === null ? (
              <EmptyRow text="Loading reports…" />
            ) : reports.length === 0 ? (
              <EmptyRow text="No reports filed for this service." />
            ) : reports.map(r => {
              const ss = STATUS_STYLE[r.status] ?? STATUS_STYLE.pending;
              const initials = (r.reporter_name || "?").split(" ").map(w => w[0]).join("").slice(0,2).toUpperCase();
              return (
                <div key={r.id} style={s.reportRow}>
                  <div style={s.reportAvatar}>{initials}</div>
                  <div style={s.reportMid}>
                    <div style={s.reportName}>{r.reporter_name || "Anonymous"}</div>
                    <div style={s.reportPreview}>
                      {(r.text || "").slice(0, 55)}{(r.text || "").length > 55 ? " …" : ""}
                    </div>
                  </div>
                  <div style={s.reportDate}>{formatShortDate(r.created_at)}</div>
                  <span style={{ ...s.statusPill, color: ss.color, background: ss.bg }}>{ss.label}</span>
                  <button style={s.eyeBtn} title="View full report" onClick={() => setSelectedReport(r)}>
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#000080" strokeWidth="1.8">
                      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                      <circle cx="12" cy="12" r="3"/>
                    </svg>
                  </button>
                </div>
              );
            })}
          </div>

          {/* Stats card */}
          <div style={s.statsCard}>
            <div style={s.statsLabel}>TOTAL</div>
            <div style={s.statsTitle}>Reports</div>
            <div style={{ fontSize: 36, fontWeight: 800, color: "#fff", lineHeight: 1.1, marginBottom: 20 }}>
              {reports === null ? "—" : reports.length.toLocaleString()}
            </div>
            {["pending","reviewed","resolved","dismissed"].map(st => {
              const count = reports ? reports.filter(r => r.status === st).length : 0;
              return (
                <div key={st} style={{ display:"flex", alignItems:"center", justifyContent:"space-between", marginBottom: 10 }}>
                  <span style={{ fontSize:11, color:"#93c5fd", fontWeight:600, textTransform:"uppercase", letterSpacing:"0.04em" }}>{st}</span>
                  <span style={{ fontSize:14, fontWeight:700, color:"#fff" }}>{count}</span>
                </div>
              );
            })}
          </div>

        </div>
      )}

    </div>

    {/* ── Report detail modal ── */}
    {selectedReport && (() => {
      const r  = selectedReport;
      const ss = STATUS_STYLE[r.status] ?? STATUS_STYLE.pending;
      const initials = (r.reporter_name || "?").split(" ").map(w => w[0]).join("").slice(0,2).toUpperCase();
      return (
        <div style={s.modalOverlay} onClick={() => setSelectedReport(null)}>
          <div style={s.modalBox} onClick={e => e.stopPropagation()}>

            <div style={s.modalHeader}>
              <div style={s.modalTitle}>Report Detail</div>
              <button style={s.modalClose} onClick={() => setSelectedReport(null)}>✕</button>
            </div>

            <div style={s.modalMeta}>
              <div style={s.reportAvatar}>{initials}</div>
              <div>
                <div style={{ fontSize:14, fontWeight:700, color:"#1F2937" }}>{r.reporter_name || "Anonymous"}</div>
                <div style={{ fontSize:12, color:"#94a3b8", marginTop:2 }}>{formatShortDate(r.created_at)}</div>
              </div>
              <span style={{ ...s.statusPill, color: ss.color, background: ss.bg, marginLeft:"auto" }}>{ss.label}</span>
            </div>

            {r.type && (
              <div style={{ fontSize:11, fontWeight:700, color:"#94a3b8", letterSpacing:"0.06em", marginBottom:8 }}>
                TYPE: {r.type.toUpperCase()}
              </div>
            )}

            <div style={s.modalText}>{r.text || "No description provided."}</div>

            {r.status === "pending" && (
              <button
                style={{ ...s.reviewBtn, opacity: updatingReport ? 0.6 : 1 }}
                disabled={updatingReport}
                onClick={() => markReviewed(r)}
              >
                {updatingReport ? "Saving…" : "Mark as Reviewed"}
              </button>
            )}

          </div>
        </div>
      );
    })()}
    </>
  );
}

function Field({ label, value }) {
  return (
    <div>
      <div style={{ fontSize:10, fontWeight:700, color:"#94a3b8", letterSpacing:"0.06em", marginBottom:4 }}>{label}</div>
      <div style={{ fontSize:13, fontWeight:600, color:"#1F2937" }}>{value}</div>
    </div>
  );
}

function capitalize(str) {
  if (!str) return "—";
  return str.charAt(0).toUpperCase() + str.slice(1);
}

const s = {
  wrap: { display:"flex", flexDirection:"column", gap:14 },
  backBtn: {
    display:"flex", alignItems:"center", gap:6, alignSelf:"flex-start",
    background:"none", border:"none", cursor:"pointer",
    color:"#64748b", fontSize:13, fontWeight:600, padding:"4px 0",
  },

  topRow: { display:"flex", alignItems:"center", justifyContent:"space-between", flexShrink:0 },
  tabsRow: {
    display:"flex", background:"#fff", borderRadius:12, border:"1px solid #f1f5f9",
    padding:4, gap:2, boxShadow:"0 2px 8px rgba(0,0,0,0.04)",
  },
  tab: {
    padding:"8px 20px", borderRadius:9, border:"none", background:"transparent",
    fontSize:13, fontWeight:500, color:"#64748b", cursor:"pointer",
  },
  tabActive: { background:"#000080", color:"#fff", fontWeight:600 },

  deactivateBtn: {
    display:"flex", alignItems:"center", gap:7,
    padding:"9px 18px", borderRadius:24, border:"1.5px solid #ef4444",
    background:"transparent", color:"#ef4444", fontSize:13, fontWeight:600, cursor:"pointer",
  },

  /* Sub-tabs */
  activityWrap: { display:"flex", flexDirection:"column", gap:14 },
  subTabsRow: { display:"flex", gap:8, flexShrink:0 },
  subTab: {
    padding:"7px 18px", borderRadius:20, border:"1.5px solid #e2e8f0",
    background:"#fff", fontSize:13, fontWeight:500, color:"#64748b", cursor:"pointer",
  },
  subTabActive: { background:"#000080", borderColor:"#000080", color:"#fff", fontWeight:600 },

  /* Cards */
  infoCard: {
    background:"#fff", borderRadius:14, border:"1px solid #f1f5f9",
    padding:"18px 20px", boxShadow:"0 2px 8px rgba(0,0,0,0.04)", flexShrink:0,
  },
  cardHeader: { display:"flex", alignItems:"center", gap:8, marginBottom:16 },
  infoIcon: {
    width:22, height:22, borderRadius:"50%", background:"#6366f1",
    color:"#fff", fontSize:13, fontWeight:700,
    display:"flex", alignItems:"center", justifyContent:"center",
  },
  cardTitle: { fontSize:14, fontWeight:700, color:"#1F2937" },
  infoGrid:  { display:"grid", gridTemplateColumns:"1fr 1fr", gap:"16px 32px" },

  aboutCard: {
    background:"#fff", borderRadius:14, border:"1px solid #f1f5f9",
    padding:"16px 20px", boxShadow:"0 2px 8px rgba(0,0,0,0.04)", marginTop:14,
  },
  aboutText: { fontSize:13, color:"#64748b", lineHeight:1.7, marginTop:10 },

  /* Lists */
  list: { display:"flex", flexDirection:"column", gap:10 },

  emptyRow: {
    display:"flex", alignItems:"center", gap:12, background:"#fff",
    borderRadius:12, border:"1px solid #f1f5f9", padding:"14px 16px",
    boxShadow:"0 1px 4px rgba(0,0,0,0.04)",
  },
  emptyIcon: {
    width:34, height:34, borderRadius:9, background:"#f8fafc",
    border:"1px solid #e2e8f0", display:"flex", alignItems:"center", justifyContent:"center",
  },

  /* Resources */
  resourceRow: {
    display:"flex", alignItems:"center", gap:12, background:"#fff",
    borderRadius:12, border:"1px solid #f1f5f9", padding:"12px 14px",
    boxShadow:"0 1px 4px rgba(0,0,0,0.04)",
  },
  resourceIcon: {
    width:38, height:38, borderRadius:9, background:"#f1f5f9",
    display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0,
  },
  resourceMid:  { flex:1, minWidth:0 },
  resourceName: { fontSize:13, fontWeight:600, color:"#1F2937", marginBottom:3 },
  resourceMeta: { fontSize:11, color:"#94a3b8", display:"flex", alignItems:"center" },
  dlBtn: {
    width:32, height:32, borderRadius:8, border:"1px solid #e2e8f0",
    background:"#f8fafc", display:"flex", alignItems:"center", justifyContent:"center",
    cursor:"pointer", textDecoration:"none", flexShrink:0,
  },

  /* Members */
  memberRow: {
    display:"flex", alignItems:"center", gap:12, background:"#fff",
    borderRadius:12, border:"1px solid #f1f5f9", padding:"10px 14px",
    boxShadow:"0 1px 4px rgba(0,0,0,0.04)",
  },
  memberAvatar: { width:40, height:40, borderRadius:"50%", objectFit:"cover", flexShrink:0 },
  memberAvatarFallback: {
    width:40, height:40, borderRadius:"50%", background:"#000080",
    color:"#fff", fontSize:12, fontWeight:700, display:"flex",
    alignItems:"center", justifyContent:"center", flexShrink:0,
  },
  memberName: { fontSize:13, fontWeight:600, color:"#1F2937" },
  memberRole: { fontSize:11, color:"#6366f1", fontWeight:600, marginTop:2 },
  eyeBtn: { background:"none", border:"none", cursor:"pointer", padding:4, display:"flex", alignItems:"center" },

  /* Reports */
  reportsWrap: { display:"flex", gap:16, alignItems:"flex-start" },
  reportList:  { flex:1, minWidth:0, display:"flex", flexDirection:"column", gap:10 },
  reportRow: {
    display:"flex", alignItems:"center", gap:12, background:"#fff",
    borderRadius:12, border:"1px solid #f1f5f9", padding:"12px 14px",
    boxShadow:"0 1px 4px rgba(0,0,0,0.04)",
  },
  reportAvatar: {
    width:38, height:38, borderRadius:"50%", background:"#eef2ff",
    color:"#6366f1", fontSize:12, fontWeight:700, flexShrink:0,
    display:"flex", alignItems:"center", justifyContent:"center",
  },
  reportMid:     { flex:1, minWidth:0 },
  reportName:    { fontSize:13, fontWeight:600, color:"#1F2937", marginBottom:2 },
  reportPreview: { fontSize:12, color:"#94a3b8", whiteSpace:"nowrap", overflow:"hidden", textOverflow:"ellipsis" },
  reportDate:    { fontSize:11, color:"#94a3b8", flexShrink:0, whiteSpace:"nowrap" },
  statusPill: {
    fontSize:10, fontWeight:700, borderRadius:6, padding:"3px 8px",
    letterSpacing:"0.04em", flexShrink:0,
  },

  /* Stats sidebar (Reports) */
  statsCard: {
    width:190, flexShrink:0, background:"#000080", borderRadius:14,
    padding:"20px 18px", color:"#fff",
  },
  statsLabel: { fontSize:10, fontWeight:700, color:"#93c5fd", letterSpacing:"0.08em", marginBottom:6 },
  statsTitle: { fontSize:20, fontWeight:700, color:"#fff", marginBottom:20, lineHeight:1.3 },

  /* Modal */
  modalOverlay: {
    position:"fixed", inset:0, background:"rgba(0,0,0,0.4)",
    display:"flex", alignItems:"center", justifyContent:"center", zIndex:100,
  },
  modalBox: {
    background:"#fff", borderRadius:18, padding:"28px 28px 24px",
    width:480, maxWidth:"90vw", boxShadow:"0 20px 60px rgba(0,0,0,0.2)",
    display:"flex", flexDirection:"column",
  },
  modalHeader: { display:"flex", alignItems:"center", justifyContent:"space-between", marginBottom:20 },
  modalTitle:  { fontSize:18, fontWeight:700, color:"#1F2937" },
  modalClose: {
    width:30, height:30, borderRadius:"50%", border:"none",
    background:"#f1f5f9", cursor:"pointer", fontSize:14, color:"#64748b",
    display:"flex", alignItems:"center", justifyContent:"center",
  },
  modalMeta: { display:"flex", alignItems:"center", gap:12, marginBottom:16 },
  modalText: {
    fontSize:14, color:"#374151", lineHeight:1.7,
    background:"#f8fafc", borderRadius:10, padding:"14px 16px",
    border:"1px solid #f1f5f9",
  },
  reviewBtn: {
    display:"flex", alignItems:"center", gap:8, marginTop:16,
    padding:"10px 20px", borderRadius:24, border:"none",
    background:"#22c55e", color:"#fff", fontSize:14, fontWeight:600, cursor:"pointer",
  },

  /* Sessions */
  sessionsGrid: { display:"grid", gridTemplateColumns:"1fr 1fr", gap:12 },
  sessionCard: {
    background:"#fff", borderRadius:12, border:"1px solid #f1f5f9",
    padding:"14px 16px", boxShadow:"0 1px 4px rgba(0,0,0,0.04)",
    display:"flex", flexDirection:"column", gap:6,
  },
  sessionDayDate: { fontSize:12, fontWeight:700, color:"#000080" },
  sessionDay:  { textTransform:"uppercase" },
  sessionDate: { textTransform:"uppercase" },
  sessionTime: { fontSize:18, fontWeight:700, color:"#1F2937" },
  sessionBadge: {
    display:"inline-flex", alignItems:"center", gap:6,
    padding:"4px 12px", borderRadius:20, fontSize:12, fontWeight:600,
    alignSelf:"flex-start",
  },
};
