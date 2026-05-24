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

-- What is the average account age (months since opening) at the time the loan was taken out?
SELECT
	ROUND(AVG(TIMESTAMPDIFF(MONTH,a.date,l.date)),2) AS age
    FROM account a JOIN loan l ON a.account_id=l.account_id;

-- Compare average balance (from last transaction before loan date) between defaulting vs non-defaulting borrowers
WITH last_balance AS(
	SELECT
    t.account_id,
    t.balance,
    t.date,
    ROW_NUMBER() OVER(PARTITION BY account_id ORDER BY t.date DESC) AS rnk
    FROM trans t JOIN loan l ON t.account_id=l.account_id
    WHERE t.date<=l.date),
pre_loan_balance AS(
	SELECT 
    account_id,
    balance AS balance_before_loan
    FROM last_balance
    WHERE rnk=1),
loan_status AS(
	SELECT
		account_id,
		CASE WHEN status IN ('B','D') THEN "DEFAULT"
		ELSE "NON-DEFAULT"
        END as borrow_type
		FROM loan)
SELECT
	ls.borrow_type,
	COUNT(*) AS total_borrowers,
	ROUND(AVG(plb.balance_before_loan),2) AS avg_balance
	FROM loan_status ls JOIN pre_loan_balance plb ON ls.account_id=plb.account_id
    JOIN last_balance lb ON plb.account_id=lb.account_id
    GROUP BY ls.borrow_type
    ORDER BY total_borrowers DESC;

-- Do clients with a credit card have lower default rates than those without? (loan → account → disposition → card LEFT JOIN)
-- select distinct type from card;
SELECT
	CASE WHEN c.type IS NULL THEN "NO CARD" ELSE "HAS CARD" END AS card_status,
	COUNT(DISTINCT l.account_id) total_borrowers,
    SUM((CASE WHEN status IN ('B','D') THEN 1 ELSE 0 END)) AS total_defaults,
    CONCAT(ROUND(SUM(CASE WHEN status IN ('B','D') THEN 1 ELSE 0 END)*100.0/COUNT(*),2),'%') AS default_rate
	FROM loan l LEFT JOIN account a ON l.account_id=a.account_id
    LEFT JOIN disp d ON a.account_id=d.account_id AND d.type='OWNER'
    LEFT JOIN card c ON d.disp_id=c.disp_id
    GROUP BY card_status
    ORDER BY default_rate DESC;

-- Find loans where the payment amount exceeds 30% of the account's average monthly inflow (stress ratio)
WITH monthly_income AS(SELECT
	account_id,
	YEAR(date) as year,
	MONTH(date) as month,
	ROUND(SUM(amount),2) as monthly_inflow
	FROM trans
	WHERE type='PRIJEM'
	GROUP BY account_id,year,month)
SELECT 
	l.loan_id,
    m.account_id, 
    l.payments as monthly_payment,
    ROUND(AVG(monthly_inflow),2) as avg_monthly_inflow
	FROM loan l LEFT JOIN monthly_income m ON l.account_id=m.account_id
	WHERE l.payments>monthly_inflow*0.3
	GROUP BY l.loan_id,m.account_id,l.payments;