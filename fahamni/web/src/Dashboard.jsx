import { useState, useEffect, Component } from "react";
import { collection, query, where, getDocs, getDoc, doc, setDoc, getCountFromServer, onSnapshot } from "firebase/firestore";
import { db } from "./firebase";
import TeachersPage from "./TeachersPage";
import TeacherProfilePage from "./TeacherProfilePage";
import UsersPage from "./UsersPage";
import UserProfilePage from "./UserProfilePage";
import ReportsPage from "./ReportsPage";
import MessagesPage from "./MessagesPage";
import StatisticsPage from "./StatisticsPage";
import SettingsPage from "./SettingsPage";
import { useTranslation } from "react-i18next";
import { applyAdminLanguage } from "./i18n";
import {
  LayoutGrid, GraduationCap, Users, FileText, MessageSquare,
  BarChart2, Settings, LogOut, Bell, Search, ArrowLeft,
  AlertCircle, Check, Flag, Calendar,
  Menu,
} from "lucide-react";


function fmtNotifTime(ts) {
  if (!ts) return "";
  const d = new Date(ts.seconds * 1000), now = new Date(), diff = now - d;
  if (diff < 60000)    return "Just now";
  if (diff < 3600000)  return `${Math.floor(diff / 60000)}m ago`;
  if (diff < 86400000) return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  return "Yesterday";
}

const STATS_KEYS = ["validatedTeachers", "totalUsers", "totalReports", "totalSessions"];

const STATS_CONFIG = [
  { key: "validatedTeachers", badge: null, borderColor: "#16a34a", iconBg: "#dcfce7", iconColor: "#16a34a", icon: "grad-cap"  },
  { key: "totalUsers",        badge: null, borderColor: "#2563eb", iconBg: "#eff6ff", iconColor: "#2563eb", icon: "users"    },
  { key: "totalReports",      badge: null, borderColor: "#ef4444", iconBg: "#fef2f2", iconColor: "#ef4444", icon: "flag"     },
  { key: "totalSessions",     badge: null, borderColor: "#d97706", iconBg: "#fffbeb", iconColor: "#d97706", icon: "calendar" },
];



class PageErrorBoundary extends Component {
  constructor(props) { super(props); this.state = { error: null }; }
  static getDerivedStateFromError(error) { return { error }; }
  componentDidCatch(err, info) { console.error("Page render error:", err, info.componentStack); }
  componentDidUpdate(prev) {
    if (prev.pageKey !== this.props.pageKey) this.setState({ error: null });
  }
  render() {
    if (this.state.error) return (
      <div style={{ display:"flex", flexDirection:"column", alignItems:"center", justifyContent:"center", height:"100%", gap:12 }}>
        <AlertCircle size={40} color="#ef4444" strokeWidth={1.5} />
        <div style={{ fontSize:15, fontWeight:600, color:"#1F2937" }}>Something went wrong</div>
        <div style={{ fontSize:13, color:"#94a3b8" }}>{this.state.error?.message}</div>
        <button onClick={() => this.setState({ error:null })} style={{ padding:"8px 24px", background:"#000080", color:"#fff", border:"none", borderRadius:20, cursor:"pointer", fontSize:13, fontWeight:600 }}>
          {this.props.tryAgainLabel ?? "Try again"}
        </button>
      </div>
    );
    return this.props.children;
  }
}

export default function Dashboard({ user, onLogout }) {
  const { t } = useTranslation();

  const NAV = [
    { id: "dashboard", label: t("nav.dashboard"), icon: <GridIcon /> },
    { id: "teachers",  label: t("nav.teachers"),  icon: <TeacherIcon /> },
    { id: "users",     label: t("nav.users"),      icon: <UsersIcon /> },
    { id: "reports",   label: t("nav.reports"),    icon: <ReportsIcon /> },
    { id: "messages",    label: t("nav.messages"),    icon: <MessagesIcon />    },
    { id: "statistics",  label: t("nav.statistics"),  icon: <StatisticsIcon /> },
    { id: "settings",    label: t("nav.settings"),    icon: <SettingsIcon />    },
  ];

  const [active, setActive] = useState("dashboard");
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [showNotif,   setShowNotif]   = useState(false);
  const [notifTab,    setNotifTab]    = useState("unread");
  const [tutorNotifs, setTutorNotifs] = useState([]);
  const [reportNotifs,setReportNotifs]= useState([]);
  const notifKey = `admin_notif_read_${user?.uid ?? ""}`;
  const [readIds,     setReadIds]     = useState(() => {
    try { return new Set(JSON.parse(localStorage.getItem(`admin_notif_read_${user?.uid ?? ""}`) || "[]")); }
    catch { return new Set(); }
  });
  const [adminData, setAdminData] = useState(null);
  const [statValues, setStatValues] = useState([null, null, null, null]);
  const [selectedTeacher, setSelectedTeacher] = useState(null);
  const [selectedUser, setSelectedUser] = useState(null);
  const [pendingTeachers, setPendingTeachers] = useState(null);
  const [sessionReports, setSessionReports] = useState(null);
  const [suspendedUsers, setSuspendedUsers] = useState(null);
  const [pendingContact, setPendingContact] = useState(null);
  const [usersInitialTab, setUsersInitialTab] = useState("all");

  useEffect(() => {
    if (active !== "dashboard") return;
    setStatValues([null, null, null, null]);
    async function fetchStats() {
      const safeCount = async (col, q) => {
        try {
          const ref = q ?? collection(db, col);
          return (await getCountFromServer(ref)).data().count;
        } catch (e) {
          console.error(`Count failed for [${col}]:`, e.message);
          return 0;
        }
      };

      const [validatedTeachers, students, tutors, parents, reports, sessions] = await Promise.all([
        safeCount("tutors", query(collection(db, "tutors"), where("account_status", "==", "validated"))),
        safeCount("students"),
        safeCount("tutors"),
        safeCount("parents"),
        safeCount("reports"),
        safeCount("sessions"),
      ]);

      setStatValues([
        validatedTeachers,
        students + tutors + parents,
        reports,
        sessions,
      ]);
    }
    fetchStats();
  }, [active]);

  useEffect(() => {
    if (active !== "dashboard") return;
    setPendingTeachers(null);
    setSessionReports(null);
    async function fetchTasks() {
      try {
        const [teacherSnap, reportSnap] = await Promise.all([
          getCountFromServer(query(collection(db, "tutors"), where("account_status", "==", "pending"))),
          getDocs(query(collection(db, "reports"), where("type", "==", "session"), where("status", "==", "pending"))),
        ]);
        setPendingTeachers(teacherSnap.data().count);
        const reports = reportSnap.docs
          .map(d => ({ id: d.id, ...d.data() }))
          .sort((a, b) => (b.created_at?.seconds ?? 0) - (a.created_at?.seconds ?? 0));
        setSessionReports(reports);
      } catch (e) {
        console.error("Tasks fetch error:", e.message);
        setPendingTeachers(0);
        setSessionReports([]);
      }
    }
    fetchTasks();
  }, [active]);

  useEffect(() => {
    if (active !== "dashboard") return;
    setSuspendedUsers(null);
    async function fetchSuspended() {
      try {
        const suspended = (col, role) =>
          getDocs(query(collection(db, col), where("is_suspended", "==", true)))
            .then(s => s.docs.map(d => ({
              name: `${d.data().first_name ?? ""} ${d.data().last_name ?? ""}`.trim(),
              role: role.toUpperCase(),
            })));
        const [students, tutors, parents] = await Promise.all([
          suspended("students", "student"),
          suspended("tutors", "teacher"),
          suspended("parents", "parent"),
        ]);
        setSuspendedUsers([...students, ...tutors, ...parents]);
      } catch (e) {
        console.error("Suspended fetch error:", e.message);
        setSuspendedUsers([]);
      }
    }
    fetchSuspended();
  }, [active]);

  useEffect(() => {
    if (!user?.uid || !user?.email) return;
    getDocs(query(collection(db, "admins"), where("email", "==", user.email)))
      .then(async snap => {
        if (snap.empty) return;
        const data = snap.docs[0].data();
        setAdminData(data);
        if (data.language) applyAdminLanguage(data.language);
        const uidRef = doc(db, "admins", user.uid);
        const uidSnap = await getDoc(uidRef).catch(() => null);
        if (uidSnap && !uidSnap.exists()) {
          await setDoc(uidRef, data).catch(() => {});
        }
      })
      .catch(err => console.error("Firestore error:", err));
  }, [user?.uid, user?.email]);

  // ── Real-time notification listeners ──
  useEffect(() => {
    const q1 = query(collection(db, "tutors"),  where("account_status", "==", "pending"));
    const q2 = query(collection(db, "reports"), where("status",         "==", "pending"));

    const unsub1 = onSnapshot(q1, snap => {
      setTutorNotifs(snap.docs.map(d => {
        const data = d.data();
        return {
          id:    `tutor_${d.id}`,
          titleKey: "dashboard.teacherValidationRequest",
          descSuffix: `${data.first_name ?? ""} ${data.last_name ?? ""}`.trim(),
          descSuffixKey: "dashboard.submittedRequest",
          time:  fmtNotifTime(data.created_at),
          ts:    data.created_at?.seconds ?? 0,
        };
      }));
    }, err => console.error("Notif tutor listener:", err));

    const unsub2 = onSnapshot(q2, snap => {
      setReportNotifs(snap.docs.map(d => {
        const data = d.data();
        return {
          id:    `report_${d.id}`,
          titleKey: "dashboard.newReport",
          desc:  data.reason ?? `A ${data.type ?? "new"} report has been submitted`,
          time:  fmtNotifTime(data.created_at),
          ts:    data.created_at?.seconds ?? 0,
        };
      }));
    }, err => console.error("Notif report listener:", err));

    return () => { unsub1(); unsub2(); };
  }, []);

  const notifications = [
    ...tutorNotifs.map(n  => ({ ...n, read: readIds.has(n.id) })),
    ...reportNotifs.map(n => ({ ...n, read: readIds.has(n.id) })),
  ].sort((a, b) => (b.ts ?? 0) - (a.ts ?? 0));

  function markAllRead() {
    const all = new Set([...readIds, ...notifications.map(n => n.id)]);
    setReadIds(all);
    try { localStorage.setItem(notifKey, JSON.stringify([...all])); } catch {}
  }

  function handleBellClick() {
    if (!showNotif) {
      const all = new Set([...readIds, ...notifications.map(n => n.id)]);
      if (all.size > readIds.size) {
        setReadIds(all);
        try { localStorage.setItem(notifKey, JSON.stringify([...all])); } catch {}
      }
    }
    setShowNotif(v => !v);
  }

  // ── Shared nav handler ──
  function navigateTo(pageId) {
    if (pageId !== "messages") setPendingContact(null);
    setActive(pageId);
    setShowNotif(false);
    setSelectedTeacher(null);
    setSelectedUser(null);
    setUsersInitialTab("all");
    setSidebarOpen(false);
  }

  function closeSidebar() { setSidebarOpen(false); }

  return (
    <div style={s.shell}>
      {/* Mobile sidebar overlay */}
      <div className={`sidebar-overlay${sidebarOpen ? " sidebar-open" : ""}`} onClick={closeSidebar} />

      {/* ── Sidebar ── */}
      <aside style={s.sidebar} className={`dash-sidebar${sidebarOpen ? " sidebar-open" : ""}`}>
        {/* Logo */}
        <div style={s.logoRow}>
          <svg width="44" height="34" viewBox="0 0 114 87" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path fillRule="evenodd" clipRule="evenodd" d="M54.0173 0.835334C51.1821 2.11215 46.6832 4.01423 44.0559 5.04652C42.9377 5.48586 41.0394 6.30352 39.8375 6.86372C38.6352 7.42351 36.9609 8.12437 36.1168 8.42023C35.2723 8.71649 33.6029 9.41573 32.4067 9.97472C29.7387 11.2208 25.0483 13.2543 19.6606 15.5003C15.7715 17.1215 12.2054 18.6424 6.44644 21.135C4.99289 21.7643 3.1051 22.4975 2.25167 22.7643C1.26976 23.0714 0.527335 23.626 0.230525 24.2739C-0.195173 25.2031 -0.109386 25.4056 1.15714 26.4569C1.92478 27.0939 2.78349 27.6153 3.06526 27.6153C3.34662 27.6153 4.61558 28.072 5.88495 28.6298C7.15391 29.1879 8.39441 29.6208 8.6408 29.5925C9.98132 29.4369 10.8896 29.7154 11.0921 30.3435C11.2178 30.7327 12.1907 31.3928 13.2544 31.8107C18.416 33.8381 24.3754 36.2931 26.5726 37.2971C27.9143 37.9102 29.4236 38.5411 29.9269 38.6992C30.6917 38.9397 30.8417 39.2763 30.8417 40.7504C30.8417 42.4847 30.8234 42.5082 29.7236 42.1824C29.1089 42.0001 27.4162 41.2855 25.9627 40.594C24.5091 39.9028 23.0914 39.337 22.8116 39.337C22.4315 39.3366 22.3034 40.6445 22.3034 44.5303C22.3034 49.6432 22.3221 49.7495 23.5061 51.3743C24.8645 53.2384 26.8226 54.4865 31.2483 56.3098C32.9255 57.0006 34.6637 57.7269 35.1109 57.9241C37.7964 59.1072 37.7533 59.1544 37.757 55.0257C37.7651 44.7413 40.9654 38.1915 47.7274 34.6185C51.9026 32.4125 55.2765 32.0342 69.6734 32.1563L82.2752 32.2634L82.3959 35.0219C82.5219 37.894 81.4181 43.1387 80.1918 45.4967C79.2184 47.3673 76.3731 50.2414 74.8805 50.8614L73.5335 51.4208V55.2407V59.0611L74.8549 58.9176C77.0127 58.6832 77.6161 58.496 81.8698 56.7419C87.1335 54.5718 90.0963 52.6245 90.8448 50.844C91.5572 49.1493 91.6645 40.341 90.9782 39.919C90.733 39.7686 90.1386 39.8406 89.6568 40.079C88.459 40.6724 83.7734 42.57 83.5071 42.57C83.3888 42.57 83.2916 41.8457 83.2916 40.9602C83.2916 39.4368 83.3998 39.2957 85.3006 38.3382C86.4053 37.7817 88.7379 36.7623 90.4846 36.0724C92.2309 35.3828 94.4273 34.471 95.3653 34.0462C96.3033 33.6214 97.1839 33.2738 97.3218 33.2738C97.4596 33.2738 98.5216 32.8288 99.682 32.2848C102.343 31.0371 107.273 28.9875 109.923 28.0275C111.041 27.6221 112.471 26.8283 113.101 26.2629C114.076 25.3874 114.177 25.1093 113.788 24.3863C113.302 23.4829 112.971 23.3115 106.698 20.7171C104.477 19.7984 101.732 18.6258 100.599 18.1109C96.2228 16.1223 91.1758 13.9652 90.2036 13.6677C89.6446 13.4968 88.1028 12.8367 86.7773 12.2005C85.4518 11.5644 84.2252 11.0438 84.0511 11.0438C83.8771 11.0438 82.5829 10.5147 81.1753 9.86801C76.528 7.73312 73.7864 6.56543 69.5758 4.92728C67.2871 4.03646 65.3094 3.13877 65.181 2.93183C65.0525 2.72529 64.6349 2.55594 64.2535 2.55594C63.8722 2.55594 62.4036 1.99494 60.9903 1.30944C57.6448 -0.312947 56.7077 -0.376406 54.0173 0.835334ZM53.5517 37.3039C51.2285 38.0024 47.4143 40.3531 46.2649 41.7956C45.5997 42.6306 44.6474 44.1924 44.149 45.2659C43.2679 47.164 43.2394 47.6603 43.1191 63.1061C42.9756 81.606 43.0532 82.1848 46.0595 84.9393C48.0933 86.803 49.0207 87.1397 51.6103 86.9557L53.4074 86.828L53.5168 77.835L53.6261 68.8419H57.0008C61.433 68.8419 64.1714 68.0125 66.0559 66.0999C67.8966 64.2318 69.1387 61.4555 68.9793 59.5675L68.8577 58.1311L61.2342 58.1796L53.6107 58.2281V53.061V47.8939L62.2507 47.7581C71.5156 47.6126 71.564 47.6025 74.2853 45.2235C76.0649 43.6682 77.8832 39.246 77.3851 37.6855C77.1493 36.9462 76.6305 36.9131 65.8827 36.9462C59.692 36.9652 54.1433 37.1265 53.5517 37.3039Z" fill="url(#dashLogoGrad)"/>
              <defs>
                <linearGradient id="dashLogoGrad" x1="20.3945" y1="19.3916" x2="57.1255" y2="86.9317" gradientUnits="userSpaceOnUse">
                  <stop stopColor="#000080"/>
                  <stop offset="1" stopColor="#00001A"/>
                </linearGradient>
              </defs>
            </svg>
          <span style={s.logoLabel}>Fahamni</span>
        </div>

        {/* User */}
        <div style={s.userBox}>
          {adminData?.picture
            ? <img src={adminData.picture} alt="avatar" style={s.avatarImg} />
            : <div style={s.avatar}>
                {adminData
                  ? `${adminData.firstName?.[0] ?? ""}${adminData.lastName?.[0] ?? ""}`
                  : "…"}
              </div>
          }
          <div>
            <div style={s.userName}>
              {adminData ? `${adminData.firstName} ${adminData.lastName}` : "—"}
            </div>
            <div style={s.userRole}>{t("nav.admin")}</div>
          </div>
        </div>

        {/* Nav */}
        <nav style={s.nav}>
          {NAV.map(item => (
            <button
              key={item.id}
              onClick={() => navigateTo(item.id)}
              style={{
                ...s.navItem,
                ...(active === item.id ? s.navActive : {}),
              }}
            >
              <span style={{ color: active === item.id ? "#fff" : "#64748B" }}>{item.icon}</span>
              <span>{item.label}</span>
            </button>
          ))}
        </nav>

        <div style={{ flex: 1 }} />

        {/* Logout */}
        <button style={s.logoutBtn} onClick={() => { onLogout(); closeSidebar(); }}>
          <LogOut size={16} color="#dc2626" />
          {t("nav.logout")}
        </button>
      </aside>

      {/* ── Main ── */}
      <main style={s.main}>
        {/* Topbar */}
        <header style={s.topbar} className="dash-topbar">
          <button className="hamburger-btn" onClick={() => setSidebarOpen(v => !v)} aria-label="Menu">
            <Menu size={18} color="#1F2937" />
          </button>
          <div style={{ flex: 1, minWidth: 0 }}>
            {active === "dashboard" && !showNotif && (
              <div style={s.searchWrap}>
                <Search size={15} color="#94a3b8" style={{ position: "absolute", left: 14, top: "50%", transform: "translateY(-50%)" }} />
                <input style={s.search} placeholder={t("topbar.searchPlaceholder")} />
              </div>
            )}
            {active === "teachers" && !showNotif && !selectedTeacher && (
              <div>
                <div style={{ fontSize: 20, fontWeight: 700, color: "#000080", lineHeight: 1.2 }}>{t("topbar.teacherManagement")}</div>
                <div style={{ fontSize: 12, color: "#64748b", marginTop: 2 }}>{t("topbar.manageTeachers")}</div>
              </div>
            )}
            {active === "users" && !showNotif && !selectedUser && (
              <div>
                <div style={{ fontSize: 20, fontWeight: 700, color: "#000080", lineHeight: 1.2 }}>{t("topbar.userManagement")}</div>
                <div style={{ fontSize: 12, color: "#64748b", marginTop: 2 }}>{t("topbar.manageUsers")}</div>
              </div>
            )}
            {active === "reports" && !showNotif && (
              <div>
                <div style={{ fontSize: 20, fontWeight: 700, color: "#000080", lineHeight: 1.2 }}>{t("topbar.reportsManagement")}</div>
                <div style={{ fontSize: 12, color: "#64748b", marginTop: 2 }}>{t("topbar.manageReports")}</div>
              </div>
            )}
            {active === "messages" && !showNotif && (
              <div>
                <div style={{ fontSize: 20, fontWeight: 700, color: "#000080", lineHeight: 1.2 }}>{t("nav.messages")}</div>
                <div style={{ fontSize: 12, color: "#64748b", marginTop: 2 }}>{t("topbar.manageConversations")}</div>
              </div>
            )}
            {active === "statistics" && !showNotif && (
              <div>
                <div style={{ fontSize: 20, fontWeight: 700, color: "#000080", lineHeight: 1.2 }}>{t("topbar.statisticsTitle")}</div>
                <div style={{ fontSize: 12, color: "#64748b", marginTop: 2 }}>{t("topbar.statisticsSub")}</div>
              </div>
            )}
            {active === "settings" && !showNotif && (
              <div>
                <div style={{ fontSize: 20, fontWeight: 700, color: "#000080", lineHeight: 1.2 }}>{t("nav.settings")}</div>
                <div style={{ fontSize: 12, color: "#64748b", marginTop: 2 }}>{t("topbar.manageAccount")}</div>
              </div>
            )}
            {active === "users" && !showNotif && selectedUser && (
              <button
                onClick={() => setSelectedUser(null)}
                style={{ background: "none", border: "none", cursor: "pointer", display: "flex", alignItems: "center", gap: 8, padding: 0 }}
              >
                <ArrowLeft size={20} color="#1F2937" />
              </button>
            )}
            {active === "teachers" && !showNotif && selectedTeacher && (
              <button
                onClick={() => setSelectedTeacher(null)}
                style={{ background: "none", border: "none", cursor: "pointer", display: "flex", alignItems: "center", gap: 8, padding: 0 }}
              >
                <ArrowLeft size={20} color="#1F2937" />
              </button>
            )}
          </div>
          <button style={{ ...s.bellBtn, position: "relative" }} onClick={handleBellClick}>
            <Bell size={20} color="#1F2937" strokeWidth={1.8} />
            {notifications.some(n => !n.read) && (
              <span style={{ position: "absolute", top: 7, right: 7, width: 8, height: 8, borderRadius: "50%", background: "#ef4444", border: "2px solid #fff" }} />
            )}
          </button>
        </header>

        {/* Content */}
        <div style={s.content} className="dash-content">
        <PageErrorBoundary pageKey={active} tryAgainLabel={t("dashboard.tryAgain")}>

          {/* ── Notifications page ── */}
          {showNotif && (() => {
            const unreadCount = notifications.filter(n => !n.read).length;
            const visible = notifTab === "unread"
              ? notifications.filter(n => !n.read)
              : notifications;
            return (
              <div style={{ display: "flex", flexDirection: "column", alignItems: "center", height: "100%", minHeight: 0 }}>
                <h1 style={{ ...s.pageTitle, alignSelf: "flex-start" }}>{t("dashboard.notifications")}</h1>
                <div style={{ ...s.notifTabs, justifyContent: "center" }}>
                  <button
                    style={{ ...s.notifTab, ...(notifTab === "unread" ? s.notifTabActive : {}) }}
                    onClick={() => setNotifTab("unread")}
                  >
                    {t("dashboard.unread")} {unreadCount > 0 && <span style={s.notifBadge}>{unreadCount}</span>}
                  </button>
                  <button
                    style={{ ...s.notifTab, ...(notifTab === "all" ? s.notifTabActive : {}) }}
                    onClick={() => setNotifTab("all")}
                  >
                    {t("dashboard.all")}
                  </button>
                </div>
                <div className="notif-scroll" style={{ ...s.notifList, flex: 1, minHeight: 0, overflowY: "auto", paddingRight: 4 }}>
                  {visible.length === 0 ? (
                    <div style={{ textAlign: "center", color: "#94a3b8", fontSize: 14, padding: "40px 0" }}>
                      {t("dashboard.noNotifications")}
                    </div>
                  ) : visible.map(n => (
                    <div key={n.id} style={{ ...s.notifCard, background: n.read ? "#fff" : "#f5f7ff" }}>
                      <div style={{ flex: 1 }}>
                        <div style={s.notifTitle}>{n.titleKey ? t(n.titleKey) : n.title}</div>
                        <div style={s.notifDesc}>
                          {n.descSuffix ? `${n.descSuffix} ${t(n.descSuffixKey)}` : n.desc}
                        </div>
                      </div>
                      <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: 6, flexShrink: 0 }}>
                        <span style={s.notifTime}>{n.time}</span>
                        {!n.read && <span style={s.notifDot} />}
                      </div>
                    </div>
                  ))}
                </div>
                {unreadCount > 0 && (
                  <div style={{ paddingTop: 16, flexShrink: 0 }}>
                    <button
                      style={s.markReadBtn}
                      onClick={markAllRead}
                    >
                      {t("dashboard.markAsRead")}
                    </button>
                  </div>
                )}
              </div>
            );
          })()}

          {/* ── Teachers page ── */}
          {!showNotif && active === "teachers" && !selectedTeacher && (
            <TeachersPage onSelect={setSelectedTeacher} />
          )}
          {!showNotif && active === "teachers" && selectedTeacher && (
            <TeacherProfilePage
              teacher={selectedTeacher}
              adminUser={user}
              onBack={() => setSelectedTeacher(null)}
              onStatusChange={(id, status) => setSelectedTeacher(prev => ({ ...prev, account_status: status }))}
            />
          )}

          {/* ── Dashboard page ── */}
          {!showNotif && active === "dashboard" && <>
          <h1 style={s.pageTitle}>{t("dashboard.title")}</h1>

          {/* Stat Cards */}
          <div className="stats-grid">
            {STATS_CONFIG.map((stat, i) => (
              <div key={i} style={{
                ...s.statCard,
                borderLeft: stat.borderColor ? `3.5px solid ${stat.borderColor}` : "1px solid #f1f5f9",
              }}>
                <div style={s.statTop}>
                  <div style={{ ...s.statIconCircle, background: stat.iconBg }}>
                    <StatIcon type={stat.icon} color={stat.iconColor} />
                  </div>
                </div>
                <div style={s.statValue}>
                  {statValues[i] === null ? "—" : statValues[i].toLocaleString()}
                </div>
                <div style={s.statLabel}>{t(`dashboard.stats.${stat.key}`)}</div>
              </div>
            ))}
          </div>

          {/* Bottom row */}
          <div className="dash-bottom-row">
            {/* Tasks */}
            <div className="dash-tasks-col">
              <h2 style={s.sectionTitle}>{t("dashboard.pendingTasks")}</h2>
              <div style={s.tasksList}>

                {pendingTeachers === null ? (
                  <div style={{ ...s.taskCard, color: "#94a3b8", fontSize: 13 }}>{t("dashboard.loading")}</div>
                ) : pendingTeachers === 0 ? (
                  <div style={{ ...s.taskCard, gap: 10 }}>
                    <Check size={18} color="#22c55e" style={{ flexShrink: 0 }} />
                    <span style={{ fontSize: 13, color: "#64748b" }}>{t("dashboard.noValidationPending")}</span>
                  </div>
                ) : (
                  <div style={s.taskCard}>
                    <div style={s.taskIcon}>
                      <GraduationCap size={20} color="#6366f1" strokeWidth={1.8} />
                    </div>
                    <div style={s.taskText}>
                      <div style={s.taskTitle}>{t("dashboard.teachersAwaiting", { count: pendingTeachers })}</div>
                      <div style={s.taskDesc}>{t("dashboard.credentialsSubmitted")}</div>
                    </div>
                    <button style={{ ...s.actionBtn, background: "#000080" }} onClick={() => navigateTo("teachers")}>{t("dashboard.review")}</button>
                  </div>
                )}

                <div style={s.taskCard}>
                  <div style={s.taskIcon}>
                    <MessageSquare size={20} color="#6366f1" strokeWidth={1.8} />
                  </div>
                  <div style={s.taskText}>
                    <div style={s.taskTitle}>{t("nav.messages")}</div>
                    <div style={s.taskDesc}>{t("dashboard.viewRespond")}</div>
                  </div>
                  <button style={{ ...s.actionBtn, background: "#000080" }} onClick={() => navigateTo("messages")}>{t("dashboard.open")}</button>
                </div>

                {sessionReports === null ? (
                  <div style={{ ...s.taskCard, color: "#94a3b8", fontSize: 13 }}>{t("dashboard.loading")}</div>
                ) : sessionReports.length === 0 ? (
                  <div style={{ ...s.taskCard, gap: 10 }}>
                    <Check size={18} color="#22c55e" style={{ flexShrink: 0 }} />
                    <span style={{ fontSize: 13, color: "#64748b" }}>{t("dashboard.noUrgentReports")}</span>
                  </div>
                ) : (
                  <div style={{ ...s.taskCard, ...s.taskCardUrgent }}>
                    <div style={s.taskIcon}>
                      <span style={{ fontSize: 18 }}>✱</span>
                    </div>
                    <div style={s.taskText}>
                      <div style={s.taskTitle}>{t("dashboard.urgentReport", { count: sessionReports.length })}</div>
                      <div style={s.taskDesc}>{sessionReports[0].text?.slice(0, 60) || t("dashboard.reportedBehavior")}{sessionReports[0].text?.length > 60 ? "…" : ""}</div>
                    </div>
                    <button style={{ ...s.actionBtn, background: "#dc2626" }} onClick={() => navigateTo("reports")}>{t("dashboard.view")}</button>
                  </div>
                )}

              </div>
            </div>

            {/* Suspended Users */}
            <div className="dash-suspended-col">
              <h2 style={s.sectionTitle}>{t("dashboard.suspendedUsers")}</h2>
              <div style={s.suspendedCard}>
                {suspendedUsers === null ? (
                  <div style={{ fontSize: 13, color: "#94a3b8", padding: "8px 0" }}>{t("dashboard.loading")}</div>
                ) : suspendedUsers.length === 0 ? (
                  <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 13, color: "#64748b", padding: "8px 0" }}>
                    <Check size={16} color="#22c55e" />
                    {t("dashboard.noSuspended")}
                  </div>
                ) : (
                  <>
                    {suspendedUsers.slice(0, 3).map((u, i) => (
                      <div
                        key={i}
                        style={{ ...s.suspendedRow, cursor: "pointer" }}
                        onClick={() => { setActive("users"); setUsersInitialTab("suspended"); setShowNotif(false); setSelectedUser(null); }}
                      >
                        <div style={s.suspendedAvatar}>
                          <Users size={24} color="#94a3b8" strokeWidth={1.5} />
                        </div>
                        <div>
                          <div style={s.suspendedName}>{u.name}</div>
                          <span style={s.roleBadge}>{u.role}</span>
                        </div>
                      </div>
                    ))}
                    {suspendedUsers.length > 3 && (
                      <button
                        style={s.seeAllBtn}
                        onClick={() => { setActive("users"); setUsersInitialTab("suspended"); setShowNotif(false); setSelectedUser(null); }}
                      >
                        {t("dashboard.seeFullList")} ({suspendedUsers.length - 3} more)
                      </button>
                    )}
                  </>
                )}
              </div>
            </div>
          </div>
          </>}

          {/* ── Users page ── */}
          {!showNotif && active === "users" && !selectedUser && (
            <UsersPage onSelect={setSelectedUser} initialTab={usersInitialTab} />
          )}
          {!showNotif && active === "users" && selectedUser && (
            <UserProfilePage
              user={selectedUser}
              onBack={() => setSelectedUser(null)}
              onSuspendChange={(id, next) => setSelectedUser(u => ({ ...u, is_suspended: next }))}
              onViewUser={setSelectedUser}
              onContact={userData => {
                setActive("messages");
                setShowNotif(false);
                setSelectedUser(null);
                // Delay so MessagesPage mounts and starts loading conversations first
                setTimeout(() => setPendingContact(userData), 0);
              }}
            />
          )}

          {/* ── Reports page ── */}
          {!showNotif && active === "reports" && (
            <ReportsPage />
          )}

          {/* ── Messages page ── */}
          {!showNotif && active === "messages" && (
            <MessagesPage
              adminUser={user}
              pendingContact={pendingContact}
              onContactHandled={() => setPendingContact(null)}
              onViewUser={userData => {
                setSelectedUser(userData);
                setActive("users");
              }}
            />
          )}

          {/* ── Statistics page ── */}
          {!showNotif && active === "statistics" && (
            <div
              className="thin-scroll"
              style={{ flex: 1, minHeight: 0, overflowY: "auto", scrollbarWidth: "thin", scrollbarColor: "rgba(0,0,0,0.1) transparent" }}
            >
              <StatisticsPage />
            </div>
          )}

          {/* ── Settings page ── */}
          {!showNotif && active === "settings" && (
            <SettingsPage
              user={user}
              adminData={adminData}
              onAdminDataChange={setAdminData}
            />
          )}

          {/* placeholder for other pages */}
          {!showNotif && !["dashboard","teachers","users","reports","messages","statistics","settings"].includes(active) && (
            <div style={{ color: "#94a3b8", fontSize: 14, paddingTop: 40, textAlign: "center" }}>
              {active.charAt(0).toUpperCase() + active.slice(1)} — coming soon.
            </div>
          )}

        </PageErrorBoundary>
        </div>
      </main>
    </div>
  );
}

// ── Icons ──
function GridIcon()       { return <LayoutGrid    size={16} />; }
function TeacherIcon()    { return <GraduationCap size={16} />; }
function UsersIcon()      { return <Users         size={16} />; }
function ReportsIcon()    { return <FileText      size={16} />; }
function MessagesIcon()   { return <MessageSquare size={16} />; }
function SettingsIcon()   { return <Settings      size={16} />; }
function StatisticsIcon() { return <BarChart2     size={16} />; }

function StatIcon({ type, color }) {
  const p = { size: 22, color, strokeWidth: 1.8 };
  if (type === "grad-cap")  return <GraduationCap {...p} />;
  if (type === "users")     return <Users         {...p} />;
  if (type === "flag")      return <Flag          {...p} />;
  if (type === "calendar")  return <Calendar      {...p} />;
  return null;
}

// ── Styles ──
const s = {
  shell: {
    display: "flex",
    height: "100vh",
    background: "#f0f4ff",
    fontFamily: "'Segoe UI', system-ui, sans-serif",
    overflow: "hidden",
  },
  sidebar: {
    width: 160,
    minWidth: 160,
    background: "#fff",
    borderRight: "1px solid #f1f5f9",
    display: "flex",
    flexDirection: "column",
    padding: "0 0 16px",
    position: "relative",
    zIndex: 10,
  },
  logoRow: {
    display: "flex",
    alignItems: "center",
    gap: 10,
    padding: "20px 16px 12px",
    borderBottom: "1px solid #f1f5f9",
  },
  logoLabel: {
    fontSize: 16,
    fontWeight: 700,
    color: "#000080",
  },
  userBox: {
    display: "flex",
    alignItems: "flex-start",
    gap: 8,
    padding: "12px 16px",
    borderBottom: "1px solid #f1f5f9",
    marginBottom: 8,
  },
  avatar: {
    width: 34,
    height: 34,
    borderRadius: "50%",
    background: "#000080",
    color: "#fff",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    fontSize: 11,
    fontWeight: 700,
    flexShrink: 0,
  },
  avatarImg: {
    width: 34,
    height: 34,
    borderRadius: "50%",
    objectFit: "cover",
    flexShrink: 0,
  },
  userName: { fontSize: 12, fontWeight: 600, color: "#1F2937", lineHeight: 1.3 },
  userRole: { fontSize: 11, color: "#000080", fontWeight: 600 },
  nav: { display: "flex", flexDirection: "column", gap: 2, padding: "0 8px" },
  navItem: {
    display: "flex",
    alignItems: "center",
    gap: 10,
    padding: "9px 12px",
    borderRadius: 10,
    border: "none",
    background: "transparent",
    cursor: "pointer",
    fontSize: 13,
    fontWeight: 500,
    color: "#64748B",
    textAlign: "left",
    width: "100%",
    transition: "background 0.15s",
  },
  navActive: {
    background: "#000080",
    color: "#fff",
  },
  logoutBtn: {
    display: "flex",
    alignItems: "center",
    gap: 8,
    margin: "0 8px",
    padding: "9px 12px",
    borderRadius: 10,
    border: "1px dashed #fca5a5",
    background: "transparent",
    cursor: "pointer",
    fontSize: 13,
    fontWeight: 500,
    color: "#dc2626",
  },
  main: { flex: 1, display: "flex", flexDirection: "column", overflow: "hidden" },
  topbar: {
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    padding: "12px 28px",
    background: "transparent",
    gap: 16,
  },
  searchWrap: { position: "relative", flex: 1, maxWidth: 400 },
  search: {
    width: "100%",
    height: 38,
    paddingLeft: 38,
    paddingRight: 16,
    border: "1px solid #e2e8f0",
    borderRadius: 20,
    background: "#fff",
    fontSize: 13,
    color: "#1F2937",
    outline: "none",
    boxSizing: "border-box",
  },
  bellBtn: {
    width: 38,
    height: 38,
    borderRadius: "50%",
    border: "1px solid #e2e8f0",
    background: "#fff",
    cursor: "pointer",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
  },
  content: {
    flex: 1,
    minHeight: 0,
    overflow: "hidden",
    padding: "0 28px 28px",
    display: "flex",
    flexDirection: "column",
  },
  pageTitle: { fontSize: 24, fontWeight: 700, color: "#000080", margin: "0 0 20px" },
  statsRow: {
    display: "grid",
    gridTemplateColumns: "repeat(4, 1fr)",
    gap: 16,
    marginBottom: 28,
  },
  statCard: {
    background: "#fff",
    borderRadius: 16,
    padding: "16px 20px",
    border: "1px solid #f1f5f9",
    boxShadow: "0 2px 8px rgba(0,0,0,0.04)",
  },
  statTop: { display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: 12 },
  statIconCircle: {
    width: 44, height: 44, borderRadius: "50%",
    display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
  },
  statValue: { fontSize: 28, fontWeight: 700, color: "#1F2937", lineHeight: 1.2, marginBottom: 4 },
  statLabel: { fontSize: 13, color: "#64748B" },
  bottomRow: { display: "flex", gap: 20, flex: 1, minHeight: 0, alignItems: "flex-start" },
  tasksCol: { flex: 1 },
  sectionTitle: { fontSize: 16, fontWeight: 600, color: "#1F2937", margin: "0 0 14px" },
  tasksList: { display: "flex", flexDirection: "column", gap: 12 },
  taskCard: {
    display: "flex", alignItems: "center", gap: 14,
    background: "#fff", borderRadius: 14, padding: "14px 16px",
    boxShadow: "0 2px 8px rgba(0,0,0,0.04)", border: "1px solid #f1f5f9",
  },
  taskCardUrgent: { background: "#fff5f5", border: "1px solid #fecaca" },
  taskIcon: {
    width: 36, height: 36, borderRadius: 10, background: "#f8faff",
    display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, color: "#dc2626",
  },
  taskText: { flex: 1 },
  taskTitle: { fontSize: 14, fontWeight: 600, color: "#1F2937", marginBottom: 3 },
  taskDesc: { fontSize: 12, color: "#64748B" },
  actionBtn: {
    padding: "8px 20px", borderRadius: 999, border: "none",
    color: "#fff", fontSize: 13, fontWeight: 600, cursor: "pointer", flexShrink: 0, whiteSpace: "nowrap",
  },
  suspendedCol: { width: 220, flexShrink: 0 },
  suspendedCard: {
    background: "#fff", borderRadius: 16, padding: "16px",
    boxShadow: "0 2px 8px rgba(0,0,0,0.04)", border: "1px solid #f1f5f9",
  },
  suspendedRow: { display: "flex", alignItems: "center", gap: 10, marginBottom: 14 },
  suspendedAvatar: {
    width: 36, height: 36, borderRadius: "50%", background: "#f1f5f9",
    display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
  },
  suspendedName: { fontSize: 13, fontWeight: 600, color: "#1F2937" },
  roleBadge: {
    fontSize: 10, fontWeight: 700, color: "#6366f1", background: "#eef2ff",
    borderRadius: 4, padding: "1px 6px", display: "inline-block", marginTop: 2,
  },
  seeAllBtn: {
    width: "100%", padding: "9px", border: "1px solid #e2e8f0",
    borderRadius: 10, background: "#fff", fontSize: 13, fontWeight: 500, color: "#1F2937", cursor: "pointer", marginTop: 4,
  },
  notifTabs: { display: "flex", gap: 10, marginBottom: 20 },
  notifTab: {
    padding: "7px 22px", borderRadius: 20, border: "1.5px solid #e2e8f0",
    background: "#fff", fontSize: 13, fontWeight: 500, color: "#64748b",
    cursor: "pointer", display: "flex", alignItems: "center", gap: 6,
  },
  notifTabActive: { background: "#000080", borderColor: "#000080", color: "#fff" },
  notifBadge: {
    background: "#ef4444", color: "#fff", borderRadius: 10,
    fontSize: 11, fontWeight: 700, padding: "1px 6px",
  },
  notifList: { display: "flex", flexDirection: "column", gap: 10, width: "100%", maxWidth: 620 },
  notifCard: {
    display: "flex", alignItems: "center", gap: 16, padding: "16px 20px",
    background: "#fff", borderRadius: 14, border: "1px solid #e2e8f0",
    boxShadow: "0 2px 8px rgba(0,0,0,0.04)",
  },
  notifTitle: { fontSize: 14, fontWeight: 600, color: "#1F2937", marginBottom: 3 },
  notifDesc:  { fontSize: 13, color: "#64748b" },
  notifTime:  { fontSize: 12, color: "#94a3b8", whiteSpace: "nowrap" },
  notifDot:   { width: 9, height: 9, borderRadius: "50%", background: "#000080", flexShrink: 0 },
  markReadBtn: {
    padding: "10px 32px", borderRadius: 24, border: "none",
    background: "#000080", color: "#fff", fontSize: 14, fontWeight: 600, cursor: "pointer",
  },
};
