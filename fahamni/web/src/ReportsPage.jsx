import { useState, useEffect } from "react";
import { Search, Eye, X } from "lucide-react";
import { collection, query, where, getDocs, doc, updateDoc, getDoc, deleteDoc } from "firebase/firestore";
import { db } from "./firebase";
import { useTranslation } from "react-i18next";
import { syncSuspensionState } from "./suspensionNotifications";

const TYPE_STYLE = {
  teacher: { label: "ACCOUNT", color: "#6366f1", bg: "#eef2ff" },
  account: { label: "ACCOUNT", color: "#6366f1", bg: "#eef2ff" },
  comment: { label: "COMMENT", color: "#16a34a", bg: "#dcfce7" },
  session: { label: "SESSION", color: "#f59e0b", bg: "#fffbeb" },
};

const STATUS_STYLE = {
  pending:   { label: "PENDING",   color: "#f59e0b", bg: "#fff7ed" },
  reviewed:  { label: "REVIEWED",  color: "#16a34a", bg: "#dcfce7" },
  resolved:  { label: "RESOLVED",  color: "#06b6d4", bg: "#ecfeff" },
  dismissed: { label: "DISMISSED", color: "#94a3b8", bg: "#f1f5f9" },
};

const ROLE_STYLE = {
  teacher: { label: "TEACHER", color: "#7c3aed", bg: "#ede9fe" },
  tutor:   { label: "TEACHER", color: "#7c3aed", bg: "#ede9fe" },
  student: { label: "STUDENT", color: "#16a34a", bg: "#dcfce7" },
  parent:  { label: "PARENT",  color: "#db2777", bg: "#fce7f3" },
};

function formatDate(val) {
  if (!val) return "—";
  const d = val.toDate ? val.toDate() : new Date(val);
  if (isNaN(d)) return "—";
  return `${String(d.getMonth()+1).padStart(2,"0")}/${String(d.getDate()).padStart(2,"0")}/${d.getFullYear()}`;
}

function initials(name) {
  if (!name) return "?";
  const parts = name.trim().split(" ").filter(Boolean);
  if (parts.length >= 2) return `${parts[0][0]}${parts[parts.length-1][0]}`.toUpperCase();
  return name.slice(0, 2).toUpperCase();
}

function typeStyle(type) {
  return TYPE_STYLE[type?.toLowerCase()] ?? { label: (type ?? "—").toUpperCase(), color: "#64748b", bg: "#f1f5f9" };
}

// Searches tutors → students → parents for a UID, returns { col, role, name, picture, is_suspended }
async function resolveUser(uid) {
  if (!uid) return null;
  for (const [col, role] of [["tutors", "teacher"], ["students", "student"], ["parents", "parent"]]) {
    try {
      const snap = await getDoc(doc(db, col, uid));
      if (snap.exists()) {
        const d = snap.data();
        return {
          col,
          role,
          name: `${d.first_name ?? ""} ${d.last_name ?? ""}`.trim(),
          picture: d.picture ?? null,
          is_suspended: d.is_suspended ?? false,
        };
      }
    } catch { /* skip */ }
  }
  return null;
}

// Loads the actual review/feedback document referenced by a report
// Returns { col, id, data } or null
async function resolveReviewDoc(report) {
  const reviewId   = report.review_id;
  const feedbackId = report.feedback_id;

  if (reviewId) {
    try {
      const snap = await getDoc(doc(db, "reviews", reviewId));
      if (snap.exists()) return { col: "reviews", id: reviewId, data: snap.data() };
    } catch { /* skip */ }
  }

  if (feedbackId) {
    try {
      const snap = await getDoc(doc(db, "feedbacks", feedbackId));
      if (snap.exists()) return { col: "feedbacks", id: feedbackId, data: snap.data() };
    } catch { /* skip */ }
  }

  return null;
}

export default function ReportsPage() {
  const { t } = useTranslation();
  const [tab, setTab] = useState("pending");
  const [search, setSearch] = useState("");
  const [reports, setReports] = useState(null);
  const [pendingCount, setPendingCount] = useState(null);

  // modal state
  const [selected, setSelected] = useState(null);
  const [reporterInfo, setReporterInfo] = useState(null);   // resolved Firestore user for reporter
  const [reportedInfo, setReportedInfo] = useState(null);   // resolved Firestore user for reported
  const [reviewDoc, setReviewDoc] = useState(null);         // { col, id, data } for the referenced review
  const [actionLoading, setActionLoading] = useState(null);
  const [actionDone, setActionDone] = useState(null);

  // ── Load reports ──────────────────────────────────────────────────────────
  useEffect(() => {
    setReports(null);
    async function load() {
      try {
        let q;
        if (tab === "pending")
          q = query(collection(db, "reports"), where("status", "==", "pending"));
        else if (tab === "reviewed")
          q = query(collection(db, "reports"), where("status", "in", ["reviewed", "resolved", "dismissed"]));
        else
          q = collection(db, "reports");

        const snap = await getDocs(q);
        const list = snap.docs
          .map(d => ({ id: d.id, ...d.data() }))
          .sort((a, b) => (b.created_at?.seconds ?? 0) - (a.created_at?.seconds ?? 0));
        setReports(list);
      } catch (e) {
        console.error("Reports fetch:", e);
        setReports([]);
      }
    }
    load();
  }, [tab]);

  // keep pending count fresh for the banner (runs on every tab switch)
  useEffect(() => {
    getDocs(query(collection(db, "reports"), where("status", "==", "pending")))
      .then(s => setPendingCount(s.size))
      .catch(() => setPendingCount(0));
  }, [tab]);

  // ── Resolve user + review doc when a report is selected ──────────────────
  useEffect(() => {
    if (!selected) {
      setReporterInfo(null);
      setReportedInfo(null);
      setReviewDoc(null);
      setActionDone(null);
      return;
    }
    setReporterInfo(null);
    setReportedInfo(null);
    setReviewDoc(null);
    setActionDone(null);

    resolveUser(selected.reporter_uid).then(setReporterInfo);
    resolveUser(selected.reported_id).then(setReportedInfo);
    resolveReviewDoc(selected).then(setReviewDoc);
  }, [selected]);

  // ── Derived ───────────────────────────────────────────────────────────────
  const filtered = (reports ?? []).filter(r => {
    const q = search.toLowerCase();
    if (!q) return true;
    return (r.reporter_name ?? "").toLowerCase().includes(q) ||
           (r.reported_name ?? "").toLowerCase().includes(q);
  });

  // A report is "comment-type" if it explicitly says so, or if there's a review doc attached
  const hasReviewRef = selected && (selected.review_id || selected.feedback_id);
  const isComment = selected && (
    selected.type === "comment" ||
    hasReviewRef ||
    selected.rating != null
  );

  // The actual comment/rating to show in the modal
  const commentText  = reviewDoc?.data?.comment ?? reviewDoc?.data?.text ?? selected?.text ?? "";
  const commentRating = reviewDoc?.data?.rating ?? selected?.rating ?? null;
  const isHidden     = reviewDoc?.data?.is_hidden === true;

  // ── Actions ───────────────────────────────────────────────────────────────
  async function markReviewed(reportId) {
    await updateDoc(doc(db, "reports", reportId), { status: "reviewed" });
    setReports(prev => tab === "pending"
      ? prev?.filter(r => r.id !== reportId)
      : prev?.map(r => r.id === reportId ? { ...r, status: "reviewed" } : r)
    );
    setSelected(r => r ? { ...r, status: "reviewed" } : r);
    setPendingCount(count => count == null ? count : Math.max(0, count - 1));
  }

  async function handleMarkReviewed() {
    if (!selected) return;
    setActionLoading("review");
    try {
      await markReviewed(selected.id);
      setActionDone("reviewed");
    } catch (e) { console.error(e); }
    finally { setActionLoading(null); }
  }

  async function handleDeleteFeedback() {
    if (!reviewDoc) return;
    setActionLoading("deleteFeedback");
    try {
      await deleteDoc(doc(db, reviewDoc.col, reviewDoc.id));
      setReviewDoc(null);
      await markReviewed(selected.id);
      setActionDone("feedbackDeleted");
    } catch (e) { console.error(e); }
    finally { setActionLoading(null); }
  }

  async function handleAvert() {
    if (!selected) return;
    setActionLoading("avert");
    try {
      await markReviewed(selected.id);
      setActionDone("averted");
    } catch (e) { console.error(e); }
    finally { setActionLoading(null); }
  }

  async function handleSuspend() {
    if (!selected) return;
    setActionLoading("suspend");
    try {
      // Use already-resolved info, or try again if it wasn't found yet
      let info = reportedInfo;
      if (!info) info = await resolveUser(selected.reported_id);

      if (info?.col) {
        await updateDoc(doc(db, info.col, selected.reported_id), { is_suspended: true });
        await syncSuspensionState(selected.reported_id, true);
        setReportedInfo(r => r ? { ...r, is_suspended: true } : { ...info, is_suspended: true });
      }
      await markReviewed(selected.id);
      setActionDone("suspended");
    } catch (e) { console.error(e); }
    finally { setActionLoading(null); }
  }

  // ── Render ────────────────────────────────────────────────────────────────
  return (
    <div style={s.page}>

      {/* Toolbar */}
      <div className="page-toolbar">
        <div style={s.searchWrap}>
          <Search size={15} color="#94a3b8" style={{ position:"absolute", left:14, top:"50%", transform:"translateY(-50%)" }} />
          <input
            style={s.search}
            placeholder={t("reports.searchPlaceholder")}
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>
        <div className="page-tabs">
          {[["pending","reports.tabs.pending"],["reviewed","reports.tabs.reviewed"],["all","reports.tabs.all"]].map(([val, labelKey]) => (
            <button
              key={val}
              style={{ ...s.tabBtn, ...(tab === val ? s.tabActive : {}) }}
              onClick={() => setTab(val)}
            >
              {t(labelKey)}
            </button>
          ))}
        </div>
      </div>

      {/* Urgent banner */}
      {pendingCount != null && pendingCount > 0 && tab !== "reviewed" && (
        <div style={s.urgentBanner}>
          <span style={s.urgentStar}>✱</span>
          <div>
            <div style={s.urgentTitle}>{t("reports.urgentReport", { count: pendingCount })}</div>
            <div style={s.urgentSub}>{t("reports.waitingReview")}</div>
          </div>
        </div>
      )}

      {/* Table */}
      <div className="table-scroll">
        <div className="table-scroll-inner thin-scroll">
        <div className="table-min">
        <div style={s.tableHead}>
          <span style={{ ...s.col, flex: 2.2 }}>{t("reports.table.reporter")}</span>
          <span style={{ ...s.col, flex: 1   }}>{t("reports.table.type")}</span>
          <span style={{ ...s.col, flex: 2.2 }}>{t("reports.table.reported")}</span>
          <span style={{ ...s.col, flex: 1.4 }}>{t("reports.table.date")}</span>
          {tab === "all" && <span style={{ ...s.col, flex: 1.2 }}>{t("reports.table.status")}</span>}
          <span style={{ ...s.col, flex: 0.6, textAlign:"center" }}>{t("reports.table.actions")}</span>
        </div>

        <div style={s.tableBody}>
          {reports === null ? (
            <div style={s.empty}>{t("reports.loading")}</div>
          ) : filtered.length === 0 ? (
            <div style={s.empty}>{t("reports.noReportsFound", { tab: tab === "all" ? "" : t(`reports.tabs.${tab}`) })}</div>
          ) : filtered.map(r => {
            const ts = typeStyle(r.type);
            const ss = STATUS_STYLE[r.status] ?? STATUS_STYLE.pending;
            return (
              <div key={r.id} style={s.row}>

                {/* Reporter */}
                <div style={{ ...s.cell, flex: 2.2, gap: 10 }}>
                  <Avatar name={r.reporter_name} picture={r.reporter_picture} />
                  <div style={{ minWidth: 0 }}>
                    <div style={s.name}>{r.reporter_name || t("reports.unknown")}</div>
                    {r.reporter_role && <RoleBadge role={r.reporter_role} />}
                  </div>
                </div>

                {/* Type */}
                <div style={{ ...s.cell, flex: 1 }}>
                  <span style={{ ...s.typeBadge, color: ts.color, background: ts.bg }}>{ts.label}</span>
                </div>

                {/* Reported */}
                <div style={{ ...s.cell, flex: 2.2, gap: 10 }}>
                  <Avatar name={r.reported_name} picture={r.reported_picture} />
                  <div style={{ minWidth: 0 }}>
                    <div style={s.name}>{r.reported_name || t("reports.unknown")}</div>
                    {r.reported_role && <RoleBadge role={r.reported_role} />}
                  </div>
                </div>

                {/* Date */}
                <div style={{ ...s.cell, flex: 1.4 }}>
                  <span style={s.date}>{formatDate(r.created_at)}</span>
                </div>

                {/* Status — All tab only */}
                {tab === "all" && (
                  <div style={{ ...s.cell, flex: 1.2 }}>
                    <span style={{ ...s.statusBadge, color: ss.color, background: ss.bg }}>{ss.label}</span>
                  </div>
                )}

                {/* Eye */}
                <div style={{ ...s.cell, flex: 0.6, justifyContent:"center" }}>
                  <button style={s.eyeBtn} title="View report" onClick={() => setSelected(r)}>
                    <Eye size={20} color="#000080" strokeWidth={1.8} />
                  </button>
                </div>
              </div>
            );
          })}
        </div>
        </div>{/* table-min */}
        </div>{/* table-scroll-inner */}
      </div>

      {/* ── Detail Modal ─────────────────────────────────────────────────────── */}
      {selected && (
        <div style={s.overlay} onClick={e => { if (e.target === e.currentTarget) setSelected(null); }}>
          <div style={s.modal}>

            {/* Header */}
            <div style={s.modalHeader}>
              <span style={s.modalTitle}>{t("reports.reportDetails")}</span>
              <button style={s.closeBtn} onClick={() => setSelected(null)}>
                <X size={16} color="#64748b" />
              </button>
            </div>

            {/* Reporter */}
            <div style={s.modalRow}>
              <span style={s.modalLabel}>REPORTER :</span>
              <div style={s.modalUser}>
                <Avatar name={selected.reporter_name} picture={reporterInfo?.picture} size={36} />
                <div>
                  <div style={s.modalName}>{selected.reporter_name || t("reports.unknown")}</div>
                  <div style={s.modalRole}>
                    {reporterInfo
                      ? (ROLE_STYLE[reporterInfo.role]?.label ?? reporterInfo.role.toUpperCase())
                      : (selected.reporter_role?.toUpperCase() ?? "")}
                  </div>
                </div>
              </div>
            </div>

            {/* Reported */}
            <div style={s.modalRow}>
              <span style={s.modalLabel}>REPORTED :</span>
              <div style={s.modalUser}>
                <Avatar name={selected.reported_name} picture={reportedInfo?.picture} size={36} />
                <div>
                  <div style={s.modalName}>{selected.reported_name || t("reports.unknown")}</div>
                  <div style={s.modalRole}>
                    {reportedInfo
                      ? (ROLE_STYLE[reportedInfo.role]?.label ?? reportedInfo.role.toUpperCase())
                      : (selected.reported_role?.toUpperCase() ?? "")}
                  </div>
                </div>
              </div>
            </div>

            {/* Content */}
            <div style={s.modalContent}>
              {isComment ? (
                <>
                  {/* Stars */}
                  {commentRating != null && (
                    <div style={{ display:"flex", gap:2, marginBottom:8 }}>
                      {[1,2,3,4,5].map(i => (
                        <span key={i} style={{ fontSize:16, color: i <= Math.round(commentRating) ? "#f59e0b" : "#e2e8f0" }}>★</span>
                      ))}
                    </div>
                  )}

                  {/* Comment box */}
                  <div style={{ ...s.commentBox, opacity: isHidden ? 0.5 : 1 }}>
                    {isHidden
                      ? <em style={{ color:"#94a3b8" }}>{t("reports.commentHidden")}</em>
                      : commentText || t("reports.noCommentText")}
                  </div>

                  {/* Delete feedback when there's a real Firestore doc to update */}
                  {hasReviewRef && reviewDoc && (
                    <button
                      style={{ ...s.hideToggleBtn, ...s.hideToggleBtnHide }}
                      disabled={actionLoading === "deleteFeedback"}
                      onClick={handleDeleteFeedback}
                    >
                      {actionLoading === "deleteFeedback"
                        ? t("reports.updating")
                        : "Delete feedback"}
                    </button>
                  )}
                </>
              ) : (
                <>
                  <div style={s.descTitle}>{t("reports.reportDescription")}</div>
                  <div style={s.descText}>{selected.text || t("reports.noDescription")}</div>
                </>
              )}
            </div>

            {/* Action feedback */}
            {actionDone && (
              <div style={s.actionFeedback}>
                {actionDone === "averted"   && t("reports.averted")}
                {actionDone === "suspended" && t("reports.suspended")}
                {actionDone === "reviewed"  && "Report marked as reviewed."}
                {actionDone === "feedbackDeleted" && "Feedback deleted and report marked as reviewed."}
              </div>
            )}

            {/* Buttons */}
            {!actionDone && (
              <div style={s.modalActions}>
                <button
                  style={{ ...s.modalBtn, ...s.modalBtnOutline }}
                  disabled={!!actionLoading || selected.status === "reviewed"}
                  onClick={handleMarkReviewed}
                >
                  {actionLoading === "review"
                    ? t("reports.processing")
                    : selected.status === "reviewed"
                    ? "Already reviewed"
                    : "Mark as reviewed"}
                </button>
                <button
                  style={{ ...s.modalBtn, ...s.modalBtnOutline }}
                  disabled={!!actionLoading}
                  onClick={handleAvert}
                >
                  {actionLoading === "avert" ? t("reports.processing") : t("reports.avertUser")}
                </button>
                <button
                  style={{
                    ...s.modalBtn,
                    ...s.modalBtnDanger,
                    ...(reportedInfo?.is_suspended ? { opacity: 0.5, cursor: "not-allowed" } : {}),
                  }}
                  disabled={!!actionLoading || reportedInfo?.is_suspended === true}
                  onClick={handleSuspend}
                >
                  {reportedInfo?.is_suspended
                    ? t("reports.alreadySuspended")
                    : actionLoading === "suspend"
                    ? t("reports.suspending")
                    : t("reports.suspendUser")}
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// ── Small components ──────────────────────────────────────────────────────────

function Avatar({ name, picture, size = 38 }) {
  return picture ? (
    <img
      src={picture}
      alt="avatar"
      style={{ width:size, height:size, borderRadius:"50%", objectFit:"cover", flexShrink:0 }}
    />
  ) : (
    <div style={{
      width:size, height:size, borderRadius:"50%", background:"#000080",
      color:"#fff", display:"flex", alignItems:"center", justifyContent:"center",
      fontSize: size > 30 ? 12 : 10, fontWeight:700, flexShrink:0,
    }}>
      {initials(name)}
    </div>
  );
}

function RoleBadge({ role }) {
  const rs = ROLE_STYLE[role?.toLowerCase()] ?? { label: role?.toUpperCase() ?? "", color: "#64748b", bg: "#f1f5f9" };
  return (
    <span style={{
      fontSize:9, fontWeight:700, color:rs.color, background:rs.bg,
      borderRadius:4, padding:"1px 5px", letterSpacing:"0.04em",
    }}>
      {rs.label}
    </span>
  );
}

// ── Styles ────────────────────────────────────────────────────────────────────
const s = {
  page: { display:"flex", flexDirection:"column", height:"100%", minHeight:0 },

  toolbar: { display:"flex", alignItems:"center", gap:16, marginBottom:16 },
  searchWrap: { position:"relative", flex:1, maxWidth:460 },
  search: {
    width:"100%", height:40, paddingLeft:38, paddingRight:16,
    border:"1px solid #e2e8f0", borderRadius:20, background:"#f8fafc",
    fontSize:13, color:"#1F2937", outline:"none", boxSizing:"border-box",
  },
  tabs: { display:"flex", gap:8 },
  tabBtn: {
    padding:"8px 20px", borderRadius:20, border:"1.5px solid #e2e8f0",
    background:"#fff", fontSize:13, fontWeight:500, color:"#64748b", cursor:"pointer",
  },
  tabActive: { background:"#000080", borderColor:"#000080", color:"#fff" },

  urgentBanner: {
    display:"flex", alignItems:"center", gap:14,
    background:"#fff5f5", border:"1px solid #fecaca",
    borderRadius:12, padding:"14px 20px", marginBottom:16, flexShrink:0,
  },
  urgentStar: { fontSize:20, color:"#dc2626", flexShrink:0 },
  urgentTitle: { fontSize:14, fontWeight:700, color:"#dc2626" },
  urgentSub:   { fontSize:12, color:"#ef4444" },

  tableWrap: {
    flex:1, minHeight:0, background:"#fff", borderRadius:16,
    border:"1px solid #f1f5f9", display:"flex", flexDirection:"column", overflow:"hidden",
  },
  tableHead: {
    display:"flex", alignItems:"center", padding:"12px 24px",
    background:"#f8fafc", borderBottom:"1px solid #f1f5f9", flexShrink:0,
  },
  col: { fontSize:11, fontWeight:700, color:"#94a3b8", letterSpacing:"0.06em" },
  tableBody: { flex:1, overflowY:"auto" },

  row: { display:"flex", alignItems:"center", padding:"13px 24px", borderBottom:"1px solid #f8fafc" },
  cell: { display:"flex", alignItems:"center", minWidth:0 },
  name: { fontSize:13, fontWeight:600, color:"#1F2937", overflow:"hidden", textOverflow:"ellipsis", whiteSpace:"nowrap" },
  date: { fontSize:13, color:"#64748b" },

  typeBadge:   { fontSize:10, fontWeight:700, borderRadius:6, padding:"3px 10px", letterSpacing:"0.04em" },
  statusBadge: { fontSize:10, fontWeight:700, borderRadius:6, padding:"3px 10px", letterSpacing:"0.04em" },
  eyeBtn: { background:"none", border:"none", cursor:"pointer", padding:4, display:"flex", alignItems:"center" },
  empty: { padding:"48px 0", textAlign:"center", color:"#94a3b8", fontSize:14 },

  // Modal
  overlay: {
    position:"fixed", inset:0, background:"rgba(0,0,0,0.35)",
    display:"flex", alignItems:"center", justifyContent:"center", zIndex:100,
  },
  modal: {
    background:"#fff", borderRadius:20, padding:"28px 32px",
    width:440, maxWidth:"90vw", boxShadow:"0 20px 60px rgba(0,0,0,0.15)",
    display:"flex", flexDirection:"column", gap:16,
  },
  modalHeader: { display:"flex", alignItems:"center", justifyContent:"space-between" },
  modalTitle:  { fontSize:17, fontWeight:700, color:"#1F2937" },
  closeBtn: { background:"none", border:"none", cursor:"pointer", padding:4, display:"flex", alignItems:"center", borderRadius:6 },

  modalRow:  { display:"flex", alignItems:"center", gap:12 },
  modalLabel:{ fontSize:12, fontWeight:700, color:"#94a3b8", width:90, flexShrink:0, letterSpacing:"0.04em" },
  modalUser: { display:"flex", alignItems:"center", gap:10 },
  modalName: { fontSize:13, fontWeight:600, color:"#1F2937" },
  modalRole: { fontSize:10, fontWeight:700, color:"#64748b", marginTop:1, letterSpacing:"0.04em" },

  modalContent: { background:"#f8fafc", borderRadius:12, padding:"16px", display:"flex", flexDirection:"column", gap:10 },
  descTitle: { fontSize:12, fontWeight:700, color:"#1F2937" },
  descText:  { fontSize:13, color:"#475569", lineHeight:1.6, wordBreak:"break-word", overflowWrap:"break-word" },
  commentBox: {
    fontSize:13, color:"#475569", lineHeight:1.6,
    background:"#fff", borderRadius:8, padding:"12px 14px",
    border:"1px solid #e2e8f0", wordBreak:"break-word", overflowWrap:"break-word",
  },

  hideToggleBtn: {
    alignSelf:"flex-start", padding:"7px 16px", borderRadius:20,
    fontSize:12, fontWeight:600, cursor:"pointer", border:"none",
  },
  hideToggleBtnHide:   { background:"#fef2f2", color:"#dc2626" },
  hideToggleBtnUnhide: { background:"#f0fdf4", color:"#16a34a" },

  actionFeedback: {
    fontSize:13, fontWeight:500, color:"#16a34a",
    background:"#f0fdf4", borderRadius:8, padding:"10px 14px",
  },
  modalActions: { display:"flex", gap:10 },
  modalBtn: {
    flex:1, padding:"10px 0", borderRadius:24, fontSize:13, fontWeight:600,
    cursor:"pointer", textAlign:"center", whiteSpace:"nowrap",
  },
  modalBtnOutline: { background:"#fff", border:"1.5px solid #e2e8f0", color:"#1F2937" },
  modalBtnDanger:  { background:"#dc2626", border:"none", color:"#fff" },
};
