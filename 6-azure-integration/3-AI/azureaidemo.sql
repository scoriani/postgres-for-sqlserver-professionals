
-- Check Extension settings
SELECT azure_ai.get_setting('azure_openai.endpoint');

-- I need vector extension
CREATE EXTENSION vector

-- Create a table
DROP TABLE IF EXISTS bill_summaries;
CREATE TABLE bill_summaries
(
    id bigint PRIMARY KEY,
    bill_id text,
    bill_text text,
    summary text,
    title text,
    text_len bigint,
    sum_len bigint
);

COPY bill_summaries
FROM 'https://<account>.blob.core.windows.net/demo/billsummaries.csv'
WITH (FORMAT 'csv', header);

-- Check psql extensions
-- check psql functions


-- Few ways to add embeddings
ALTER TABLE bill_summaries
ADD COLUMN bill_vector vector(1536);

UPDATE bill_summaries b
SET bill_vector = azure_openai.create_embeddings('text-embedding-ada-002', b.bill_text)
where bill_vector IS  NULL;

-- vector populated
SELECT bill_vector FROM bill_summaries LIMIT 1;

-- Another way would be adding as default as generated.
ALTER TABLE bill_summaries ADD COLUMN bill_vector vector(1536) 
GENERATED ALWAYS AS (azure_openai.create_embeddings('text-embedding-ada-002'
					 ,bill_text )::vector) STORED;


-- Different types of indexes Ivfflat or hnsw and depends on distance or nearest neighbor search
-- Consine similarity 
CREATE INDEX ON bill_summaries USING hnsw (bill_vector vector_cosine_ops);
CREATE INDEX ON bill_summaries USING hnsw (bill_vector vector_ip_ops);


-- Consine similarity search.
SELECT bill_id, title, bill_text
from bill_summaries
ORDER BY bill_vector <=> azure_openai.create_embeddings('text-embedding-ada-002'
									, 'Show me bills relating to veterans entrepreneurship.')::vector
LIMIT 5

SELECT bill_id, title, bill_text
from bill_summaries
ORDER BY bill_vector <=> azure_openai.create_embeddings('text-embedding-ada-002'
									, 'Can my mother, a marine get financing to open a business')::vector
LIMIT 5


-- I used clauses such as Ilike
SELECT bill_id, title, bill_text
from bill_summaries
where bill_text ilike '%mother%' or bill_text ilike '%marine%' or bill_text ilike '%financing%'

-- I used clauses such as Ilike
SELECT bill_id, title, bill_text
from bill_summaries
where bill_text ilike '%Can my mother, a marine get financing to open a business%'

-- Fulltext
ALTER TABLE bill_summaries ADD COLUMN textsearch tsvector 
	GENERATED ALWAYS AS (to_tsvector('english', bill_text)) STORED;

-- Query using Fulltext Index
SELECT bill_id, title, bill_text 
FROM bill_summaries WHERE textsearch @@ phraseto_tsquery('%Can my mother, a marine get financing to open a business%');


-- Cognitive services
-- Abstractive Summarization
SELECT
    bill_id,
    unnest(azure_cognitive.summarize_abstractive(bill_text, 'en')) abstractive_summary
FROM bill_summaries
WHERE bill_id = '114_hr2499';

-- Quotes sentences from the passage
SELECT
    bill_id,
    unnest(azure_cognitive.summarize_extractive(bill_text, 'en')) as extractive_summary
FROM bill_summaries
WHERE bill_id = '114_hr2499';

-- Key Phase extraction
select s.* from 
unnest(azure_cognitive.linked_entities('Luka Doncic of the Dallas Mavericks 
									   is one of the best NBA players and probably an MVP candidate','en-us')) s

GRANT azure_pg_admin TO postgres;
CREATE ROLE postgres;



