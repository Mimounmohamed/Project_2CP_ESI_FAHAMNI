import { useState, useEffect, useRef } from "react";
import { Search, ArrowLeft, User, X, Send, MessageSquare } from "lucide-react";
import {
  collection, query, orderBy, onSnapshot,
  addDoc, updateDoc, doc, serverTimestamp,
  where, getDocs,
} from "firebase/firestore";
import { getDownloadURL, ref, uploadBytes } from "firebase/storage";
import { db, storage } from "./firebase";
import { useTranslation } from "react-i18next";

const ROLE_STYLE = {
  teacher: { label: "TEACHER", color: "#16a34a", bg: "#dcfce7" },
  student: { label: "STUDENT", color: "#0284c7", bg: "#e0f2fe" },
  parent:  { label: "PARENT",  color: "#db2777", bg: "#fce7f3" },
};

const MAX_ATTACHMENTS = 5;
const MAX_ATTACHMENT_BYTES = 20 * 1024 * 1024;

function fmtTime(val) {
  if (!val) return "";
  try {
    const d = val.toDate ? val.toDate() : new Date(val);
    if (isNaN(d)) return "";
    const now = new Date();
    const yesterday = new Date(now);
    yesterday.setDate(now.getDate() - 1);
    if (d.toDateString() === now.toDateString()) {
      const h = d.getHours(), m = String(d.getMinutes()).padStart(2, "0");
      return `${String(h % 12 || 12).padStart(2, "0")}:${m} ${h >= 12 ? "PM" : "AM"}`;
    }
    if (d.toDateString() === yesterday.toDateString()) return "YESTERDAY";
    return `${String(d.getDate()).padStart(2,"0")}/${String(d.getMonth()+1).padStart(2,"0")}/${d.getFullYear()}`;
  } catch { return ""; }
}

function ConvAvatar({ src, name, size = 42, dark = false }) {
  const initials = (name || "?").split(" ").filter(Boolean).map(w => w[0]).join("").slice(0, 2).toUpperCase();
  if (src) return <img src={src} alt="" style={{ width: size, height: size, borderRadius: "50%", objectFit: "cover", flexShrink: 0 }} />;
  return (
    <div style={{ width: size, height: size, borderRadius: "50%", flexShrink: 0, display: "flex", alignItems: "center", justifyContent: "center", fontSize: Math.round(size * 0.32), fontWeight: 700, background: dark ? "#000080" : "#eef2ff", color: dark ? "#fff" : "#6366f1" }}>
      {initials}
    </div>
  );
}

function MessageAttachments({ attachments = [], isAdmin }) {
  if (!attachments.length) return null;
  return (
    <div style={s.attachments}>
      {attachments.map((att, index) => {
        const isImage = (att.mimeType ?? "").startsWith("image/");
        if (isImage) {
          return (
            <a key={index} href={att.url} target="_blank" rel="noreferrer">
              <img src={att.url} alt={att.name ?? "attachment"} style={s.attachmentImage} />
            </a>
          );
        }
        return (
          <a
            key={index}
            href={att.url}
            target="_blank"
            rel="noreferrer"
            style={{ ...s.attachmentFile, color: isAdmin ? "#fff" : "#1F2937", borderColor: isAdmin ? "rgba(255,255,255,0.35)" : "#e2e8f0" }}
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
              <polyline points="14 2 14 8 20 8"/>
            </svg>
            <span>{att.name ?? "Attachment"}</span>
          </a>
        );
      })}
    </div>
  );
}

export default function MessagesPage({ adminUser, onViewUser, pendingContact, onContactHandled }) {
  const { t } = useTranslation();
  const [conversations, setConversations] = useState([]);
  const [selected, setSelected]           = useState(null);
  const [mobileChatOpen, setMobileChatOpen] = useState(false);
  const [messages, setMessages]           = useState([]);
  const [input, setInput]                 = useState("");
  const [selectedFiles, setSelectedFiles] = useState([]);
  const [search, setSearch]               = useState("");
  const [sending, setSending]             = useState(false);
  const [loadingConvs, setLoadingConvs]   = useState(true);
  const [loadingMsgs, setLoadingMsgs]     = useState(false);
  const [error, setError]                 = useState(null);
  const bottomRef = useRef(null);
  const inputRef  = useRef(null);
  const fileInputRef = useRef(null);

  // ── Real-time conversation list ──
  useEffect(() => {
    let unsub = () => {};
    try {
      const q = query(collection(db, "conversations"), orderBy("last_message_at", "desc"));
      unsub = onSnapshot(
        q,
        snap => {
          setConversations(snap.docs.map(d => ({ id: d.id, ...d.data() })));
          setLoadingConvs(false);
          setError(null);
        },
        err => {
          console.error("Conversations listener error:", err);
          getDocs(collection(db, "conversations"))
            .then(snap => {
              const list = snap.docs
                .map(d => ({ id: d.id, ...d.data() }))
                .sort((a, b) => (b.last_message_at?.seconds ?? 0) - (a.last_message_at?.seconds ?? 0));
              setConversations(list);
            })
            .catch(() => {})
            .finally(() => setLoadingConvs(false));
        }
      );
    } catch (e) {
      console.error("Failed to subscribe to conversations:", e);
      setLoadingConvs(false);
    }
    return () => unsub();
  }, []);

  // ── Real-time messages for selected conversation ──
  useEffect(() => {
    if (!selected?.id || selected._isNew) { setMessages([]); return; }
    setLoadingMsgs(true);
    let unsub = () => {};
    try {
      const q = query(
        collection(db, "conversations", selected.id, "messages"),
        orderBy("created_at", "asc")
      );
      unsub = onSnapshot(
        q,
        snap => { setMessages(snap.docs.map(d => ({ id: d.id, ...d.data() }))); setLoadingMsgs(false); },
        err  => { console.error("Messages listener error:", err); setLoadingMsgs(false); }
      );
    } catch (e) {
      console.error("Failed to subscribe to messages:", e);
      setLoadingMsgs(false);
    }
    return () => unsub();
  }, [selected?.id]);

  // ── Auto-scroll ──
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  // ── Mark unread → 0 when conversation is opened ──
  useEffect(() => {
    if (!selected?.id || selected._isNew || !(selected.unread_admin > 0)) return;
    updateDoc(doc(db, "conversations", selected.id), { unread_admin: 0 }).catch(() => {});
    setConversations(prev =>
      prev.map(c => c.id === selected.id ? { ...c, unread_admin: 0 } : c)
    );
  }, [selected?.id]);

  // ── Handle pendingContact: wait for conversations to load first ──
  useEffect(() => {
    if (!pendingContact?.uid || loadingConvs) return;
    const existing = conversations.find(c => c.user_uid === pendingContact.uid);
    if (existing) {
      setSelected(existing);
    } else {
      setSelected({
        _isNew:       true,
        user_uid:     pendingContact.uid,
        user_name:    pendingContact.name,
        user_role:    pendingContact.role,
        user_picture: pendingContact.picture ?? null,
        unread_admin: 0,
        is_closed:    false,
      });
    }
    setInput("");
    setSelectedFiles([]);
    onContactHandled?.();
  }, [pendingContact?.uid, loadingConvs]); // eslint-disable-line react-hooks/exhaustive-deps

  function handleFileSelect(e) {
    const files = Array.from(e.target.files ?? []);
    const validFiles = files.filter(file => file.size <= MAX_ATTACHMENT_BYTES);
    setSelectedFiles(prev => [...prev, ...validFiles].slice(0, MAX_ATTACHMENTS));
    e.target.value = "";
  }

  function removeSelectedFile(index) {
    setSelectedFiles(prev => prev.filter((_, i) => i !== index));
  }

  async function uploadAttachments(convId) {
    return Promise.all(selectedFiles.map(async (file, index) => {
      const safeName = file.name.replace(/[^\w.() -]+/g, "_");
      const fileRef = ref(storage, `chats/${convId}/attachments/${Date.now()}_${index}_${safeName}`);
      await uploadBytes(fileRef, file, { contentType: file.type || "application/octet-stream" });
      return {
        url: await getDownloadURL(fileRef),
        name: file.name,
        size: file.size,
        sizeBytes: file.size,
        mimeType: file.type || "application/octet-stream",
        kind: (file.type || "").startsWith("image/") ? "image" : "file",
        isLink: false,
      };
    }));
  }

  async function sendMessage() {
    if ((!input.trim() && selectedFiles.length === 0) || !selected || sending) return;
    const text = input.trim();
    setInput("");
    setSending(true);
    try {
      let convId = selected.id;

      // If this is a brand-new local conversation, create the Firestore doc first
      if (selected._isNew) {
        const ref = await addDoc(collection(db, "conversations"), {
          participants:     [selected.user_uid, adminUser?.uid, "admin"].filter(Boolean),
          conversationId:   "",
          conversation_id:  "",
          user_uid:        selected.user_uid,
          user_name:       selected.user_name,
          user_role:       selected.user_role,
          user_picture:    selected.user_picture ?? null,
          last_message:    "",
          last_message_at: serverTimestamp(),
          unread_admin:    0,
          is_closed:       false,
        });
        convId = ref.id;
        await updateDoc(ref, { conversationId: convId, conversation_id: convId });
        setSelected(prev => ({ ...prev, id: convId, _isNew: false }));
      }
      const attachments = await uploadAttachments(convId);
      const type = attachments.length
        ? attachments.every(att => (att.mimeType ?? "").startsWith("image/")) ? "image" : "file"
        : "text";
      const preview = text || (type === "image" ? "Photo" : "Attachment");

      await addDoc(collection(db, "conversations", convId, "messages"), {
        text,
        content:     text,
        conversationId: convId,
        conversation_id: convId,
        senderId:    adminUser?.uid ?? "admin",
        sender_id:   "admin",
        sender_name: "Admin",
        receiverId:  selected.user_uid,
        receiver_id: selected.user_uid,
        type,
        attachments,
        readBy:      [],
        isRead:      false,
        created_at:  serverTimestamp(),
        createdAt:   serverTimestamp(),
      });
      await updateDoc(doc(db, "conversations", convId), {
        last_message:    preview,
        last_message_at: serverTimestamp(),
        is_closed:       false,
      });
      setSelectedFiles([]);
    } catch (e) {
      console.error(e);
      setInput(text);
    } finally {
      setSending(false);
      inputRef.current?.focus();
    }
  }

  async function closeConversation() {
    if (!selected) return;
    if (!selected._isNew) {
      await updateDoc(doc(db, "conversations", selected.id), { is_closed: true }).catch(() => {});
      setConversations(prev => prev.map(c => c.id === selected.id ? { ...c, is_closed: true } : c));
    }
    setSelected(null);
    setMobileChatOpen(false);
  }

  async function handleViewProfile() {
    if (!selected?.user_uid || !selected?.user_role) return;
    const col = selected.user_role === "teacher" ? "tutors" : selected.user_role === "parent" ? "parents" : "students";
    try {
      const snap = await getDocs(query(collection(db, col), where("uid", "==", selected.user_uid)));
      if (!snap.empty) {
        const d = snap.docs[0];
        onViewUser?.({ ...d.data(), id: d.id, col, role: selected.user_role });
      }
    } catch (e) { console.error(e); }
  }

  const filtered    = conversations.filter(c => !search || (c.user_name ?? "").toLowerCase().includes(search.toLowerCase()));
  const totalUnread = conversations.reduce((s, c) => s + (c.unread_admin ?? 0), 0);

  return (
    <div style={s.page}>
      <h1 style={s.title}>{t("messages.title")}</h1>

      <div className="msg-body">

        {/* ── Left: Inbox ── */}
        <div style={{ ...s.inbox }} className={`msg-inbox-panel${mobileChatOpen ? " msg-inbox-hidden" : ""}`}>
          <div style={s.searchWrap}>
            <Search size={14} color="#94a3b8" style={{ position: "absolute", left: 13, top: "50%", transform: "translateY(-50%)", pointerEvents: "none" }} />
            <input style={s.searchInput} placeholder={t("messages.searchPlaceholder")} value={search} onChange={e => setSearch(e.target.value)} />
          </div>

          <div style={s.inboxHeader}>
            <span style={s.inboxTitle}>{t("messages.inbox")}</span>
            {totalUnread > 0 && <span style={s.unreadBadge}>{t("messages.unread", { count: totalUnread })}</span>}
          </div>

          <div className="thin-scroll" style={s.convList}>
            {loadingConvs ? (
              <div style={s.emptyState}>{t("messages.loading")}</div>
            ) : filtered.length === 0 ? (
              <div style={s.emptyState}>{search ? t("messages.noResults") : t("messages.noConversations")}</div>
            ) : filtered.map(conv => {
              const role       = ROLE_STYLE[conv.user_role] ?? ROLE_STYLE.student;
              const isSelected = selected?.id === conv.id;
              const hasUnread  = (conv.unread_admin ?? 0) > 0;
              return (
                <div
                  key={conv.id}
                  style={{ ...s.convRow, ...(isSelected ? s.convRowSelected : {}) }}
                  onClick={() => { setSelected(conv); setInput(""); setSelectedFiles([]); setMobileChatOpen(true); }}
                >
                  <div style={{ position: "relative", flexShrink: 0 }}>
                    <ConvAvatar src={conv.user_picture} name={conv.user_name} size={44} />
                  </div>
                  <div style={s.convInfo}>
                    <div style={s.convTopRow}>
                      <span style={{ ...s.convName, fontWeight: hasUnread ? 700 : 600 }}>{conv.user_name || "User"}</span>
                      <span style={s.convTime}>{fmtTime(conv.last_message_at)}</span>
                    </div>
                    <span style={{ ...s.rolePill, color: role.color, background: role.bg }}>{role.label}</span>
                    <div style={{ ...s.convPreview, fontWeight: hasUnread ? 600 : 400 }}>{conv.last_message || ""}</div>
                  </div>
                  {hasUnread && <span style={s.unreadDot} />}
                </div>
              );
            })}
          </div>
        </div>

        {/* ── Right: Chat panel ── */}
        {selected ? (
          <div style={s.chat} className={`msg-chat-panel${!mobileChatOpen ? " msg-chat-hidden" : ""}`}>
            {/* Mobile back button */}
            <button className="msg-back-btn" onClick={() => setMobileChatOpen(false)}>
              <ArrowLeft size={16} />
              {t("messages.backToInbox")}
            </button>
            {/* Header */}
            <div style={s.chatHeader}>
              <div style={s.chatHeaderLeft}>
                <div style={{ position: "relative", flexShrink: 0 }}>
                  <ConvAvatar src={selected.user_picture} name={selected.user_name} size={46} />
                  <span style={s.onlineDot} />
                </div>
                <div>
                  <div style={s.chatName}>{selected.user_name || "User"}</div>
                  {(() => {
                    const r = ROLE_STYLE[selected.user_role] ?? ROLE_STYLE.student;
                    return <span style={{ ...s.rolePill, color: r.color, background: r.bg }}>{r.label}</span>;
                  })()}
                </div>
              </div>
              <div style={s.chatHeaderRight}>
                <button style={s.viewProfileBtn} onClick={handleViewProfile}>
                  <User size={14} />
                  {t("messages.viewProfile")}
                </button>
                <button style={s.closeBtn} onClick={closeConversation}>
                  <X size={12} strokeWidth={2.5} />
                  {t("messages.closeConversation")}
                </button>
              </div>
            </div>

            {/* Messages */}
            <div className="thin-scroll" style={s.messagesArea}>
              {loadingMsgs ? (
                <div style={s.emptyState}>{t("messages.loadingMessages")}</div>
              ) : messages.length === 0 ? (
                <div style={s.emptyState}>{t("messages.noMessages")}</div>
              ) : messages.map(msg => {
                const isAdmin = msg.sender_id === "admin";
                const text = msg.text ?? msg.content ?? "";
                return (
                  <div key={msg.id} style={{ ...s.msgRow, justifyContent: isAdmin ? "flex-end" : "flex-start" }}>
                    {!isAdmin && <ConvAvatar src={selected.user_picture} name={selected.user_name} size={36} />}
                    <div style={{ maxWidth: "62%", display: "flex", flexDirection: "column", alignItems: isAdmin ? "flex-end" : "flex-start", gap: 4 }}>
                      <div style={{ ...s.bubble, ...(isAdmin ? s.bubbleAdmin : s.bubbleUser) }}>
                        {text && <div>{text}</div>}
                        <MessageAttachments attachments={msg.attachments} isAdmin={isAdmin} />
                      </div>
                      <span style={s.msgMeta}>{isAdmin ? t("messages.admin") : selected.user_name} • {fmtTime(msg.created_at)}</span>
                    </div>
                    {isAdmin && <ConvAvatar src={null} name="Admin" size={36} dark />}
                  </div>
                );
              })}
              <div ref={bottomRef} />
            </div>

            {/* Input */}
            {selectedFiles.length > 0 && (
              <div style={s.selectedFiles}>
                {selectedFiles.map((file, index) => (
                  <div key={`${file.name}_${index}`} style={s.selectedFile}>
                    <span style={s.selectedFileName}>{file.name}</span>
                    <button type="button" style={s.removeFileBtn} onClick={() => removeSelectedFile(index)} disabled={sending}>x</button>
                  </div>
                ))}
              </div>
            )}
            <div style={s.inputRow}>
              <input
                ref={fileInputRef}
                type="file"
                multiple
                style={{ display: "none" }}
                onChange={handleFileSelect}
                disabled={sending}
              />
              <button
                style={{ ...s.attachBtn, opacity: sending ? 0.45 : 1 }}
                onClick={() => fileInputRef.current?.click()}
                disabled={sending}
                title="Attach files"
                type="button"
              >
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M21.44 11.05 12.25 20.24a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 1 1-2.83-2.83l8.49-8.48"/>
                </svg>
              </button>
              <input
                ref={inputRef}
                style={s.messageInput}
                placeholder={t("messages.inputPlaceholder")}
                value={input}
                onChange={e => setInput(e.target.value)}
                onKeyDown={e => { if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); sendMessage(); } }}
              />
              <button
                style={{ ...s.sendBtn, opacity: ((!input.trim() && selectedFiles.length === 0) || sending) ? 0.4 : 1 }}
                onClick={sendMessage}
                disabled={(!input.trim() && selectedFiles.length === 0) || sending}
                title="Send message"
              >
                <Send size={18} color="#fff" />
              </button>
            </div>
          </div>
        ) : (
          <div style={s.noSelection}>
            <MessageSquare size={52} color="#cbd5e1" strokeWidth={1} />
            <span style={{ color: "#94a3b8", fontSize: 14, marginTop: 14, textAlign: "center" }}>
              {t("messages.selectConversation")}
            </span>
          </div>
        )}
      </div>
    </div>
  );
}

const s = {
  page:  { display: "flex", flexDirection: "column", height: "100%", minHeight: 0, gap: 16 },
  title: { fontSize: 24, fontWeight: 700, color: "#000080", margin: 0, flexShrink: 0 },
  body:  { display: "flex", gap: 16, flex: 1, minHeight: 0, overflow: "hidden" },

  inbox: {
    width: 300, flexShrink: 0, background: "#fff", borderRadius: 18,
    border: "1px solid #f1f5f9", boxShadow: "0 2px 12px rgba(0,0,0,0.06)",
    display: "flex", flexDirection: "column", overflow: "hidden",
  },
  searchWrap:  { position: "relative", padding: "14px 14px 0" },
  searchInput: {
    width: "100%", height: 40, paddingLeft: 36, paddingRight: 14,
    border: "1.5px solid #e2e8f0", borderRadius: 24,
    background: "#f8fafc", fontSize: 13, color: "#1F2937",
    outline: "none", boxSizing: "border-box",
  },
  inboxHeader: { display: "flex", alignItems: "center", justifyContent: "space-between", padding: "14px 16px 10px" },
  inboxTitle:  { fontSize: 15, fontWeight: 700, color: "#1F2937" },
  unreadBadge: { fontSize: 11, fontWeight: 700, color: "#fff", background: "#000080", borderRadius: 20, padding: "3px 10px" },
  convList:    { flex: 1, minHeight: 0, overflowY: "auto" },

  convRow: {
    display: "flex", alignItems: "flex-start", gap: 12, padding: "12px 16px",
    cursor: "pointer", borderLeft: "3px solid transparent", position: "relative",
  },
  convRowSelected: { background: "#f5f7ff", borderLeft: "3px solid #000080" },
  convInfo:   { flex: 1, minWidth: 0 },
  convTopRow: { display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 3 },
  convName:   { fontSize: 13, fontWeight: 600, color: "#1F2937", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" },
  convTime:   { fontSize: 11, color: "#94a3b8", flexShrink: 0, marginLeft: 6 },
  convPreview:{ fontSize: 12, color: "#64748b", marginTop: 4, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" },
  unreadDot:  { width: 9, height: 9, borderRadius: "50%", background: "#000080", flexShrink: 0, alignSelf: "center" },
  emptyState: { fontSize: 13, color: "#94a3b8", padding: "32px 20px", textAlign: "center" },
  rolePill:   { display: "inline-block", fontSize: 10, fontWeight: 700, borderRadius: 6, padding: "2px 7px", letterSpacing: "0.04em", marginTop: 2 },

  chat: {
    flex: 1, minWidth: 0, background: "#fff", borderRadius: 18,
    border: "1px solid #f1f5f9", boxShadow: "0 2px 12px rgba(0,0,0,0.06)",
    display: "flex", flexDirection: "column", overflow: "hidden",
  },
  chatHeader:      { display: "flex", alignItems: "center", justifyContent: "space-between", padding: "14px 20px", borderBottom: "1px solid #f1f5f9", flexShrink: 0 },
  chatHeaderLeft:  { display: "flex", alignItems: "center", gap: 12 },
  chatHeaderRight: { display: "flex", alignItems: "center", gap: 10 },
  chatName:  { fontSize: 15, fontWeight: 700, color: "#1F2937", marginBottom: 3 },
  onlineDot: { position: "absolute", bottom: 2, right: 2, width: 12, height: 12, borderRadius: "50%", background: "#22c55e", border: "2px solid #fff" },
  viewProfileBtn: {
    display: "flex", alignItems: "center", gap: 6, padding: "8px 16px", borderRadius: 20,
    border: "1.5px solid #e2e8f0", background: "#fff", fontSize: 13, fontWeight: 600, color: "#1F2937", cursor: "pointer",
  },
  closeBtn: {
    display: "flex", alignItems: "center", gap: 6, padding: "8px 16px", borderRadius: 20,
    border: "1.5px solid #fecaca", background: "#fff5f5", fontSize: 13, fontWeight: 600, color: "#ef4444", cursor: "pointer",
  },

  messagesArea: { flex: 1, minHeight: 0, overflowY: "auto", padding: "20px 20px 10px", display: "flex", flexDirection: "column", gap: 16 },
  msgRow:  { display: "flex", alignItems: "flex-end", gap: 10 },
  bubble:  { fontSize: 14, lineHeight: 1.6, padding: "12px 16px", borderRadius: 18, maxWidth: "100%" },
  bubbleUser:  { background: "#fff", border: "1px solid #e2e8f0", color: "#1F2937", borderBottomLeftRadius: 4, boxShadow: "0 1px 4px rgba(0,0,0,0.05)" },
  bubbleAdmin: { background: "#000080", color: "#fff", borderBottomRightRadius: 4 },
  msgMeta: { fontSize: 11, color: "#94a3b8" },
  attachments: { display: "flex", flexDirection: "column", gap: 8, marginTop: 8 },
  attachmentImage: { width: 180, maxWidth: "100%", borderRadius: 10, display: "block" },
  attachmentFile: {
    display: "flex", alignItems: "center", gap: 8, padding: "8px 10px",
    border: "1px solid", borderRadius: 10, textDecoration: "none", fontSize: 12, fontWeight: 600,
  },

  inputRow: {
    display: "flex", alignItems: "center", gap: 10,
    padding: "12px 16px", borderTop: "1px solid #f1f5f9", flexShrink: 0, background: "#fafbff",
  },
  selectedFiles: {
    display: "flex", gap: 8, flexWrap: "wrap",
    padding: "10px 16px 0", background: "#fafbff", borderTop: "1px solid #f1f5f9",
  },
  selectedFile: {
    display: "flex", alignItems: "center", gap: 8, maxWidth: 220,
    padding: "6px 9px", borderRadius: 10, border: "1px solid #e2e8f0",
    background: "#fff", fontSize: 12, color: "#1F2937",
  },
  selectedFileName: { overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" },
  removeFileBtn: {
    border: "none", background: "transparent", color: "#ef4444",
    cursor: "pointer", fontSize: 13, fontWeight: 700, padding: 0,
  },
  attachBtn: {
    width: 40, height: 40, borderRadius: "50%", border: "1.5px solid #e2e8f0",
    background: "#fff", color: "#64748b", cursor: "pointer",
    display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
  },
  messageInput: {
    flex: 1, height: 44, paddingLeft: 18, paddingRight: 14,
    border: "1.5px solid #e2e8f0", borderRadius: 24,
    background: "#fff", fontSize: 14, color: "#1F2937",
    outline: "none", boxSizing: "border-box",
  },
  sendBtn: {
    width: 40, height: 40, borderRadius: "50%", border: "none",
    background: "#000080", cursor: "pointer",
    display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
    transition: "opacity 0.15s",
  },

  noSelection: {
    flex: 1, background: "#fff", borderRadius: 18,
    border: "1px solid #f1f5f9", boxShadow: "0 2px 12px rgba(0,0,0,0.06)",
    display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
  },
};
