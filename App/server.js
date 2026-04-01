const express = require("express");
const sql = require("mssql");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// SQL Server connection config from environment variables
const dbConfig = {
  server: process.env.DB_HOST,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  port: parseInt(process.env.DB_PORT || "1433", 10),
  options: {
    encrypt: true,
    trustServerCertificate: false,
  },
};

let pool;

async function connectDb() {
  try {
    pool = await sql.connect(dbConfig);
    console.log("Connected to SQL Server");

    // Create a sample table if it doesn't exist
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='items' AND xtype='U')
      CREATE TABLE items (
        id INT IDENTITY(1,1) PRIMARY KEY,
        name NVARCHAR(255) NOT NULL,
        created_at DATETIME2 DEFAULT GETDATE()
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
    const result = await pool.request().query("SELECT * FROM items ORDER BY created_at DESC");
    res.json(result.recordset);
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
    const result = await pool
      .request()
      .input("name", sql.NVarChar, name)
      .query("INSERT INTO items (name) OUTPUT INSERTED.* VALUES (@name)");
    res.status(201).json(result.recordset[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get item by id
app.get("/items/:id", async (req, res) => {
  try {
    const result = await pool
      .request()
      .input("id", sql.Int, parseInt(req.params.id, 10))
      .query("SELECT * FROM items WHERE id = @id");
    if (result.recordset.length === 0) {
      return res.status(404).json({ error: "item not found" });
    }
    res.json(result.recordset[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete item by id
app.delete("/items/:id", async (req, res) => {
  try {
    const result = await pool
      .request()
      .input("id", sql.Int, parseInt(req.params.id, 10))
      .query("DELETE FROM items WHERE id = @id");
    if (result.rowsAffected[0] === 0) {
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
