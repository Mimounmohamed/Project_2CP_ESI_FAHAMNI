import { addDoc, collection, doc, serverTimestamp, setDoc } from "firebase/firestore";
import { db } from "./firebase";

export async function syncSuspensionState(userId, isSuspended) {
  if (!userId) return;

  await setDoc(doc(db, "users", userId), { is_suspended: isSuspended }, { merge: true });

  if (!isSuspended) return;

  await addDoc(collection(db, "notifications"), {
    title: "Account Suspended",
    content: "Your account has been suspended. Please contact the admins for help.",
    date_time: serverTimestamp(),
    receiver_id: userId,
    reciever_id: userId,
    sender_id: "admin",
    type: "account_suspended",
    metadata: {},
    is_read: false,
  });
}
