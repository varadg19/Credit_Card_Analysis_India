-- Top 5 cities with highest spends and their percentage contribution of total credit card spends
WITH TotalSpendsCTE AS (
    SELECT SUM(CAST(Amount AS DECIMAL(10, 2))) AS TotalSpends
    FROM credit_card_transactions
)
SELECT TOP 5
    City,
    SUM(CAST(Amount AS DECIMAL(10, 2))) AS TotalSpends,
    (SUM(CAST(Amount AS DECIMAL(10, 2))) * 100.0) / TotalSpends AS PercentageContribution
FROM credit_card_transactions
CROSS JOIN TotalSpendsCTE
GROUP BY City, TotalSpends
ORDER BY TotalSpends DESC;

-- Highest spend month and amount spent in that month for each card type

WITH MonthlySpends AS (
    SELECT
        Card_Type,
        DATEPART(YEAR, Date) AS Year,
        DATEPART(MONTH, Date) AS Month,
        SUM(Amount) AS TotalSpent
    FROM credit_card_transactions
    GROUP BY Card_Type, DATEPART(YEAR, Date), DATEPART(MONTH, Date)
),
MaxSpendsPerCard AS (
    SELECT
        Card_Type,
        Year,
        Month,
        TotalSpent,
        RANK() OVER (PARTITION BY Card_Type ORDER BY TotalSpent DESC) AS rn
    FROM MonthlySpends
)
SELECT
    Card_Type,
    Year,
    Month,
    TotalSpent
FROM MaxSpendsPerCard
WHERE rn = 1;


--The transaction details(all columns from the table) for each card type when it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

WITH CumulativeSpends AS (
    SELECT
        *,
        SUM(Amount) OVER (PARTITION BY Card_Type ORDER BY Date) AS CumulativeTotal
    FROM credit_card_transactions
)
SELECT *
FROM CumulativeSpends
WHERE CumulativeTotal >= 1000000;


--City which had lowest percentage spend for gold card type

WITH GoldCardSpends AS (
    SELECT
        City,
        SUM(CASE WHEN Card_Type = 'Gold' THEN Amount ELSE 0 END) AS GoldTotalSpends,
        SUM(Amount) AS TotalSpends
    FROM credit_card_transactions
    GROUP BY City
)
SELECT TOP 1
    City,
    (GoldTotalSpends * 100.0) / NULLIF(TotalSpends, 0) AS PercentageSpend
FROM GoldCardSpends
ORDER BY PercentageSpend ASC;


--City which had lowest percentage spend for gold card type. IF THE PERCENTAGE IS 0 THEN MOVE TO ANOTHER CITY

WITH GoldCardSpends AS (
    SELECT
        City,
        SUM(CASE WHEN Card_Type = 'Gold' THEN Amount ELSE 0 END) AS GoldTotalSpends,
        SUM(Amount) AS TotalSpends
    FROM credit_card_transactions
    GROUP BY City
)
SELECT TOP 1
    City,
    (GoldTotalSpends * 100.0) / NULLIF(TotalSpends, 0) AS PercentageSpend
FROM GoldCardSpends
WHERE (GoldTotalSpends * 100.0) / NULLIF(TotalSpends, 0) > 0
ORDER BY PercentageSpend ASC;


--Write a query to print 3 columns: city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

WITH ExpenseSummary AS (
    SELECT
        City,
        Exp_Type,
        SUM(Amount) AS TotalSpent
    FROM credit_card_transactions
    GROUP BY City, Exp_Type
)
SELECT
    City,
    MAX(CASE WHEN Rank_Highest = 1 THEN Exp_Type END) AS Highest_Expense_Type,
    MAX(CASE WHEN Rank_Lowest = 1 THEN Exp_Type END) AS Lowest_Expense_Type
FROM (
    SELECT
        City,
        Exp_Type,
        TotalSpent,
        RANK() OVER (PARTITION BY City ORDER BY TotalSpent DESC) AS Rank_Highest,
        RANK() OVER (PARTITION BY City ORDER BY TotalSpent ASC) AS Rank_Lowest
    FROM ExpenseSummary
) RankedExpenses
WHERE Rank_Highest = 1 OR Rank_Lowest = 1
GROUP BY City;


--Percentage contribution of spends by females for each expense type

SELECT
    Exp_Type,
    SUM(CASE WHEN Gender = 'F' THEN Amount ELSE 0 END) AS FemaleSpends,
    SUM(Amount) AS TotalSpends,
    (SUM(CASE WHEN Gender = 'F' THEN Amount ELSE 0 END) * 100.0) / NULLIF(SUM(Amount), 0) AS PercentageContribution
FROM credit_card_transactions
GROUP BY Exp_Type;


-- which card and expense type combination saw highest month over month growth in Jan-2014

WITH MonthlySpend AS (
    SELECT
        Card_Type,
        Exp_Type,
        DATEPART(YEAR, Date) AS Year,
        DATEPART(MONTH, Date) AS Month,
        SUM(Amount) AS TotalSpent
    FROM credit_card_transactions
    WHERE DATEPART(YEAR, Date) = 2014 AND DATEPART(MONTH, Date) = 1
    GROUP BY Card_Type, Exp_Type, DATEPART(YEAR, Date), DATEPART(MONTH, Date)
),
MonthOverMonthGrowth AS (
    SELECT
        Card_Type,
        Exp_Type,
        TotalSpent,
        COALESCE(LAG(TotalSpent) OVER (PARTITION BY Card_Type, Exp_Type ORDER BY Year, Month), 0) AS PrevMonthSpent
    FROM MonthlySpend
)
SELECT TOP 1
    Card_Type,
    Exp_Type,
    (TotalSpent - PrevMonthSpent) AS Growth
FROM MonthOverMonthGrowth
ORDER BY Growth DESC;


--During weekends which city has highest total spend to total no of transcations ratio 

WITH WeekendTransactions AS (
    SELECT
        City,
        COUNT(*) AS TotalTransactions,
        SUM(Amount) AS TotalSpend
    FROM credit_card_transactions
    WHERE DATEPART(WEEKDAY, Date) IN (1, 7) -- Saturday and Sunday
    GROUP BY City
)
SELECT TOP 1
    City,
    TotalSpend,
    TotalTransactions,
    (TotalSpend * 1.0) / NULLIF(TotalTransactions, 0) AS Spend_To_TransactionRatio
FROM WeekendTransactions
ORDER BY Spend_To_TransactionRatio DESC;


--City that took least number of days to reach its 500th transaction after first transaction in that city

WITH FirstTransactionDates AS (
    SELECT
        City,
        MIN(Date) AS FirstTransactionDate
    FROM credit_card_transactions
    GROUP BY City
),
TransactionCounts AS (
    SELECT
        City,
        Date,
        ROW_NUMBER() OVER (PARTITION BY City ORDER BY Date) AS TransactionNumber
    FROM credit_card_transactions
)
SELECT TOP 1
    t.City,
    DATEDIFF(DAY, ft.FirstTransactionDate, t.Date) AS DaysTo500thTransaction
FROM TransactionCounts AS t
JOIN FirstTransactionDates AS ft ON t.City = ft.City
WHERE t.TransactionNumber = 500
ORDER BY DaysTo500thTransaction;


--The Amount Spent by Gender and credit card type

SELECT
    Gender,
    Card_Type,
    SUM(Amount) AS AmountSpent
FROM credit_card_transactions
GROUP BY Gender, Card_Type;

