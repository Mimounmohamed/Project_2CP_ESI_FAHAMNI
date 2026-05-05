import { useState, useEffect } from "react";
import { collection, query, where, getDocs, getDoc, updateDoc, doc } from "firebase/firestore";
import { db } from "./firebase";
import ServiceDetailPanel from "./ServiceDetailPanel";

const MONTHS = ["January","February","March","April","May","June",
                 "July","August","September","October","November","December"];

function formatDate(val) {
  if (!val) return "—";
  const d = val.toDate ? val.toDate() : new Date(val);
  if (isNaN(d)) return "—";
  return `${MONTHS[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}`;
}

function formatShortDate(val) {
  if (!val) return "—";
  const d = val.toDate ? val.toDate() : new Date(val);
  if (isNaN(d)) return "—";
  return `${String(d.getDate()).padStart(2,"0")}/${String(d.getMonth()+1).padStart(2,"0")}/${d.getFullYear()}`;
}

const STATUS_STYLE = {
  pending:   { label: "PENDING",   color: "#fff",     bg: "#000080" },
  reviewed:  { label: "REVIEWED",  color: "#fff",     bg: "#22c55e" },
  resolved:  { label: "RESOLVED",  color: "#fff",     bg: "#06b6d4" },
  dismissed: { label: "DISMISSED", color: "#64748b",  bg: "#f1f5f9" },
};

function timeAgo(val) {
  if (!val) return "—";
  const d = val.toDate ? val.toDate() : new Date(val);
  if (isNaN(d)) return "—";
  const diff = Date.now() - d.getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  if (days < 30) return `${days} day${days > 1 ? "s" : ""} ago`;
  return formatDate(val);
}

function formatBirthday(val) {
  if (!val) return "—";
  const d = val.toDate ? val.toDate() : new Date(val);
  if (isNaN(d)) return "—";
  return `${d.getMonth()+1}/${d.getDate()}/${d.getFullYear()}`;
}

function Stars({ rating }) {
  return (
    <div style={{ display: "flex", gap: 2 }}>
      {[1,2,3,4,5].map(i => (
        <span key={i} style={{ fontSize: 14, color: i <= Math.round(rating) ? "#f59e0b" : "#e2e8f0" }}>★</span>
      ))}
    </div>
  );
}

function capitalize(str) {
  if (!str) return "—";
  return str.charAt(0).toUpperCase() + str.slice(1);
}

function formatLevels(levels) {
  if (!levels?.length) return "—";
  return levels.map(l => l.replace(/_/g, " ").replace(/\b\w/g, c => c.toUpperCase())).join(", ");
}

const TEACHER_TABS = ["General Info", "Reports", "Services", "Feedbacks"];
const STUDENT_TABS = ["General Info", "Activity", "Reports"];
const PARENT_TABS  = ["General Info", "Activity", "Reports"];

const ROLE_STYLE = {
  teacher: { label: "Teacher", color: "#6366f1", bg: "#eef2ff" },
  student: { label: "Student", color: "#16a34a", bg: "#dcfce7" },
  parent:  { label: "Parent",  color: "#db2777", bg: "#fce7f3" },
};

export default function UserProfilePage({ user, onBack, onSuspendChange, onViewUser, onContact }) {
  const [activeTab, setActiveTab] = useState("General Info");
  const [certificates, setCertificates] = useState(null);
  const [stats, setStats] = useState({
    students: user.students_count ?? null,
    rating: user.average_rating ?? null,
    courses: user.courses_count ?? null,
  });
  const [suspended, setSuspended] = useState(user.is_suspended === true);
  const [saving, setSaving] = useState(false);
  const [reports, setReports] = useState(null);
  const [selectedReport, setSelectedReport] = useState(null);
  const [updatingReport, setUpdatingReport] = useState(false);
  const [services, setServices]           = useState(null);
  const [selectedService, setSelectedService] = useState(null);
  const [feedbacks, setFeedbacks]         = useState(null);
  const [activity, setActivity]           = useState(null);
  const [selectedActivity, setSelectedActivity] = useState(null);
  const [children, setChildren]           = useState(null);

  const tutorUid = user.uid ?? user.id;
  const fullName = `${user.first_name ?? ""} ${user.last_name ?? ""}`.trim();
  const isTeacher = user.role === "teacher";
  const isStudent = user.role === "student";
  const isParent  = user.role === "parent";
  const TABS = isTeacher ? TEACHER_TABS : isParent ? PARENT_TABS : STUDENT_TABS;
  const roleStyle = ROLE_STYLE[user.role] ?? ROLE_STYLE.teacher;
  const userCol = isTeacher ? "tutors" : isParent ? "parents" : "students";

  useEffect(() => {
    if (!tutorUid) return;

    getDocs(query(collection(db, "resources"), where("tutor_id", "==", tutorUid)))
      .then(snap => setCertificates(snap.docs.map(d => ({ id: d.id, ...d.data() }))))
      .catch(() => setCertificates([]));
  }, [tutorUid]);

  useEffect(() => {
    if (activeTab !== "Reports" || reports !== null || !tutorUid) return;
    getDocs(query(collection(db, "reports"), where("reported_id", "==", tutorUid)))
      .then(snap => {
        const list = snap.docs
          .map(d => ({ id: d.id, ...d.data() }))
          .sort((a, b) => (b.created_at?.seconds ?? 0) - (a.created_at?.seconds ?? 0));
        setReports(list);
      })
      .catch(() => setReports([]));
  }, [activeTab, tutorUid, reports]);

  useEffect(() => {
    if (activeTab !== "Services" || services !== null || !tutorUid) return;
    getDocs(query(collection(db, "services"), where("tutor_id", "==", tutorUid)))
      .then(snap => {
        const list = snap.docs
          .map(d => ({ id: d.id, ...d.data() }))
          .sort((a, b) => (b.created_at?.seconds ?? 0) - (a.created_at?.seconds ?? 0));
        setServices(list);
      })
      .catch(() => setServices([]));
  }, [activeTab, tutorUid, services]);

  useEffect(() => {
    if ((!isStudent && !isParent) || activeTab !== "Activity" || activity !== null || !tutorUid) return;

    async function fetchActivity() {
      let svcs = [];

      if (isStudent) {
        const snap = await getDocs(
          query(collection(db, "services"), where("student_ids", "array-contains", tutorUid))
        );
        svcs = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      } else {
        // parent: fetch services where any child is enrolled
        const childrenUids = user.children_uids ?? [];
        if (childrenUids.length === 0) { setActivity([]); return; }

        // children collection docs for name lookup
        const childDocs = await getDocs(
          query(collection(db, "children"), where("parentUid", "==", tutorUid))
        );
        const childMap = {};
        childDocs.forEach(d => { childMap[d.id] = d.data(); });

        // array-contains-any supports up to 30 items
        const snap = await getDocs(
          query(collection(db, "services"), where("student_ids", "array-contains-any", childrenUids.slice(0, 30)))
        );
        svcs = snap.docs.map(d => {
          const data = d.data();
          const enrolledChildren = (data.student_ids ?? [])
            .filter(id => childMap[id])
            .map(id => childMap[id].name ?? "Child");
          return { id: d.id, ...data, enrolled_children: enrolledChildren };
        });
      }

      const tutorIds = [...new Set(svcs.map(s => s.tutor_id).filter(Boolean))];
      const tutorMap = {};
      await Promise.all(
        tutorIds.map(tid =>
          getDoc(doc(db, "tutors", tid)).then(d => {
            if (d.exists()) tutorMap[tid] = d.data();
          })
        )
      );

      const list = svcs
        .map(s => {
          const t = tutorMap[s.tutor_id];
          return {
            ...s,
            tutor_name   : t ? `${t.first_name} ${t.last_name}` : "—",
            tutor_picture: t?.picture ?? null,
          };
        })
        .sort((a, b) => (b.created_at?.seconds ?? 0) - (a.created_at?.seconds ?? 0));

      setActivity(list);
    }

    fetchActivity().catch(() => setActivity([]));
  }, [activeTab, tutorUid, activity, isStudent, isParent]);

  useEffect(() => {
    if (activeTab !== "Feedbacks" || feedbacks !== null || !tutorUid) return;
    getDocs(query(collection(db, "feedbacks"), where("tutor_id", "==", tutorUid)))
      .then(snap => {
        const list = snap.docs
          .map(d => ({ id: d.id, ...d.data() }))
          .sort((a, b) => (b.created_at?.seconds ?? 0) - (a.created_at?.seconds ?? 0));
        setFeedbacks(list);
      })
      .catch(() => setFeedbacks([]));
  }, [activeTab, tutorUid, feedbacks]);

  useEffect(() => {
    if (!isParent || !tutorUid) return;
    getDocs(query(collection(db, "children"), where("parentUid", "==", tutorUid)))
      .then(snap => setChildren(snap.docs.map(d => ({ id: d.id, ...d.data() }))))
      .catch(() => setChildren([]));
  }, [isParent, tutorUid]);

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

  async function toggleSuspend() {
    setSaving(true);
    const next = !suspended;
    try {
      await updateDoc(doc(db, user.col ?? userCol, user.id ?? user.uid), { is_suspended: next });
      setSuspended(next);
      onSuspendChange?.(user.id, next);
    } catch (e) {
      console.error(e);
    } finally {
      setSaving(false);
    }
  }

  return (
    <div style={s.page}>

      {/* ── Header ── */}
      <div style={s.header}>
        <div>
          <div style={s.breadcrumb}>
            <span style={s.breadLink} onClick={onBack}>Users</span>
            <span style={s.breadSep}>›</span>
            <span style={s.breadCurrent}>User Profile</span>
          </div>
          <h1 style={s.pageTitle}>User Profile</h1>
        </div>
        <div style={s.headerBtns}>
          <button style={s.contactBtn} onClick={() => onContact?.({
            uid: tutorUid,
            name: fullName,
            role: user.role,
            picture: user.picture ?? null,
          })}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2">
              <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
            </svg>
            Contact
          </button>
          <button
            style={{ ...s.suspendBtn, opacity: saving ? 0.6 : 1 }}
            disabled={saving}
            onClick={toggleSuspend}
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2">
              <circle cx="12" cy="12" r="10"/>
              <line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/>
            </svg>
            {saving ? "Saving…" : suspended ? "Unsuspend Account" : "Suspend Account"}
          </button>
        </div>
      </div>

      {/* ── Body ── */}
      <div style={s.body}>

        {/* Left card */}
        <div style={s.leftCard}>
          <div style={s.statusBadge(suspended)}>
            {suspended ? "SUSPENDED" : "ACTIVE"}
          </div>

          {user.picture
            ? <img src={user.picture} alt="avatar" style={s.avatar} />
            : <div style={s.avatarFallback}>
                <svg width="44" height="44" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="1.4">
                  <circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/>
                </svg>
              </div>
          }

          <div style={s.name}>{fullName}</div>
          <span style={{ ...s.rolePill, color: roleStyle.color, background: roleStyle.bg }}>{roleStyle.label}</span>

          <div style={s.contactRow}>
            <div style={s.contactIcon}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="2">
                <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                <polyline points="22,6 12,13 2,6"/>
              </svg>
            </div>
            <div>
              <div style={s.contactLabel}>EMAIL ADDRESS</div>
              <div style={s.contactValue}>{user.email || "—"}</div>
            </div>
          </div>

          <div style={s.contactRow}>
            <div style={s.contactIcon}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="2">
                <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12 19.79 19.79 0 0 1 1.61 3.38 2 2 0 0 1 3.58 1.18h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 8.73a16 16 0 0 0 6 6l.92-.92a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 21.73 16l.19.92z"/>
              </svg>
            </div>
            <div>
              <div style={s.contactLabel}>PHONE NUMBER</div>
              <div style={s.contactValue}>{user.phone || "—"}</div>
            </div>
          </div>

          {user.pedagogical_description && (
            <div style={s.descSection}>
              <div style={s.descTitle}>Personal Description</div>
              <div style={s.descText}>{user.pedagogical_description}</div>
            </div>
          )}
        </div>

        {/* Right area */}
        <div style={s.right}>

          {/* Tabs */}
          <div style={s.tabsRow}>
            {TABS.map(t => (
              <button
                key={t}
                style={{ ...s.tab, ...(activeTab === t ? s.tabActive : {}) }}
                onClick={() => setActiveTab(t)}
              >
                {t}
              </button>
            ))}
          </div>

          {/* Scrollable tab content */}
          <div className="thin-scroll" style={s.scrollArea}>

          {activeTab === "General Info" && isTeacher && (
            <div style={s.tabContent}>

              {/* Main column */}
              <div style={s.mainCol}>

                {/* Detailed Information */}
                <div style={s.infoCard}>
                  <div style={s.cardHeader}>
                    <div style={s.infoIcon}>i</div>
                    <span style={s.cardTitle}>Detailed Information</span>
                  </div>
                  <div style={s.infoGrid}>
                    <Field label="FULL NAME"         value={fullName || "—"} />
                    <Field label="GENDER"            value={capitalize(user.gender)} />
                    <Field label="LEVEL"             value={formatLevels(user.levels_taught)} />
                    <Field label="EXPERTISE DOMAIN"  value={user.expertise_domain || "—"} />
                    <Field label="TEACHING MODE"     value={capitalize(user.teaching_mode)} />
                    <Field label="JOINED DATE"       value={formatDate(user.created_at)} />
                  </div>
                </div>

                {/* Academic Description */}
                {user.academic_description && (
                  <div style={s.descCard}>
                    <div style={s.cardTitle}>Academic Description</div>
                    <div style={s.descBody}>{user.academic_description}</div>
                  </div>
                )}

                {/* Certificates */}
                <div style={s.certCard}>
                  <div style={s.cardTitle}>Teacher Certificates</div>
                  <div style={s.certList}>
                    {certificates === null ? (
                      <span style={s.dimText}>Loading...</span>
                    ) : certificates.length === 0 ? (
                      <span style={s.dimText}>No certificates uploaded.</span>
                    ) : certificates.map(c => (
                      <div key={c.id} style={s.certItem}>
                        <div style={s.certIconWrap}>
                          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#6366f1" strokeWidth="1.8">
                            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                            <polyline points="14 2 14 8 20 8"/>
                          </svg>
                        </div>
                        <div>
                          <div style={{ fontSize: 12, fontWeight: 600, color: "#1F2937" }}>
                            {c.title || "Certificate.pdf"}
                          </div>
                          {c.size_mb && <div style={{ fontSize: 11, color: "#94a3b8" }}>{c.size_mb} MB</div>}
                        </div>
                        <button style={s.dlBtn} title="Download">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="2">
                            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                            <polyline points="7 10 12 15 17 10"/>
                            <line x1="12" y1="15" x2="12" y2="3"/>
                          </svg>
                        </button>
                      </div>
                    ))}
                  </div>
                </div>

              </div>

              {/* Quick Stats column */}
              <div style={s.statsCard}>
                <div style={s.statsLabel}>QUICK STATS</div>
                <div style={s.statsTitle}>Teacher Profile</div>
                <div style={s.statRow}>
                  <span style={s.statKey}>Students</span>
                  <span style={s.statVal}>{stats.students === null ? "—" : stats.students.toLocaleString()}</span>
                </div>
                <div style={s.statRow}>
                  <span style={s.statKey}>Rating</span>
                  <span style={s.statVal}>
                    {stats.rating == null ? "—" : `${Number(stats.rating).toFixed(1)} / 5.0`}
                  </span>
                </div>
                <div style={s.statRow}>
                  <span style={s.statKey}>Courses</span>
                  <span style={s.statVal}>{stats.courses === null ? "—" : stats.courses}</span>
                </div>
              </div>

            </div>
          )}

          {/* ── Student General Info ── */}
          {activeTab === "General Info" && isStudent && (
            <div style={s.tabContent}>
              <div style={s.mainCol}>
                <div style={s.infoCard}>
                  <div style={s.cardHeader}>
                    <div style={s.infoIcon}>i</div>
                    <span style={s.cardTitle}>Detailed Information</span>
                  </div>
                  <div style={s.infoGrid}>
                    <Field label="FULL NAME"   value={fullName || "—"} />
                    <Field label="LEVEL"       value={capitalize(user.school_level ?? user.level)} />
                    <Field label="GRADE"       value={user.grade || "—"} />
                    <Field label="BIRTHDAY"    value={formatBirthday(user.birth_date ?? user.birthday)} />
                    <Field label="JOINED DATE" value={formatDate(user.created_at)} />
                    <Field label="LAST LOGIN"  value={timeAgo(user.last_login_date ?? user.last_seen ?? user.last_login)} />
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* ── Parent General Info ── */}
          {activeTab === "General Info" && isParent && (
            <div style={s.tabContent}>
              <div style={s.mainCol}>
                <div style={s.infoCard}>
                  <div style={s.cardHeader}>
                    <div style={s.infoIcon}>i</div>
                    <span style={s.cardTitle}>Detailed Information</span>
                  </div>
                  <div style={s.infoGrid}>
                    <Field label="FULL NAME"    value={fullName || "—"} />
                    <Field label="CHILDS NUMBER" value={String((user.children_uids ?? []).length || (children?.length ?? "—"))} />
                    <Field label="BIRTHDAY"     value={formatBirthday(user.birth_date ?? user.birthday)} />
                    <Field label="JOINED DATE"  value={formatDate(user.created_at)} />
                    <Field label="LAST LOGIN"   value={timeAgo(user.last_login_date ?? user.last_seen ?? user.last_login)} />
                  </div>
                </div>

                {/* Linked Children */}
                <div style={s.infoCard}>
                  <div style={s.cardHeader}>
                    <div style={s.infoIcon}>
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2.5">
                        <circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/>
                      </svg>
                    </div>
                    <span style={s.cardTitle}>Linked Children</span>
                  </div>
                  <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
                    {children === null ? (
                      <span style={s.dimText}>Loading…</span>
                    ) : children.length === 0 ? (
                      <span style={s.dimText}>No children linked to this account.</span>
                    ) : children.map(child => (
                      <div key={child.id} style={s.childRow}>
                        <div style={s.childAvatar}>
                          {child.picture
                            ? <img src={child.picture} alt="" style={{ width: "100%", height: "100%", borderRadius: "50%", objectFit: "cover" }} />
                            : <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.5">
                                <circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/>
                              </svg>
                          }
                        </div>
                        <div>
                          <div style={{ fontSize: 13, fontWeight: 600, color: "#1F2937" }}>{child.name || "—"}</div>
                          <div style={{ fontSize: 11, color: "#94a3b8" }}>
                            {[capitalize(child.level), child.grade, (child.subjects ?? [])[0]].filter(Boolean).join(", ") || "—"}
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* ── Reports tab ── */}
          {activeTab === "Reports" && (
            <div style={s.tabContent}>

              {/* Report list */}
              <div style={{ ...s.mainCol, gap: 10 }}>
                {reports === null ? (
                  <div style={s.emptyRow}>
                    <div style={s.emptyIcon}>
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.8">
                        <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
                      </svg>
                    </div>
                    <span style={s.emptyText}>Loading reports…</span>
                  </div>
                ) : reports.length === 0 ? (
                  <div style={s.emptyRow}>
                    <div style={s.emptyIcon}>
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.8">
                        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/>
                      </svg>
                    </div>
                    <span style={s.emptyText}>No reports filed against this user.</span>
                  </div>
                ) : reports.map(r => {
                  const ss = STATUS_STYLE[r.status] ?? STATUS_STYLE.pending;
                  const initials = (r.reporter_name || "?").split(" ").map(w => w[0]).join("").slice(0,2).toUpperCase();
                  return (
                    <div key={r.id} style={s.reportRow}>
                      <div style={s.reportAvatar}>{initials}</div>
                      <div style={s.reportMid}>
                        <div style={s.reportName}>{r.reporter_name || "Anonymous"}</div>
                        <div style={s.reportPreview}>{(r.text || "").slice(0, 55)}{(r.text || "").length > 55 ? " …" : ""}</div>
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

              {/* Reports stats card */}
              <div style={s.statsCard}>
                <div style={s.statsLabel}>TOTAL</div>
                <div style={s.statsTitle}>Reports</div>
                <div style={{ fontSize: 36, fontWeight: 800, color: "#fff", lineHeight: 1.1 }}>
                  {reports === null ? "—" : reports.length.toLocaleString()}
                </div>
                <div style={{ marginTop: 20, display: "flex", flexDirection: "column", gap: 10 }}>
                  {["pending","reviewed","resolved","dismissed"].map(st => {
                    const count = reports ? reports.filter(r => r.status === st).length : 0;
                    const ss = STATUS_STYLE[st];
                    return (
                      <div key={st} style={{ display:"flex", alignItems:"center", justifyContent:"space-between" }}>
                        <span style={{ fontSize:11, color:"#93c5fd", fontWeight:600, textTransform:"uppercase", letterSpacing:"0.04em" }}>{st}</span>
                        <span style={{ fontSize:14, fontWeight:700, color:"#fff" }}>{count}</span>
                      </div>
                    );
                  })}
                </div>
              </div>

            </div>
          )}

          {/* ── Activity detail (course clicked) ── */}
          {activeTab === "Activity" && selectedActivity && (
            <ServiceDetailPanel
              service={selectedActivity}
              tutorUid={selectedActivity.tutor_id}
              onBack={() => setSelectedActivity(null)}
              onViewUser={onViewUser}
            />
          )}

          {/* ── Activity tab (students) ── */}
          {activeTab === "Activity" && !selectedActivity && (
            <div style={s.tabContent}>
              <div style={{ ...s.mainCol, gap: 10 }}>
                {activity === null ? (
                  <div style={s.emptyRow}>
                    <div style={s.emptyIcon}>
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.8">
                        <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
                      </svg>
                    </div>
                    <span style={s.emptyText}>Loading courses…</span>
                  </div>
                ) : activity.length === 0 ? (
                  <div style={s.emptyRow}>
                    <div style={s.emptyIcon}>
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.8">
                        <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/>
                      </svg>
                    </div>
                    <span style={s.emptyText}>No courses enrolled yet.</span>
                  </div>
                ) : activity.map(item => (
                  <div key={item.id} style={s.svcRow}>
                    <div style={{ ...s.svcThumb(true), background: "linear-gradient(135deg,#1e3a5f,#2563eb)" }}>
                      {item.service_picture ?? item.thumbnail
                        ? <img src={item.service_picture ?? item.thumbnail} alt="" style={{ width:"100%", height:"100%", objectFit:"cover", borderRadius:10 }} />
                        : <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="1.8">
                            <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/>
                          </svg>
                      }
                    </div>
                    <div style={s.svcMid}>
                      <div style={s.svcName}>{item.name ?? item.service_name ?? item.course_name ?? "Untitled Course"}</div>
                      <div style={{ display:"flex", alignItems:"center", gap:6, marginTop:4 }}>
                        {item.tutor_picture && (
                          <img src={item.tutor_picture} alt="" style={{ width:18, height:18, borderRadius:"50%", objectFit:"cover" }} />
                        )}
                        <span style={{ fontSize:12, color:"#64748b" }}>{item.tutor_name ?? "—"}</span>
                        {isParent && item.enrolled_children?.length > 0 && (
                          <>
                            <span style={{ color:"#cbd5e1", fontSize:12 }}>·</span>
                            <span style={{ fontSize:12, color:"#000080", fontWeight:600 }}>
                              {item.enrolled_children.join(", ")}
                            </span>
                          </>
                        )}
                      </div>
                    </div>
                    <button style={s.eyeBtn} title="View course" onClick={() => setSelectedActivity(item)}>
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#000080" strokeWidth="1.8">
                        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                        <circle cx="12" cy="12" r="3"/>
                      </svg>
                    </button>
                  </div>
                ))}
              </div>

              {/* Courses stats card */}
              <div style={s.statsCard}>
                <div style={s.statsLabel}>TOTAL</div>
                <div style={s.statsTitle}>{isParent ? "Children's Courses" : "Courses"}</div>
                <div style={{ fontSize: 36, fontWeight: 800, color: "#fff", lineHeight: 1.1 }}>
                  {activity === null ? "—" : activity.length.toLocaleString()}
                </div>
                {isParent && activity !== null && activity.length > 0 && (
                  <div style={{ marginTop: 16, fontSize: 12, color: "#93c5fd" }}>
                    Across {[...new Set(activity.flatMap(a => a.enrolled_children ?? []))].length} child{[...new Set(activity.flatMap(a => a.enrolled_children ?? []))].length !== 1 ? "ren" : ""}
                  </div>
                )}
              </div>
            </div>
          )}

          {/* ── Services tab ── */}
          {activeTab === "Services" && !selectedService && (
            <div style={s.tabContent}>

              <div style={{ ...s.mainCol, gap: 10 }}>
                {services === null ? (
                  <div style={s.emptyRow}>
                    <div style={s.emptyIcon}>
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.8">
                        <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
                      </svg>
                    </div>
                    <span style={s.emptyText}>Loading services…</span>
                  </div>
                ) : services.length === 0 ? (
                  <div style={s.emptyRow}>
                    <div style={s.emptyIcon}>
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.8">
                        <rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/>
                      </svg>
                    </div>
                    <span style={s.emptyText}>No services created by this teacher.</span>
                  </div>
                ) : services.map(svc => (
                  <div key={svc.id} style={s.svcRow}>
                    <div style={s.svcThumb(svc.is_active)}>
                      {svc.picture
                        ? <img src={svc.picture} alt="" style={{ width:"100%", height:"100%", objectFit:"cover", borderRadius:10 }} />
                        : <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="1.8">
                            <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/>
                          </svg>
                      }
                    </div>
                    <div style={s.svcMid}>
                      <div style={s.svcName}>{svc.name || "Untitled Service"}</div>
                      <div style={s.svcMeta}>
                        {svc.subject && <span>{svc.subject}</span>}
                        {svc.level   && <><span style={s.metaDot}>·</span><span>{svc.level}</span></>}
                        <span style={s.metaDot}>·</span>
                        <span style={{ color: svc.is_active ? "#22c55e" : "#ef4444", fontWeight: 600 }}>
                          {svc.is_active ? "Active" : "Inactive"}
                        </span>
                      </div>
                    </div>
                    <div style={s.svcInfo}>
                      <span style={s.svcEnrolled}>{svc.enrolled_num ?? 0} / {svc.maxstudents ?? "—"}</span>
                      <span style={s.svcEnrolledLabel}>students</span>
                    </div>
                    <button style={s.eyeBtn} title="View service" onClick={() => setSelectedService(svc)}>
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#000080" strokeWidth="1.8">
                        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                        <circle cx="12" cy="12" r="3"/>
                      </svg>
                    </button>
                  </div>
                ))}
              </div>

              {/* Services stats card */}
              <div style={s.statsCard}>
                <div style={s.statsLabel}>OVERVIEW</div>
                <div style={s.statsTitle}>Services</div>
                <div style={{ fontSize: 36, fontWeight: 800, color: "#fff", lineHeight: 1.1, marginBottom: 20 }}>
                  {services === null ? "—" : services.length}
                </div>
                {[
                  { key: "Active",   val: services ? services.filter(sv => sv.is_active).length : "—" },
                  { key: "Inactive", val: services ? services.filter(sv => !sv.is_active).length : "—" },
                  { key: "Students", val: services ? services.reduce((acc, sv) => acc + (sv.enrolled_num ?? 0), 0) : "—" },
                ].map(({ key, val }) => (
                  <div key={key} style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:12 }}>
                    <span style={{ fontSize:11, color:"#93c5fd", fontWeight:600, textTransform:"uppercase", letterSpacing:"0.04em" }}>{key}</span>
                    <span style={{ fontSize:14, fontWeight:700, color:"#fff" }}>{val}</span>
                  </div>
                ))}
              </div>

            </div>
          )}

          {/* ── Service detail panel ── */}
          {activeTab === "Services" && selectedService && (
            <ServiceDetailPanel
              service={selectedService}
              tutorUid={tutorUid}
              onBack={() => setSelectedService(null)}
              onViewUser={onViewUser}
            />
          )}

          {/* ── Feedbacks tab ── */}
          {activeTab === "Feedbacks" && (
            <div style={s.tabContent}>

              <div style={{ ...s.mainCol, gap: 12 }}>
                {feedbacks === null ? (
                  <div style={s.emptyRow}>
                    <div style={s.emptyIcon}>
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.8">
                        <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
                      </svg>
                    </div>
                    <span style={s.emptyText}>Loading feedbacks…</span>
                  </div>
                ) : feedbacks.length === 0 ? (
                  <div style={s.emptyRow}>
                    <div style={s.emptyIcon}>
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.8">
                        <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
                      </svg>
                    </div>
                    <span style={s.emptyText}>No feedbacks yet for this teacher.</span>
                  </div>
                ) : feedbacks.map(fb => {
                  const name = fb.reviewer_name ?? fb.student_name ?? "Anonymous";
                  return (
                    <div key={fb.id} style={s.fbCard}>
                      <div style={s.fbHeader}>
                        <div style={s.fbLeft}>
                          {fb.reviewer_picture ?? fb.student_picture
                            ? <img src={fb.reviewer_picture ?? fb.student_picture} alt="avatar" style={s.fbAvatar} />
                            : <div style={s.fbAvatarFallback}>
                                {name.split(" ").map(w => w[0]).join("").slice(0,2).toUpperCase()}
                              </div>
                          }
                          <div>
                            <div style={s.fbName}>{name}</div>
                            <Stars rating={fb.rating ?? 5} />
                          </div>
                        </div>
                        <div style={s.fbRight}>
                          <span style={s.fbDate}>{timeAgo(fb.created_at)}</span>
                          <div style={s.fbDots}>
                            {[0,1,2].map(i => <span key={i} style={{ width:3, height:3, borderRadius:"50%", background:"#94a3b8", display:"block" }} />)}
                          </div>
                        </div>
                      </div>
                      {(fb.text ?? fb.comment) && (
                        <div style={s.fbText}>{fb.text ?? fb.comment}</div>
                      )}
                    </div>
                  );
                })}
              </div>

              {/* Quick Stats */}
              {isTeacher && <div style={s.statsCard}>
                <div style={s.statsLabel}>QUICK STATS</div>
                <div style={s.statsTitle}>Teacher Profile</div>
                <div style={s.statRow}>
                  <span style={s.statKey}>Students</span>
                  <span style={s.statVal}>{stats.students === null ? "—" : stats.students.toLocaleString()}</span>
                </div>
                <div style={s.statRow}>
                  <span style={s.statKey}>Rating</span>
                  <span style={s.statVal}>
                    {stats.rating == null ? "—" : `${Number(stats.rating).toFixed(1)} / 5.0`}
                  </span>
                </div>
                <div style={s.statRow}>
                  <span style={s.statKey}>Courses</span>
                  <span style={s.statVal}>{stats.courses === null ? "—" : stats.courses}</span>
                </div>
              </div>}

            </div>
          )}

          {!["General Info","Reports","Activity","Services","Feedbacks"].includes(activeTab) && (
            <div style={{ color: "#94a3b8", fontSize: 14, paddingTop: 40, textAlign: "center" }}>
              {activeTab} — coming soon.
            </div>
          )}

          </div>{/* end scrollArea */}
        </div>
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
                  style={{ ...s.contactBtn, marginTop:16, opacity: updatingReport ? 0.6 : 1 }}
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

    </div>
  );
}

function Field({ label, value }) {
  return (
    <div>
      <div style={{ fontSize: 10, fontWeight: 700, color: "#94a3b8", letterSpacing: "0.06em", marginBottom: 4 }}>{label}</div>
      <div style={{ fontSize: 13, fontWeight: 600, color: "#1F2937" }}>{value}</div>
    </div>
  );
}

const s = {
  page: { display: "flex", flexDirection: "column", height: "100%", minHeight: 0, gap: 16 },

  header: {
    display: "flex", alignItems: "flex-start", justifyContent: "space-between", flexShrink: 0,
  },
  breadcrumb: { display: "flex", alignItems: "center", gap: 6, marginBottom: 4 },
  breadLink: { fontSize: 12, color: "#94a3b8", cursor: "pointer" },
  breadSep: { fontSize: 12, color: "#cbd5e1" },
  breadCurrent: { fontSize: 12, color: "#000080", fontWeight: 600 },
  pageTitle: { fontSize: 28, fontWeight: 800, color: "#1F2937", margin: 0 },

  headerBtns: { display: "flex", gap: 10, alignItems: "center", paddingTop: 14 },
  contactBtn: {
    display: "flex", alignItems: "center", gap: 8,
    padding: "10px 20px", borderRadius: 24, border: "none",
    background: "#22c55e", color: "#fff", fontSize: 14, fontWeight: 600, cursor: "pointer",
  },
  suspendBtn: {
    display: "flex", alignItems: "center", gap: 8,
    padding: "10px 20px", borderRadius: 24, border: "none",
    background: "#ef4444", color: "#fff", fontSize: 14, fontWeight: 600, cursor: "pointer",
  },

  body: { display: "flex", gap: 20, flex: 1, minHeight: 0, overflow: "hidden" },

  /* left card */
  leftCard: {
    width: 230, flexShrink: 0, alignSelf: "flex-start",
    background: "#fff", borderRadius: 16, border: "1px solid #f1f5f9",
    padding: "20px 18px", display: "flex", flexDirection: "column", alignItems: "center",
    boxShadow: "0 2px 8px rgba(0,0,0,0.04)",
  },
  statusBadge: (suspended) => ({
    alignSelf: "flex-end",
    fontSize: 11, fontWeight: 700, letterSpacing: "0.06em",
    color: suspended ? "#ef4444" : "#22c55e",
    background: suspended ? "#fef2f2" : "#f0fdf4",
    borderRadius: 6, padding: "3px 10px", marginBottom: 12,
  }),
  avatar: { width: 80, height: 80, borderRadius: "50%", objectFit: "cover", marginBottom: 12 },
  avatarFallback: {
    width: 80, height: 80, borderRadius: "50%", background: "#000080",
    display: "flex", alignItems: "center", justifyContent: "center", marginBottom: 12,
  },
  name: { fontSize: 16, fontWeight: 700, color: "#1F2937", textAlign: "center", marginBottom: 6 },
  rolePill: {
    fontSize: 11, fontWeight: 600, color: "#6366f1", background: "#eef2ff",
    borderRadius: 20, padding: "3px 14px", marginBottom: 18,
  },
  contactRow: { display: "flex", alignItems: "flex-start", gap: 10, width: "100%", marginBottom: 12 },
  contactIcon: {
    width: 30, height: 30, borderRadius: 8, background: "#f8fafc",
    border: "1px solid #e2e8f0", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
  },
  contactLabel: { fontSize: 9, fontWeight: 700, color: "#94a3b8", letterSpacing: "0.06em", marginBottom: 2 },
  contactValue: { fontSize: 12, fontWeight: 600, color: "#1F2937" },
  descSection: { width: "100%", marginTop: 8 },
  descTitle: { fontSize: 12, fontWeight: 700, color: "#1F2937", marginBottom: 6 },
  descText: { fontSize: 12, color: "#64748b", lineHeight: 1.6 },

  /* right */
  right: { flex: 1, minWidth: 0, display: "flex", flexDirection: "column", gap: 14, minHeight: 0 },
  scrollArea: { flex: 1, minHeight: 0, overflowY: "auto", paddingRight: 6, paddingBottom: 8, display: "flex", flexDirection: "column", gap: 14 },

  tabsRow: {
    display: "flex", background: "#fff", borderRadius: 12,
    border: "1px solid #f1f5f9", padding: 4, gap: 2, flexShrink: 0,
    boxShadow: "0 2px 8px rgba(0,0,0,0.04)", alignSelf: "flex-start",
  },
  tab: {
    padding: "8px 20px", borderRadius: 9, border: "none",
    background: "transparent", fontSize: 13, fontWeight: 500,
    color: "#64748b", cursor: "pointer",
  },
  tabActive: { background: "#000080", color: "#fff", fontWeight: 600 },

  tabContent: { display: "flex", gap: 16, alignItems: "flex-start" },

  mainCol: { flex: 1, minWidth: 0, display: "flex", flexDirection: "column", gap: 14 },

  infoCard: {
    background: "#fff", borderRadius: 14, border: "1px solid #f1f5f9",
    padding: "18px 20px", boxShadow: "0 2px 8px rgba(0,0,0,0.04)",
  },
  cardHeader: { display: "flex", alignItems: "center", gap: 8, marginBottom: 16 },
  infoIcon: {
    width: 22, height: 22, borderRadius: "50%", background: "#6366f1",
    color: "#fff", fontSize: 13, fontWeight: 700,
    display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
  },
  cardTitle: { fontSize: 14, fontWeight: 700, color: "#1F2937" },
  infoGrid: { display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px 32px" },

  descCard: {
    background: "#fff", borderRadius: 14, border: "1px solid #f1f5f9",
    padding: "16px 20px", boxShadow: "0 2px 8px rgba(0,0,0,0.04)",
  },
  descBody: { fontSize: 13, color: "#64748b", lineHeight: 1.7, marginTop: 10 },

  certCard: {
    background: "#fff", borderRadius: 14, border: "1px solid #f1f5f9",
    padding: "16px 20px", boxShadow: "0 2px 8px rgba(0,0,0,0.04)",
  },
  certList: { display: "flex", flexWrap: "wrap", gap: 10, marginTop: 12 },
  certItem: {
    display: "flex", alignItems: "center", gap: 10,
    background: "#f8fafc", borderRadius: 10, border: "1px solid #e2e8f0",
    padding: "10px 12px", width: 180,
  },
  certIconWrap: {
    width: 36, height: 36, borderRadius: 8, background: "#eef2ff",
    display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
  },
  dlBtn: {
    background: "none", border: "none", cursor: "pointer",
    marginLeft: "auto", padding: 4, display: "flex",
  },
  dimText: { fontSize: 13, color: "#94a3b8" },

  childRow: {
    display: "flex", alignItems: "center", gap: 12,
    background: "#f8fafc", borderRadius: 10, border: "1px solid #e2e8f0",
    padding: "10px 14px",
  },
  childAvatar: {
    width: 36, height: 36, borderRadius: "50%", background: "#f1f5f9",
    border: "1px solid #e2e8f0", display: "flex", alignItems: "center",
    justifyContent: "center", flexShrink: 0, overflow: "hidden",
  },

  /* Quick Stats */
  statsCard: {
    width: 190, flexShrink: 0, background: "#000080", borderRadius: 14,
    padding: "20px 18px", color: "#fff",
  },
  statsLabel: { fontSize: 10, fontWeight: 700, color: "#93c5fd", letterSpacing: "0.08em", marginBottom: 6 },
  statsTitle: { fontSize: 20, fontWeight: 700, color: "#fff", marginBottom: 20, lineHeight: 1.3 },
  statRow: {
    display: "flex", alignItems: "center", justifyContent: "space-between",
    paddingBottom: 14, marginBottom: 14, borderBottom: "1px solid rgba(255,255,255,0.1)",
  },
  statKey: { fontSize: 13, color: "#93c5fd" },
  statVal: { fontSize: 18, fontWeight: 700, color: "#fff" },

  /* Reports */
  reportRow: {
    display: "flex", alignItems: "center", gap: 12,
    background: "#fff", borderRadius: 12, border: "1px solid #f1f5f9",
    padding: "12px 14px", boxShadow: "0 1px 4px rgba(0,0,0,0.04)",
  },
  reportAvatar: {
    width: 38, height: 38, borderRadius: "50%", background: "#eef2ff",
    color: "#6366f1", fontSize: 12, fontWeight: 700, flexShrink: 0,
    display: "flex", alignItems: "center", justifyContent: "center",
  },
  reportMid: { flex: 1, minWidth: 0 },
  reportName: { fontSize: 13, fontWeight: 600, color: "#1F2937", marginBottom: 2 },
  reportPreview: { fontSize: 12, color: "#94a3b8", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" },
  reportDate: { fontSize: 11, color: "#94a3b8", flexShrink: 0, whiteSpace: "nowrap" },
  statusPill: {
    fontSize: 10, fontWeight: 700, borderRadius: 6, padding: "3px 8px",
    letterSpacing: "0.04em", flexShrink: 0,
  },
  eyeBtn: { background: "none", border: "none", cursor: "pointer", padding: 4, display: "flex", alignItems: "center", flexShrink: 0 },

  /* Empty state row */
  emptyRow: {
    display: "flex", alignItems: "center", gap: 12,
    background: "#fff", borderRadius: 12, border: "1px solid #f1f5f9",
    padding: "16px 18px", boxShadow: "0 1px 4px rgba(0,0,0,0.04)",
  },
  emptyIcon: {
    width: 36, height: 36, borderRadius: 10, background: "#f8fafc",
    border: "1px solid #e2e8f0", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
  },
  emptyText: { fontSize: 13, color: "#94a3b8" },

  /* Services */
  svcRow: {
    display: "flex", alignItems: "center", gap: 14,
    background: "#fff", borderRadius: 12, border: "1px solid #f1f5f9",
    padding: "10px 14px", boxShadow: "0 1px 4px rgba(0,0,0,0.04)",
  },
  svcThumb: (active) => ({
    width: 52, height: 52, borderRadius: 10, flexShrink: 0, overflow: "hidden",
    background: active ? "linear-gradient(135deg,#059669,#10b981)" : "linear-gradient(135deg,#94a3b8,#cbd5e1)",
    display: "flex", alignItems: "center", justifyContent: "center",
  }),
  svcMid:  { flex: 1, minWidth: 0 },
  svcName: { fontSize: 13, fontWeight: 700, color: "#1F2937", marginBottom: 4, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" },
  svcMeta: { display: "flex", alignItems: "center", gap: 4, fontSize: 12, color: "#64748b" },
  metaDot: { color: "#cbd5e1" },
  svcInfo: { display: "flex", flexDirection: "column", alignItems: "flex-end", flexShrink: 0 },
  svcEnrolled:      { fontSize: 13, fontWeight: 700, color: "#1F2937" },
  svcEnrolledLabel: { fontSize: 10, color: "#94a3b8", letterSpacing: "0.04em" },

  /* Feedbacks */
  fbCard: {
    background: "#fff", borderRadius: 14, border: "1px solid #f1f5f9",
    padding: "16px 18px", boxShadow: "0 1px 4px rgba(0,0,0,0.04)",
  },
  fbHeader: { display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: 12 },
  fbLeft:   { display: "flex", alignItems: "center", gap: 12 },
  fbRight:  { display: "flex", alignItems: "center", gap: 12, flexShrink: 0 },
  fbAvatar: { width: 42, height: 42, borderRadius: "50%", objectFit: "cover", flexShrink: 0 },
  fbAvatarFallback: {
    width: 42, height: 42, borderRadius: "50%", background: "#000080",
    color: "#fff", fontSize: 13, fontWeight: 700,
    display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
  },
  fbName: { fontSize: 14, fontWeight: 700, color: "#1F2937", marginBottom: 4 },
  fbDate: { fontSize: 12, color: "#94a3b8", whiteSpace: "nowrap" },
  fbDots: { display: "flex", flexDirection: "column", gap: 3, padding: "4px 6px", cursor: "pointer" },
  fbText: { fontSize: 13, color: "#374151", lineHeight: 1.65, paddingTop: 4 },

  /* Modal */
  modalOverlay: {
    position: "fixed", inset: 0, background: "rgba(0,0,0,0.4)",
    display: "flex", alignItems: "center", justifyContent: "center", zIndex: 100,
  },
  modalBox: {
    background: "#fff", borderRadius: 18, padding: "28px 28px 24px",
    width: 480, maxWidth: "90vw", boxShadow: "0 20px 60px rgba(0,0,0,0.2)",
    display: "flex", flexDirection: "column",
  },
  modalHeader: { display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 20 },
  modalTitle: { fontSize: 18, fontWeight: 700, color: "#1F2937" },
  modalClose: {
    width: 30, height: 30, borderRadius: "50%", border: "none",
    background: "#f1f5f9", cursor: "pointer", fontSize: 14, color: "#64748b",
    display: "flex", alignItems: "center", justifyContent: "center",
  },
  modalMeta: { display: "flex", alignItems: "center", gap: 12, marginBottom: 16 },
  modalText: {
    fontSize: 14, color: "#374151", lineHeight: 1.7,
    background: "#f8fafc", borderRadius: 10, padding: "14px 16px",
    border: "1px solid #f1f5f9",
  },
};
