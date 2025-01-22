{{ config(
    materialized='incremental',
    unique_key='message_id',
    incremental_strategy='append'
) }}

with enriched_messages as (
    select * from {{ ref('int_messages_enriched') }}
    {% if is_incremental() %}
    where message_timestamp > (select max(message_timestamp) from {{ this }})
    {% endif %}
),

conversations as (
    select * from {{ ref('dim_conversations') }}
),

customers as (
    select * from {{ ref('dim_customers') }}
)

select
    em.message_id,
    em.conversation_id,
    em.customer_id,
    c.clinic_code,
    cast(em.message_date as date) as date_id,
    em.message_timestamp,
    em.message_hour,
    em.direction,
    em.direction_type,
    em.channel,
    conv.tags,
    conv.is_urgent,
    conv.is_sensitive,
    conv.is_pog,
    conv.is_plan,
    -- Metrics
    1 as message_count,
    case when em.direction = 'in' then 1 else 0 end as inbound_message_count,
    case when em.direction = 'out' then 1 else 0 end as outbound_message_count,
    case when em.direction_type like '%initial%' then 1 else 0 end as initial_message_count,
    case when em.direction_type like '%followup%' then 1 else 0 end as followup_message_count,
    case when em.direction_type like '%response%' then 1 else 0 end as response_message_count,
    -- Response time calculation
    case 
        when lag(em.message_timestamp) over (partition by em.conversation_id order by em.message_timestamp) is not null
        then datediff('minute', lag(em.message_timestamp) over (partition by em.conversation_id order by em.message_timestamp), em.message_timestamp)
    end as minutes_since_last_message
from enriched_messages em
left join conversations conv
    on em.conversation_id = conv.conversation_id
left join customers c
    on em.customer_id = c.customer_id
