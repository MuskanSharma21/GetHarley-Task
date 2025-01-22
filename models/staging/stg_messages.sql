with source as (
    select * from {{ source('getharley', 'messages') }}
)

select
    id as message_id,
    conversation_id,
    direction,
    direction_type,
    channel,
    date_time as message_timestamp
from source
