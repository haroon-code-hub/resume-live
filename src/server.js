const express = require("express");
const fs = require("fs");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 3000;
const { initDb, incrementVisitCount, getVisitCount } = require("./db");

const css = fs.readFileSync(path.join(__dirname, "styles.css"), "utf8");

app.get("/", async (req, res) => {
  const visitCount = await incrementVisitCount();
  res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Haroon Saeed — Software Developer | DevOps & Cloud</title>
  <style>${css}</style>
</head>
<body>
<div class="container">

  <header>
    <h1>Haroon Saeed</h1>
    <div class="subtitle">Software Developer | DevOps &amp; Cloud</div>
    <div class="contact">
      Fürstenfeldbruck, Germany &nbsp;·&nbsp;
      <a href="mailto:haroon.saeed@outlook.de">haroon.saeed@outlook.de</a> &nbsp;·&nbsp;
      +49 (176) 67055966 &nbsp;·&nbsp;
      <a href="https://github.com/haroon-code-hub" target="_blank">GitHub</a> &nbsp;·&nbsp;
      <a href="https://linkedin.com" target="_blank">LinkedIn</a>
    </div>
  </header>

  <section>
    <h2>Professional Summary</h2>
    <p style="font-size:0.9rem;">
      Software Developer with 3+ years of experience building and operating production systems,
      transitioning into Cloud &amp; DevOps. Hands-on experience with Docker, Terraform, AWS,
      Kubernetes, and CI/CD pipelines, with a track record of automating deployment workflows
      and maintaining reliability in live customer-facing systems.
    </p>
  </section>

  <section>
    <h2>Technical Skills</h2>
    <div class="skills-grid">
      <div class="skill-row"><span class="skill-label">Cloud &amp; Infrastructure:</span> AWS, Linux, Git</div>
      <div class="skill-row"><span class="skill-label">IaC &amp; Containers:</span> Terraform, Docker, Kubernetes</div>
      <div class="skill-row"><span class="skill-label">CI/CD:</span> GitHub Actions, Azure DevOps</div>
      <div class="skill-row"><span class="skill-label">Scripting:</span> Bash, Python</div>
      <div class="skill-row"><span class="skill-label">Dev:</span> TypeScript, JavaScript, React, Node.js</div>
    </div>
  </section>

  <section>
    <h2>Work Experience</h2>
    <div class="job">
      <div class="job-header">
        <span class="job-title">Software Developer</span>
        <span class="job-date">Oct 2022 – Present</span>
      </div>
      <div class="job-company">Inter-Connect GmbH · Munich, Germany</div>
      <ul>
        <li>Worked on production systems serving hundreds of EU customers, ensuring reliability in live environments.</li>
        <li>Worked within CI/CD pipelines (Azure DevOps and Git) supporting daily production deployments within a 3-person engineering team.</li>
        <li>Containerised applications using Docker to ensure consistent development and deployment environments.</li>
        <li>Fixed production bugs and implemented iterative improvements in deployed systems.</li>
        <li>Developed and maintained customer-facing applications using React, Next.js, and TypeScript.</li>
      </ul>
    </div>
  </section>

  <section>
    <h2>Cloud &amp; DevOps Projects</h2>

    <div class="project">
      <div class="project-header">
        <span class="project-name">Resume-Live</span>
        <a class="project-link" href="https://github.com/haroon-code-hub/resume-live" target="_blank">github.com/haroon-code-hub/resume-live</a>
      </div>
      <div style="margin: 6px 0;">
        <span class="tag">AWS</span><span class="tag">Terraform</span><span class="tag">Kubernetes</span>
        <span class="tag">k3s</span><span class="tag">GitHub Actions</span><span class="tag">Docker</span>
      </div>
      <ul>
        <li>Containerised a full-stack application (Node.js, PostgreSQL) with Docker and deployed it to AWS EC2.</li>
        <li>Provisioned cloud infrastructure as code using Terraform, including compute, networking, and security group configuration.</li>
        <li>Built a CI/CD pipeline with GitHub Actions to automate image builds and deployment on every push.</li>
        <li>Deployed application workloads using a lightweight Kubernetes (k3s) cluster.</li>
        <li><em>Planned: HTTPS via custom domain, monitoring/alerting, and autoscaling.</em></li>
      </ul>
    </div>
  </section>

  <section>
    <h2>Education &amp; Training</h2>
    <div class="edu-item"><strong>M.Sc. Computer Science</strong> — University of Passau, Germany · 2016–2021</div>
    <div class="edu-item"><strong>B.Sc. Information Technology</strong> — Bahauddin Zakariya University, Pakistan · 2010–2014</div>
    <div class="edu-item"><strong>AWS Certified Cloud Practitioner</strong> — In Progress, expected 2026</div>
    <div class="edu-item"><strong>DevOps Engineering Path</strong> — Boot.dev · 2026</div>
  </section>

  <section>
    <h2>Languages</h2>
    <p style="font-size:0.9rem;">English (fluent) · German (intermediate) · Urdu (native)</p>
  </section>

  <div class="footer">
    Deployed on AWS · k3s · Kubernetes · Docker · GitHub Actions &nbsp;·&nbsp; Visits: ${visitCount}
  </div>

</div>
</body>
</html>
  `);
});

app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok", service: "live-resume-devops" });
});

app.get("/visits", async (req, res) => {
  const visits = await getVisitCount();
  res.json({ visits });
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
