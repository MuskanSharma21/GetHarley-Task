with source as (
    select * from {{ source('getharley', 'conversations') }}
)

select
    conversation_id,
    status,
    customer_id
from source
