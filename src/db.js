const { Pool } = require("pg");
require("dotenv").config();

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

async function initDb() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS visits (
      id SERIAL PRIMARY KEY,
      count INTEGER NOT NULL DEFAULT 0
    );
  `);

  const result = await pool.query("SELECT COUNT(*) FROM visits");

  if (Number(result.rows[0].count) === 0) {
    await pool.query("INSERT INTO visits (count) VALUES (0)");
  }
}

async function incrementVisitCount() {
  const result = await pool.query(`
    UPDATE visits
    SET count = count + 1
    WHERE id = 1
    RETURNING count;
  `);

  return result.rows[0].count;
}

async function getVisitCount() {
  const result = await pool.query("SELECT count FROM visits WHERE id = 1");
  return result.rows[0].count;
}

module.exports = {
  pool,
  initDb,
  incrementVisitCount,
  getVisitCount,
};
