-- Slice 11 — enriched conversation prompt help cards.
-- Validates prompts JSON shape (optional help cue / same-family approved memory).
-- Does not weaken forced RLS or memora_has_capability parity.
-- Fictional development only; no hosted project, credentials, LLM or speech storage.

create or replace function public.memora_validate_conversation_prompts(
  p_family_space_id uuid,
  p_prompts jsonb
) returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  elem jsonb;
  ord integer;
  txt text;
  help jsonb;
  cue text;
  help_memory_id uuid;
  seen_orders integer[] := array[]::integer[];
  expected_order integer := 0;
  help_count integer := 0;
  memory_ok boolean;
begin
  if jsonb_typeof(p_prompts) is distinct from 'array' then
    return false;
  end if;
  if jsonb_array_length(p_prompts) < 1 or jsonb_array_length(p_prompts) > 5 then
    return false;
  end if;

  for elem in select * from jsonb_array_elements(p_prompts)
  loop
    if jsonb_typeof(elem) is distinct from 'object' then
      return false;
    end if;
    if not (elem ? 'order' and elem ? 'text') then
      return false;
    end if;
    begin
      ord := (elem ->> 'order')::integer;
    exception
      when others then
        return false;
    end;
    if ord is distinct from expected_order then
      return false;
    end if;
    if ord = any (seen_orders) then
      return false;
    end if;
    seen_orders := array_append(seen_orders, ord);
    expected_order := expected_order + 1;

    txt := trim(both from coalesce(elem ->> 'text', ''));
    if char_length(txt) < 1 or char_length(txt) > 240 then
      return false;
    end if;

    if elem ? 'help' and elem -> 'help' is not null
       and jsonb_typeof(elem -> 'help') is distinct from 'null' then
      help := elem -> 'help';
      if jsonb_typeof(help) is distinct from 'object' then
        return false;
      end if;
      help_count := help_count + 1;
      if help_count > 5 then
        return false;
      end if;

      cue := null;
      if help ? 'cue' and help -> 'cue' is not null
         and jsonb_typeof(help -> 'cue') is distinct from 'null' then
        cue := trim(both from coalesce(help ->> 'cue', ''));
        if cue = '' then
          cue := null;
        elsif char_length(cue) > 160 then
          return false;
        end if;
      end if;

      help_memory_id := null;
      if help ? 'memoryId' and help -> 'memoryId' is not null
         and jsonb_typeof(help -> 'memoryId') is distinct from 'null' then
        begin
          help_memory_id := (help ->> 'memoryId')::uuid;
        exception
          when others then
            return false;
        end;
      end if;

      if cue is null and help_memory_id is null then
        return false;
      end if;

      if help_memory_id is not null then
        select exists (
          select 1
          from public.memories m
          where m.id = help_memory_id
            and m.family_space_id = p_family_space_id
            and m.lifecycle_status = 'approved'
            and m.deleted_at is null
        ) into memory_ok;
        if not coalesce(memory_ok, false) then
          return false;
        end if;
      end if;
    end if;
  end loop;

  return true;
end;
$$;

revoke all on function public.memora_validate_conversation_prompts(uuid, jsonb)
  from public;
grant execute on function public.memora_validate_conversation_prompts(uuid, jsonb)
  to authenticated;

alter table public.conversation_topics
  drop constraint if exists conversation_topics_prompts_valid;

alter table public.conversation_topics
  add constraint conversation_topics_prompts_valid
  check (
    public.memora_validate_conversation_prompts(family_space_id, prompts)
  );

comment on function public.memora_validate_conversation_prompts(uuid, jsonb) is
  'Slice 11: validates conversation prompt JSON including optional help cards '
  'and same-family approved memory references. Slice 10 rows without help remain valid.';
