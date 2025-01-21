with conversations as (
    select * from {{ ref('stg_conversations') }}
),

conversation_tags as (
    select * from {{ ref('stg_conversation_tags') }}
),

-- Aggregate tags for each conversation
conversation_tag_groups as (
    select
        conversation_id,
        listagg(tag, ', ') within group (order by tag) as tags,
        count(distinct tag) as tag_count,
        max(case when lower(tag) like '%urgent%' then 1 else 0 end) as is_urgent,
        max(case when lower(tag) like '%sensitive%' then 1 else 0 end) as is_sensitive,
        max(case when lower(tag) like '%pog%' then 1 else 0 end) as is_pog,
        max(case when lower(tag) like '%plan%' then 1 else 0 end) as is_plan
    from conversation_tags
    group by conversation_id
)

select
    c.conversation_id,
    c.customer_id,
    c.status,
    coalesce(t.tags, '') as tags,
    coalesce(t.tag_count, 0) as tag_count,
    coalesce(t.is_urgent, 0) as is_urgent,
    coalesce(t.is_sensitive, 0) as is_sensitive,
    coalesce(t.is_pog, 0) as is_pog,
    coalesce(t.is_plan, 0) as is_plan
from conversations c
left join conversation_tag_groups t
    on c.conversation_id = t.conversation_id
