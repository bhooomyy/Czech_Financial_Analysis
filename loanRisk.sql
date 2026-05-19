-- Count loans by status. Decode: A=finished/OK, B=finished/default, C=running/OK, D=running/default
SELECT
	status,
    CASE WHEN status="A" THEN "finished/OK"
		 WHEN status="B" THEN "finished/default"
		 WHEN status="C" THEN "running/OK"
		 WHEN status='D' THEN "running/default"
		 END as decoded_status,
    COUNT(*) AS status_cnt
    FROM loan
    GROUP BY status
    ORDER BY status_cnt DESC;

-- What is the total loan amount, avg loan amount, and avg duration by status?
SELECT
	status,
	ROUND(SUM(amount),2) AS total_amt,
    ROUND(AVG(amount),2) AS avg_loan_amt,
    ROUND(AVG(duration),2) AS avg_duration
    FROM loan
    GROUP BY status
    ORDER BY avg_duration ASC;

-- What is the overall default rate (B+D) as a percentage of all loans?
SELECT
	COUNT(*) AS total_loan,
    SUM(CASE WHEN status IN ('B','D') THEN 1 ELSE 0 END) as default_rate,
    ROUND(SUM(CASE WHEN status IN ('B','D') THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS default_Rate
    FROM loan;

-- Which accounts have a loan? Left join account to loan to find accounts WITHOUT any loan
SELECT 
    account_id
    FROM account 
    WHERE account_id NOT IN (
                            SELECT  
                            account_id 
                            FROM loan);

-- Join loan → account → district: default rate by region (A3 column). Which region has highest default rate?
SELECT
    d.region,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN l.status IN ('B','D') THEN 1 ELSE 0 END) AS total_defaults,
    CONCAT(ROUND(SUM(CASE WHEN l.status IN ('B','D') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2), '%') AS default_rate
    FROM loan l 
	JOIN account a ON l.account_id = a.account_id
	JOIN district d ON a.district_id = d.district_id
	GROUP BY d.region;


-- Do longer duration loans have higher default rates? Group by duration (12/24/36/48/60 months)
SELECT
    duration,
    ROUND((SUM(CASE WHEN status IN ('B','D') THEN 1 ELSE 0 END)*100.0/COUNT(*)),2) AS default_rate
	FROM loan
    GROUP BY duration
    ORDER BY default_rate DESC;