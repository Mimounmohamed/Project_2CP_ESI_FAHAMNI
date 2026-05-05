import { useState, useEffect } from "react";
import { collection, query, where, getDocs } from "firebase/firestore";
import { db } from "./firebase";
import { useTranslation } from "react-i18next";

const STATUS_MAP = { pending: "pending", approved: "validated", rejected: "rejected" };
const TABS = ["pending", "approved", "rejected"];

export default function TeachersPage({ onSelect }) {
  const { t } = useTranslation();
  const [tab, setTab] = useState("pending");
  const [search, setSearch] = useState("");
  const [teachers, setTeachers] = useState(null);

  useEffect(() => {
    setTeachers(null);
    getDocs(query(collection(db, "tutors"), where("account_status", "==", STATUS_MAP[tab])))
      .then(snap => setTeachers(snap.docs.map(d => ({ id: d.id, ...d.data() }))))
      .catch(err => { console.error(err); setTeachers([]); });
  }, [tab]);

  const filtered = (teachers ?? []).filter(t => {
    const name = `${t.first_name ?? ""} ${t.last_name ?? ""}`.toLowerCase();
    const email = (t.email ?? "").toLowerCase();
    const q = search.toLowerCase();
    return !q || name.includes(q) || email.includes(q);
  });

  function formatDate(val) {
    if (!val) return "—";
    const d = val.toDate ? val.toDate() : new Date(val);
    return isNaN(d) ? "—" : `${String(d.getMonth()+1).padStart(2,"0")}/${String(d.getDate()).padStart(2,"0")}/${d.getFullYear()}`;
  }

  function initials(t) {
    return `${(t.first_name ?? "")[0] ?? ""}${(t.last_name ?? "")[0] ?? ""}`.toUpperCase();
  }

  return (
    <div style={s.page}>
      {/* Toolbar */}
      <div className="page-toolbar">
        <div style={s.searchWrap}>
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="2"
            style={{ position: "absolute", left: 14, top: "50%", transform: "translateY(-50%)" }}>
            <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
          </svg>
          <input
            style={s.search}
            placeholder={t("teachers.searchPlaceholder")}
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>
        <div className="page-tabs">
          {TABS.map(tabKey => (
            <button
              key={tabKey}
              onClick={() => setTab(tabKey)}
              style={{ ...s.tabBtn, ...(tab === tabKey ? s.tabActive : {}) }}
            >
              {t(`teachers.tabs.${tabKey}`)}
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      <div className="table-scroll">
        <div className="table-scroll-inner thin-scroll">
        <div className="table-min">
        {/* Head */}
        <div style={s.tableHead}>
          <span style={{ ...s.col, flex: 2.5 }}>{t("teachers.userProfile")}</span>
          <span style={{ ...s.col, flex: 2 }}>{t("teachers.contact")}</span>
          <span style={{ ...s.col, flex: 1.5 }}>{t("teachers.submittedDate")}</span>
          <span style={{ ...s.col, flex: 1, textAlign: "center" }}>{t("teachers.actions")}</span>
        </div>

        {/* Body */}
        <div style={s.tableBody}>
          {teachers === null ? (
            <div style={s.empty}>{t("teachers.loading")}</div>
          ) : filtered.length === 0 ? (
            <div style={s.empty}>{t("teachers.noTeachersFound", { tab: t(`teachers.tabs.${tab}`) })}</div>
          ) : filtered.map(t => (
            <div key={t.id} style={s.row}>
              <div style={{ ...s.cell, flex: 2.5, gap: 12 }}>
                {t.picture
                  ? <img src={t.picture} alt="avatar" style={s.avatar} />
                  : <div style={s.avatarFallback}>
                      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="1.6">
                        <circle cx="12" cy="8" r="4" />
                        <path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" />
                      </svg>
                    </div>
                }
                <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                  <span style={s.name}>{t.first_name} {t.last_name}</span>
                  {t.certified && <VerifiedBadge size={15} />}
                </div>
              </div>
              <div style={{ ...s.cell, flex: 2 }}>
                <span style={s.email}>{t.email}</span>
              </div>
              <div style={{ ...s.cell, flex: 1.5 }}>
                <span style={s.date}>{formatDate(t.created_at)}</span>
              </div>
              <div style={{ ...s.cell, flex: 1, justifyContent: "center" }}>
                <button style={s.eyeBtn} title="View profile" onClick={() => onSelect(t)}>
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#000080" strokeWidth="1.8">
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                    <circle cx="12" cy="12" r="3" />
                  </svg>
                </button>
              </div>
            </div>
          ))}
        </div>
        </div>{/* table-min */}
        </div>{/* table-scroll-inner */}
      </div>
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
  page: {
    display: "flex",
    flexDirection: "column",
    height: "100%",
    minHeight: 0,
  },
  toolbar: {
    display: "flex",
    alignItems: "center",
    gap: 16,
    marginBottom: 24,
  },
  searchWrap: {
    position: "relative",
    flex: 1,
    maxWidth: 460,
  },
  search: {
    width: "100%",
    height: 40,
    paddingLeft: 38,
    paddingRight: 16,
    border: "1px solid #e2e8f0",
    borderRadius: 20,
    background: "#f8fafc",
    fontSize: 13,
    color: "#1F2937",
    outline: "none",
    boxSizing: "border-box",
  },
  tabs: { display: "flex", gap: 8 },
  tabBtn: {
    padding: "8px 20px",
    borderRadius: 20,
    border: "1.5px solid #e2e8f0",
    background: "#fff",
    fontSize: 13,
    fontWeight: 500,
    color: "#64748b",
    cursor: "pointer",
  },
  tabActive: {
    background: "#000080",
    borderColor: "#000080",
    color: "#fff",
  },
  tableWrap: {
    flex: 1,
    minHeight: 0,
    background: "#fff",
    borderRadius: 16,
    border: "1px solid #f1f5f9",
    overflow: "hidden",
    display: "flex",
    flexDirection: "column",
  },
  tableHead: {
    display: "flex",
    alignItems: "center",
    padding: "12px 24px",
    background: "#f8fafc",
    borderBottom: "1px solid #f1f5f9",
  },
  col: {
    fontSize: 11,
    fontWeight: 700,
    color: "#94a3b8",
    letterSpacing: "0.06em",
    textTransform: "uppercase",
  },
  tableBody: {
    flex: 1,
    overflowY: "auto",
  },
  row: {
    display: "flex",
    alignItems: "center",
    padding: "14px 24px",
    borderBottom: "1px solid #f8fafc",
  },
  cell: {
    display: "flex",
    alignItems: "center",
  },
  avatar: {
    width: 40,
    height: 40,
    borderRadius: "50%",
    objectFit: "cover",
    flexShrink: 0,
  },
  avatarFallback: {
    width: 40,
    height: 40,
    borderRadius: "50%",
    background: "#000080",
    color: "#fff",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    fontSize: 13,
    fontWeight: 700,
    flexShrink: 0,
  },
  name:  { fontSize: 14, fontWeight: 600, color: "#1F2937" },
  email: { fontSize: 13, color: "#64748b" },
  date:  { fontSize: 13, color: "#64748b" },
  eyeBtn: {
    background: "none",
    border: "none",
    cursor: "pointer",
    padding: 4,
    display: "flex",
    alignItems: "center",
  },
  empty: {
    padding: "48px 0",
    textAlign: "center",
    color: "#94a3b8",
    fontSize: 14,
  },
};
