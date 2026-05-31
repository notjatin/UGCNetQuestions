import { query } from './db.js';

async function setupAndTestDB(params) {
    try {
        console.log("Checking database connection...");
        
        // 1. Create a sample users table if it doesn't exist
        const createTableQuery = `
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `;
        await query(createTableQuery);
        console.log("'users' table is ready.");
        
        // 2. Insert a sample user safely using parameterized queries (prevents SQL injection)
        const insertUserQuery = `
            INSERT INTO users (name, email)
            VALUES ($1, $2)
            ON CONFLICT (email) DO NOTHING
            RETURNING *;
        `;
        const insertResult = await query(insertUserQuery, ['Alice Dev', 'alice@example.com']);

        if (insertResult.rows.length > 0) {
            console.log("User inserted successfully:", insertResult.rows[0]);
        } else {
            console.log("User already exists, skipping insertion.");    
        }

        // 3. Fetch data back from the database
        const selectUsersQuery = `SELECT * FROM users;`;
        const { rows } = await query (selectUsersQuery);

        console.log("\n--- Currrent Users in Database ---");
        console.table(rows);
    } catch (err) {
        console.error("Initialization failed:", err);
    } finally {
        // Process exits cleanly
        process.exit();
    }
}

setupAndTestDB();