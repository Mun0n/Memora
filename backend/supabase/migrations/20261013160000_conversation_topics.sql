-- Slice 10 — family-scoped conversation topics + capability wires.
-- Forced RLS; Dart FamilyAccessPolicy matrix must stay identical.
-- Fictional development only; no hosted project, credentials, LLM or speech storage.

-- ---------------------------------------------------------------------------
-- Extend memora_has_capability with conversation-topic wires (full matrix)
-- ---------------------------------------------------------------------------

create or replace function public.memora_has_capability(
  p_family_space_id uuid,
  p_capability text
) returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.family_memberships m
    where m.family_space_id = p_family_space_id
      and m.user_id = auth.uid()
      and m.status = 'active'
      and (
        (p_capability = 'viewFamilySpace'
          and m.role in (
            'supportedPerson',
            'primaryCaregiver',
            'caregiver',
            'familyContributor'
          ))
        or (p_capability = 'updateFamilySpace'
          and m.role = 'primaryCaregiver')
        or (p_capability = 'viewMemberships'
          and m.role in ('primaryCaregiver', 'caregiver'))
        or (p_capability = 'manageMemberships'
          and m.role = 'primaryCaregiver')
        or (p_capability = 'viewRoutines'
          and m.role in (
            'supportedPerson',
            'primaryCaregiver',
            'caregiver',
            'familyContributor'
          ))
        or (p_capability = 'editRoutines'
          and m.role in ('primaryCaregiver', 'caregiver'))
        or (p_capability = 'recordRoutineProgress'
          and m.role = 'supportedPerson')
        or (p_capability = 'viewReminders'
          and m.role in (
            'supportedPerson',
            'primaryCaregiver',
            'caregiver'
          ))
        or (p_capability = 'configureReminders'
          and m.role in ('primaryCaregiver', 'caregiver'))
        or (p_capability = 'viewApprovedMemories'
          and m.role in (
            'supportedPerson',
            'primaryCaregiver',
            'caregiver',
            'familyContributor'
          ))
        or (p_capability = 'manageMemories'
          and m.role in ('primaryCaregiver', 'caregiver'))
        or (p_capability = 'contributeMemories'
          and m.role = 'familyContributor')
        or (p_capability = 'manageMediaMetadata'
          and m.role in ('primaryCaregiver', 'caregiver'))
        or (p_capability = 'viewObservations'
          and m.role in ('primaryCaregiver', 'caregiver'))
        or (p_capability = 'recordObservations'
          and m.role in ('primaryCaregiver', 'caregiver'))
        or (p_capability = 'resolveSyncConflicts'
          and m.role in ('primaryCaregiver', 'caregiver'))
        or (p_capability = 'viewPastimes'
          and m.role in (
            'supportedPerson',
            'primaryCaregiver',
            'caregiver'
          ))
        or (p_capability = 'editPastimes'
          and m.role in ('primaryCaregiver', 'caregiver'))
        or (p_capability = 'viewConversationTopics'
          and m.role in (
            'supportedPerson',
            'primaryCaregiver',
            'caregiver'
          ))
        or (p_capability = 'editConversationTopics'
          and m.role in ('primaryCaregiver', 'caregiver'))
      )
  );
$$;

revoke all on function public.memora_has_capability(uuid, text) from public;
grant execute on function public.memora_has_capability(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- conversation_topics table
-- ---------------------------------------------------------------------------

create table public.conversation_topics (
  id uuid primary key,
  family_space_id uuid not null references public.family_spaces (id),
  title text not null,
  introduction text not null,
  prompts jsonb not null,
  closing text not null,
  display_order integer not null default 0,
  lifecycle_status text not null,
  memory_id uuid references public.memories (id),
  row_version bigint not null default 1,
  idempotency_key text,
  deleted_at timestamptz,
  deleted_by uuid references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint conversation_topics_title_length
    check (
      char_length(trim(title)) between 1 and 60
    ),
  constraint conversation_topics_introduction_length
    check (
      char_length(trim(introduction)) between 1 and 240
    ),
  constraint conversation_topics_closing_length
    check (
      char_length(trim(closing)) between 1 and 160
    ),
  constraint conversation_topics_display_order_nonneg
    check (display_order >= 0),
  constraint conversation_topics_lifecycle_known
    check (lifecycle_status in ('draft', 'active', 'archived')),
  constraint conversation_topics_prompts_array
    check (jsonb_typeof(prompts) = 'array'),
  constraint conversation_topics_prompts_count
    check (
      jsonb_array_length(prompts) between 1 and 5
    ),
  constraint conversation_topics_idempotency_unique
    unique (family_space_id, idempotency_key)
);

create index conversation_topics_family_space_idx
  on public.conversation_topics (family_space_id);

create index conversation_topics_family_active_idx
  on public.conversation_topics (family_space_id)
  where lifecycle_status = 'active' and deleted_at is null;

-- At most six active non-deleted conversation topics per family space.
create or replace function public.memora_enforce_conversation_topic_active_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  active_count integer;
begin
  if new.lifecycle_status = 'active' and new.deleted_at is null then
    select count(*)::integer into active_count
    from public.conversation_topics t
    where t.family_space_id = new.family_space_id
      and t.lifecycle_status = 'active'
      and t.deleted_at is null
      and t.id is distinct from new.id;
    if active_count >= 6 then
      raise exception
        'family already has 6 active conversation topics'
        using errcode = 'check_violation';
    end if;
  end if;
  return new;
end;
$$;

create trigger conversation_topics_active_limit
  before insert or update on public.conversation_topics
  for each row
  execute procedure public.memora_enforce_conversation_topic_active_limit();

alter table public.conversation_topics enable row level security;
alter table public.conversation_topics force row level security;

revoke all on table public.conversation_topics from public, anon;
grant select, insert, update on table public.conversation_topics to authenticated;

-- Supported person (viewConversationTopics only): active non-deleted rows.
-- Caregivers with editConversationTopics: full family-scoped read.
create policy conversation_topics_select
  on public.conversation_topics for select to authenticated
  using (
    public.memora_has_capability(family_space_id, 'editConversationTopics')
    or (
      public.memora_has_capability(family_space_id, 'viewConversationTopics')
      and lifecycle_status = 'active'
      and deleted_at is null
    )
  );

create policy conversation_topics_insert
  on public.conversation_topics for insert to authenticated
  with check (
    public.memora_has_capability(family_space_id, 'editConversationTopics')
  );

create policy conversation_topics_update
  on public.conversation_topics for update to authenticated
  using (
    public.memora_has_capability(family_space_id, 'editConversationTopics')
    or public.memora_has_capability(family_space_id, 'resolveSyncConflicts')
  )
  with check (
    public.memora_has_capability(family_space_id, 'editConversationTopics')
    or public.memora_has_capability(family_space_id, 'resolveSyncConflicts')
  );
