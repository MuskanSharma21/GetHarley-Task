with messages as (
    select * from {{ ref('stg_messages') }}
),

conversations as (
    select * from {{ ref('stg_conversations') }}
)

select
    m.message_id,
    m.conversation_id,
    m.direction,
    m.direction_type,
    m.channel,
    m.message_timestamp,
    date_trunc('day', m.message_timestamp) as message_date,
    extract(hour from m.message_timestamp) as message_hour,
    c.customer_id,
    c.status as conversation_status
from messages m
left join conversations c
    on m.conversation_id = c.conversation_id
