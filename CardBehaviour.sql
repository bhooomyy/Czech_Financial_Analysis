-- How many cards of each type (classic/junior/gold) exist? What % of all accounts have a card?
SELECT
	type,
	COUNT(*) as card_cnt,
    CONCAT(ROUND(COUNT(*)/(SELECT COUNT(*) FROM card),2),'%') AS card_perc
    FROM card 
    GROUP BY type;

-- Card issuance trend over time — how many cards were issued per year? (parse issued date)
SELECT
	YEAR(issued) as year,
	COUNT(*) as num_cards
	FROM card
	GROUP BY year;

