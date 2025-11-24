import express from "express";
import os from "os";

const app = express();
const PORT = 7860;

app.use((req, res, next) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  next();
});

app.get("/", (req, res) => {
  const now = new Date();

  res.json({
    server_time: now.toISOString(),
    local_time: now.toLocaleString(),
    timestamp: Date.now(),

    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    uptime_seconds: process.uptime(),
    uptime_human_readable: `${Math.floor(process.uptime()/60)} minutes`,

    server_ip: getServerIP(),
    hostname: os.hostname(),
    platform: os.platform(),
    cpu_model: os.cpus()[0].model,
    cpu_cores: os.cpus().length,
    ram_total_mb: Math.round(os.totalmem() / 1024 / 1024),
    ram_free_mb: Math.round(os.freemem() / 1024 / 1024),
  });
});

function getServerIP() {
  const interfaces = os.networkInterfaces();
  for (let iface of Object.values(interfaces)) {
    for (let config of iface) {
      if (config.family === "IPv4" && !config.internal) {
        return config.address;
      }
    }
  }
  return "Unknown";
}

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});