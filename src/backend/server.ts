import { createApp } from './app';

const PORT = process.env.PORT || 4000;
const app = createApp();

app.listen(PORT, () => {
  console.log(`[LensIQ Backend] Express server listening on http://localhost:${PORT}`);
  console.log(`[LensIQ Backend] Supported camera source types: RTSP, Hikvision P2P`);
});
