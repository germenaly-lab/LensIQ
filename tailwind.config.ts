import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        cctv: {
          bg: "#0b0f19",
          card: "#111827",
          border: "#1f2937",
          accent: "#06b6d4",
          hikvision: "#a855f7",
          statusOnline: "#10b981",
          statusOffline: "#ef4444",
          statusDegraded: "#f59e0b",
        },
      },
    },
  },
  plugins: [],
};
export default config;
