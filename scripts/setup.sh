#!/usr/bin/env bash
set -euo pipefail
APP="hala-madrid-housing"
mkdir -p "$APP" && cd "$APP"

# .gitignore
cat > .gitignore <<'EOF'
node_modules/
.next/
out/
.env*
!.env.example
npm-debug.log*
yarn-*.log*
pnpm-debug.log*
EOF

# package.json
cat > package.json <<'EOF'
{
  "name": "hala-madrid-housing",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "14.2.5",
    "react": "18.2.0",
    "react-dom": "18.2.0",
    "@supabase/supabase-js": "2.46.1"
  },
  "devDependencies": {
    "typescript": "5.4.5",
    "eslint": "8.57.0",
    "tailwindcss": "3.4.4",
    "postcss": "8.4.38",
    "autoprefixer": "10.4.18"
  }
}
EOF

# next config
cat > next.config.mjs <<'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: { serverActions: { bodySizeLimit: '2mb' } }
};
export default nextConfig;
EOF

# tsconfig
cat > tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["DOM", "ES2020"],
    "jsx": "preserve",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "skipLibCheck": true,
    "strict": false,
    "noEmit": true,
    "types": ["node"]
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx"],
  "exclude": ["node_modules"]
}
EOF

# PostCSS + Tailwind
cat > postcss.config.mjs <<'EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
EOF

cat > tailwind.config.ts <<'EOF'
import type { Config } from 'tailwindcss'
const config: Config = {
  content: [
    './app/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './pages/**/*.{ts,tsx}'
  ],
  theme: { extend: {} },
  plugins: []
}
export default config
EOF

# styles
mkdir -p styles
cat > styles/globals.css <<'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

.btn { @apply inline-flex items-center justify-center rounded-xl border px-4 py-2 text-sm font-medium hover:opacity-90; }
.btn-primary { @apply bg-black text-white; }
.btn-outline { @apply bg-white; }
.input { @apply w-full rounded-xl border px-3 py-2 text-sm; }
.textarea { @apply w-full rounded-xl border px-3 py-2 text-sm min-h-[120px]; }
.muted { @apply text-sm text-neutral-500; }
.container { @apply mx-auto max-w-5xl px-4; }
.card { @apply rounded-2xl border p-3; }
EOF

# env example
cat > .env.example <<'EOF'
NEXT_PUBLIC_SUPABASE_URL=https://lyuktkbwisrrrzlbvkyu.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_ANON_KEY
SUPABASE_SERVICE_KEY=YOUR_SERVICE_ROLE_KEY
NEXT_PUBLIC_GROUP_INVITE=https://chat.whatsapp.com/BEheesC4KfdGAP1YzpPWRe?mode=r_t
ADMIN_SECRET=change-me
EOF

# folders
mkdir -p app/(marketing) app/listings app/listings/[id] app/seekers app/api/listings app/api/listings/[id] app/api/reports app/api/tokens app/api/seekers app/api/wa/send components lib supabase

# layout + marketing
cat > app/layout.tsx <<'EOF'
import './globals.css';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Hala Madrid 🏡',
  description: 'Student housing community powered by WhatsApp'
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <nav className="border-b">
          <div className="container py-3 flex items-center justify-between">
            <a href="/" className="font-semibold">Hala Madrid 🏡</a>
            <div className="flex gap-3">
              <a className="btn" href="/listings">Browse</a>
              <a className="btn" href="/seekers">Seekers</a>
              <a className="btn btn-primary" href="/listings/new">Post</a>
              <a className="btn btn-outline" href={process.env.NEXT_PUBLIC_GROUP_INVITE || '#'} target="_blank" rel="noreferrer">Join WhatsApp</a>
            </div>
          </div>
        </nav>
        {children}
        <footer className="border-t mt-10">
          <div className="container py-6 text-sm text-neutral-500">© {new Date().getFullYear()} Hala Madrid Housing</div>
        </footer>
      </body>
    </html>
  );
}
EOF

cat > app/(marketing)/page.tsx <<'EOF'
export default function Page() {
  return (
    <main className="container py-10 space-y-6">
      <section className="text-center space-y-4">
        <h1 className="text-4xl font-bold">Find rooms & flatmates in Madrid</h1>
        <p className="text-neutral-600">WhatsApp-first housing community for students and expats.</p>
        <div className="mt-6 flex justify-center gap-3">
          <a className="btn btn-primary" href="/listings">Browse listings</a>
          <a className="btn" href="/seekers">Find flatmates</a>
          <a className="btn btn-outline" href={process.env.NEXT_PUBLIC_GROUP_INVITE || '#'} target="_blank" rel="noreferrer">Join WhatsApp Group</a>
        </div>
      </section>
    </main>
  );
}
EOF

# ensure / route
cat > app/page.tsx <<'EOF'
export { default } from './(marketing)/page';
EOF

# lib
cat > lib/supabaseClient.ts <<'EOF'
import { createClient } from '@supabase/supabase-js'

export function createBrowserClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}

export function createServerClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { auth: { persistSession: false } }
  );
}
EOF

cat > lib/phone.ts <<'EOF'
import crypto from 'crypto';
export const phoneHash = (phone: string) => crypto.createHash('sha256').update(phone.trim()).digest('hex');
export const waDM = (phone: string, text: string) => `https://wa.me/${phone.replace(/\D/g,'')}?text=${encodeURIComponent(text)}`;
EOF

cat > lib/auth.ts <<'EOF'
export function isAdmin(headers: Headers) {
  const secret = headers.get('x-admin-secret');
  return !!secret && secret === process.env.ADMIN_SECRET;
}
EOF

# components
cat > components/ListingCard.tsx <<'EOF'
import Link from 'next/link';
import { waDM } from '@/lib/phone';
export default function ListingCard({ item }: { item: any }) {
  const dm = waDM('34600111222', `Hola! I'm interested in ${item.title} (${item.location_text})`);
  return (
    <div className="card space-y-2">
      {item.images?.[0] && <img src={item.images[0]} alt={item.title} className="w-full h-40 object-cover rounded-xl"/>}
      <div className="flex justify-between items-center">
        <h3 className="font-medium">{item.title}</h3>
        <span className="font-semibold">€{item.price}</span>
      </div>
      <p className="text-sm text-neutral-600 line-clamp-2">{item.location_text}</p>
      <div className="flex gap-2">
        <a className="btn btn-outline" href={dm} target="_blank">Message on WhatsApp</a>
        <Link className="btn" href={`/listings/${item.id}`}>Details</Link>
      </div>
    </div>
  );
}
EOF

cat > components/ImageUploader.tsx <<'EOF'
'use client';
import { useState } from 'react';
import { createBrowserClient } from '@/lib/supabaseClient';

export default function ImageUploader({ token, onUploaded }:{ token:string; onUploaded:(url:string)=>void }) {
  const [loading, setLoading] = useState(false);
  const supabase = createBrowserClient();
  async function handleFile(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setLoading(true);
    const ext = file.name.split('.').pop();
    const path = `${crypto.randomUUID()}.${ext}`;
    // @ts-ignore pass token header for RLS
    const { data, error } = await supabase.storage.from('listing-images').upload(path, file, {
      cacheControl: '3600', upsert: false, duplex: 'half',
      fetch: (url: string, opts: any) => fetch(url, { ...opts, headers: { ...(opts?.headers||{}), 'x-post-token': token } })
    });
    setLoading(false);
    if (error) return alert(error.message);
    const { data: pub } = supabase.storage.from('listing-images').getPublicUrl(path);
    onUploaded(pub.publicUrl);
  }
  return (
    <label className="block">
      <span className="btn">{loading ? 'Uploading…' : 'Upload image'}</span>
      <input type="file" accept="image/*" className="hidden" onChange={handleFile} />
    </label>
  );
}
EOF

# listings
cat > app/listings/page.tsx <<'EOF'
'use client';
import { useEffect, useState } from 'react';
import ListingCard from '@/components/ListingCard';
export default function ListingsPage() {
  const [data, setData] = useState<any[]>([]);
  const [min, setMin] = useState('');
  const [max, setMax] = useState('');
  useEffect(() => {
    const p = new URLSearchParams();
    if (min) p.set('min', min);
    if (max) p.set('max', max);
    fetch('/api/listings?' + p.toString()).then(r => r.json()).then(r => setData(r.data || []));
  }, [min, max]);
  return (
    <main className="container py-6 space-y-6">
      <div className="flex gap-4">
        <input className="input" placeholder="Min €" value={min} onChange={e=>setMin(e.target.value)} />
        <input className="input" placeholder="Max €" value={max} onChange={e=>setMax(e.target.value)} />
        <a className="btn btn-primary" href="/listings/new">Post a listing</a>
      </div>
      {data.length === 0 ? <div className="muted">No listings yet.</div> : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {data.map(x => <ListingCard key={x.id} item={x} />)}
        </div>
      )}
    </main>
  );
}
EOF

cat > app/listings/new/page.tsx <<'EOF'
'use client';
import { useState } from 'react';
import ImageUploader from '@/components/ImageUploader';
export default function NewListingPage() {
  const [token, setToken] = useState('');
  const [images, setImages] = useState<string[]>([]);
  const [form, setForm] = useState<any>({ title:'', price:'', location_text:'', rooms:1, description:'' });
  const onSubmit = async () => {
    const res = await fetch('/api/listings', { method:'POST', headers:{ 'Content-Type':'application/json', 'x-post-token': token }, body: JSON.stringify({ ...form, price: Number(form.price), images })});
    const json = await res.json();
    alert(json.error ? json.error : 'Posted!');
    if (!json.error) window.location.href = '/listings';
  };
  return (
    <main className="container py-6 space-y-4 max-w-2xl">
      <h1 className="text-2xl font-semibold">Post a listing</h1>
      <input className="input" placeholder="Posting token" value={token} onChange={e=>setToken(e.target.value)} />
      <input className="input" placeholder="Title" value={form.title} onChange={e=>setForm({ ...form, title: e.target.value })} />
      <input className="input" placeholder="Price (€)" value={form.price} onChange={e=>setForm({ ...form, price: e.target.value })} />
      <input className="input" placeholder="Location" value={form.location_text} onChange={e=>setForm({ ...form, location_text: e.target.value })} />
      <textarea className="textarea" placeholder="Description" value={form.description} onChange={e=>setForm({ ...form, description: e.target.value })} />
      <div className="space-y-2">
        <p className="text-sm font-medium">Photos</p>
        <div className="flex flex-wrap gap-2">
          {images.map((u,i)=> (<img key={i} src={u} className="h-20 w-20 object-cover rounded-lg border"/>))}
        </div>
        <ImageUploader token={token} onUploaded={(u)=> setImages(prev=> [...prev, u])} />
      </div>
      <button className="btn btn-primary" onClick={onSubmit}>Publish</button>
      <p className="text-sm text-neutral-500">Ask an admin for a token. Tokens expire automatically.</p>
    </main>
  );
}
EOF

cat > app/listings/[id]/page.tsx <<'EOF'
import { createServerClient } from '@/lib/supabaseClient';
export default async function ListingDetail({ params }: { params: { id: string }}) {
  const supabase = createServerClient();
  const { data, error } = await supabase.from('listings').select('*').eq('id', params.id).single();
  if (error || !data) return <main className="container py-6">Listing not found.</main>;
  return (
    <main className="container py-6 space-y-4">
      <h1 className="text-2xl font-semibold">{data.title}</h1>
      {data.images?.[0] && <img src={data.images[0]} alt={data.title} className="w-full max-h-[400px] object-cover rounded-xl" />}
      <div className="text-lg font-semibold">€{data.price}</div>
      <div className="whitespace-pre-wrap">{data.description}</div>
      <a className="btn btn-outline" href={`https://wa.me/34600111222?text=${encodeURIComponent('Hi! Interested in ' + data.title)}`} target="_blank">Message on WhatsApp</a>
    </main>
  );
}
EOF

# seekers
cat > app/seekers/page.tsx <<'EOF'
'use client';
import { useEffect, useState } from 'react';
function Card({ item }: { item: any }) {
  const msg = encodeURIComponent(`Hola! Saw your seeker post: ${item.title}`);
  return (
    <div className="card space-y-2">
      {item.images?.[0] && <img src={item.images[0]} alt={item.title} className="w-full h-40 object-cover rounded-xl"/>}
      <div className="flex justify-between items-center">
        <h3 className="font-medium">{item.title}</h3>
        {item.max_budget ? <span className="font-semibold">Up to €{item.max_budget}</span> : null}
      </div>
      <p className="text-sm text-neutral-600 line-clamp-2">{item.bio}</p>
      <div className="flex gap-2">
        <a className="btn btn-outline" href={`https://wa.me/34600111222?text=${msg}`} target="_blank">Message on WhatsApp</a>
      </div>
    </div>
  );
}
export default function SeekersPage() {
  const [data, setData] = useState<any[]>([]);
  useEffect(() => { fetch('/api/seekers').then(r => r.json()).then(r => setData(r.data || [])); }, []);
  return (
    <main className="container py-6 space-y-6">
      <div className="flex gap-4">
        <a className="btn btn-primary" href="/seekers/new">Post as Seeker</a>
      </div>
      {data.length === 0 ? <div className="muted">No seeker posts yet.</div> : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {data.map(x => <Card key={x.id} item={x} />)}
        </div>
      )}
    </main>
  );
}
EOF

cat > app/seekers/new/page.tsx <<'EOF'
'use client';
import { useState } from 'react';
export default function NewSeekerPage() {
  const [token, setToken] = useState('');
  const [form, setForm] = useState<any>({ title:'', bio:'', max_budget:'', roommates_count:1, length_months:6 });
  const onSubmit = async () => {
    const res = await fetch('/api/seekers', { method:'POST', headers:{ 'Content-Type':'application/json', 'x-post-token': token }, body: JSON.stringify({ ...form, max_budget: form.max_budget ? Number(form.max_budget) : null })});
    const json = await res.json();
    alert(json.error ? json.error : 'Posted!');
    if (!json.error) window.location.href = '/seekers';
  };
  return (
    <main className="container py-6 space-y-4 max-w-2xl">
      <h1 className="text-2xl font-semibold">Post a seeker profile</h1>
      <input className="input" placeholder="Posting token" value={token} onChange={e=>setToken(e.target.value)} />
      <input className="input" placeholder="Title" value={form.title} onChange={e=>setForm({ ...form, title: e.target.value })} />
      <textarea className="textarea" placeholder="Short bio / what you're looking for" value={form.bio} onChange={e=>setForm({ ...form, bio: e.target.value })} />
      <input className="input" placeholder="Max budget (€)" value={form.max_budget} onChange={e=>setForm({ ...form, max_budget: e.target.value })} />
      <input className="input" placeholder="Length of stay (months)" value={form.length_months} onChange={e=>setForm({ ...form, length_months: e.target.value })} />
      <button className="btn btn-primary" onClick={onSubmit}>Publish</button>
      <p className="text-sm text-neutral-500">Ask an admin for a token. Tokens expire automatically.</p>
    </main>
  );
}
EOF

# API routes
cat > app/api/listings/route.ts <<'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@/lib/supabaseClient';
export async function GET(req: NextRequest) {
  const supabase = createServerClient();
  const { searchParams } = new URL(req.url);
  const min = Number(searchParams.get('min') ?? 0);
  const max = Number(searchParams.get('max') ?? 999999);
  const { data, error } = await supabase
    .from('listings').select('*')
    .eq('status','active')
    .gte('price', min).lte('price', max)
    .order('created_at',{ascending:false});
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  return NextResponse.json({ data });
}
export async function POST(req: NextRequest) {
  const supabase = createServerClient();
  const body = await req.json();
  const token = req.headers.get('x-post-token') || '';
  const { data, error } = await supabase.from('listings').insert({ ...body }).select('*').single();
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  return NextResponse.json({ data }, { headers: { 'x-post-token': token } });
}
EOF

cat > app/api/listings/[id]/route.ts <<'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@/lib/supabaseClient';
export async function GET(_: NextRequest, { params }: { params: { id: string }}) {
  const supabase = createServerClient();
  const { data, error } = await supabase.from('listings').select('*').eq('id', params.id).single();
  if (error) return NextResponse.json({ error: error.message }, { status: 404 });
  return NextResponse.json({ data });
}
EOF

cat > app/api/reports/route.ts <<'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@/lib/supabaseClient';
export async function POST(req: NextRequest) {
  const supabase = createServerClient();
  const body = await req.json();
  const { data, error } = await supabase.from('reports').insert(body).select('*').single();
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  return NextResponse.json({ data });
}
EOF

cat > app/api/tokens/route.ts <<'EOF'
import { NextRequest, NextResponse } from 'next/server';
import crypto from 'crypto';
import { createClient } from '@supabase/supabase-js';
import { isAdmin } from '@/lib/auth';
export async function POST(req: NextRequest) {
  if (!isAdmin(req.headers)) return NextResponse.json({ error:'unauthorized' }, { status:401 });
  const { group_id, type = 'post', ttl_minutes = 1440 } = await req.json();
  const admin = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.SUPABASE_SERVICE_KEY!);
  const token = crypto.randomBytes(16).toString('hex');
  const expires_at = new Date(Date.now() + ttl_minutes * 60_000).toISOString();
  const { data, error } = await admin.from('tokens').insert({ token, type, group_id, expires_at }).select('*').single();
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  return NextResponse.json({ data });
}
EOF

cat > app/api/seekers/route.ts <<'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@/lib/supabaseClient';
export async function GET(req: NextRequest) {
  const supabase = createServerClient();
  const { data, error } = await supabase.from('seeker_posts').select('*').eq('status','active').order('created_at',{ascending:false});
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  return NextResponse.json({ data });
}
export async function POST(req: NextRequest) {
  const supabase = createServerClient();
  const body = await req.json();
  const token = req.headers.get('x-post-token') || '';
  const { data, error } = await supabase.from('seeker_posts').insert(body).select('*').single();
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  return NextResponse.json({ data }, { headers: { 'x-post-token': token } });
}
EOF

cat > app/api/wa/send/route.ts <<'EOF'
import { NextRequest, NextResponse } from 'next/server';
export async function POST(req: NextRequest) {
  if (req.headers.get('x-admin-secret') !== process.env.ADMIN_SECRET)
    return NextResponse.json({ error:'unauthorized' }, { status:401 });
  const { to, template, params } = await req.json();
  const r = await fetch(`https://graph.facebook.com/v20.0/${process.env.WHATSAPP_PHONE_NUMBER_ID}/messages`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${process.env.WHATSAPP_TOKEN}`, 'Content-Type':'application/json' },
    body: JSON.stringify({
      messaging_product: 'whatsapp',
      to,
      type: 'template',
      template: { name: template, language: { code: 'en' }, components: [{ type:'body', parameters: (params||[]).map((t:string)=> ({ type:'text', text:t })) }] }
    })
  });
  const json = await r.json();
  if (!r.ok) return NextResponse.json({ error: json?.error?.message || 'send failed' }, { status: 400 });
  return NextResponse.json({ ok: true, id: json.messages?.[0]?.id });
}
EOF

# admin page
cat > app/admin/page.tsx <<'EOF'
import { headers } from 'next/headers';
import crypto from 'crypto';
import { createClient } from '@supabase/supabase-js';
export default async function AdminPage() {
  if (headers().get('x-admin-secret') !== process.env.ADMIN_SECRET) {
    return <div className="container py-6">Unauthorized</div>;
  }
  const admin = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.SUPABASE_SERVICE_KEY!);
  const { data: pendingReports } = await admin.from('reports').select('*').order('created_at',{ascending:false}).limit(50);
  const { data: recentListings } = await admin.from('listings').select('*').order('created_at',{ascending:false}).limit(50);
  async function issueToken(formData: FormData) {
    'use server';
    const type = formData.get('type') as string;
    const group_id = formData.get('group_id') as string;
    const ttl = Number(formData.get('ttl')) || 1440;
    const token = crypto.randomUUID().replace(/-/g,'');
    const adminClient = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.SUPABASE_SERVICE_KEY!);
    await adminClient.from('tokens').insert({ token, type, group_id, expires_at: new Date(Date.now()+ttl*60_000).toISOString() });
    return { token };
  }
  return (
    <main className="container p-6 space-y-8">
      <h1 className="text-2xl font-semibold">Admin</h1>
      <section className="space-y-3">
        <h2 className="text-xl font-medium">Issue posting token</h2>
        <form action={issueToken} className="flex flex-wrap gap-2 items-end">
          <input name="group_id" placeholder="group_id" className="input" required />
          <select name="type" className="input"><option value="post">post</option><option value="admin">admin</option></select>
          <input name="ttl" placeholder="TTL minutes" className="input" />
          <button className="btn btn-primary" type="submit">Create</button>
        </form>
      </section>
      <section className="space-y-2">
        <h2 className="text-xl font-medium">Recent listings</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {recentListings?.map((l:any)=> (
            <div key={l.id} className="card">
              <div className="flex justify-between"><b>{l.title}</b><span>€{l.price}</span></div>
              <div className="text-sm text-neutral-600">{l.location_text}</div>
            </div>
          ))}
        </div>
      </section>
      <section className="space-y-2">
        <h2 className="text-xl font-medium">Reports</h2>
        {pendingReports?.length ? pendingReports.map((r:any)=> (
          <div key={r.id} className="card">
            <div className="text-sm">Listing: {r.listing_id}</div>
            <div className="text-sm">Reason: {r.reason}</div>
            <div className="text-xs text-neutral-500">{new Date(r.created_at).toLocaleString()}</div>
          </div>
        )) : <div className="muted">No reports.</div>}
      </section>
    </main>
  );
}
EOF

# SQL files
cat > supabase/schema.sql <<'EOF'
create extension if not exists pgcrypto;
create table if not exists profiles (
  id uuid primary key default gen_random_uuid(),
  display_name text,
  phone_hash text unique,
  role text check (role in ('member','poster','admin')) default 'member',
  created_at timestamptz default now()
);
create table if not exists groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  city text,
  wa_invite_url text not null,
  created_at timestamptz default now()
);
create table if not exists listings (
  id uuid primary key default gen_random_uuid(),
  group_id uuid references groups(id) on delete cascade,
  owner_id uuid references profiles(id) on delete set null,
  title text not null,
  description text,
  price numeric(10,2) not null,
  location_text text,
  lat double precision,
  lng double precision,
  rooms int,
  amenities text[],
  images text[],
  contact_phone_last4 text,
  status text check (status in ('active','hidden','sold','expired')) default 'active',
  expires_at timestamptz,
  match_score numeric(5,2),
  created_at timestamptz default now()
);
create table if not exists reports (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid references listings(id) on delete cascade,
  reporter_id uuid references profiles(id) on delete set null,
  reason text,
  notes text,
  created_at timestamptz default now()
);
create table if not exists announcements (
  id uuid primary key default gen_random_uuid(),
  group_id uuid references groups(id) on delete cascade,
  title text not null,
  body_md text,
  is_pinned boolean default false,
  created_at timestamptz default now()
);
create table if not exists tokens (
  id uuid primary key default gen_random_uuid(),
  token text unique not null,
  type text check (type in ('post','admin')) not null,
  group_id uuid references groups(id) on delete cascade,
  issued_to_phone_hash text,
  expires_at timestamptz not null,
  used_at timestamptz
);
create table if not exists seeker_posts (
  id uuid primary key default gen_random_uuid(),
  group_id uuid references groups(id) on delete cascade,
  owner_id uuid references profiles(id) on delete set null,
  title text not null,
  bio text,
  max_budget numeric(10,2),
  preferred_districts text[],
  move_in_date date,
  length_months int,
  roommates_count int,
  whatsapp_phone_last4 text,
  images text[],
  status text check (status in ('active','hidden','expired')) default 'active',
  created_at timestamptz default now()
);
EOF

cat > supabase/policies.sql <<'EOF'
alter table profiles enable row level security;
alter table listings enable row level security;
alter table reports enable row level security;
alter table announcements enable row level security;
alter table tokens enable row level security;
alter table seeker_posts enable row level security;
create policy "read_active_listings" on listings for select using (status = 'active');
create policy "read_announcements" on announcements for select using (true);
create policy "public_read_seekers" on seeker_posts for select using (status='active');
create or replace function has_valid_post_token() returns boolean as $$
  select exists(
    select 1 from tokens t
    where t.type = 'post'
      and t.token = current_setting('request.headers', true)::json->>'x-post-token'
      and t.expires_at > now()
      and t.used_at is null
  );
$$ language sql stable;
create policy "insert_with_token" on listings for insert with check (has_valid_post_token());
create policy "insert_seekers_with_token" on seeker_posts for insert with check (has_valid_post_token());
create policy "insert_reports" on reports for insert with check (true);
EOF

cat > supabase/storage-buckets.sql <<'EOF'
insert into storage.buckets (id, name, public)
values ('listing-images','listing-images', true)
on conflict (id) do nothing;
create policy if not exists "public_read_images" on storage.objects
  for select using (bucket_id = 'listing-images');
create or replace function has_valid_post_token_storage() returns boolean as $$
  select exists(
    select 1 from tokens t
    where t.type = 'post'
      and t.token = current_setting('request.headers', true)::json->>'x-post-token'
      and t.expires_at > now()
      and t.used_at is null
  );
$$ language sql stable;
create policy if not exists "upload_with_token" on storage.objects
  for insert with check (bucket_id = 'listing-images' and has_valid_post_token_storage());
EOF

cat > supabase/seed.sql <<'EOF'
insert into groups (name, city, wa_invite_url) values
 ('Hala Madrid 🏡', 'Madrid', 'https://chat.whatsapp.com/BEheesC4KfdGAP1YzpPWRe?mode=r_t')
on conflict do nothing;
with g as (select id from groups where name='Hala Madrid 🏡' limit 1)
insert into listings (group_id, title, description, price, location_text, rooms, amenities, images, contact_phone_last4)
select g.id,
  'Fully-furnished room near IE (10 min walk)',
  $$About the House:
- Fully furnished with modern amenities
- Plenty of windows and great lighting
- Living room with a lounger
- Open kitchen with seating + separate dining table

About the Room (3rd bedroom):
- 4×6" bed
- Study table with ergonomic chair
- 3 cupboards (ample storage)
- Non-attached 2nd bathroom shared with one flatmate

Distances:
- ~10 minutes (600–700m) walking to IE María de Molina

Terms:
- Rent: €750/month
- Utilities: €60–70/month on actuals
- Agent commission: 1 month
- Deposit: 1 month$$,
  750,
  'María de Molina / Salamanca',
  1,
  '{wifi, furnished, bright, kitchen, dining}',
  '{"/placeholder/room.jpg"}',
  '1234'
from g on conflict do nothing;
EOF

# README
cat > README.md <<'EOF'
# Hala Madrid Housing
WhatsApp-first housing site for students and expats in Madrid. Built with **Next.js 14 + Supabase + Tailwind**.

## Quickstart
1. Copy envs
