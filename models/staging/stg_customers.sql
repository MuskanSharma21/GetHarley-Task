with source as (
    select * from {{ source('getharley', 'customers') }}
)

select
    customer_id,
    code as clinic_code
from source
