// KOPPA Registry — Supabase configuration
// !! Replace these two values after creating your Supabase project !!
// Dashboard → Project Settings → API

const KOPPA_SUPABASE_URL      = 'https://YOUR_PROJECT_ID.supabase.co'
const KOPPA_SUPABASE_ANON_KEY = 'YOUR_ANON_KEY_HERE'

// Registry fallback (used when Supabase not configured)
const KOPPA_REGISTRY_JSON = 'https://raw.githubusercontent.com/guea14012/koppa-registry-/main/index.json'
const KOPPA_REPO_BASE     = 'https://github.com/guea14012'

function isSupabaseConfigured() {
  return !KOPPA_SUPABASE_URL.includes('YOUR_PROJECT') &&
         !KOPPA_SUPABASE_ANON_KEY.includes('YOUR_ANON')
}
