import { useState, useEffect } from "react";
import { collection, query, where, getDocs, updateDoc, doc, getCountFromServer } from "firebase/firestore";
import { db } from "./firebase";
import { useTranslation } from "react-i18next";

const PAGE_SIZE = 10;

const ROLE_STYLE = {
  teacher: { label: "TEACHER", color: "#7c3aed", bg: "#ede9fe" },
  student: { label: "STUDENT", color: "#16a34a", bg: "#dcfce7" },
  parent:  { label: "PARENT",  color: "#db2777", bg: "#fce7f3" },
};

const MONTHS = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];

function formatJoined(val) {
  if (!val) return null;
  const d = val.toDate ? val.toDate() : new Date(val);
  if (isNaN(d)) return null;
  return `${MONTHS[d.getMonth()]} ${String(d.getDate()).padStart(2,"0")}, ${d.getFullYear()}`;
}

export default function UsersPage({ onSelect, initialTab }) {
  const { t } = useTranslation();
  const [tab, setTab]       = useState(initialTab ?? "all");
  const [search, setSearch] = useState("");
  const [users, setUsers]   = useState(null);
  const [stats, setStats]   = useState({ total: null, teachers: null, students: null, suspended: null });
  const [page, setPage]     = useState(1);
  const [toggling, setToggling] = useState(null);

  // ── Counts ──────────────────────────────────────────────
  useEffect(() => {
    async function fetchStats() {
      const safeCount = async (ref) => {
        try { return (await getCountFromServer(ref)).data().count; }
        catch { return 0; }
      };
      const [teachers, students, parents, suspT, suspS, suspP] = await Promise.all([
        safeCount(collection(db, "tutors")),
        safeCount(collection(db, "students")),
        safeCount(collection(db, "parents")),
        safeCount(query(collection(db, "tutors"),   where("is_suspended", "==", true))),
        safeCount(query(collection(db, "students"), where("is_suspended", "==", true))),
        safeCount(query(collection(db, "parents"),  where("is_suspended", "==", true))),
      ]);
      setStats({ total: teachers + students + parents, teachers, students, suspended: suspT + suspS + suspP });
    }
    fetchStats();
  }, []);

  // ── Users ────────────────────────────────────────────────
  useEffect(() => {
    setUsers(null);
    setPage(1);
    async function fetchUsers() {
      try {
        const makeQ = (col) =>
          tab === "suspended"
            ? query(collection(db, col), where("is_suspended", "==", true))
            : collection(db, col);

        const [tSnap, sSnap, pSnap] = await Promise.all([
          getDocs(makeQ("tutors")),
          getDocs(makeQ("students")),
          getDocs(makeQ("parents")),
        ]);

        const merge = (snap, role, col) =>
          snap.docs.map(d => ({ id: d.id, ...d.data(), col, role }));

        const all = [
          ...merge(tSnap, "teacher", "tutors"),
          ...merge(sSnap, "student", "students"),
          ...merge(pSnap, "parent",  "parents"),
        ].sort((a, b) => (b.created_at?.seconds ?? 0) - (a.created_at?.seconds ?? 0));

        setUsers(all);
      } catch (e) {
        console.error(e);
        setUsers([]);
      }
    }
    fetchUsers();
  }, [tab]);

  // ── Filter ───────────────────────────────────────────────
  const filtered = (users ?? []).filter(u => {
    if (tab === "active" && u.is_suspended === true) return false;
    const name  = `${u.first_name ?? ""} ${u.last_name ?? ""}`.toLowerCase();
    const email = (u.email ?? "").toLowerCase();
    const q = search.toLowerCase();
    return !q || name.includes(q) || email.includes(q);
  });

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const paginated  = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

  // ── Toggle suspend ────────────────────────────────────────
  async function toggleSuspend(u) {
    setToggling(u.id);
    const next = !u.is_suspended;
    try {
      await updateDoc(doc(db, u.col, u.id), { is_suspended: next });
      setUsers(prev => prev.map(x => x.id === u.id ? { ...x, is_suspended: next } : x));
      setStats(s => ({ ...s, suspended: (s.suspended ?? 0) + (next ? 1 : -1) }));
    } catch (e) {
      console.error(e);
    } finally {
      setToggling(null);
    }
  }

  // ── Pagination numbers ────────────────────────────────────
  function pageNums() {
    if (totalPages <= 5) return Array.from({ length: totalPages }, (_, i) => i + 1);
    if (page <= 3)                 return [1, 2, 3, "...", totalPages];
    if (page >= totalPages - 2)    return [1, "...", totalPages - 2, totalPages - 1, totalPages];
    return [1, "...", page - 1, page, page + 1, "...", totalPages];
  }

  return (
    <div style={s.page}>

      {/* ── Toolbar ── */}
      <div className="page-toolbar">
        <div style={s.searchWrap}>
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="2"
            style={{ position:"absolute", left:14, top:"50%", transform:"translateY(-50%)" }}>
            <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
          </svg>
          <input
            style={s.search}
            placeholder={t("users.searchPlaceholder")}
            value={search}
            onChange={e => { setSearch(e.target.value); setPage(1); }}
          />
        </div>
        <div className="page-tabs">
          {["all","active","suspended"].map(tabKey => (
            <button
              key={tabKey}
              style={{ ...s.tabBtn, ...(tab === tabKey ? s.tabActive : {}) }}
              onClick={() => setTab(tabKey)}
            >
              {t(`users.tabs.${tabKey}`)}
            </button>
          ))}
        </div>
      </div>

      {/* ── Stat cards ── */}
      <div className="users-stats-grid">
        <StatCard label={t("users.stats.totalUsers")}  value={stats.total}     accent="#6366f1" bold />
        <StatCard label={t("users.stats.teachers")}   value={stats.teachers}  accent="#6366f1" sub={t("users.stats.activeEducators")} />
        <StatCard label={t("users.stats.students")}   value={stats.students}  accent="#6366f1" sub={t("users.stats.enrolledLearners")} />
        <StatCard label={t("users.stats.suspended")}  value={stats.suspended} accent="#ef4444" sub={t("users.stats.requiresReview")} red />
      </div>

      {/* ── Table ── */}
      <div className="table-scroll">
        <div className="table-scroll-inner thin-scroll">
        <div className="table-min">
        <div style={s.tableHead}>
          <span style={{ ...s.col, flex: 2.5 }}>{t("users.table.userProfile")}</span>
          <span style={{ ...s.col, flex: 1.1 }}>{t("users.table.role")}</span>
          <span style={{ ...s.col, flex: 2   }}>{t("users.table.contact")}</span>
          <span style={{ ...s.col, flex: 1.2 }}>{t("users.table.status")}</span>
          <span style={{ ...s.col, flex: 1, textAlign:"center" }}>{t("users.table.actions")}</span>
        </div>

        <div style={s.tableBody}>
          {users === null ? (
            <div style={s.empty}>{t("users.loading")}</div>
          ) : paginated.length === 0 ? (
            <div style={s.empty}>{t("users.noUsersFound")}</div>
          ) : paginated.map(u => {
            const rs = ROLE_STYLE[u.role];
            const suspended = u.is_suspended === true;
            const joined = formatJoined(u.created_at);
            return (
              <div key={`${u.col}-${u.id}`} style={s.row}>

                {/* Profile */}
                <div style={{ ...s.cell, flex: 2.5, gap: 12 }}>
                  {u.picture
                    ? <img src={u.picture} alt="avatar" style={s.avatar} />
                    : <div style={s.avatarFallback}>
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="1.6">
                          <circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/>
                        </svg>
                      </div>
                  }
                  <div>
                    <div style={s.name}>{u.first_name} {u.last_name}</div>
                    {joined && <div style={s.joined}>{t("users.joined")} {joined.toUpperCase()}</div>}
                  </div>
                </div>

                {/* Role */}
                <div style={{ ...s.cell, flex: 1.1 }}>
                  <span style={{ ...s.roleBadge, color: rs.color, background: rs.bg }}>{rs.label}</span>
                </div>

                {/* Contact */}
                <div style={{ ...s.cell, flex: 2 }}>
                  <span style={s.email}>{u.email || "—"}</span>
                </div>

                {/* Status */}
                <div style={{ ...s.cell, flex: 1.2, gap: 6 }}>
                  <span style={{ ...s.statusDot, background: suspended ? "#ef4444" : "#22c55e" }} />
                  <span style={{ fontSize: 13, fontWeight: 500, color: suspended ? "#ef4444" : "#22c55e" }}>
                    {suspended ? t("users.suspendedStatus") : t("users.activeStatus")}
                  </span>
                </div>

                {/* Actions */}
                <div style={{ ...s.cell, flex: 1, justifyContent:"center", gap: 14 }}>
                  <button style={s.eyeBtn} title="View profile" onClick={() => onSelect?.(u)}>
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#000080" strokeWidth="1.8">
                      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                      <circle cx="12" cy="12" r="3"/>
                    </svg>
                  </button>
                  <Toggle
                    on={!suspended}
                    disabled={toggling === u.id}
                    onClick={() => toggleSuspend(u)}
                  />
                </div>
              </div>
            );
          })}
        </div>

        {/* ── Pagination ── */}
        {filtered.length > 0 && (
          <div style={s.pagin}>
            <span style={s.paginInfo}>
              {t("users.showing", { from: Math.min((page-1)*PAGE_SIZE+1, filtered.length), to: Math.min(page*PAGE_SIZE, filtered.length), total: filtered.length })}
            </span>
            <div style={s.paginBtns}>
              <button style={s.paginArrow} disabled={page === 1} onClick={() => setPage(p => p-1)}>‹</button>
              {pageNums().map((p, i) =>
                p === "..." ? (
                  <span key={`d${i}`} style={s.paginDots}>…</span>
                ) : (
                  <button
                    key={p}
                    style={{ ...s.paginBtn, ...(p === page ? s.paginBtnActive : {}) }}
                    onClick={() => setPage(p)}
                  >
                    {p}
                  </button>
                )
              )}
              <button style={s.paginArrow} disabled={page >= totalPages} onClick={() => setPage(p => p+1)}>›</button>
            </div>
          </div>
        )}
        </div>{/* table-min */}
        </div>{/* table-scroll-inner */}
      </div>
    </div>
  );
}

function StatCard({ label, sub, value, accent, bold, red }) {
  return (
    <div style={{ ...s.statCard, borderLeft: `3.5px solid ${accent}` }}>
      <div style={{ fontSize: 11, fontWeight: 700, color: "#94a3b8", letterSpacing: "0.06em", marginBottom: 8 }}>{label}</div>
      <div style={{ fontSize: bold ? 32 : 28, fontWeight: 700, color: red ? "#ef4444" : "#1F2937", lineHeight: 1.1, marginBottom: 4 }}>
        {value === null ? "—" : value.toLocaleString()}
      </div>
      {sub && <div style={{ fontSize: 12, color: red ? "#ef4444" : "#64748b" }}>{sub}</div>}
    </div>
  );
}

function Toggle({ on, disabled, onClick }) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      style={{
        width: 40, height: 22, borderRadius: 11, border: "none",
        background: on ? "#000080" : "#cbd5e1",
        cursor: disabled ? "not-allowed" : "pointer",
        position: "relative", transition: "background 0.2s",
        flexShrink: 0, opacity: disabled ? 0.6 : 1,
        padding: 0,
      }}
    >
      <span style={{
        position: "absolute", top: 3,
        left: on ? 21 : 3,
        width: 16, height: 16, borderRadius: "50%", background: "#fff",
        transition: "left 0.2s", boxShadow: "0 1px 3px rgba(0,0,0,0.2)",
        display: "block",
      }} />
    </button>
  );
}

const s = {
  page: { display:"flex", flexDirection:"column", height:"100%", minHeight:0 },

  toolbar: { display:"flex", alignItems:"center", gap:16, marginBottom:20 },
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

  statsRow: { display:"grid", gridTemplateColumns:"repeat(4,1fr)", gap:14, marginBottom:20 },
  statCard: {
    background:"#fff", borderRadius:14, padding:"18px 20px",
    border:"1px solid #f1f5f9", boxShadow:"0 2px 8px rgba(0,0,0,0.04)",
  },

  tableWrap: {
    flex:1, minHeight:0, background:"#fff", borderRadius:16,
    border:"1px solid #f1f5f9", display:"flex", flexDirection:"column",
    overflow:"hidden",
  },
  tableHead: {
    display:"flex", alignItems:"center", padding:"12px 24px",
    background:"#f8fafc", borderBottom:"1px solid #f1f5f9", flexShrink:0,
  },
  col: { fontSize:11, fontWeight:700, color:"#94a3b8", letterSpacing:"0.06em" },
  tableBody: { flex:1, overflowY:"auto" },

  row: { display:"flex", alignItems:"center", padding:"13px 24px", borderBottom:"1px solid #f8fafc" },
  cell: { display:"flex", alignItems:"center" },

  avatar: { width:40, height:40, borderRadius:"50%", objectFit:"cover", flexShrink:0 },
  avatarFallback: {
    width:40, height:40, borderRadius:"50%", background:"#000080",
    display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0,
  },
  name:   { fontSize:14, fontWeight:600, color:"#1F2937" },
  joined: { fontSize:10, color:"#94a3b8", marginTop:2, letterSpacing:"0.04em" },
  roleBadge: {
    fontSize:11, fontWeight:700, borderRadius:6, padding:"3px 10px",
    letterSpacing:"0.04em",
  },
  email:  { fontSize:13, color:"#64748b" },
  statusDot: { width:7, height:7, borderRadius:"50%", flexShrink:0 },
  eyeBtn: { background:"none", border:"none", cursor:"pointer", padding:4, display:"flex", alignItems:"center" },

  pagin: {
    display:"flex", alignItems:"center", justifyContent:"space-between",
    padding:"12px 24px", borderTop:"1px solid #f1f5f9", flexShrink:0,
  },
  paginInfo: { fontSize:11, fontWeight:600, color:"#94a3b8", letterSpacing:"0.04em" },
  paginBtns: { display:"flex", alignItems:"center", gap:4 },
  paginBtn: {
    width:32, height:32, borderRadius:8, border:"1px solid #e2e8f0",
    background:"#fff", fontSize:13, fontWeight:500, color:"#64748b",
    cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center",
  },
  paginBtnActive: { background:"#000080", borderColor:"#000080", color:"#fff", fontWeight:700 },
  paginArrow: {
    width:32, height:32, borderRadius:8, border:"1px solid #e2e8f0",
    background:"#fff", fontSize:16, color:"#64748b", cursor:"pointer",
    display:"flex", alignItems:"center", justifyContent:"center",
  },
  paginDots: { width:32, textAlign:"center", color:"#94a3b8", fontSize:14 },

  empty: { padding:"48px 0", textAlign:"center", color:"#94a3b8", fontSize:14 },
};
