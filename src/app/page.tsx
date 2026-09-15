'use client';

import React from 'react';

export default function Home() {
  return (
    <main className="fixed inset-0 w-screen h-screen overflow-hidden bg-[#070B14]">
      <iframe
        src="/app/index.html"
        title="LensIQ Enterprise AI CCTV Platform"
        className="w-full h-full border-none block"
        allow="camera; microphone; fullscreen; display-capture; autoplay"
      />
    </main>
  );
}

