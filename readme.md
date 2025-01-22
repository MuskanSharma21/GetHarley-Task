# GetHarley Data Warehouse

A star schema data warehouse implemented using dbt and Snowflake to analyze customer conversations and messaging patterns. The warehouse features incremental loading for fact tables and SCD Type 2 for tracking dimensional changes, enabling comprehensive analysis of customer interactions and clinic performance.

## Business Problems Solved

### 1. Response Time Analysis
Track and optimize clinic response times to customer messages, analyzing patterns by clinic, time of day, and message type.

### 2. Customer Engagement Tracking
Monitor customer interaction patterns, conversation frequencies, and engagement levels across different clinics and time periods.

### 3. Conversation Theme Analysis
Analyze common conversation topics and urgent issues using conversation tags, helping identify trending concerns and areas needing attention.

### 4. Clinic Performance Monitoring
Compare clinic performance metrics including response times, conversation volumes, and customer satisfaction indicators.

### 5. Historical Trend Analysis
Track changes in conversation patterns and clinic performance over time using SCD Type 2 tracking in dimension tables.

## Data Model

```mermaid
erDiagram
    FACT_MESSAGES ||--o{ DIM_CONVERSATIONS : has
    FACT_MESSAGES ||--o{ DIM_CUSTOMERS : involves
    FACT_MESSAGES ||--o{ DIM_CLINICS : belongs_to
    FACT_MESSAGES ||--o{ DIM_DATES : occurred_on
    DIM_CUSTOMERS ||--o{ DIM_CLINICS : belongs_to

    FACT_MESSAGES {
        string message_id PK
        string conversation_id FK
        string customer_id FK
        string clinic_code FK
        date date_id FK
        timestamp message_timestamp
        string direction
        string direction_type
        string channel
        int message_count
        int minutes_since_last_message
    }

    DIM_CONVERSATIONS {
        string conversation_id PK
        string customer_id FK
        string status
        string tags
        boolean is_urgent
        boolean is_sensitive
        timestamp valid_from
        timestamp valid_to
    }

    DIM_CUSTOMERS {
        string customer_id PK
        string clinic_code FK
        int total_conversations
        string customer_segment
        timestamp valid_from
        timestamp valid_to
    }

    DIM_CLINICS {
        string clinic_code PK
        string clinic_name
        string clinic_type
        timestamp valid_from
        timestamp valid_to
    }

    DIM_DATES {
        date date_id PK
        int year
        int month
        int day
        int day_of_week
        boolean is_business_day
    }
```