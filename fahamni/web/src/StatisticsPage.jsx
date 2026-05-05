import { useState, useEffect } from "react";
import { collection, query, where, getDocs, getCountFromServer, Timestamp } from "firebase/firestore";
// getDocs is used inside safeDocs; getCountFromServer inside safeCount
import { db } from "./firebase";
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell,
  BarChart, Bar,
} from "recharts";
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

function tsToDate(ts) {
  if (!ts) return null;
  if (ts.toDate) return ts.toDate();
  if (ts.seconds) return new Date(ts.seconds * 1000);
  return new Date(ts);
}

function getHeatmapCells(countsMap) {
  const cells = [];
  for (let i = 83; i >= 0; i--) {
    const d = new Date();
    d.setHours(0, 0, 0, 0);
    d.setDate(d.getDate() - i);
    const key = d.toISOString().slice(0, 10);
    cells.push({ date: key, count: countsMap[key] || 0 });
  }
  return cells;
}

function heatmapColor(count, max) {
  if (count === 0) return "#f1f5f9";
  const t = Math.min(count / Math.max(max, 1), 1);
  if (t < 0.25) return "#c7d2fe";
  if (t < 0.5)  return "#818cf8";
  if (t < 0.75) return "#4338ca";
  return "#000080";
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

function KpiCard({ label, value, type, bg, iconColor }) {
  return (
    <div style={{
      flex: "1 1 160px", minWidth: 150,
      background: "#fff", borderRadius: 14, border: "1px solid #e8edf5",
      padding: "20px 22px", display: "flex", flexDirection: "column", gap: 16,
      boxShadow: "0 1px 4px rgba(0,0,128,0.04)",
    }}>
      <div style={{ width: 44, height: 44, borderRadius: 12, background: bg, display: "flex", alignItems: "center", justifyContent: "center" }}>
        <KpiSvg type={type} color={iconColor} />
      </div>
      <div>
        <div style={{ fontSize: 30, fontWeight: 800, color: "#1F2937", lineHeight: 1, letterSpacing: "-0.5px" }}>
          {value == null
            ? <span style={{ color: "#e2e8f0", fontSize: 22, fontWeight: 400 }}>—</span>
            : value.toLocaleString()}
        </div>
        <div style={{ fontSize: 12, color: "#94a3b8", marginTop: 5, fontWeight: 500 }}>{label}</div>
      </div>
    </div>
  );
}

function KpiSvg({ type, color }) {
  const p = { width: 20, height: 20, viewBox: "0 0 24 24", fill: "none", stroke: color, strokeWidth: 2 };
  if (type === "users")   return <svg {...p}><circle cx="9" cy="8" r="3"/><path d="M2 20c0-3.3 3-6 7-6s7 2.7 7 6"/><circle cx="17" cy="8" r="3"/><path d="M22 20c0-3.3-2-5.5-5-6"/></svg>;
  if (type === "teacher") return <svg {...p}><circle cx="10" cy="7" r="4"/><path d="M2 21c0-4 3.6-7 8-7"/><polyline points="16 18 18 20 22 16"/></svg>;
  if (type === "sessions")return <svg {...p}><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>;
  if (type === "reports") return <svg {...p}><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>;
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

// ── Heatmap ───────────────────────────────────────────────────────────────────

function HeatmapGrid({ cells, maxCount }) {
  const { t } = useTranslation();
  const isRtl = i18n.dir() === "rtl";
  const weeks = [];
  for (let i = 0; i < cells.length; i += 7) weeks.push(cells.slice(i, i + 7));
  const swatches = ["#f1f5f9", "#c7d2fe", "#818cf8", "#4338ca", "#000080"];

  return (
    // Force LTR for the heatmap grid itself — time always flows oldest → newest
    <div style={{ direction: "ltr" }}>
      <div style={{ overflowX: "auto", paddingBottom: 4 }}>
        <div style={{ display: "flex", gap: 3, minWidth: "max-content" }}>
          {weeks.map((week, wi) => (
            <div key={wi} style={{ display: "flex", flexDirection: "column", gap: 3 }}>
              {week.map((cell, di) => (
                <div
                  key={di}
                  title={`${cell.date}: ${cell.count}`}
                  style={{
                    width: 14, height: 14, borderRadius: 3,
                    background: heatmapColor(cell.count, maxCount),
                  }}
                />
              ))}
            </div>
          ))}
        </div>
      </div>
      {/* Legend — flip label order in RTL so "أكثر ← swatches → أقل" */}
      <div style={{ display: "flex", alignItems: "center", gap: 5, marginTop: 12, fontSize: 10, color: "#94a3b8", direction: isRtl ? "rtl" : "ltr" }}>
        <span>{isRtl ? t("statistics.more") : t("statistics.less")}</span>
        {swatches.map((c, i) => (
          <div key={i} style={{ width: 12, height: 12, borderRadius: 3, background: c }} />
        ))}
        <span>{isRtl ? t("statistics.less") : t("statistics.more")}</span>
      </div>
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
  const [heatmapCounts,    setHeatmapCounts]    = useState(null);

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

    // ── Activity heatmap ─────────────────────────────────────────────────────
    // Counts report activity per day for the last 84 days.
    async function fetchHeatmap() {
      const since = Timestamp.fromDate(new Date(Date.now() - 84 * 24 * 60 * 60 * 1000));
      const docs  = await safeDocs(query(collection(db, "reports"), where("created_at", ">=", since)));
      const counts = {};
      docs.forEach(d => {
        const date = tsToDate(d.data().created_at);
        if (!date) return;
        const key = date.toISOString().slice(0, 10);
        counts[key] = (counts[key] || 0) + 1;
      });
      setHeatmapCounts(counts);
    }

    fetchKpiAndDist();
    fetchTeacherStatus();
    fetchMonthly();
    fetchHeatmap();
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

  const heatmapCells = heatmapCounts ? getHeatmapCells(heatmapCounts) : null;
  const heatmapMax   = heatmapCells  ? Math.max(1, ...heatmapCells.map(c => c.count)) : 1;
  const userTotal    = userDist       ? userDist.reduce((s, d) => s + d.value, 0) : 0;

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>

      {/* ── KPI Cards ── */}
      <div style={{ display: "flex", flexWrap: "wrap", gap: 14 }}>
        <KpiCard label={t("statistics.totalUsers")}        value={kpi?.totalUsers}        type="users"    bg="#f0f4ff" iconColor="#000080" />
        <KpiCard label={t("statistics.validatedTeachers")} value={kpi?.validatedTeachers} type="teacher"  bg="#f0fdf4" iconColor="#22c55e" />
        <KpiCard label={t("statistics.totalSessions")}     value={kpi?.totalSessions}     type="sessions" bg="#fefce8" iconColor="#f59e0b" />
        <KpiCard label={t("statistics.totalReports")}      value={kpi?.totalReports}      type="reports"  bg="#fef2f2" iconColor="#ef4444" />
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

        {/* Teacher Status Bar */}
        <ChartCard title={t("statistics.teacherStatus")} subtitle={t("statistics.teacherStatusSub")}>
          {teacherStatus === null ? <LoadingBar height={170} /> : (
            /* dir=ltr: Recharts SVG doesn't support RTL */
            <div style={{ direction: "ltr" }}>
              <ResponsiveContainer width="100%" height={170}>
                <BarChart data={teacherStatus} layout="vertical" margin={{ top: 0, right: 44, bottom: 0, left: 6 }}>
                  <CartesianGrid stroke="#f1f5f9" strokeDasharray="4 4" horizontal={false} />
                  <XAxis
                    type="number"
                    tick={{ fontSize: 11, fill: "#94a3b8" }}
                    axisLine={false} tickLine={false}
                    allowDecimals={false}
                  />
                  <YAxis
                    type="category" dataKey="name"
                    tick={{ fontSize: 12, fill: "#374151", fontWeight: 500 }}
                    axisLine={false} tickLine={false}
                    width={76}
                  />
                  <Tooltip content={<ChartTooltip />} cursor={{ fill: "rgba(0,0,128,0.04)" }} />
                  <Bar dataKey="value" radius={[0, 7, 7, 0]} maxBarSize={26} label={{ position: "right", fontSize: 12, fontWeight: 700, fill: "#374151" }}>
                    {teacherStatus.map((e, i) => <Cell key={i} fill={e.fill} />)}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}
        </ChartCard>

        {/* Activity Heatmap */}
        <ChartCard title={t("statistics.activityHeatmap")} subtitle={t("statistics.activityHeatmapSub")}>
          {heatmapCells === null ? <LoadingBar height={130} /> : (
            <HeatmapGrid cells={heatmapCells} maxCount={heatmapMax} />
          )}
        </ChartCard>
      </div>

    </div>
  );
}
