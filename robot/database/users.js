const { databaseQuery } = require('../postgre');

async function databaseGetUserByUserId(userid) {
  const res = await databaseQuery('SELECT * FROM users WHERE userid = $1 LIMIT 1', [userid]);
  return res.rows[0] || null;
}

async function databaseGetUsers() {
  const res = await databaseQuery('SELECT * FROM users');
  return res.rows;
}

async function databaseCreateUser(name, userid) {
  const res = await databaseQuery(`INSERT INTO users (userid,name) VALUES ($1, $2) RETURNING *;`, [userid, name]);
  return res.rows[0];
}

async function databaseSetUserById(userid, fields) {
  const allowed = ['name', 'points', 'oinks'];
  const updates = [];
  const values = [];
  for (const [key, value] of Object.entries(fields)) {
    if (!allowed.includes(key)) continue;
    values.push(value);
    updates.push(`${key} = $${values.length}`);
  }
  if (updates.length === 0) return await databaseGetUserByUserId(userid);
  values.push(userid);
  const res = await databaseQuery(`UPDATE users SET ${updates.join(', ')} WHERE userid = $${values.length} RETURNING *;`, values);
  return res.rows[0] || null;
}

module.exports = { databaseGetUserByUserId, databaseGetUsers, databaseCreateUser, databaseSetUserById };
