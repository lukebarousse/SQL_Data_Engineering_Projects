UPDATE staging.priority_roles
SET priority_lvl = 3
WHERE role_name = 'Software Engineer';

DELETE FROM staging.priority_roles
WHERE role_name = 'Data Scientist';

CREATE OR REPLACE TABLE main.priority_jobs_snapshot (
    job_id              INTEGER PRIMARY KEY,
    job_title_short     VARCHAR,
    company_name        VARCHAR,
    job_posted_date     TIMESTAMP,
    salary_year_avg     DOUBLE,
    priority_lvl        INTEGER,
    updated_at          TIMESTAMP
);

INSERT INTO main.priority_jobs_snapshot (
    job_id,
    job_title_short,
    company_name,
    job_posted_date,
    salary_year_avg,
    priority_lvl,
    updated_at
)
SELECT
    jpf.job_id,
    jpf.job_title_short,
    cd.name AS company_name,
    jpf.job_posted_date,
    jpf.salary_year_avg,
    r.priority_lvl,
    CURRENT_TIMESTAMP                   
FROM data_jobs.job_postings_fact AS jpf
LEFT JOIN data_jobs.company_dim AS cd
    ON jpf.company_id = cd.company_id
INNER JOIN staging.priority_roles AS r 
    ON jpf.job_title_short = r.role_name;

UPDATE staging.priority_roles
SET priority_lvl = 3
WHERE role_name = 'Software Engineer';

INSERT INTO staging.priority_roles (role_id, role_name, priority_lvl)
VALUES (4, 'Data Scientist', 3);

DELETE FROM staging.priority_roles
WHERE role_name = 'Data Scientist';

MERGE INTO main.priority_jobs_snapshot AS tgt
USING (
    SELECT
        jpf.job_id,
        jpf.job_title_short,
        cd.name AS company_name,
        jpf.job_posted_date,
        jpf.salary_year_avg,
        r.priority_lvl               
    FROM data_jobs.job_postings_fact AS jpf
    LEFT JOIN data_jobs.company_dim AS cd
        ON jpf.company_id = cd.company_id
    INNER JOIN staging.priority_roles AS r 
        ON jpf.job_title_short = r.role_name
) AS src 
ON tgt.job_id = src.job_id

WHEN MATCHED AND (
    tgt.priority_lvl IS DISTINCT FROM src.priority_lvl
) THEN
    UPDATE SET
        -- job_id              = src.job_id,
        -- job_title_short     = src.job_title_short,
        -- company_name        = src.company_name,
        -- job_posted_date     = src.job_posted_date,
        -- salary_year_avg     = src.salary_year_avg,
        priority_lvl        = src.priority_lvl,
        updated_at          = CURRENT_TIMESTAMP

WHEN NOT MATCHED THEN
    INSERT (
        job_id,
        job_title_short,
        company_name,
        job_posted_date,
        salary_year_avg,
        priority_lvl,
        updated_at
    )
    VALUES (
        src.job_id,
        src.job_title_short,
        src.company_name,
        src.job_posted_date,
        src.salary_year_avg,
        src.priority_lvl,
        CURRENT_TIMESTAMP
    )
    
WHEN NOT MATCHED BY SOURCE THEN DELETE;

SELECT *
FROM staging.priority_roles;

SELECT 
    job_title_short,
    COUNT(*) AS job_count,
    MIN(priority_lvl) AS priority_lvl,
    MIN(updated_at) AS updated_at
FROM priority_jobs_snapshot
GROUP BY job_title_short
ORDER BY job_count DESC;

CREATE OR REPLACE TABLE main.priority_jobs_snapshot AS
SELECT
    jpf.job_id,
    jpf.job_title_short,
    cd.name AS company_name,
    jpf.job_posted_date,
    jpf.salary_year_avg,
    r.priority_lvl,
    CURRENT_TIMESTAMP  AS updated_at                 
FROM data_jobs.job_postings_fact AS jpf
LEFT JOIN data_jobs.company_dim AS cd
    ON jpf.company_id = cd.company_id
INNER JOIN staging.priority_roles AS r 
    ON jpf.job_title_short = r.role_name;