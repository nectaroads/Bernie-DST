require('dotenv').config();
const { Pool } = require('pg');
const { dotenv } = require('./variables');

const pool = new Pool({
  user: dotenv.DATABASEUSER,
  host: dotenv.DATABASEHOST,
  database: dotenv.DATABASENAME,
  password: dotenv.DATABASEPASSWORD,
  port: Number(dotenv.DATABASEPORT)
});

async function databaseQuery(order, params = null) {
  let res = await pool.query(order, params);
  return res;
}

module.exports = { databaseQuery };
