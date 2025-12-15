import { createDb, seedAll } from 'inflow-get';
import { createClient } from 'inflow-client';

const DB_PATH = './data/inflow.sqlite';

async function main() {
  const apiKey = process.env.INFLOW_API_KEY;
  const companyId = process.env.INFLOW_COMPANY_ID;

  if (!apiKey || !companyId) {
    console.error('Missing INFLOW_API_KEY or INFLOW_COMPANY_ID');
    process.exit(1);
  }

  console.log('Creating database at', DB_PATH);
  const db = createDb(DB_PATH);

  console.log('Creating Inflow client...');
  const client = createClient({ apiKey, companyId });

  console.log('Seeding database from Inflow API...');
  await seedAll({ db, client });

  console.log('Done! Database seeded at', DB_PATH);
}

main().catch((err) => {
  console.error('Sync failed:', err);
  process.exit(1);
});
