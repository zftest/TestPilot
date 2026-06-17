import { create } from "zustand";

export interface User {
  id: string;
  username: string;
  email: string;
  nickname: string;
  role: string;
}

interface AuthState {
  token: string | null;
  user: User | null;
  setAuth: (token: string, user: User) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  token: null,
  user: null,
  setAuth: (token, user) => {
    localStorage.setItem("auth-storage", JSON.stringify({ state: { token, user } }));
    set({ token, user });
  },
  logout: () => {
    localStorage.removeItem("auth-storage");
    set({ token: null, user: null });
  },
}));
