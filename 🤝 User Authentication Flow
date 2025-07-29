import { createClient } from 'jsr:@supabase/supabase-js@^2';

async function registerUser(email: string, preferences: UserPreferences) {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  const { user, error } = await supabase.auth.signUp({
    email,
    password: generateStrongPassword(),
    options: {
      data: {
        full_name: preferences.fullName,
        preferred_districts: preferences.districts,
        language: preferences.language
      }
    }
  });

  // Automatically create user preferences record
  await supabase
    .from('user_preferences')
    .insert(preferences);

  return { user, error };
}

function generateStrongPassword() {
  // Implement secure password generation logic
  return 'SecurePassword123!';
}

Deno.serve(async (req) => {
  const { email, preferences } = await req.json();
  
  try {
    const result = await registerUser(email, preferences);
    return new Response(JSON.stringify(result), {
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
});
