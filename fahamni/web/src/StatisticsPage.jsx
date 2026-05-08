import { useState, useEffect } from "react";
import { collection, query, where, getDocs, getCountFromServer, Timestamp } from "firebase/firestore";
import { db } from "./firebase";
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell,
  BarChart, Bar,
} from "recharts";
import { GraduationCap, Users, Flag, Calendar } from "lucide-react";
import { useTranslation } from "react-i18next";
import i18n from "./i18n";

// ── Safe Firestore helpers ────────────────────────────────────────────────────
// Each returns a fallback (0 / []) instead of throwing, so one bad query
// never silences the rest of the page.

async function safeCount(ref) {
  try { return (await getCountFromServer(ref)).data().count; }
  catch (e) { console.warn("Stats count failed:", e.message); return 0; }
}

async function safeDocs(q) {
  try { return (await getDocs(q)).docs; }
  catch (e) { console.warn("Stats query failed:", e.message); return []; }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function getLast6Months() {
  const months = [];
  for (let i = 5; i >= 0; i--) {
    const d = new Date();
    d.setDate(1);
    d.setMonth(d.getMonth() - i);
    months.push({
      key:   `${d.getFullYear()}-${d.getMonth()}`,
      label: d.toLocaleString("default", { month: "short" }),
    });
  }
  return months;
}

function groupByMonth(docs, field) {
  const counts = {};
  docs.forEach(d => {
    const ts = d.data()[field];
    if (!ts) return;
    const date = ts.toDate ? ts.toDate() : new Date(ts.seconds ? ts.seconds * 1000 : ts);
    const key  = `${date.getFullYear()}-${date.getMonth()}`;
    counts[key] = (counts[key] || 0) + 1;
  });
  return counts;
}

// ── Custom Tooltip ────────────────────────────────────────────────────────────

function ChartTooltip({ active, payload, label }) {
  if (!active || !payload?.length) return null;
  return (
    <div style={{
      background: "#fff", border: "1px solid #e2e8f0", borderRadius: 10,
      padding: "9px 14px", boxShadow: "0 6px 20px rgba(0,0,0,0.09)", fontSize: 13,
    }}>
      {label && <div style={{ fontWeight: 700, color: "#1F2937", marginBottom: 6 }}>{label}</div>}
      {payload.map((p, i) => (
        <div key={i} style={{ display: "flex", alignItems: "center", gap: 7, color: "#374151", marginBottom: i < payload.length - 1 ? 3 : 0 }}>
          <span style={{ width: 9, height: 9, borderRadius: 2, background: p.color ?? p.fill, flexShrink: 0, display: "inline-block" }} />
          <span style={{ color: "#64748b" }}>{p.name}:</span>
          <span style={{ fontWeight: 600, color: "#1F2937" }}>{p.value}</span>
        </div>
      ))}
    </div>
  );
}

// ── KPI Card ──────────────────────────────────────────────────────────────────

function KpiCard({ label, value, type, bg, iconColor, borderColor }) {
  return (
    <div style={{
      flex: "1 1 160px", minWidth: 150,
      background: "#fff", borderRadius: 16,
      border: "1px solid #f1f5f9",
      borderLeft: borderColor ? `3.5px solid ${borderColor}` : "1px solid #f1f5f9",
      padding: "16px 20px", display: "flex", flexDirection: "column", gap: 14,
      boxShadow: "0 2px 8px rgba(0,0,0,0.04)",
    }}>
      <div style={{ width: 44, height: 44, borderRadius: "50%", background: bg, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
        <KpiIcon type={type} color={iconColor} />
      </div>
      <div>
        <div style={{ fontSize: 28, fontWeight: 700, color: "#1F2937", lineHeight: 1.2, marginBottom: 4 }}>
          {value == null
            ? <span style={{ color: "#e2e8f0", fontSize: 22, fontWeight: 400 }}>—</span>
            : value.toLocaleString()}
        </div>
        <div style={{ fontSize: 13, color: "#64748b" }}>{label}</div>
      </div>
    </div>
  );
}

function KpiIcon({ type, color }) {
  const p = { size: 22, color, strokeWidth: 1.8 };
  if (type === "teacher")  return <GraduationCap {...p} />;
  if (type === "users")    return <Users         {...p} />;
  if (type === "sessions") return <Calendar      {...p} />;
  if (type === "reports")  return <Flag          {...p} />;
  return null;
}

// ── Chart Card ────────────────────────────────────────────────────────────────

function ChartCard({ title, subtitle, flex = "1 1 280px", children }) {
  return (
    <div style={{
      flex, minWidth: 240,
      background: "#fff", borderRadius: 14, border: "1px solid #e8edf5",
      padding: "22px 24px", boxShadow: "0 1px 4px rgba(0,0,128,0.04)",
    }}>
      <div style={{ fontSize: 15, fontWeight: 700, color: "#1F2937", marginBottom: 2 }}>{title}</div>
      <div style={{ fontSize: 12, color: "#94a3b8", marginBottom: 18 }}>{subtitle}</div>
      {children}
    </div>
  );
}

// ── Loading placeholder ───────────────────────────────────────────────────────

function LoadingBar({ height = 160 }) {
  return (
    <div style={{
      width: "100%", height, borderRadius: 8,
      background: "linear-gradient(135deg, #f8faff 0%, #f0f4ff 50%, #f8faff 100%)",
      display: "flex", alignItems: "center", justifyContent: "center",
    }}>
      <span style={{ fontSize: 12, color: "#c7d2fe", fontWeight: 500 }}>Loading…</span>
    </div>
  );
}

// ── Legend row ────────────────────────────────────────────────────────────────

function LegendRow({ items }) {
  return (
    <div style={{ display: "flex", flexWrap: "wrap", gap: "6px 16px", marginTop: 12 }}>
      {items.map((item, i) => (
        <div key={i} style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 12, color: "#64748b" }}>
          <span style={{ width: 10, height: 10, borderRadius: 2, background: item.color, display: "inline-block" }} />
          {item.label}
        </div>
      ))}
    </div>
  );
}

// ── Main Page ─────────────────────────────────────────────────────────────────

export default function StatisticsPage() {
  const { t } = useTranslation();
  const isRtl = i18n.dir() === "rtl";

  const [kpi,              setKpi]              = useState(null);
  const [userCounts,       setUserCounts]       = useState(null);
  const [teacherCounts,    setTeacherCounts]    = useState(null);
  const [monthlyData,      setMonthlyData]      = useState(null);
  const [sessionMonthly,   setSessionMonthly]   = useState(null);
  const [reportStatusDist, setReportStatusDist] = useState(null);

  useEffect(() => {
    // ── KPI counts + user distribution ──────────────────────────────────────
    // safeCount never throws — one failing query returns 0, the rest still load.
    async function fetchKpiAndDist() {
      const [sc, tc, pc, reports, sessions, validated] = await Promise.all([
        safeCount(collection(db, "students")),
        safeCount(collection(db, "tutors")),
        safeCount(collection(db, "parents")),
        safeCount(collection(db, "reports")),
        safeCount(collection(db, "sessions")),
        safeCount(query(collection(db, "tutors"), where("account_status", "==", "validated"))),
      ]);
      setKpi({
        totalUsers:        sc + tc + pc,
        validatedTeachers: validated,
        totalSessions:     sessions,
        totalReports:      reports,
      });
      setUserCounts({ students: sc, tutors: tc, parents: pc });
    }

    // ── Teacher status bar chart ─────────────────────────────────────────────
    async function fetchTeacherStatus() {
      const [vl, pe, re, su] = await Promise.all([
        safeCount(query(collection(db, "tutors"), where("account_status", "==", "validated"))),
        safeCount(query(collection(db, "tutors"), where("account_status", "==", "pending"))),
        safeCount(query(collection(db, "tutors"), where("account_status", "==", "rejected"))),
        safeCount(query(collection(db, "tutors"), where("is_suspended",   "==", true))),
      ]);
      setTeacherCounts({ validated: vl, pending: pe, rejected: re, suspended: su });
    }

    // ── Monthly area chart ───────────────────────────────────────────────────
    // Queries reports and new tutor registrations for the last 6 months.
    // safeDocs returns [] on failure so the chart shows real zeros, not fake ones.
    async function fetchMonthly() {
      const since = Timestamp.fromDate(new Date(Date.now() - 180 * 24 * 60 * 60 * 1000));
      const [repDocs, tutDocs] = await Promise.all([
        safeDocs(query(collection(db, "reports"), where("created_at", ">=", since))),
        safeDocs(query(collection(db, "tutors"),  where("created_at", ">=", since))),
      ]);
      const repCounts = groupByMonth(repDocs, "created_at");
      const tutCounts = groupByMonth(tutDocs, "created_at");
      setMonthlyData(getLast6Months().map(m => ({
        month:    m.label,
        reports:  repCounts[m.key]  || 0,
        teachers: tutCounts[m.key]  || 0,
      })));
    }

    // ── Sessions per month ───────────────────────────────────────────────────
    async function fetchSessionMonthly() {
      const since = Timestamp.fromDate(new Date(Date.now() - 180 * 24 * 60 * 60 * 1000));
      const docs  = await safeDocs(query(collection(db, "sessions"), where("date", ">=", since)));
      const counts = groupByMonth(docs, "date");
      setSessionMonthly(getLast6Months().map(m => ({
        month:    m.label,
        sessions: counts[m.key] || 0,
      })));
    }

    // ── Report status distribution ───────────────────────────────────────────
    async function fetchReportStatusDist() {
      const [pending, reviewed, resolved, dismissed] = await Promise.all([
        safeCount(query(collection(db, "reports"), where("status", "==", "pending"))),
        safeCount(query(collection(db, "reports"), where("status", "==", "reviewed"))),
        safeCount(query(collection(db, "reports"), where("status", "==", "resolved"))),
        safeCount(query(collection(db, "reports"), where("status", "==", "dismissed"))),
      ]);
      setReportStatusDist({ pending, reviewed, resolved, dismissed });
    }

    fetchKpiAndDist();
    fetchTeacherStatus();
    fetchMonthly();
    fetchSessionMonthly();
    fetchReportStatusDist();
  }, []);

  // Derived — computed at render time so translations are always fresh
  const userDist = userCounts ? [
    { name: t("statistics.students"), value: userCounts.students, color: "#000080" },
    { name: t("statistics.tutors"),   value: userCounts.tutors,   color: "#6366f1" },
    { name: t("statistics.parents"),  value: userCounts.parents,  color: "#22c55e" },
  ] : null;

  const teacherStatus = teacherCounts ? [
    { name: t("statistics.validated"), value: teacherCounts.validated, fill: "#000080" },
    { name: t("statistics.pending"),   value: teacherCounts.pending,   fill: "#f59e0b" },
    { name: t("statistics.rejected"),  value: teacherCounts.rejected,  fill: "#ef4444" },
    { name: t("statistics.suspended"), value: teacherCounts.suspended, fill: "#94a3b8" },
  ] : null;

  const reportStatusData = reportStatusDist ? [
    { name: t("statistics.pending"),   value: reportStatusDist.pending,   color: "#f59e0b" },
    { name: t("statistics.reviewed"),  value: reportStatusDist.reviewed,  color: "#22c55e" },
    { name: t("statistics.resolved"),  value: reportStatusDist.resolved,  color: "#06b6d4" },
    { name: t("statistics.dismissed"), value: reportStatusDist.dismissed, color: "#94a3b8" },
  ] : null;
  const reportTotal  = reportStatusData ? reportStatusData.reduce((s, d) => s + d.value, 0) : 0;
  const userTotal    = userDist ? userDist.reduce((s, d) => s + d.value, 0) : 0;

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>

      {/* ── KPI Cards ── */}
      <div style={{ display: "flex", flexWrap: "wrap", gap: 14 }}>
        <KpiCard label={t("statistics.validatedTeachers")} value={kpi?.validatedTeachers} type="teacher"  bg="#dcfce7" iconColor="#16a34a" borderColor="#16a34a" />
        <KpiCard label={t("statistics.totalUsers")}        value={kpi?.totalUsers}        type="users"    bg="#eff6ff" iconColor="#2563eb" borderColor="#2563eb" />
        <KpiCard label={t("statistics.totalReports")}      value={kpi?.totalReports}      type="reports"  bg="#fef2f2" iconColor="#ef4444" borderColor="#ef4444" />
        <KpiCard label={t("statistics.totalSessions")}     value={kpi?.totalSessions}     type="sessions" bg="#fffbeb" iconColor="#d97706" borderColor="#d97706" />
      </div>

      {/* ── Row 2: Area chart + Donut ── */}
      <div style={{ display: "flex", flexWrap: "wrap", gap: 14 }}>

        {/* Monthly Activity */}
        <ChartCard
          title={t("statistics.monthlyActivity")}
          subtitle={t("statistics.monthlyActivitySub")}
          flex="3 1 360px"
        >
          {monthlyData === null ? <LoadingBar height={210} /> : (
            <>
              {/* dir=ltr: Recharts doesn't support RTL — charts always render LTR */}
              <div style={{ direction: "ltr" }}>
              <ResponsiveContainer width="100%" height={210}>
                <AreaChart data={monthlyData} margin={{ top: 4, right: 6, bottom: 0, left: -22 }}>
                  <defs>
                    <linearGradient id="sgReports" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%"  stopColor="#ef4444" stopOpacity={0.22} />
                      <stop offset="95%" stopColor="#ef4444" stopOpacity={0}   />
                    </linearGradient>
                    <linearGradient id="sgTeachers" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%"  stopColor="#000080" stopOpacity={0.18} />
                      <stop offset="95%" stopColor="#000080" stopOpacity={0}   />
                    </linearGradient>
                  </defs>
                  <CartesianGrid stroke="#f1f5f9" strokeDasharray="4 4" vertical={false} />
                  <XAxis dataKey="month" tick={{ fontSize: 11, fill: "#94a3b8" }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 11, fill: "#94a3b8" }} axisLine={false} tickLine={false} allowDecimals={false} />
                  <Tooltip content={<ChartTooltip />} />
                  <Area type="monotone" dataKey="reports"  name={t("statistics.reports")}  stroke="#ef4444" strokeWidth={2.2} fill="url(#sgReports)"  dot={false} activeDot={{ r: 4, stroke: "#ef4444", strokeWidth: 2, fill: "#fff" }} />
                  <Area type="monotone" dataKey="teachers" name={t("statistics.teachers")} stroke="#000080" strokeWidth={2.2} fill="url(#sgTeachers)" dot={false} activeDot={{ r: 4, stroke: "#000080", strokeWidth: 2, fill: "#fff" }} />
                </AreaChart>
              </ResponsiveContainer>
              </div>
              <LegendRow items={[
                { color: "#ef4444", label: t("statistics.reports")  },
                { color: "#000080", label: t("statistics.teachers") },
              ]} />
            </>
          )}
        </ChartCard>

        {/* User Distribution Donut */}
        <ChartCard
          title={t("statistics.userDistribution")}
          subtitle={t("statistics.userDistributionSub")}
          flex="2 1 240px"
        >
          {userDist === null ? <LoadingBar height={210} /> : (
            <>
              {/* dir=ltr: Recharts SVG doesn't support RTL */}
              <div style={{ direction: "ltr" }}>
                <div style={{ position: "relative" }}>
                  <ResponsiveContainer width="100%" height={195}>
                    <PieChart>
                      <Pie
                        data={userDist}
                        cx="50%" cy="50%"
                        innerRadius={60} outerRadius={86}
                        paddingAngle={3} dataKey="value"
                        startAngle={90} endAngle={-270}
                        stroke="none"
                      >
                        {userDist.map((e, i) => <Cell key={i} fill={e.color} />)}
                      </Pie>
                      <Tooltip content={<ChartTooltip />} />
                    </PieChart>
                  </ResponsiveContainer>
                  {/* Center label */}
                  <div style={{
                    position: "absolute", top: "50%", left: "50%",
                    transform: "translate(-50%, -50%)",
                    textAlign: "center", pointerEvents: "none",
                  }}>
                    <div style={{ fontSize: 24, fontWeight: 800, color: "#1F2937", lineHeight: 1 }}>
                      {userTotal.toLocaleString()}
                    </div>
                    <div style={{ fontSize: 11, color: "#94a3b8", marginTop: 3 }}>Total</div>
                  </div>
                </div>
              </div>
              {/* Donut legend — uses document direction (RTL-aware flex) */}
              <div style={{ display: "flex", flexDirection: "column", gap: 8, marginTop: 6 }}>
                {userDist.map((d, i) => (
                  <div key={i} style={{ display: "flex", alignItems: "center", gap: 9 }}>
                    <span style={{ width: 11, height: 11, borderRadius: "50%", background: d.color, flexShrink: 0 }} />
                    <span style={{ flex: 1, fontSize: 13, color: "#374151" }}>{d.name}</span>
                    <span style={{ fontSize: 13, fontWeight: 700, color: "#1F2937" }}>{d.value.toLocaleString()}</span>
                    <span style={{ fontSize: 11, color: "#94a3b8", minWidth: 34, textAlign: isRtl ? "left" : "right" }}>
                      {userTotal > 0 ? `${Math.round(d.value / userTotal * 100)}%` : "0%"}
                    </span>
                  </div>
                ))}
              </div>
            </>
          )}
        </ChartCard>
      </div>

      {/* ── Row 3: Bar chart + Heatmap ── */}
      <div style={{ display: "flex", flexWrap: "wrap", gap: 14 }}>

        {/* Teacher Status */}
        <ChartCard title={t("statistics.teacherStatus")} subtitle={t("statistics.teacherStatusSub")}>
          {teacherStatus === null ? <LoadingBar height={170} /> : (() => {
            const total = teacherStatus.reduce((sum, s) => sum + s.value, 0);
            return (
              <div style={{ display: "flex", flexDirection: "column", gap: 16, paddingTop: 6 }}>
                {teacherStatus.map((item, i) => {
                  const pct = total > 0 ? Math.round(item.value / total * 100) : 0;
                  return (
                    <div key={i}>
                      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 6 }}>
                        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                          <span style={{ width: 10, height: 10, borderRadius: "50%", background: item.fill, flexShrink: 0 }} />
                          <span style={{ fontSize: 13, color: "#374151", fontWeight: 500 }}>{item.name}</span>
                        </div>
                        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                          <span style={{ fontSize: 15, fontWeight: 700, color: "#1F2937" }}>{item.value.toLocaleString()}</span>
                          <span style={{ fontSize: 11, color: "#94a3b8", minWidth: 32, textAlign: "right" }}>{pct}%</span>
                        </div>
                      </div>
                      <div style={{ height: 7, borderRadius: 4, background: "#f1f5f9", overflow: "hidden" }}>
                        <div style={{ height: "100%", borderRadius: 4, background: item.fill, width: `${pct}%` }} />
                      </div>
                    </div>
                  );
                })}
              </div>
            );
          })()}
        </ChartCard>

        {/* Report Status Distribution Donut */}
        <ChartCard title={t("statistics.reportStatus")} subtitle={t("statistics.reportStatusSub")} flex="1 1 240px">
          {reportStatusData === null ? <LoadingBar height={195} /> : (
            <>
              <div style={{ direction: "ltr" }}>
                <div style={{ position: "relative" }}>
                  <ResponsiveContainer width="100%" height={195}>
                    <PieChart>
                      <Pie
                        data={reportStatusData}
                        cx="50%" cy="50%"
                        innerRadius={55} outerRadius={80}
                        paddingAngle={3} dataKey="value"
                        startAngle={90} endAngle={-270}
                        stroke="none"
                      >
                        {reportStatusData.map((e, i) => <Cell key={i} fill={e.color} />)}
                      </Pie>
                      <Tooltip content={<ChartTooltip />} />
                    </PieChart>
                  </ResponsiveContainer>
                  <div style={{
                    position: "absolute", top: "50%", left: "50%",
                    transform: "translate(-50%,-50%)", textAlign: "center", pointerEvents: "none",
                  }}>
                    <div style={{ fontSize: 22, fontWeight: 800, color: "#1F2937", lineHeight: 1 }}>{reportTotal.toLocaleString()}</div>
                    <div style={{ fontSize: 11, color: "#94a3b8", marginTop: 3 }}>Total</div>
                  </div>
                </div>
              </div>
              <div style={{ display: "flex", flexDirection: "column", gap: 7, marginTop: 6 }}>
                {reportStatusData.map((d, i) => (
                  <div key={i} style={{ display: "flex", alignItems: "center", gap: 9 }}>
                    <span style={{ width: 10, height: 10, borderRadius: "50%", background: d.color, flexShrink: 0 }} />
                    <span style={{ flex: 1, fontSize: 12, color: "#374151" }}>{d.name}</span>
                    <span style={{ fontSize: 12, fontWeight: 700, color: "#1F2937" }}>{d.value.toLocaleString()}</span>
                    <span style={{ fontSize: 11, color: "#94a3b8", minWidth: 34, textAlign: "right" }}>
                      {reportTotal > 0 ? `${Math.round(d.value / reportTotal * 100)}%` : "0%"}
                    </span>
                  </div>
                ))}
              </div>
            </>
          )}
        </ChartCard>
      </div>

      {/* ── Row 4: Sessions per month ── */}
      <div style={{ display: "flex", flexWrap: "wrap", gap: 14 }}>
        <ChartCard title={t("statistics.sessionsMonthly")} subtitle={t("statistics.sessionsMonthySub")} flex="1 1 360px">
          {sessionMonthly === null ? <LoadingBar height={200} /> : (
            <div style={{ direction: "ltr" }}>
              <ResponsiveContainer width="100%" height={200}>
                <BarChart data={sessionMonthly} margin={{ top: 4, right: 10, bottom: 0, left: -22 }}>
                  <CartesianGrid stroke="#f1f5f9" strokeDasharray="4 4" vertical={false} />
                  <XAxis dataKey="month" tick={{ fontSize: 11, fill: "#94a3b8" }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 11, fill: "#94a3b8" }} axisLine={false} tickLine={false} allowDecimals={false} />
                  <Tooltip content={<ChartTooltip />} cursor={{ fill: "rgba(0,0,128,0.04)" }} />
                  <Bar dataKey="sessions" name={t("statistics.sessions")} fill="#000080" radius={[6,6,0,0]} maxBarSize={40} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}
        </ChartCard>
      </div>

    </div>
  );
}
