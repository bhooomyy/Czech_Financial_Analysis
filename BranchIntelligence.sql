-- Rank districts by total loan amount disbursed. Overlay with district population to get loans-per-capita
SELECT 
d.district_id,
d.population,
Round(SUM(l.amount)/d.population,2) AS loan_per_capita,
SUM(amount) as total_fund_by_dist,
RANK() OVER(ORDER BY SUM(amount) DESC) AS rnk
FROM district d JOIN account a ON d.district_id=a.district_id JOIN loan l ON a.account_id=l.account_id
GROUP BY district_id,d.population;

