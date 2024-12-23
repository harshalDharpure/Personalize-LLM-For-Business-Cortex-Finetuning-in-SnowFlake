--Lab section: 
DROP DATABASE IF EXISTS snowflake_llm_poc;
CREATE Database snowflake_llm_poc;
use snowflake_llm_poc;

CREATE or REPLACE file format csvformat
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  type = 'CSV';

CREATE or REPLACE stage support_tickets_data_stage
  file_format = csvformat
  url = 's3://sfquickstarts/finetuning_llm_using_snowflake_cortex_ai/';

CREATE or REPLACE TABLE SUPPORT_TICKETS (
  ticket_id VARCHAR(60),
  customer_name VARCHAR(60),
  customer_email VARCHAR(60),
  service_type VARCHAR(60),
  request VARCHAR,
  contact_preference VARCHAR(60)
);

CREATE WAREHOUSE warehouse_name
WITH
    WAREHOUSE_SIZE = 'XSMALL'  -- Size options: XSMALL, SMALL, MEDIUM, etc.
    AUTO_SUSPEND = 300         -- Automatically suspend after 300 seconds of inactivity
    AUTO_RESUME = TRUE         -- Automatically resume when a query is executed
    INITIALLY_SUSPENDED = TRUE;

COPY into SUPPORT_TICKETS
  from @support_tickets_data_stage;

select * from SUPPORT_TICKETS;

--with mistral-large
select *,snowflake.cortex.complete('mistral-large',concat('You are an agent that helps organize requests that come to our support team. 

The request category is the reason why the customer reached out. These are the possible types of request categories:

Roaming fees
Slow data speed
Lost phone
Add new line
Closing account

Try doing it for this request and return only the request category only.
<request>',REQUEST,'</request>')) as classification_result from SUPPORT_TICKETS;



--with mistral-7b
select *,snowflake.cortex.complete('mistral-7b',concat('You are an agent that helps organize requests that come to our support team. 

The request category is the reason why the customer reached out. These are the possible types of request categories:

Roaming fees
Slow data speed
Lost phone
Add new line
Closing account

Try doing it for this request and return only the request category only.
<request>',REQUEST,'</request>')) as classification_result from SUPPORT_TICKETS;


--step 1 : create the data format
Create or replace table snowflake_llm_poc.public.annotated_data_for_finetuning as 
(select *,concat('You are an agent that helps organize requests that come to our support team. 

The request category is the reason why the customer reached out. These are the possible types of request categories:

Roaming fees
Slow data speed
Lost phone
Add new line
Closing account

Try doing it for this request and return only the request category only.
<request>',REQUEST,'</request>') as prompt,snowflake.cortex.complete('mistral-large',concat('You are an agent that helps organize requests that come to our support team. 

The request category is the reason why the customer reached out. These are the possible types of request categories:

Roaming fees
Slow data speed
Lost phone
Add new line
Closing account

Try doing it for this request and return only the request category only.
<request>',REQUEST,'</request>')) as classification_result from SUPPORT_TICKETS);

select * from snowflake_llm_poc.public.annotated_data_for_finetuning;

--splitting into training & test dataset
create or replace table snowflake_llm_poc.public.trainig_data as select * from snowflake_llm_poc.public.annotated_data_for_finetuning sample(80);

select * from snowflake_llm_poc.public.trainig_data;

create or replace table snowflake_llm_poc.public.validation_data as select * from snowflake_llm_poc.public.annotated_data_for_finetuning minus
select * from snowflake_llm_poc.public.trainig_data;

select * from snowflake_llm_poc.public.validation_data;

select * from snowflake_llm_poc.public.trainig_data
intersect
select * from snowflake_llm_poc.public.validation_data;

--fine-tuning
SELECT snowflake.cortex.finetune(
  'CREATE', 
  'SUPPORT_TICKETS_FINETUNED_MISTRAL_7B', 
  'mistral-7b', 
  'SELECT prompt, CLASSIFICATION_RESULT AS completion FROM snowflake_llm_poc.PUBLIC.training_data', 
  'SELECT prompt, CLASSIFICATION_RESULT AS completion FROM snowflake_llm_poc.PUBLIC.validation_data'
);

--check the fine-tune job completed or not
select SNOWFLAKE.CORTEX.FINETUNE(
  'DESCRIBE',
  'CortexFineTuningWorkflow_398c6ef0-afcf-4934-913c-546285e53ec7'
);

--Inferencing the fine-tuned model
select *,snowflake.cortex.complete('snowflake_llm_poc.PUBLIC.SUPPORT_TICKETS_FINETUNED_MISTRAL_7B',concat('You are an agent that helps organize requests that come to our support team. 

The request category is the reason why the customer reached out. These are the possible types of request categories:

Roaming fees
Slow data speed
Lost phone
Add new line
Closing account

Try doing it for this request and return only the request category only.
<request>',REQUEST,'</request>')) as classification_result from SUPPORT_TICKETS;
