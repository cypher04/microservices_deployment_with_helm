const express = require("express");
const { Pool } = require("pg");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// PostgreSQL Flexible Server connection config from environment variables
const pool = new Pool({
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  port: parseInt(process.env.DB_PORT || "5432", 10),
  ssl: {
    rejectUnauthorized: false,
  },
});

async function connectDb() {
  try {
    await pool.query("SELECT 1");
    console.log("Connected to PostgreSQL");

    // Create a sample table if it doesn't exist
    await pool.query(`
      CREATE TABLE IF NOT EXISTS items (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);
    console.log("Table 'items' is ready");
  } catch (err) {
    console.error("Database connection failed:", err.message);
  }
}

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "healthy" });
});

// Get all items
app.get("/items", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM items ORDER BY created_at DESC");
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create an item
app.post("/items", async (req, res) => {
  const { name } = req.body;
  if (!name) {
    return res.status(400).json({ error: "name is required" });
  }
  try {
    const result = await pool.query(
      "INSERT INTO items (name) VALUES ($1) RETURNING *",
      [name]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get item by id
app.get("/items/:id", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT * FROM items WHERE id = $1",
      [parseInt(req.params.id, 10)]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: "item not found" });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete item by id
app.delete("/items/:id", async (req, res) => {
  try {
    const result = await pool.query(
      "DELETE FROM items WHERE id = $1",
      [parseInt(req.params.id, 10)]
    );
    if (result.rowCount === 0) {
      return res.status(404).json({ error: "item not found" });
    }
    res.json({ message: "item deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);
  await connectDb();
});
