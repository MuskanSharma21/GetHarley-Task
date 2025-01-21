with source as (
    select * from {{ source('getharley', 'clinics') }}
)

select
    name as clinic_name,
    code as clinic_code
from source
