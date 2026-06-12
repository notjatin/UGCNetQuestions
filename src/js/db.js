import pg from "pg";
import dotenv from "dotenv";
import idleTimeoutMillis from "pg/lib/defaults";

// Load environment variables
dotenv.config();

const { Pool } = pg;

// Intialize the connection pool
const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_DATABASE,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
    // Max nuber of clients in the pool
    max: 10,
    // Close idle clients after 10 seconds
    idleTimeoutMillis: 30000,
});

// A helper function to export for running queries
export const query = async (text, params) => {
    const start = Date.now();
    try {
        const res = await pool.query(text, params);
        const duration = Date.now() - start;
        console.log("Execute query", { text, duration, rows: res.rowCount });
        return res;
    } catch (error) {
        console.error("Database query error:", error);
        throw error;
    }
};

export default pool;