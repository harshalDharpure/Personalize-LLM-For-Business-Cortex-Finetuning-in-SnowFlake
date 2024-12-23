=====
CREATE or replace Database snowflake_llm_poc;
use snowflake_llm_poc;

CREATE TABLE question_data (
    text STRING,
    category STRING
);

--training data
INSERT INTO question_data (text, category) VALUES
    ('What is the capital of France?', 'geography'),
    ('Name the tallest mountain in the world', 'geography'),
    ('How does quantum computing work?', 'technology'),
    ('Best practices for cybersecurity', 'technology'),
    ('Explain the theory of relativity', 'science'),
    ('What are the planets in our solar system?', 'science'),
    ('Who discovered electricity?', 'science'),
    ('What is the largest desert in the world?', 'geography'),
    ('Difference between classical and quantum computing?', 'technology'),
    ('What is the circumference of the Earth?', 'geography');


select * from question_data;

--Test Data: What is the largest ocean in the Planet Earth?

--vector embedding
create or replace table question_data_vector_store as 
select TEXT,CATEGORY,SNOWFLAKE.CORTEX.EMBED_TEXT_768( 'e5-base-v2', Text) as embedding_vector from question_data;

select * from question_data_vector_store;

select text,category,VECTOR_L2_DISTANCE(SNOWFLAKE.CORTEX.EMBED_TEXT_768( 'e5-base-v2', 'What is the python programming language?'),embedding_vector) as distance from question_data_vector_store 
order by 
VECTOR_L2_DISTANCE(SNOWFLAKE.CORTEX.EMBED_TEXT_768( 'e5-base-v2', 'What is AI,ML & Deep Learning difference?'),embedding_vector)
limit 3;
