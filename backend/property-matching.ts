import { createClient } from 'jsr:@supabase/supabase-js@^2';

Deno.serve(async (req) => {
  const { user_id } = await req.json();
  
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    {
      global: {
        headers: { Authorization: req.headers.get('Authorization')! }
      }
    }
  );

  // Fetch user preferences
  const { data: userPrefs } = await supabaseClient
    .from('user_preferences')
    .select('*')
    .eq('user_id', user_id)
    .single();

  // Advanced Property Matching
  const { data: matchedProperties } = await supabaseClient
    .rpc('match_properties', {
      p_user_id: user_id,
      p_max_budget: userPrefs.max_budget,
      p_preferred_districts: userPrefs.preferred_districts
    });

  return new Response(JSON.stringify(matchedProperties), {
    headers: { 'Content-Type': 'application/json' }
  });
});
