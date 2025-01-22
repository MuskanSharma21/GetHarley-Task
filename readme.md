# GetHarley Data Warehouse

This data warehouse implements a star schema design to analyze customer conversations and messaging patterns. 
The model is built using dbt (data build tool) and Snowflake, featuring incremental loading for fact tables 
and SCD Type 2 for tracking dimensional changes.

## Architecture

### Data Flow

1. Source data from operational systems loaded into Snowflake `dev` schema
2. dbt models transform this data through:
   - Staging models (clean and standardize)
   - Intermediate models (business logic)
   - Mart models (star schema)
3. Final warehouse tables in Snowflake `dbt_msharma_wh` schema

### Key Features

- Incremental loading for fact tables
- SCD Type 2 tracking for dimensional changes
- Historical tracking of conversation statuses
- Tag-based analysis capabilities
- Customer segmentation
- Clinic performance metrics

## Business Problems Solved

### 1. Conversation Response Time Analysis

**Problem**: Need to track and optimize response times for customer messages
**Solution**:

- Fact table tracks `minutes_since_last_message`
- Can be analyzed by:
 ```sql
  SELECT
      c.clinic_name,
      AVG(minutes_since_last_message) as avg_response_time
  FROM fact_messages f
  JOIN dim_clinics c ON f.clinic_code = c.clinic_code
  WHERE f.direction = 'out'
  GROUP BY 1;
  ```

### 2. Customer Engagement Tracking

**Problem**: Understanding customer interaction patterns
**Solution**:

- Customer dimension includes engagement metrics
- Historical tracking of conversation patterns

```sql
SELECT
    customer_segment,
    COUNT(DISTINCT customer_id) as customer_count,
    AVG(total_conversations) as avg_conversations
FROM dim_customers
WHERE is_current = true
GROUP BY 1;
```

### 3. Conversation Tag Analysis

**Problem**: Understanding common conversation themes and urgent issues
**Solution**:

- Tag-based analysis in conversation dimension
- Urgent and sensitive conversation tracking

```sql
SELECT
    tag,
    COUNT(*) as tag_count,
    COUNT(DISTINCT customer_id) as customers_affected
FROM dim_conversations
WHERE is_current = true
GROUP BY 1
ORDER BY 2 DESC;
```

### 4. Clinic Performance Monitoring

**Problem**: Track and compare clinic performance
**Solution**:

- Clinic dimension with type classification
- Message and conversation metrics by clinic

```sql
SELECT
    c.clinic_name,
    COUNT(DISTINCT f.conversation_id) as total_conversations,
    AVG(f.minutes_since_last_message) as avg_response_time,
    SUM(f.initial_message_count) as new_conversations
FROM fact_messages f
JOIN dim_clinics c ON f.clinic_code = c.clinic_code
GROUP BY 1;
```

### 5. Historical Trend Analysis

**Problem**: Track changes in conversation patterns over time
**Solution**:

- SCD Type 2 tracking in dimensions
- Date dimension for time-based analysis

```sql
SELECT
    d.month,
    c.clinic_name,
    COUNT(*) as message_count,
    SUM(f.inbound_message_count) as inbound_messages
FROM fact_messages f
JOIN dim_dates d ON f.date_id = d.date_id
JOIN dim_clinics c ON f.clinic_code = c.clinic_code
GROUP BY 1, 2;
```

### 6. Customer Service Quality Monitoring

**Problem**: Monitor and improve customer service quality
**Solution**:

- Track conversation status changes
- Monitor urgent and sensitive conversations

```sql
SELECT
    c.clinic_name,
    COUNT(DISTINCT CASE WHEN conv.is_urgent THEN conv.conversation_id END) as urgent_conversations,
    COUNT(DISTINCT CASE WHEN conv.is_sensitive THEN conv.conversation_id END) as sensitive_conversations
FROM dim_conversations conv
JOIN dim_clinics c ON conv.clinic_code = c.clinic_code
WHERE conv.is_current = true
GROUP BY 1;
```

## Implementation Details

### Incremental Loading

- Fact messages use incremental loading with append strategy
- Only processes new messages based on timestamp

```sql
{% if is_incremental() %}
where message_timestamp > (select max(message_timestamp) from {{ this }})
{% endif %}
```

### Historical Tracking (SCD Type 2)

- Dimensions track changes over time (conversations)
- Maintains valid_from/valid_to dates
- Enables point-in-time analysis

```sql
SELECT * FROM dim_conversations
WHERE '2024-01-01' BETWEEN valid_from AND COALESCE(valid_to, CURRENT_TIMESTAMP());
```

### Data Quality

- Primary and foreign key constraints
- Not null constraints on critical fields
- Data freshness checks
- Relationship validation between dimensions and facts

## Future Enhancements

1. Add machine learning models for:
   - Response time prediction
   - Customer churn prediction
   - Conversation topic clustering
2. Implement real-time analytics
3. Add more customer segmentation dimensions
4. Create automated alerting for service quality metrics

## Maintenance

- Daily incremental loads for fact tables
- Daily snapshot updates for dimensions
- Weekly data quality checks
- Monthly performance optimization review
