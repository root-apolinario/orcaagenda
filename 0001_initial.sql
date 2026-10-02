-- OrçaAgenda: multi-tenant schema, RLS and business operations.
-- Execute with `supabase db push` or in Supabase SQL Editor. Run only on a new project.

create extension if not exists pgcrypto;
create extension if not exists btree_gist;

create type public.company_lifecycle as enum ('demo', 'active', 'suspended', 'archived');
create type public.booking_mode as enum ('automatic', 'manual');
create type public.price_kind as enum ('fixed', 'manual');
create type public.appointment_state as enum ('confirmed', 'pending', 'hold', 'declined', 'cancelled', 'completed');
create type public.deal_stage as enum ('new', 'analyzed', 'demo_prepared', 'contacted', 'replied', 'interested', 'proposal_sent', 'won', 'lost', 'do_not_contact');
create type public.verification_state as enum ('unverified', 'verified', 'needs_review');
create type public.member_role as enum ('owner', 'manager', 'scheduler', 'viewer');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text check (char_length(display_name) <= 120),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.platform_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.companies (
  id uuid primary key default gen_random_uuid(),
  lead_id uuid unique,
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  public_token uuid not null unique default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 160),
  description text check (char_length(description) <= 1200),
  theme_key text not null default 'professional' check (theme_key in ('beauty', 'maintenance', 'professional')),
  lifecycle public.company_lifecycle not null default 'demo',
  booking_enabled boolean not null default false,
  booking_mode public.booking_mode not null default 'automatic',
  manual_holds_slot boolean not null default true,
  manual_hold_minutes integer not null default 120 check (manual_hold_minutes between 5 and 10080),
  timezone text not null default 'America/Sao_Paulo',
  city text check (char_length(city) <= 120),
  state text check (state is null or state ~ '^[A-Z]{2}$'),
  address_text text check (char_length(address_text) <= 500),
  service_area text check (char_length(service_area) <= 500),
  contact_phone text check (contact_phone is null or contact_phone ~ '^[0-9+() -]{10,22}$'),
  contact_email text check (contact_email is null or contact_email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
  logo_path text,
  color_primary text not null default '#0f8b78' check (color_primary ~ '^#[0-9A-Fa-f]{6}$'),
  booking_notice_hours integer not null default 2 check (booking_notice_hours between 0 and 720),
  booking_horizon_days integer not null default 60 check (booking_horizon_days between 1 and 365),
  demo_expires_at timestamptz,
  demo_disabled_at timestamptz,
  activated_at timestamptz,
  suspended_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint booking_only_active check (not booking_enabled or lifecycle = 'active'),
  constraint demo_expiry_only_demo check (demo_expires_at is null or lifecycle = 'demo')
);

create table public.company_members (
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.member_role not null default 'viewer',
  created_at timestamptz not null default now(),
  primary key (company_id, user_id)
);

create table public.services (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 160),
  description text check (char_length(description) <= 1000),
  price_type public.price_kind not null default 'manual',
  price_cents integer check (price_cents is null or price_cents >= 0),
  duration_minutes integer not null check (duration_minutes between 5 and 1440),
  buffer_minutes integer not null default 0 check (buffer_minutes between 0 and 240),
  quantity_label text check (char_length(quantity_label) <= 80),
  service_area text check (char_length(service_area) <= 500),
  pricing_rules jsonb not null default '{}'::jsonb check (jsonb_typeof(pricing_rules) = 'object'),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint fixed_price_requires_value check ((price_type = 'fixed' and price_cents is not null) or (price_type = 'manual' and price_cents is null))
);
create index services_company_active_idx on public.services(company_id, is_active);

create table public.availability_windows (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  day_of_week smallint not null check (day_of_week between 0 and 6),
  start_time time not null,
  end_time time not null,
  created_at timestamptz not null default now(),
  check (start_time < end_time)
);
create index availability_windows_company_day_idx on public.availability_windows(company_id, day_of_week);

create table public.schedule_blocks (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  reason text check (char_length(reason) <= 300),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  check (starts_at < ends_at)
);
create index schedule_blocks_company_range_idx on public.schedule_blocks using gist(company_id, tstzrange(starts_at, ends_at, '[)'));

create table public.leads (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 160),
  segment text check (char_length(segment) <= 160),
  city text check (char_length(city) <= 120),
  state text check (state is null or state ~ '^[A-Z]{2}$'),
  website_url text check (website_url is null or website_url ~* '^https?://'),
  google_maps_url text check (google_maps_url is null or google_maps_url ~* '^https?://'),
  phone_public text check (phone_public is null or phone_public ~ '^[0-9+() -]{10,22}$'),
  email_public text check (email_public is null or email_public ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
  whatsapp_verified boolean not null default false,
  source_urls text[] not null default '{}',
  source_checked_at timestamptz,
  verification_status public.verification_state not null default 'needs_review',
  score integer not null default 0 check (score between 0 and 100),
  score_reasons text[] not null default '{}',
  deal_stage public.deal_stage not null default 'new',
  notes text check (char_length(notes) <= 4000),
  last_contact_at timestamptz,
  next_action_at timestamptz,
  dedupe_key text generated always as (lower(regexp_replace(name, '[^a-zA-Z0-9]+', '', 'g')) || ':' || coalesce(state, '') || ':' || lower(regexp_replace(coalesce(city, ''), '[^a-zA-Z0-9]+', '', 'g'))) stored,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (not whatsapp_verified or phone_public is not null)
);
create unique index leads_dedupe_key_unique on public.leads(dedupe_key);
create unique index leads_domain_unique on public.leads((lower(split_part(regexp_replace(coalesce(website_url, ''), '^https?://', ''), '/', 1)))) where website_url is not null;
create index leads_stage_idx on public.leads(deal_stage);

alter table public.companies add constraint companies_lead_fk foreign key (lead_id) references public.leads(id) on delete set null;

create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  service_id uuid not null references public.services(id) on delete restrict,
  public_token uuid not null unique default gen_random_uuid(),
  idempotency_key uuid not null,
  consumer_name text not null check (char_length(consumer_name) between 2 and 160),
  consumer_phone text check (consumer_phone is null or consumer_phone ~ '^[0-9+() -]{10,22}$'),
  consumer_email text check (consumer_email is null or consumer_email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  price_type public.price_kind not null,
  price_cents integer check (price_cents is null or price_cents >= 0),
  state public.appointment_state not null,
  hold_expires_at timestamptz,
  customer_notes text check (char_length(customer_notes) <= 1000),
  internal_notes text check (char_length(internal_notes) <= 4000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (starts_at < ends_at),
  check ((state = 'hold' and hold_expires_at is not null) or (state <> 'hold' and hold_expires_at is null)),
  unique (company_id, idempotency_key)
);
alter table public.appointments add constraint appointments_no_active_overlap exclude using gist (
  company_id with =,
  tstzrange(starts_at, ends_at, '[)') with &&
) where (state in ('confirmed', 'pending', 'hold'));
create index appointments_company_starts_idx on public.appointments(company_id, starts_at);

create table public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id) on delete set null,
  company_id uuid references public.companies(id) on delete set null,
  action text not null check (char_length(action) between 3 and 120),
  entity_type text not null check (char_length(entity_type) between 3 and 80),
  entity_id uuid,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index audit_logs_company_created_idx on public.audit_logs(company_id, created_at desc);

create or replace function public.touch_updated_at()
returns trigger language plpgsql security invoker set search_path = public as $$
begin new.updated_at = now(); return new; end; $$;
create trigger profiles_updated before update on public.profiles for each row execute function public.touch_updated_at();
create trigger companies_updated before update on public.companies for each row execute function public.touch_updated_at();
create trigger services_updated before update on public.services for each row execute function public.touch_updated_at();
create trigger leads_updated before update on public.leads for each row execute function public.touch_updated_at();
create trigger appointments_updated before update on public.appointments for each row execute function public.touch_updated_at();

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin insert into public.profiles(id, display_name) values (new.id, nullif(new.raw_user_meta_data ->> 'display_name', '')) on conflict do nothing; return new; end; $$;
create trigger auth_user_profile after insert on auth.users for each row execute function public.handle_new_user();

create or replace function public.is_platform_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.platform_admins where user_id = auth.uid());
$$;

create or replace function public.is_company_member(target_company uuid, minimum_role public.member_role default 'viewer')
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_platform_admin() or exists (
    select 1 from public.company_members cm
    where cm.company_id = target_company and cm.user_id = auth.uid()
      and case minimum_role
        when 'viewer' then true
        when 'scheduler' then cm.role in ('owner','manager','scheduler')
        when 'manager' then cm.role in ('owner','manager')
        when 'owner' then cm.role = 'owner'
      end
  );
$$;

create or replace function public.log_audit(p_company_id uuid, p_action text, p_entity_type text, p_entity_id uuid, p_details jsonb default '{}'::jsonb)
returns void language plpgsql security definer set search_path = public as $$
begin insert into public.audit_logs(actor_id, company_id, action, entity_type, entity_id, details) values (auth.uid(), p_company_id, p_action, p_entity_type, p_entity_id, p_details); end; $$;

-- RLS: no client can switch a company id and obtain another tenant's data.
alter table public.profiles enable row level security;
alter table public.platform_admins enable row level security;
alter table public.companies enable row level security;
alter table public.company_members enable row level security;
alter table public.services enable row level security;
alter table public.availability_windows enable row level security;
alter table public.schedule_blocks enable row level security;
alter table public.leads enable row level security;
alter table public.appointments enable row level security;
alter table public.audit_logs enable row level security;

create policy profiles_self_select on public.profiles for select to authenticated using (id = auth.uid() or public.is_platform_admin());
create policy profiles_self_update on public.profiles for update to authenticated using (id = auth.uid() or public.is_platform_admin()) with check (id = auth.uid() or public.is_platform_admin());
create policy admins_self_select on public.platform_admins for select to authenticated using (user_id = auth.uid() or public.is_platform_admin());
create policy companies_select on public.companies for select to authenticated using (public.is_company_member(id) or public.is_platform_admin());
create policy companies_insert on public.companies for insert to authenticated with check (public.is_platform_admin());
create policy companies_update on public.companies for update to authenticated using (public.is_company_member(id, 'manager') or public.is_platform_admin()) with check (public.is_company_member(id, 'manager') or public.is_platform_admin());
create policy members_select on public.company_members for select to authenticated using (public.is_company_member(company_id) or public.is_platform_admin());
create policy members_manage on public.company_members for all to authenticated using (public.is_company_member(company_id, 'owner') or public.is_platform_admin()) with check (public.is_company_member(company_id, 'owner') or public.is_platform_admin());
create policy services_select on public.services for select to authenticated using (public.is_company_member(company_id) or public.is_platform_admin());
create policy services_manage on public.services for all to authenticated using (public.is_company_member(company_id, 'manager') or public.is_platform_admin()) with check (public.is_company_member(company_id, 'manager') or public.is_platform_admin());
create policy availability_select on public.availability_windows for select to authenticated using (public.is_company_member(company_id) or public.is_platform_admin());
create policy availability_manage on public.availability_windows for all to authenticated using (public.is_company_member(company_id, 'manager') or public.is_platform_admin()) with check (public.is_company_member(company_id, 'manager') or public.is_platform_admin());
create policy blocks_select on public.schedule_blocks for select to authenticated using (public.is_company_member(company_id) or public.is_platform_admin());
create policy blocks_manage on public.schedule_blocks for all to authenticated using (public.is_company_member(company_id, 'scheduler') or public.is_platform_admin()) with check (public.is_company_member(company_id, 'scheduler') or public.is_platform_admin());
create policy leads_platform_only on public.leads for all to authenticated using (public.is_platform_admin()) with check (public.is_platform_admin());
create policy appointments_select on public.appointments for select to authenticated using (public.is_company_member(company_id, 'viewer') or public.is_platform_admin());
create policy appointments_manage on public.appointments for update to authenticated using (public.is_company_member(company_id, 'scheduler') or public.is_platform_admin()) with check (public.is_company_member(company_id, 'scheduler') or public.is_platform_admin());
create policy audit_select on public.audit_logs for select to authenticated using (public.is_company_member(company_id, 'manager') or public.is_platform_admin());

-- Public, narrow views. Demonstrations are intentionally separate from booking pages.
create view public.public_companies as
  select id, slug, name, description, theme_key, timezone, city, state, contact_phone, contact_email, booking_mode, booking_enabled, lifecycle, created_at, public_token, demo_expires_at
  from public.companies where lifecycle = 'active' and booking_enabled = true;
create view public.public_demos as
  select id, slug, name, description, theme_key, timezone, city, state, lifecycle, public_token, demo_expires_at, created_at
  from public.companies where lifecycle = 'demo' and demo_disabled_at is null and (demo_expires_at is null or demo_expires_at > now());
create view public.public_services as
  select s.id, s.company_id, s.name, s.description, s.price_type, s.price_cents, s.duration_minutes, s.buffer_minutes
  from public.services s
  join public.companies c on c.id = s.company_id
  where c.lifecycle = 'active' and c.booking_enabled and s.is_active;
grant select on public.public_companies, public.public_demos, public.public_services to anon, authenticated;

create or replace function public.expire_holds()
returns integer language plpgsql security definer set search_path = public as $$
declare changed integer; begin
  update public.appointments set state = 'cancelled', hold_expires_at = null
  where state = 'hold' and hold_expires_at <= now();
  get diagnostics changed = row_count; return changed;
end; $$;

create or replace function public.accept_lead_create_demo(p_lead_id uuid)
returns table(company_slug text, public_token uuid)
language plpgsql security definer set search_path = public as $$
declare l public.leads%rowtype; c public.companies%rowtype; base_slug text; suffix integer := 0;
begin
  if not public.is_platform_admin() then raise exception 'unauthorized'; end if;
  select * into l from public.leads where id = p_lead_id for update;
  if not found then raise exception 'lead_not_found'; end if;
  select * into c from public.companies where lead_id = l.id;
  if found then return query select c.slug, c.public_token; return; end if;
  base_slug := trim(both '-' from regexp_replace(lower(translate(l.name, 'áàãâäéèêëíìîïóòõôöúùûüçÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇ', 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC')), '[^a-z0-9]+', '-', 'g'));
  if base_slug = '' then base_slug := 'empresa'; end if;
  while exists(select 1 from public.companies where slug = base_slug || case when suffix = 0 then '' else '-' || suffix::text end) loop suffix := suffix + 1; end loop;
  insert into public.companies(lead_id, slug, name, theme_key, lifecycle, booking_enabled, city, state, contact_phone, contact_email, demo_expires_at)
  values (l.id, base_slug || case when suffix = 0 then '' else '-' || suffix::text end, l.name,
    case when coalesce(l.segment,'') ~* 'beleza|sal[aã]o|barbear|est[ée]tica' then 'beauty' when coalesce(l.segment,'') ~* 'manuten|oficina|assist|instala|limpeza' then 'maintenance' else 'professional' end,
    'demo', false, l.city, l.state, l.phone_public, l.email_public, now() + interval '14 days') returning * into c;
  insert into public.company_members(company_id, user_id, role) values(c.id, auth.uid(), 'owner') on conflict do nothing;
  update public.leads set deal_stage = 'demo_prepared' where id = l.id;
  perform public.log_audit(c.id, 'demo_created_from_lead', 'company', c.id, jsonb_build_object('lead_id', l.id));
  return query select c.slug, c.public_token;
end; $$;
grant execute on function public.accept_lead_create_demo(uuid) to authenticated;

create or replace function public.create_booking(
  p_company_id uuid, p_service_id uuid, p_starts_at timestamptz, p_consumer_name text, p_consumer_phone text, p_consumer_email text, p_idempotency_key uuid
) returns table(appointment_id uuid, public_token uuid, state public.appointment_state, starts_at timestamptz, ends_at timestamptz, price_cents integer, price_type public.price_kind)
language plpgsql security definer set search_path = public as $$
declare c public.companies%rowtype; s public.services%rowtype; a public.appointments%rowtype; local_start timestamp; local_end timestamp; selected_state public.appointment_state; hold_until timestamptz;
begin
  perform public.expire_holds();
  select * into a from public.appointments where company_id = p_company_id and idempotency_key = p_idempotency_key;
  if found then return query select a.id, a.public_token, a.state, a.starts_at, a.ends_at, a.price_cents, a.price_type; return; end if;
  select * into c from public.companies where id = p_company_id;
  if not found or c.lifecycle <> 'active' or not c.booking_enabled then raise exception 'booking_not_available'; end if;
  select * into s from public.services where id = p_service_id and company_id = c.id and is_active = true;
  if not found then raise exception 'service_not_available'; end if;
  if char_length(trim(coalesce(p_consumer_name,''))) < 2 then raise exception 'consumer_name_required'; end if;
  if p_consumer_email is not null and p_consumer_email !~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'invalid_email'; end if;
  if p_starts_at < now() + make_interval(hours => c.booking_notice_hours) or p_starts_at > now() + make_interval(days => c.booking_horizon_days) then raise exception 'outside_booking_window'; end if;
  local_start := p_starts_at at time zone c.timezone; local_end := (p_starts_at + make_interval(mins => s.duration_minutes + s.buffer_minutes)) at time zone c.timezone;
  if not exists(select 1 from public.availability_windows aw where aw.company_id = c.id and aw.day_of_week = extract(dow from local_start)::smallint and aw.start_time <= local_start::time and aw.end_time >= local_end::time) then raise exception 'outside_business_hours'; end if;
  if exists(select 1 from public.schedule_blocks b where b.company_id = c.id and tstzrange(b.starts_at,b.ends_at,'[)') && tstzrange(p_starts_at,p_starts_at + make_interval(mins => s.duration_minutes + s.buffer_minutes),'[)')) then raise exception 'slot_blocked'; end if;
  perform pg_advisory_xact_lock(hashtextextended(c.id::text || ':' || p_starts_at::text, 0));
  selected_state := case when c.booking_mode = 'automatic' then 'confirmed' when c.manual_holds_slot then 'hold' else 'pending' end;
  hold_until := case when selected_state = 'hold' then now() + make_interval(mins => c.manual_hold_minutes) else null end;
  insert into public.appointments(company_id, service_id, idempotency_key, consumer_name, consumer_phone, consumer_email, starts_at, ends_at, price_type, price_cents, state, hold_expires_at)
  values(c.id, s.id, p_idempotency_key, trim(p_consumer_name), nullif(trim(p_consumer_phone),''), nullif(lower(trim(p_consumer_email)),''), p_starts_at, p_starts_at + make_interval(mins => s.duration_minutes + s.buffer_minutes), s.price_type, s.price_cents, selected_state, hold_until) returning * into a;
  perform public.log_audit(c.id, 'booking_created', 'appointment', a.id, jsonb_build_object('source','public','state',a.state));
  return query select a.id, a.public_token, a.state, a.starts_at, a.ends_at, a.price_cents, a.price_type;
exception when exclusion_violation then raise exception 'slot_unavailable'; end; $$;
grant execute on function public.create_booking(uuid, uuid, timestamptz, text, text, text, uuid) to anon, authenticated;

create or replace function public.activate_company(p_company_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare c public.companies%rowtype;
begin
  if not public.is_company_member(p_company_id, 'owner') and not public.is_platform_admin() then raise exception 'unauthorized'; end if;
  select * into c from public.companies where id = p_company_id for update;
  if not found then raise exception 'company_not_found'; end if;
  if c.contact_phone is null and c.contact_email is null then raise exception 'contact_required'; end if;
  if not exists(select 1 from public.services where company_id = c.id and is_active) then raise exception 'active_service_required'; end if;
  if not exists(select 1 from public.availability_windows where company_id = c.id) then raise exception 'availability_required'; end if;
  if exists(select 1 from public.services where company_id = c.id and is_active and (duration_minutes is null or (price_type='fixed' and price_cents is null))) then raise exception 'service_configuration_incomplete'; end if;
  update public.companies set lifecycle='active', booking_enabled=true, activated_at=now(), demo_expires_at=null where id=c.id;
  perform public.log_audit(c.id, 'company_activated', 'company', c.id);
end; $$;
grant execute on function public.activate_company(uuid) to authenticated;

create or replace function public.export_company_records(p_company_id uuid)
returns table(record_type text, payload jsonb)
language plpgsql security definer set search_path = public as $$
begin
 if not public.is_company_member(p_company_id, 'manager') and not public.is_platform_admin() then raise exception 'unauthorized'; end if;
 return query select 'company', to_jsonb(c) from public.companies c where c.id=p_company_id;
 return query select 'service', to_jsonb(s) from public.services s where s.company_id=p_company_id;
 return query select 'appointment', to_jsonb(a) - 'consumer_email' from public.appointments a where a.company_id=p_company_id;
end; $$;
grant execute on function public.export_company_records(uuid) to authenticated;

-- Bootstrap (run manually ONCE after creating your first Auth user, replacing the UUID):
-- insert into public.platform_admins(user_id) values ('SEU-USER-ID-AQUI');
-- Never put a service_role key in the frontend or in .env files committed to Git.

-- Returns slots derived from working windows, blocks and existing active appointments.
-- The public client only displays these results; create_booking repeats every critical validation.
create or replace function public.available_slots(p_company_id uuid, p_service_id uuid, p_date date)
returns table(slot_start timestamptz)
language plpgsql security definer set search_path = public as $$
declare c public.companies%rowtype; s public.services%rowtype; local_day integer;
begin
  perform public.expire_holds();
  select * into c from public.companies where id=p_company_id and lifecycle='active' and booking_enabled;
  if not found then raise exception 'booking_not_available'; end if;
  select * into s from public.services where id=p_service_id and company_id=c.id and is_active;
  if not found then raise exception 'service_not_available'; end if;
  if p_date < (now() at time zone c.timezone)::date or p_date > (now() at time zone c.timezone)::date + c.booking_horizon_days then return; end if;
  local_day := extract(dow from p_date::timestamp)::integer;
  return query
  with candidates as (
    select (candidate_local at time zone c.timezone) as starts_at,
           ((candidate_local + make_interval(mins => s.duration_minutes + s.buffer_minutes)) at time zone c.timezone) as ends_at
    from public.availability_windows aw,
      lateral generate_series(
        p_date::timestamp + aw.start_time,
        p_date::timestamp + aw.end_time - make_interval(mins => s.duration_minutes + s.buffer_minutes),
        interval '30 minutes'
      ) candidate_local
    where aw.company_id=c.id and aw.day_of_week=local_day
  )
  select candidates.starts_at from candidates
  where candidates.starts_at >= now() + make_interval(hours => c.booking_notice_hours)
    and not exists(select 1 from public.schedule_blocks b where b.company_id=c.id and tstzrange(b.starts_at,b.ends_at,'[)') && tstzrange(candidates.starts_at,candidates.ends_at,'[)'))
    and not exists(select 1 from public.appointments a where a.company_id=c.id and a.state in ('confirmed','pending','hold') and (a.state <> 'hold' or a.hold_expires_at > now()) and tstzrange(a.starts_at,a.ends_at,'[)') && tstzrange(candidates.starts_at,candidates.ends_at,'[)'))
  order by candidates.starts_at;
end; $$;
grant execute on function public.available_slots(uuid, uuid, date) to anon, authenticated;
