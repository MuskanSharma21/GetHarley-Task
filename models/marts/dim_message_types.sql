{{ config(materialized='table') }}

with message_types as (
    select distinct
        direction,
        direction_type,
        channel
    from {{ ref('stg_messages') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['direction', 'direction_type', 'channel']) }} as message_type_id,
    direction,
    direction_type,
    channel,
    case 
        when direction = 'in' then 'Inbound'
        when direction = 'out' then 'Outbound'
        else 'Unknown'
    end as direction_description,
    case
        when direction_type like '%initial%' then 'Initial Message'
        when direction_type like '%followup%' then 'Follow-up Message'
        when direction_type like '%response%' then 'Response Message'
        else 'Other'
    end as message_type_description
from message_types
