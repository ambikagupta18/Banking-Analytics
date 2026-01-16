select * from dnc;
desc dnc; 

--- 1) Transaction Flow & Balances View

CREATE OR REPLACE VIEW vw_dnc_flow AS
SELECT 
    SUM(CASE WHEN `Transaction Type` = 'Credit' THEN Amount ELSE 0 END) AS Total_Credit_Amount,
    SUM(CASE WHEN `Transaction Type` = 'Debit' THEN Amount ELSE 0 END) AS Total_Debit_Amount,
    SUM(CASE WHEN `Transaction Type` = 'Credit' THEN Amount ELSE 0 END) * 1.0 /
    NULLIF(SUM(CASE WHEN `Transaction Type` = 'Debit' THEN Amount ELSE 0 END), 0) AS Credit_Debit_Ratio,
    SUM(CASE WHEN `Transaction Type` = 'Credit' THEN Amount ELSE 0 END) -
    SUM(CASE WHEN `Transaction Type` = 'Debit' THEN Amount ELSE 0 END) AS Net_Transaction_Amount
FROM dnc;

--- 2) Customer & Account Activity View
CREATE OR REPLACE VIEW vw_dnc_activity AS
SELECT 
    a.`Account Number`,
    COUNT(*) * 1.0 / NULLIF(MAX(a.Balance), 0) AS Account_Activity_Ratio,
    
    -- Transactions per Day
    DATE(a.`Transaction Date`) AS Tran_Day,
    COUNT(*) AS Transactions_Per_Day,
    
    -- Total Amount by Branch
    a.Branch,
    SUM(a.Amount) AS Total_Transaction_By_Branch,
    
    -- Total Amount by Bank
    a.`Bank Name`,
    SUM(a.Amount) AS Total_Transaction_By_Bank

FROM dnc a
GROUP BY 
    a.`Account Number`,
    a.Branch,
    a.`Bank Name`,
    DATE(a.`Transaction Date`);

--- 3) Risk & Behavior View
CREATE OR REPLACE VIEW vw_dnc_risk AS
SELECT 
    a.`Transaction Method`,
    COUNT(*) AS Transaction_Count,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dnc) AS Method_Percentage,

    a.Branch,
    DATE_FORMAT(a.`Transaction Date`, '%Y-%m') AS Tran_Month,
    SUM(a.Amount) AS Monthly_Transaction_Amount,

    CASE WHEN a.Amount > 100000 THEN 'High-Risk' ELSE 'Normal' END AS Risk_Flag,

    SUM(CASE WHEN a.Amount > 100000 THEN 1 ELSE 0 END) AS Suspicious_Transaction_Frequency
FROM dnc a
GROUP BY 
    a.`Transaction Method`,
    a.Branch,
    DATE_FORMAT(a.`Transaction Date`, '%Y-%m'),
    Risk_Flag;


SELECT * FROM vw_dnc_flow;      -- Flow KPIs
SELECT * FROM vw_dnc_activity; -- Account/Branch/Bank KPIs
SELECT * FROM vw_dnc_risk;      -- Risk/Fraud KPIs
