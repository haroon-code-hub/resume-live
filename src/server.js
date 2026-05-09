const express = require("express");

const app = express();
const PORT = process.env.PORT || 3000;
const { initDb, incrementVisitCount, getVisitCount } = require("./db");

app.get("/", async (req, res) => {
  const visitCount = await incrementVisitCount();
  res.send(`
    <html>
      <head>
        <title>Haroon Saeed - DevOps Resume</title>
      </head>
      <body>
        <h1>Haroon Saeed</h1>
        <h2>Software Developer | DevOps Enthusiast</h2>

        <p>
          I am a Software Developer with experience in React, Next.js,
          Node.js, Docker, Jenkins, Kubernetes, and CI/CD.
        </p>

        <h3>DevOps Skills</h3>
        <ul>
          <li>Docker</li>
          <li>Kubernetes</li>
          <li>Jenkins</li>
          <li>GitHub Actions</li>
          <li>Terraform basics</li>
          <li>Prometheus & Grafana</li>
        </ul>

        <h3>Project Goal</h3>
        <p>
          This app will be deployed using Docker, Kubernetes, CI/CD,
          monitoring, and Terraform.
        </p>
        <p><strong>Visits:</strong> ${visitCount}</p>
      </body>
    </html>
  `);
});

app.get("/health", (req, res) => {
  res.status(200).json({
    status: "ok",
    service: "live-resume-devops",
  });
});

app.get("/visits", async (req, res) => {
  const visits = await getVisitCount();

  res.json({
    visits,
  });
});

initDb()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  })
  .catch((error) => {
    console.error("Failed to initialize database:", error);
    process.exit(1);
  });
