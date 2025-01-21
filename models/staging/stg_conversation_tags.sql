with source as (
    select * from {{ source('getharley', 'conversation_tags') }}
)

select
    conversation_id,
    tag
from source
