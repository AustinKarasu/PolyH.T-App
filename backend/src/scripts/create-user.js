const bcrypt = require('bcryptjs');
const { pool } = require('../config/db');

async function main() {
  const [role, fullName, identifier, password, branchCode] = process.argv.slice(2);

  if (!role || !fullName || !identifier || !password) {
    console.log('Usage: npm run create-user -- <admin|student> "<Full Name>" <email_or_college_id> <password> [branch_code]');
    process.exit(1);
  }

  if (!['admin', 'student'].includes(role)) {
    throw new Error('Role must be admin or student');
  }

  let branchId = null;
  if (role === 'student') {
    if (!branchCode) {
      throw new Error('Students require a branch_code, for example CO');
    }
    const [branches] = await pool.execute('SELECT id FROM branches WHERE code = :code', { code: branchCode });
    if (!branches[0]) {
      throw new Error(`Branch not found: ${branchCode}`);
    }
    branchId = branches[0].id;
  }

  const passwordHash = await bcrypt.hash(password, 12);
  const email = role === 'admin' ? identifier : null;
  const collegeId = role === 'student' ? identifier : null;

  await pool.execute(
    `INSERT INTO users (full_name, email, college_id, password_hash, role, branch_id)
     VALUES (:fullName, :email, :collegeId, :passwordHash, :role, :branchId)`,
    { fullName, email, collegeId, passwordHash, role, branchId }
  );

  console.log(`${role} user created: ${identifier}`);
}

main()
  .catch((err) => {
    console.error(err.message);
    process.exit(1);
  })
  .finally(() => pool.end());
