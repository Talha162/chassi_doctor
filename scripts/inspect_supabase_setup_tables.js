const fs = require('fs');
const path = require('path');
const env = fs.readFileSync(path.join(process.cwd(), '.env'), 'utf8');
function get(name) {
  const m = env.match(new RegExp('^' + name + '\\s*=\\s*"?([^"\\r\\n]+)"?', 'm'));
  return m ? m[1].trim() : null;
}
const url = get('SUPABASE_URL');
const key = get('SUPABASE_SERVICE_ROLE_KEY');
const tables = [
  'chassis_symptoms',
  'chassis_issue_options',
  'adjustment_recommendations',
  'chassis_adjustment_sets',
  'chassis_adjustment_set_issue_options',
  'chassis_adjustment_set_recommendations',
  'chassis_adjustment_set_track_presets',
  'track_config_presets',
  'track_configurations'
];
(async () => {
  for (const table of tables) {
    const res = await fetch(`${url}/rest/v1/${table}?select=*&limit=1`, {
      headers: { apikey: key, Authorization: `Bearer ${key}` }
    });
    const text = await res.text();
    console.log('TABLE', table, 'STATUS', res.status);
    console.log(text.slice(0, 800));
  }
})().catch(err => { console.error(err); process.exit(1); });
