{{ config(
    materialized='incremental',
    unique_key='message_id',
    incremental_strategy='append'
) }}

-- First, ensure messages are unique from source
with base_messages as (
    select distinct
        message_id,
        conversation_id,
        direction,
        direction_type,
        channel,
        message_timestamp,
        message_date,
        message_hour,
        customer_id,
        conversation_status
    from {{ ref('int_messages_enriched') }}
    {% if is_incremental() %}
    where message_timestamp > (select max(message_timestamp) from {{ this }})
    {% endif %}
),

-- Get the latest conversation attributes
latest_conversations as (
    select distinct
        conversation_id,
        tags,
        is_urgent,
        is_sensitive,
        is_pog,
        is_plan
    from {{ ref('dim_conversations') }}
),

-- Get the latest customer attributes
latest_customers as (
    select distinct
        customer_id,
        clinic_code
    from {{ ref('dim_customers') }}
)

-- Final select with all attributes
select distinct
    bm.message_id,
    bm.conversation_id,
    bm.customer_id,
    c.clinic_code,
    cast(bm.message_date as date) as date_id,
    bm.message_timestamp,
    bm.message_hour,
    bm.direction,
    bm.direction_type,
    bm.channel,
    conv.tags,
    conv.is_urgent,
    conv.is_sensitive,
    conv.is_pog,
    conv.is_plan,
    -- Metrics
    1 as message_count,
    case when bm.direction = 'in' then 1 else 0 end as inbound_message_count,
    case when bm.direction = 'out' then 1 else 0 end as outbound_message_count,
    case when bm.direction_type like '%initial%' then 1 else 0 end as initial_message_count,
    case when bm.direction_type like '%followup%' then 1 else 0 end as followup_message_count,
    case when bm.direction_type like '%response%' then 1 else 0 end as response_message_count,
    -- Response time calculation
    case 
        when lag(bm.message_timestamp) over (partition by bm.conversation_id order by bm.message_timestamp) is not null
        then datediff('minute', lag(bm.message_timestamp) over (partition by bm.conversation_id order by bm.message_timestamp), bm.message_timestamp)
    end as minutes_since_last_message
from base_messages bm
left join latest_conversations conv
    on bm.conversation_id = conv.conversation_id
left join latest_customers c
    on bm.customer_id = c.customer_id
