{% snapshot conversations_snapshot %}
{{
    config(
      target_schema='wh',
      unique_key='conversation_id',
      strategy='check',
      check_cols=['status']
    )
}}

select * from {{ ref('stg_conversations') }}

{% endsnapshot %}