import { useState, useMemo } from "react";
import {
  collection, writeBatch, doc, getDocs,
  setDoc, Timestamp, query, where, limit,
} from "firebase/firestore";
import { getAuth } from "firebase/auth";
import { db } from "./firebase";

// ── Data pools ───────────────────────────────────────────────────────────────
const M_NAMES = ["Mohamed","Ahmed","Youcef","Amine","Riad","Karim","Bilal","Anis","Zakaria","Hocine",
  "Sofiane","Nassim","Walid","Mehdi","Adel","Samir","Tarek","Fares","Ilyes","Ayoub",
  "Ryad","Omar","Redha","Islam","Lotfi","Hamza","Sami","Nadir","Rachid","Aziz",
  "Djamel","Fouad","Hakim","Mounir","Nabil","Oussama","Ramzi","Sifeddine","Toufik","Zine"];
const F_NAMES = ["Amira","Sara","Lina","Yasmine","Nour","Meriem","Fatima","Hafsa","Ines","Rima",
  "Asma","Lamia","Sabrina","Djamila","Houda","Wafa","Sihem","Chaima","Dina","Rania",
  "Manel","Imane","Selma","Nadine","Leila","Sonia","Hana","Rim","Cylia","Feriel",
  "Karima","Lynda","Naima","Ouarda","Samira","Thiziri","Wissam","Zahia","Amel","Baya"];
const LASTNAMES = ["Benali","Khelil","Meziane","Boudaoud","Hamidi","Chérif","Mansouri","Hadj","Benamor",
  "Tebib","Laouari","Boubekeur","Ferhat","Zerrouk","Aissaoui","Boukhalfa","Chabane","Mebarki",
  "Rahmani","Lounici","Belarbi","Djilali","Belkacemi","Bouaziz","Guerrouf","Kaced","Malek",
  "Sahraoui","Touati","Ziani","Benkhaled","Amrani","Djaballah","Boumaza","Benbrahim",
  "Gharbi","Miloudi","Salhi","Benmoussa","Hadjadj","Boufeldja","Cheniti","Drif","Essid","Fellah"];
const CITIES = ["Algiers","Oran","Constantine","Annaba","Blida","Batna","Djelfa","Sétif",
  "Sidi Bel Abbès","Biskra","Tébessa","El Oued","Skikda","Tiaret","Béjaïa","Tlemcen",
  "Béchar","Mostaganem","Bordj Bou Arréridj","Chlef","Médéa","Boumerdès","Tizi Ouzou",
  "Jijel","Mascara","Khenchela","Guelma","Souk Ahras","Mila","Relizane"];
const SCHOOL_LEVELS = ["middle_school","high_school","university"];
const GRADES = {
  middle_school: ["1AM","2AM","3AM","4AM"],
  high_school:   ["1AS","2AS","3AS"],
  university:    ["L1","L2","L3","M1","M2"],
};
const SPECIALITIES = {
  middle_school: ["General"],
  high_school:   ["Sciences","Mathematics","Lettres et Langues Étrangères","Gestion et Économie","Technique Mathématique"],
  university:    ["Computer Science","Mathematics","Physics","Chemistry","Law","Economics","Medicine","Engineering","Architecture"],
};
const ALL_SUBJECTS = ["Mathematics","Physics","Chemistry","Biology","History","Geography",
  "Arabic","French","English","Philosophy","Economics","Computer Science","Algebra","Calculus"];
const OBJECTIVES = [
  "Improve my grades and understanding of core subjects",
  "Prepare thoroughly for the BAC exam",
  "Strengthen my fundamentals in science and math",
  "Catch up on missed material from previous semesters",
  "Advance beyond the standard school curriculum",
  "Prepare for university entrance competitive exams",
  "Master problem-solving techniques for complex exercises",
  "Build confidence in analytical and abstract subjects",
  "Develop a strong study methodology and discipline",
  "Improve my French and English academic proficiency",
];
const SVC_TEMPLATES = [
  (d) => `${d} Fundamentals`,
  (d) => `Advanced ${d}`,
  (d) => `${d} Exam Preparation`,
  (d) => `${d} Problem Solving Workshop`,
  (d) => `${d} Intensive Program`,
  (d) => `Applied ${d}`,
  (d) => `${d} Mastery Course`,
  (d) => `${d} for Beginners`,
];
const SVC_DESC = (name, domain) =>
  `This course — "${name}" — covers essential and advanced topics in ${domain}. ` +
  `Through structured lessons, targeted exercises and regular assessments, students build ` +
  `deep conceptual understanding and strong problem-solving skills. ` +
  `Ideal for students seeking to improve their academic performance or prepare for exams.`;

const REPORT_TEXTS = [
  "This teacher was consistently late to sessions and never notified students in advance.",
  "The content taught was well below the level advertised. Very disappointed with the quality.",
  "This teacher cancelled two sessions without offering a refund or rescheduling.",
  "I suspect this profile has false credentials. The claimed qualifications seem exaggerated.",
  "Unprofessional behavior — dismissive and rude during our last session.",
  "Teaching method is outdated and the exercises were copied from free online resources.",
  "Teacher stopped responding to messages after receiving payment.",
  "Sessions were consistently shorter than promised with no explanation given.",
  "The teacher kept pushing additional paid services during each session.",
  "Knowledgeable but explains too fast and refuses to slow down when asked.",
  "No progress after 6 sessions. The approach does not adapt to the student's level.",
  "Session was cancelled 10 minutes before start time with no alternative offered.",
];

const FEEDBACK_TEXTS = {
  5: [
    "Outstanding teacher! My grades improved significantly after just a few sessions.",
    "Absolutely brilliant — clear explanations, patient, and very knowledgeable. Highly recommend!",
    "The best tutor I have ever had. Made complex topics feel simple and approachable.",
    "My son went from failing to top of his class. Cannot thank this teacher enough!",
    "Exceptional pedagogy. Every session is well-structured and engaging. Worth every dinar.",
    "I finally understood calculus after years of struggling. Truly gifted at teaching.",
  ],
  4: [
    "Very good teacher overall. Explains concepts clearly and always comes prepared.",
    "Good experience. Would have liked more exercises but the theory was solid.",
    "Solid tutor — punctual and professional. A few sessions could be more interactive.",
    "Really helpful. My understanding of the subject improved a lot over the past month.",
    "Responsive and patient. Makes a real effort to adapt to the student's learning pace.",
  ],
  3: [
    "Decent teacher. Some sessions were better than others. Has room to improve.",
    "Average experience. Content was okay but I expected more personalized attention.",
    "Sessions sometimes feel rushed. Better time management would help a lot.",
    "Mixed feelings. Knows the subject but struggles to explain it in simple terms.",
    "Acceptable but nothing exceptional. The price is a bit high for what is offered.",
  ],
  2: [
    "Disappointed. The sessions did not match what was advertised at all.",
    "The teacher was often unprepared and seemed distracted during our sessions.",
    "Too much theory with no practical exercises. Did not help with exam preparation.",
    "Rarely available at the agreed time. Communication is very poor.",
  ],
  1: [
    "Terrible experience. Would not recommend to anyone.",
    "Complete waste of time and money. The teacher barely showed up on time.",
    "Very poor quality. The expertise claimed on the profile is clearly not accurate.",
    "Rude and dismissive. No effort was made to help the student understand the material.",
  ],
};

const SESSION_NOTES = [
  "Review of last week's exercises and introduction to derivatives.",
  "Problem-solving session focused on quadratic equations and inequalities.",
  "Exam preparation — past papers and time management strategies.",
  "Deep dive into Newton's laws and their real-world applications.",
  "Grammar revision and written expression practice for the BAC.",
  "Introduction to organic chemistry fundamentals.",
  "Comprehension exercises and vocabulary building.",
  "Algebra review: polynomials, factoring, and simplification.",
  "Practice session using official national BAC exam format.",
  "Student requested focus on weak areas identified in last assessment.",
  "Correction of homework and clarification of doubts from previous session.",
  "Mock oral exam with feedback on pronunciation and structure.",
  "",
  "",
];

// ── Helpers ──────────────────────────────────────────────────────────────────
const pick   = (arr) => arr[Math.floor(Math.random() * arr.length)];
const randInt= (a, b) => Math.floor(Math.random() * (b - a + 1)) + a;
const shuffle= (arr) => [...arr].sort(() => Math.random() - 0.5);
const subset = (arr, a, b) => shuffle(arr).slice(0, randInt(a, b));
const makeId = (prefix) => `${prefix}_${Math.random().toString(36).slice(2,9)}${Math.random().toString(36).slice(2,6)}`;
const daysAgo= (d) => new Date(Date.now() - d * 86_400_000);
const algPhone= () => `+213 ${pick(["5","6","7"])}${Array.from({length:8},()=>randInt(0,9)).join("")}`;

async function commitBatches(ops, log, label) {
  const LIMIT = 450;
  const total = Math.ceil(ops.length / LIMIT);
  for (let i = 0; i < ops.length; i += LIMIT) {
    const batch = writeBatch(db);
    ops.slice(i, i + LIMIT).forEach(({ type, ref, data }) => {
      if (type === "set")    batch.set(ref, data);
      else                   batch.update(ref, data);
    });
    await batch.commit();
    if (total > 1) log(`   batch ${Math.floor(i / LIMIT) + 1}/${total} committed`);
  }
  log(`✓ ${ops.length} ${label} written`);
}

// ── Seed function ─────────────────────────────────────────────────────────────
export async function runSeed(cfg, log) {
  // 0. Ensure admin doc exists
  log("⟳ Verifying admin identity…");
  const currentUser = getAuth().currentUser;
  if (!currentUser) throw new Error("Not authenticated — please log in first.");
  await setDoc(doc(db, "admins", currentUser.uid), { uid: currentUser.uid }, { merge: true });
  log(`✓ Admin verified (${currentUser.email})`);

  // 1. Load existing teachers
  log("⟳ Loading teachers…");
  const tutorsSnap = await getDocs(collection(db, "tutors"));
  const teachers = tutorsSnap.docs.map((d) => ({ firestoreId: d.id, ...d.data() }));
  if (!teachers.length) throw new Error("No teachers found in Firestore. Add at least one teacher first.");
  log(`✓ Found ${teachers.length} teacher(s)`);

  // 2. Generate services per teacher
  log(`⟳ Building ${cfg.servicesMin}–${cfg.servicesMax} services per teacher…`);
  const allServices = [];
  const teacherServices = {};

  for (const t of teachers) {
    const domain  = (t.expertise_domain || "General Studies").trim();
    const levels  = t.levels_taught?.length ? t.levels_taught : ["high_school"];
    const mode    = t.teaching_mode || "hybrid";
    const city    = t.location || pick(CITIES);
    const count   = randInt(cfg.servicesMin, cfg.servicesMax);
    const names   = shuffle(SVC_TEMPLATES).slice(0, count);
    teacherServices[t.firestoreId] = [];

    for (let j = 0; j < count; j++) {
      const id   = makeId("svc");
      const name = names[j](domain);
      const svc  = {
        _id:          id,
        service_id:   id,
        tutor_id:     t.firestoreId,
        name,
        area:         city,
        level:        pick(levels).replace(/_/g, " "),
        subject:      domain,
        mode,
        description:  SVC_DESC(name, domain),
        price:        randInt(800, 5000),
        duration:     pick([60, 90, 120]),
        sessions_num: randInt(8, 24),
        enrolled_num: 0,
        maxstudents:  randInt(cfg.capacityMin, cfg.capacityMax),
        is_active:    true,
        student_ids:  [],
        pending_ids:  [],
        picture:      `https://picsum.photos/seed/${id}/400/200`,
        created_at:   Timestamp.fromDate(daysAgo(randInt(30, 365))),
        updated_at:   Timestamp.fromDate(new Date()),
      };
      allServices.push(svc);
      teacherServices[t.firestoreId].push(svc);
    }
  }
  log(`✓ Built ${allServices.length} service(s)`);

  // 3. Generate students
  log(`⟳ Generating ${cfg.students} student(s)…`);
  const students = [];
  for (let i = 0; i < cfg.students; i++) {
    const gender    = Math.random() < 0.5 ? "male" : "female";
    const firstName = pick(gender === "male" ? M_NAMES : F_NAMES);
    const lastName  = pick(LASTNAMES);
    const level     = pick(SCHOOL_LEVELS);
    const id        = makeId("stu");
    students.push({
      _id:          id,
      uid:          id,
      first_name:   firstName,
      last_name:    lastName,
      email:        `${firstName.toLowerCase()}.${lastName.toLowerCase().replace(/[^a-z]/g,"")}${i}@student.fahamni.dz`,
      phone:        algPhone(),
      location:     pick(CITIES),
      gender,
      birthday:     Timestamp.fromDate(daysAgo(randInt(14, 24) * 365 + randInt(0, 365))),
      picture:      `https://i.pravatar.cc/150?u=stu_${i}_${id}`,
      role:         "student",
      account_status: "validated",
      is_suspended: false,
      school_level:        level,
      grade:               pick(GRADES[level]),
      speciality:          pick(SPECIALITIES[level]),
      learning_objectives: pick(OBJECTIVES),
      preferred_subjects:  subset(ALL_SUBJECTS, 2, 4),
      favorite_teachers:   [],
      courses:             [],
      created_at: Timestamp.fromDate(daysAgo(randInt(10, 600))),
    });
  }
  log(`✓ Generated ${students.length} student(s)`);

  // 4. Generate parents + children
  let allParents  = [];
  let allChildren = [];
  if (cfg.parents > 0) {
    log(`⟳ Generating ${cfg.parents} parent(s) with ${cfg.childrenMin}–${cfg.childrenMax} children each…`);
    for (let i = 0; i < cfg.parents; i++) {
      const gender    = Math.random() < 0.5 ? "male" : "female";
      const firstName = pick(gender === "male" ? M_NAMES : F_NAMES);
      const lastName  = pick(LASTNAMES);
      const parentId  = makeId("par");
      const numKids   = randInt(cfg.childrenMin, cfg.childrenMax);
      const childIds  = [];

      for (let k = 0; k < numKids; k++) {
        const cGender    = Math.random() < 0.5 ? "male" : "female";
        const cFirstName = pick(cGender === "male" ? M_NAMES : F_NAMES);
        const cLevel     = pick(SCHOOL_LEVELS);
        const childId    = makeId("chd");
        childIds.push(childId);
        allChildren.push({
          _id:        childId,
          id:         childId,
          name:       `${cFirstName} ${lastName}`,
          gender:     cGender,
          level:      cLevel,
          grade:      pick(GRADES[cLevel]),
          speciality: pick(SPECIALITIES[cLevel]),
          subjects:   subset(ALL_SUBJECTS, 2, 4),
          picture:    `https://i.pravatar.cc/150?u=chd_${childId}`,
          parentUid:  parentId,
        });
      }

      allParents.push({
        _id:          parentId,
        uid:          parentId,
        first_name:   firstName,
        last_name:    lastName,
        email:        `${firstName.toLowerCase()}.${lastName.toLowerCase().replace(/[^a-z]/g,"")}${i}@parent.fahamni.dz`,
        phone:        algPhone(),
        location:     pick(CITIES),
        gender,
        birthday:     Timestamp.fromDate(daysAgo(randInt(30, 55) * 365 + randInt(0, 365))),
        picture:      `https://i.pravatar.cc/150?u=par_${i}_${parentId}`,
        role:         "parent",
        account_status: "validated",
        is_suspended: false,
        children_uids: childIds,
        created_at:   Timestamp.fromDate(daysAgo(randInt(10, 600))),
      });
    }
    log(`✓ Generated ${allParents.length} parent(s) and ${allChildren.length} child(ren)`);
  }

  // 5. Enroll students in services
  log("⟳ Assigning students to services…");
  const enrolled = new Set();

  function enroll(student, svc) {
    const key = `${student._id}::${svc._id}`;
    if (enrolled.has(key) || svc.student_ids.length >= svc.maxstudents) return false;
    enrolled.add(key);
    svc.student_ids.push(student._id);
    svc.enrolled_num++;
    student.courses.push(svc._id);
    if (!student.favorite_teachers.includes(svc.tutor_id))
      student.favorite_teachers.push(svc.tutor_id);
    return true;
  }

  // Pass 1: guarantee min students per teacher
  for (const t of teachers) {
    const svcs = teacherServices[t.firestoreId];
    for (const stu of shuffle(students).slice(0, cfg.guaranteedPerTeacher))
      enroll(stu, pick(svcs));
  }
  // Pass 2: random extra enrollment per student
  for (const stu of shuffle(students)) {
    for (const svc of shuffle(allServices).slice(0, randInt(cfg.enrollMin, cfg.enrollMax)))
      enroll(stu, svc);
  }
  // Pass 3: ensure every student is in at least one service
  for (const stu of students)
    if (!stu.courses.length) enroll(stu, pick(allServices));

  log(`✓ Total enrolments: ${enrolled.size}`);

  // 6. Compute teacher counters
  const tutorOps = teachers.map((t) => {
    const svcs          = teacherServices[t.firestoreId];
    const uniqueStudents = new Set(svcs.flatMap((s) => s.student_ids));
    const data = { students_count: uniqueStudents.size, courses_count: svcs.length };
    log(`   ${t.first_name ?? ""} ${t.last_name ?? ""} → ${data.courses_count} courses, ${data.students_count} students`);
    return { type: "update", ref: doc(collection(db, "tutors"), t.firestoreId), data };
  });

  // 7. Write everything
  log("⟳ Writing students…");
  await commitBatches(
    students.map(({ _id, ...d }) => ({ type:"set", ref: doc(collection(db,"students"),_id), data:d })),
    log, "students"
  );

  log("⟳ Writing services…");
  await commitBatches(
    allServices.map(({ _id, ...d }) => ({ type:"set", ref: doc(collection(db,"services"),_id), data:d })),
    log, "services"
  );

  if (allParents.length) {
    log("⟳ Writing parents…");
    await commitBatches(
      allParents.map(({ _id, ...d }) => ({ type:"set", ref: doc(collection(db,"parents"),_id), data:d })),
      log, "parents"
    );
  }

  if (allChildren.length) {
    log("⟳ Writing children…");
    await commitBatches(
      allChildren.map(({ _id, ...d }) => ({ type:"set", ref: doc(collection(db,"children"),_id), data:d })),
      log, "children"
    );
  }

  log("⟳ Updating teacher counters…");
  await commitBatches(tutorOps, log, "teacher counters");

  log("🎉 Seed complete!");
  return {
    students:  students.length,
    parents:   allParents.length,
    children:  allChildren.length,
    services:  allServices.length,
    teachers:  teachers.length,
    enrolments: enrolled.size,
  };
}

// ── Inject function (sessions + reports + feedbacks into existing data) ───────
export async function runInject(cfg, log) {
  log("⟳ Verifying admin identity…");
  const currentUser = getAuth().currentUser;
  if (!currentUser) throw new Error("Not authenticated — please log in first.");
  log(`✓ Admin verified (${currentUser.email})`);

  // 1. Load existing teachers
  log("⟳ Loading teachers…");
  const tutorsSnap = await getDocs(collection(db, "tutors"));
  const teachers = tutorsSnap.docs.map(d => ({ firestoreId: d.id, ...d.data() }));
  if (!teachers.length) throw new Error("No teachers found. Add teachers first.");
  log(`✓ Found ${teachers.length} teacher(s)`);

  // 2. Load existing services
  log("⟳ Loading services…");
  const servicesSnap = await getDocs(collection(db, "services"));
  const services = servicesSnap.docs.map(d => ({ firestoreId: d.id, ...d.data() }));
  if (!services.length) throw new Error("No services found. Run the main seed first.");
  log(`✓ Found ${services.length} service(s)`);

  // 3. Generate sessions
  log(`⟳ Generating ${cfg.sessionsMin}–${cfg.sessionsMax} sessions per service…`);
  const sessions = [];
  for (const svc of services) {
    const count       = randInt(cfg.sessionsMin, cfg.sessionsMax);
    const modality    = svc.mode ?? pick(["online", "in_person", "hybrid"]);
    const studentPool = Array.isArray(svc.student_ids) ? svc.student_ids : [];

    for (let i = 0; i < count; i++) {
      const id         = makeId("ses");
      const daysOff    = randInt(-60, 30);
      const base       = new Date(Date.now() + daysOff * 86_400_000);
      base.setHours(randInt(8, 19), 0, 0, 0);
      const end        = new Date(base.getTime() + (svc.duration ?? 90) * 60_000);
      const past       = daysOff < 0;
      const statusPool = past
        ? ["Completed","Completed","Completed","Canceled"]
        : ["Planned","Planned","Ongoing"];
      const sessionStudents = studentPool.length
        ? shuffle(studentPool).slice(0, randInt(1, Math.min(studentPool.length, 10)))
        : [];

      sessions.push({
        id,
        session_id:   id,
        service_id:   svc.firestoreId,
        tutor_id:     svc.tutor_id,
        student_ids:  sessionStudents,
        status:       pick(statusPool),
        type:         sessionStudents.length > 1 ? "group" : "individual",
        modality,
        mode:         modality,
        meeting_link: modality !== "in_person"
          ? `https://meet.google.com/${id.slice(4, 14)}`
          : "",
        notes:        pick(SESSION_NOTES),
        date:         Timestamp.fromDate(base),
        start_time:   Timestamp.fromDate(base),
        end_time:     Timestamp.fromDate(end),
      });
    }
  }
  log(`✓ Built ${sessions.length} session(s)`);

  // 4. Generate reports per teacher
  log(`⟳ Generating ${cfg.reportsMin}–${cfg.reportsMax} reports per teacher…`);
  const reports = [];
  for (const t of teachers) {
    const count       = randInt(cfg.reportsMin, cfg.reportsMax);
    const teacherName = `${t.first_name ?? ""} ${t.last_name ?? ""}`.trim();
    for (let i = 0; i < count; i++) {
      const id       = makeId("rpt");
      const rGender  = Math.random() < 0.5 ? "male" : "female";
      const rName    = `${pick(rGender === "male" ? M_NAMES : F_NAMES)} ${pick(LASTNAMES)}`;
      reports.push({
        id,
        report_id:     id,
        reporter_uid:  makeId("usr"),
        reporter_name: rName,
        reported_id:   t.firestoreId,
        reported_name: teacherName,
        type:          "teacher",
        text:          pick(REPORT_TEXTS),
        created_at:    Timestamp.fromDate(daysAgo(randInt(1, 180))),
        status:        pick(["pending","pending","pending","reviewed","reviewed","resolved","dismissed"]),
      });
    }
  }
  log(`✓ Built ${reports.length} report(s)`);

  // 5. Generate feedbacks per teacher
  log(`⟳ Generating ${cfg.feedbacksMin}–${cfg.feedbacksMax} feedbacks per teacher…`);
  const feedbacks = [];
  for (const t of teachers) {
    const count = randInt(cfg.feedbacksMin, cfg.feedbacksMax);
    for (let i = 0; i < count; i++) {
      const id      = makeId("fb");
      const fGender = Math.random() < 0.5 ? "male" : "female";
      const fName   = `${pick(fGender === "male" ? M_NAMES : F_NAMES)} ${pick(LASTNAMES)}`;
      const rating  = pick([5,5,5,4,4,4,4,3,3,2,1]);
      const texts   = FEEDBACK_TEXTS[rating];
      const text    = pick(texts);
      feedbacks.push({
        id,
        tutor_id:         t.firestoreId,
        reviewer_id:      makeId("usr"),
        reviewer_name:    fName,
        student_name:     fName,
        reviewer_picture: `https://i.pravatar.cc/150?u=fb_${id}`,
        student_picture:  `https://i.pravatar.cc/150?u=fb_${id}`,
        rating,
        text,
        comment:          text,
        created_at:       Timestamp.fromDate(daysAgo(randInt(1, 365))),
      });
    }
  }
  log(`✓ Built ${feedbacks.length} feedback(s)`);

  // 6. Write all
  log("⟳ Writing sessions…");
  await commitBatches(
    sessions.map(({ id, ...d }) => ({ type:"set", ref: doc(collection(db,"sessions"),id), data:d })),
    log, "sessions"
  );

  log("⟳ Writing reports…");
  await commitBatches(
    reports.map(({ id, ...d }) => ({ type:"set", ref: doc(collection(db,"reports"),id), data:d })),
    log, "reports"
  );

  log("⟳ Writing feedbacks…");
  await commitBatches(
    feedbacks.map(({ id, ...d }) => ({ type:"set", ref: doc(collection(db,"feedbacks"),id), data:d })),
    log, "feedbacks"
  );

  log("🎉 Inject complete!");
  return { sessions: sessions.length, reports: reports.length, feedbacks: feedbacks.length };
}

// ── Config defaults ───────────────────────────────────────────────────────────
const DEFAULTS = {
  students:           200,
  parents:             50,
  childrenMin:          1,
  childrenMax:          3,
  servicesMin:          2,
  servicesMax:          5,
  capacityMin:         18,
  capacityMax:         40,
  enrollMin:            1,
  enrollMax:            3,
  guaranteedPerTeacher: 3,
};

const INJECT_DEFAULTS = {
  sessionsMin:   4,
  sessionsMax:   10,
  reportsMin:    3,
  reportsMax:    8,
  feedbacksMin:  6,
  feedbacksMax:  18,
};

// ── UI components ─────────────────────────────────────────────────────────────
function NumField({ label, hint, value, onChange, min = 0, max = 9999 }) {
  return (
    <div style={sf.field}>
      <div style={sf.fieldLabel}>{label}</div>
      {hint && <div style={sf.fieldHint}>{hint}</div>}
      <div style={sf.numRow}>
        <button style={sf.nudge} onClick={() => onChange(Math.max(min, value - 1))}>−</button>
        <input
          type="number"
          style={sf.numInput}
          value={value}
          min={min}
          max={max}
          onChange={e => {
            const v = parseInt(e.target.value, 10);
            if (!isNaN(v)) onChange(Math.max(min, Math.min(max, v)));
          }}
        />
        <button style={sf.nudge} onClick={() => onChange(Math.min(max, value + 1))}>+</button>
      </div>
    </div>
  );
}

function RangeField({ label, hint, valueMin, valueMax, onMin, onMax, min = 0, max = 9999 }) {
  return (
    <div style={sf.field}>
      <div style={sf.fieldLabel}>{label}</div>
      {hint && <div style={sf.fieldHint}>{hint}</div>}
      <div style={{ display:"flex", alignItems:"center", gap:10, marginTop:6 }}>
        <div style={sf.numRow}>
          <button style={sf.nudge} onClick={() => onMin(Math.max(min, valueMin - 1))}>−</button>
          <input type="number" style={{ ...sf.numInput, width:52 }} value={valueMin} min={min} max={valueMax}
            onChange={e => { const v=parseInt(e.target.value,10); if(!isNaN(v)) onMin(Math.max(min,Math.min(valueMax,v))); }} />
          <button style={sf.nudge} onClick={() => onMin(Math.min(valueMax, valueMin + 1))}>+</button>
        </div>
        <span style={{ color:"#94a3b8", fontSize:12 }}>to</span>
        <div style={sf.numRow}>
          <button style={sf.nudge} onClick={() => onMax(Math.max(valueMin, valueMax - 1))}>−</button>
          <input type="number" style={{ ...sf.numInput, width:52 }} value={valueMax} min={valueMin} max={max}
            onChange={e => { const v=parseInt(e.target.value,10); if(!isNaN(v)) onMax(Math.max(valueMin,Math.min(max,v))); }} />
          <button style={sf.nudge} onClick={() => onMax(Math.min(max, valueMax + 1))}>+</button>
        </div>
      </div>
    </div>
  );
}

function ConfigCard({ title, icon, children }) {
  return (
    <div style={sf.card}>
      <div style={sf.cardHead}>
        <span style={sf.cardIcon}>{icon}</span>
        <span style={sf.cardTitle}>{title}</span>
      </div>
      <div style={sf.cardBody}>{children}</div>
    </div>
  );
}

// ── Main page ─────────────────────────────────────────────────────────────────
export default function SeedPage() {
  const [cfg, setCfg]         = useState(DEFAULTS);
  const [lines, setLines]     = useState([]);
  const [state, setState]     = useState("idle");
  const [summary, setSummary] = useState(null);

  const [icfg, setIcfg]           = useState(INJECT_DEFAULTS);
  const [iLines, setILines]       = useState([]);
  const [iState, setIState]       = useState("idle");
  const [iSummary, setISummary]   = useState(null);

  const set  = (key) => (val) => setCfg(prev => ({ ...prev, [key]: val }));
  const iset = (key) => (val) => setIcfg(prev => ({ ...prev, [key]: val }));

  const estServices = useMemo(() => {
    // approximate teachers count unknown, show per-teacher range
    return `${cfg.servicesMin}–${cfg.servicesMax} per teacher`;
  }, [cfg.servicesMin, cfg.servicesMax]);

  const estChildren = useMemo(() =>
    `~${Math.round(cfg.parents * (cfg.childrenMin + cfg.childrenMax) / 2)} children`,
    [cfg.parents, cfg.childrenMin, cfg.childrenMax]
  );

  function addLine(msg) {
    setLines(prev => [...prev, { id: Date.now() + Math.random(), msg }]);
  }

  async function start() {
    setState("checking");
    setLines([]);
    setSummary(null);
    try {
      const check = await getDocs(query(collection(db, "students"), where("uid", ">=", "stu_"), limit(1)));
      if (!check.empty) { setState("already_seeded"); return; }
    } catch { /* proceed */ }

    setState("running");
    try {
      const result = await runSeed(cfg, addLine);
      setSummary(result);
      setState("done");
    } catch (e) {
      addLine(`❌ ERROR: ${e.message}`);
      if (e.code) addLine(`   Firebase code: ${e.code}`);
      addLine("   Open DevTools (F12) for the full stack trace.");
      setState("error");
    }
  }

  async function startInject() {
    setIState("running");
    setILines([]);
    setISummary(null);
    const addILine = (msg) => setILines(prev => [...prev, { id: Date.now() + Math.random(), msg }]);
    try {
      const result = await runInject(icfg, addILine);
      setISummary(result);
      setIState("done");
    } catch (e) {
      addILine(`❌ ERROR: ${e.message}`);
      if (e.code) addILine(`   Firebase code: ${e.code}`);
      addILine("   Open DevTools (F12) for the full stack trace.");
      setIState("error");
    }
  }

  const isRunning  = state === "checking" || state === "running";
  const isInjecting = iState === "running";

  return (
    <div style={s.page}>

      {/* Header */}
      <div style={s.header}>
        <h1 style={s.title}>Data Seeder</h1>
        <p style={s.sub}>Configure the volume of test data then click Run Seed. Runs only once — blocked if seed data already exists.</p>
      </div>

      {/* Config grid */}
      <div style={s.grid}>

        <ConfigCard title="Students" icon="🎓">
          <NumField label="Count" hint="Total student accounts to create"
            value={cfg.students} onChange={set("students")} min={1} max={2000} />
        </ConfigCard>

        <ConfigCard title="Parents" icon="👨‍👩‍👧">
          <NumField label="Count" hint="Total parent accounts to create (0 to skip)"
            value={cfg.parents} onChange={set("parents")} min={0} max={1000} />
          <RangeField label="Children per parent" hint="Range of child profiles per parent"
            valueMin={cfg.childrenMin} valueMax={cfg.childrenMax}
            onMin={set("childrenMin")} onMax={set("childrenMax")} min={1} max={10} />
        </ConfigCard>

        <ConfigCard title="Services" icon="📚">
          <RangeField label="Per teacher" hint="How many services each teacher gets"
            valueMin={cfg.servicesMin} valueMax={cfg.servicesMax}
            onMin={set("servicesMin")} onMax={set("servicesMax")} min={1} max={20} />
          <RangeField label="Capacity per service" hint="Max students a service can hold"
            valueMin={cfg.capacityMin} valueMax={cfg.capacityMax}
            onMin={set("capacityMin")} onMax={set("capacityMax")} min={5} max={200} />
        </ConfigCard>

        <ConfigCard title="Enrollment" icon="🔗">
          <RangeField label="Extra services per student" hint="Random extra services each student joins"
            valueMin={cfg.enrollMin} valueMax={cfg.enrollMax}
            onMin={set("enrollMin")} onMax={set("enrollMax")} min={0} max={20} />
          <NumField label="Guaranteed students per teacher" hint="Minimum students forced onto each teacher"
            value={cfg.guaranteedPerTeacher} onChange={set("guaranteedPerTeacher")} min={1} max={50} />
        </ConfigCard>

      </div>

      {/* Summary bar */}
      <div style={s.summary}>
        <SumChip label="Students"  value={cfg.students} />
        <SumChip label="Parents"   value={cfg.parents} />
        <SumChip label="Children"  value={estChildren} />
        <SumChip label="Services"  value={estServices} />
      </div>

      {/* Action */}
      {state === "idle" && (
        <button style={s.runBtn} onClick={start}>Run Seed</button>
      )}
      {isRunning && (
        <button style={{ ...s.runBtn, background:"#94a3b8", cursor:"not-allowed" }} disabled>
          {state === "checking" ? "Checking…" : "Running…"}
        </button>
      )}
      {state === "already_seeded" && (
        <div style={{ ...s.banner, background:"#fffbeb", color:"#b45309", borderColor:"#fde68a" }}>
          ⚠️ Seed data already exists — database was not modified.
        </div>
      )}
      {state === "done" && summary && (
        <div style={s.banner}>
          ✅ Done — {summary.students} students · {summary.parents} parents ·{" "}
          {summary.children} children · {summary.services} services ·{" "}
          {summary.enrolments} enrolments
        </div>
      )}
      {state === "error" && (
        <div style={{ ...s.banner, background:"#fef2f2", color:"#dc2626", borderColor:"#fecaca" }}>
          Seed failed — see log below.
        </div>
      )}

      {/* Log */}
      {lines.length > 0 && (
        <div style={s.logBox}>
          {lines.map(l => <div key={l.id} style={s.logLine}>{l.msg}</div>)}
        </div>
      )}

      {/* ── Inject section ── */}
      <div style={s.divider} />
      <div style={s.header}>
        <h2 style={s.injectTitle}>Inject into Existing Data</h2>
        <p style={s.sub}>Adds sessions to existing services, and reports + feedbacks to all teachers. Safe to run multiple times.</p>
      </div>

      <div style={s.grid}>
        <ConfigCard title="Sessions" icon="📅">
          <RangeField label="Per service" hint="Sessions generated per existing service"
            valueMin={icfg.sessionsMin} valueMax={icfg.sessionsMax}
            onMin={iset("sessionsMin")} onMax={iset("sessionsMax")} min={1} max={30} />
        </ConfigCard>

        <ConfigCard title="Reports" icon="🚩">
          <RangeField label="Per teacher" hint="Complaint reports filed against each teacher"
            valueMin={icfg.reportsMin} valueMax={icfg.reportsMax}
            onMin={iset("reportsMin")} onMax={iset("reportsMax")} min={1} max={30} />
        </ConfigCard>

        <ConfigCard title="Feedbacks" icon="⭐">
          <RangeField label="Per teacher" hint="Student feedback reviews per teacher (rating 1–5)"
            valueMin={icfg.feedbacksMin} valueMax={icfg.feedbacksMax}
            onMin={iset("feedbacksMin")} onMax={iset("feedbacksMax")} min={1} max={50} />
        </ConfigCard>
      </div>

      {(iState === "idle" || iState === "done" || iState === "error") && (
        <button style={s.injectBtn} onClick={startInject}>Inject Sessions, Reports & Feedbacks</button>
      )}
      {isInjecting && (
        <button style={{ ...s.injectBtn, background:"#94a3b8", cursor:"not-allowed" }} disabled>Running…</button>
      )}
      {iState === "done" && iSummary && (
        <div style={s.banner}>
          ✅ Injected — {iSummary.sessions} sessions · {iSummary.reports} reports · {iSummary.feedbacks} feedbacks
        </div>
      )}
      {iState === "error" && (
        <div style={{ ...s.banner, background:"#fef2f2", color:"#dc2626", borderColor:"#fecaca" }}>
          Inject failed — see log below. Fix the issue and click the button again.
        </div>
      )}

      {iLines.length > 0 && (
        <div style={s.logBox}>
          {iLines.map(l => <div key={l.id} style={s.logLine}>{l.msg}</div>)}
        </div>
      )}

    </div>
  );
}

function SumChip({ label, value }) {
  return (
    <div style={sf.chip}>
      <div style={sf.chipVal}>{value}</div>
      <div style={sf.chipLabel}>{label}</div>
    </div>
  );
}

// ── Styles ────────────────────────────────────────────────────────────────────
const s = {
  page:        { display:"flex", flexDirection:"column", gap:20, height:"100%", minHeight:0, overflowY:"auto" },
  header:      { flexShrink:0 },
  title:       { fontSize:28, fontWeight:800, color:"#1F2937", margin:"0 0 6px" },
  injectTitle: { fontSize:20, fontWeight:700, color:"#1F2937", margin:"0 0 6px" },
  sub:         { fontSize:13, color:"#64748b", margin:0, lineHeight:1.6 },
  divider:     { borderTop:"2px dashed #e2e8f0", margin:"8px 0" },
  injectBtn: {
    alignSelf:"flex-start", padding:"12px 36px", borderRadius:24, border:"none",
    background:"#6366f1", color:"#fff", fontSize:14, fontWeight:700, cursor:"pointer",
    flexShrink:0,
  },
  grid:   { display:"grid", gridTemplateColumns:"repeat(auto-fill, minmax(260px,1fr))", gap:14, flexShrink:0 },
  summary:{ display:"flex", gap:12, flexWrap:"wrap", flexShrink:0 },
  runBtn: {
    alignSelf:"flex-start", padding:"12px 36px", borderRadius:24, border:"none",
    background:"#000080", color:"#fff", fontSize:14, fontWeight:700, cursor:"pointer",
    flexShrink:0,
  },
  banner: {
    padding:"14px 20px", borderRadius:12, border:"1px solid #bbf7d0",
    background:"#f0fdf4", color:"#16a34a", fontSize:14, fontWeight:600, flexShrink:0,
  },
  logBox: {
    flex:1, minHeight:160, overflowY:"auto", background:"#0f172a", borderRadius:14,
    padding:"16px 20px", fontFamily:"'Courier New', monospace",
  },
  logLine:{ fontSize:12, color:"#94a3b8", lineHeight:1.9, whiteSpace:"pre-wrap" },
};

const sf = {
  card:      { background:"#fff", borderRadius:14, border:"1px solid #f1f5f9", padding:"16px 18px", boxShadow:"0 2px 8px rgba(0,0,0,0.04)" },
  cardHead:  { display:"flex", alignItems:"center", gap:8, marginBottom:14, paddingBottom:12, borderBottom:"1px solid #f1f5f9" },
  cardIcon:  { fontSize:18 },
  cardTitle: { fontSize:14, fontWeight:700, color:"#1F2937" },
  cardBody:  { display:"flex", flexDirection:"column", gap:14 },
  field:     { display:"flex", flexDirection:"column" },
  fieldLabel:{ fontSize:12, fontWeight:600, color:"#374151", marginBottom:2 },
  fieldHint: { fontSize:11, color:"#94a3b8", marginBottom:6, lineHeight:1.4 },
  numRow:    { display:"flex", alignItems:"center", gap:0, marginTop:4 },
  nudge:     {
    width:28, height:32, border:"1px solid #e2e8f0", background:"#f8fafc",
    cursor:"pointer", fontSize:16, color:"#374151", display:"flex",
    alignItems:"center", justifyContent:"center", userSelect:"none",
  },
  numInput:  {
    width:64, height:32, border:"1px solid #e2e8f0", borderLeft:"none", borderRight:"none",
    textAlign:"center", fontSize:13, fontWeight:600, color:"#1F2937",
    background:"#fff", outline:"none",
  },
  chip:      { background:"#fff", borderRadius:10, border:"1px solid #f1f5f9", padding:"10px 16px", boxShadow:"0 1px 4px rgba(0,0,0,0.04)" },
  chipVal:   { fontSize:20, fontWeight:700, color:"#000080" },
  chipLabel: { fontSize:11, color:"#94a3b8", fontWeight:600, letterSpacing:"0.04em", marginTop:2 },
};
