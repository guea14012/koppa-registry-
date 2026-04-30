// KOPPA Registry — Supabase configuration
// !! Replace these two values after creating your Supabase project !!
// Dashboard → Project Settings → API

const KOPPA_SUPABASE_URL      = 'https://uovrlnnwzaqkjsnqhxvq.supabase.co'
const KOPPA_SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVvdnJsbm53emFxa2pzbnFoeHZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0ODQxMDcsImV4cCI6MjA5MzA2MDEwN30.WpIBO6duMHUKctnR1d74smB9h2swDfe0-rYEAucf1ns'

// Registry fallback (used when Supabase not configured)
const KOPPA_REGISTRY_JSON = 'https://raw.githubusercontent.com/guea14012/koppa-registry-/main/index.json'
const KOPPA_REPO_BASE     = 'https://github.com/guea14012'

function isSupabaseConfigured() {
  return !KOPPA_SUPABASE_URL.includes('YOUR_PROJECT') &&
         !KOPPA_SUPABASE_ANON_KEY.includes('YOUR_ANON')
}
