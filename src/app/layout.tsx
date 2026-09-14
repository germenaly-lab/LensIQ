import './globals.css';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'LensIQ - Enterprise CCTV Platform',
  description: 'Multi-Source Camera Architecture & Monitoring Platform',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <body className="min-h-screen bg-slate-950 text-slate-100 antialiased">
        {children}
      </body>
    </html>
  );
}
