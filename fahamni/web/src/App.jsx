import { useEffect, useState } from "react";
import { getAuth, onAuthStateChanged, signOut } from "firebase/auth";
import app from "./firebase";
import Login from "./Login";
import Dashboard from "./Dashboard";

const auth = getAuth(app);

export default function App() {
  const [user, setUser] = useState(undefined);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (u) => setUser(u ?? null));
    return unsub;
  }, []);

  if (user === undefined) return null;
  if (user === null) return <Login />;
  return <Dashboard user={user} onLogout={() => signOut(auth)} />;
}
