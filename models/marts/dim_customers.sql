{{ config(materialized='table') }}

with customer_metrics as (
    select
        c.customer_id,
        c.clinic_code,
        count(distinct conv.conversation_id) as total_conversations,
        sum(case when conv.status = 'open' then 1 else 0 end) as open_conversations,
        sum(case when conv.status = 'done' then 1 else 0 end) as completed_conversations,
        sum(conv.is_urgent) as urgent_conversations,
        sum(conv.is_sensitive) as sensitive_conversations
    from {{ ref('stg_customers') }} c
    left join {{ ref('int_conversations_with_tags') }} conv
        on c.customer_id = conv.customer_id
    group by 1, 2
)

select
    cm.customer_id,
    cm.clinic_code,
    cl.clinic_name,
    cm.total_conversations,
    cm.open_conversations,
    cm.completed_conversations,
    cm.urgent_conversations,
    cm.sensitive_conversations,
    case
        when cm.total_conversations >= 10 then 'High Volume'
        when cm.total_conversations >= 5 then 'Medium Volume'
        else 'Low Volume'
    end as customer_segment
from customer_metrics cm
left join {{ ref('dim_clinics') }} cl
    on cm.clinic_code = cl.clinic_code
