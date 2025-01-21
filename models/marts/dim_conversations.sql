-- models/marts/dim_conversations.sql
{{ config(materialized='table') }}

with conversation_history as (
    select 
        conversation_id,
        status,
        dbt_valid_from as valid_from,
        dbt_valid_to as valid_to,
        case when dbt_valid_to is null then true else false end as is_current
    from {{ ref('conversations_snapshot') }}
),

enriched_conversations as (
    select
        c.conversation_id,
        c.customer_id,
        cust.clinic_code,
        c.status,
        c.tags,
        c.tag_count,
        c.is_urgent,
        c.is_sensitive,
        c.is_pog,
        c.is_plan,
        -- Add status flags
        case when c.status = 'open' then true else false end as is_open,
        case when c.status = 'done' then true else false end as is_completed,
        case when c.status = 'snoozed' then true else false end as is_snoozed,
        -- Add history tracking
        ch.valid_from,
        ch.valid_to,
        ch.is_current
    from {{ ref('int_conversations_with_tags') }} c
    left join {{ ref('stg_customers') }} cust
        on c.customer_id = cust.customer_id
    left join conversation_history ch
        on c.conversation_id = ch.conversation_id
)

select * from enriched_conversations