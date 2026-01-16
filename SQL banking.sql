select * from  `dim client`;
select * from  `dim branch`;
select * from  `dim product`;
select * from  `fact loan`;
select * from  `fact repayment`;
select * from  `final fact`;

CREATE OR REPLACE VIEW vw_bank AS
SELECT 
    c.`Client id`,
    c.`Client Name`,
    c.`Gender ID`,
    c.`Age`,
    c.`Age _T`,
    c.`Dateof Birth`,
    c.`Caste`,
    c.`Religion`,
    c.`Home Ownership`,
    c.`Client Income Range`,
    c.`Employment Type`,
    c.`Credit Score`,

    b.`BranchID`,
    b.`Branch Name`,
    b.`Bank Name`,
    b.`Region Name`,
    b.`State Abbr`,
    b.`State Name`,
    b.`City`,
    b.`Center Id`,
    b.`BH Name`,
    b.`Branch Performance Category`,

    p.`Product Id`,
    p.`Product Code`,
    p.`Purpose Category`,
    p.`Term`,
    p.`Int Rate`,
    p.`Grade`,
    p.`Sub Grade`,

    l.`Account ID`,
    l.`Loan Amount`,
    l.`Funded Amount`,
    l.`Funded Amount Inv`,
    l.`Disbursement Date`,
    l.`Loan Status`,
    l.`Repayment Type`,

    r.`Total Pymnt`,
    r.`Total Pymnt inv`,
    r.`Total Rec Prncp`,
    r.`Total Fees`,
    r.`Total Rrec int`,
    r.`Is Delinquent Loan`,
    r.`Is Default Loan`,
    r.`Delinq 2 Yrs`,
    r.`Repayment Behavior`

FROM `fact loan` l
JOIN `dim client` c   ON l.`Client id` = c.`Client id`
JOIN `dim branch` b   ON l.`BranchID` = b.`BranchID`
JOIN `dim product` p  ON l.`Product Id` = p.`Product Id`
LEFT JOIN `fact repayment` r ON l.`Account ID` = r.`Account ID`;

CREATE OR REPLACE VIEW vw_credit_debit AS
SELECT 
    l.`Account ID`,
    c.`Client Name`,
    b.`Branch Name`,
    p.`Product Code`,
    l.`Loan Amount`,
    l.`Funded Amount`,
    l.`Disbursement Date`,
    l.`Loan Status`,

    r.`Total Pymnt` AS `Total Credit`,
    r.`Total Rec Prncp` AS `Total Principal Repaid`,
    r.`Total Rrec int` AS `Total Interest Repaid`,
    r.`Total Fees` AS `Total Fees Paid`,
    (r.`Total Pymnt` - (r.`Total Rec Prncp` + r.`Total Rrec int` + r.`Total Fees`)) AS `Total Debit`,

    r.`Is Delinquent Loan`,
    r.`Is Default Loan`,
    r.`Repayment Behavior`
FROM `fact loan` l
JOIN `dim client` c   ON l.`Client id` = c.`Client id`
JOIN `dim branch` b   ON l.`BranchID` = b.`BranchID`
JOIN `dim product` p  ON l.`Product Id` = p.`Product Id`
JOIN `fact repayment` r ON l.`Account ID` = r.`Account ID`;

CREATE OR REPLACE VIEW vw_bank_credit_debit AS
SELECT 
    -- Client Info
    c.`Client id`,
    c.`Client Name`,
    c.`Gender ID`,
    c.`Age`,
    c.`Age _T`,
    c.`Dateof Birth`,
    c.`Caste`,
    c.`Religion`,
    c.`Home Ownership`,
    c.`Client Income Range`,
    c.`Employment Type`,
    c.`Credit Score`,

    -- Branch Info
    b.`BranchID`,
    b.`Branch Name`,
    b.`Bank Name`,
    b.`Region Name`,
    b.`State Abbr`,
    b.`State Name`,
    b.`City`,
    b.`Center Id`,
    b.`BH Name`,
    b.`Branch Performance Category`,

    -- Product Info
    p.`Product Id`,
    p.`Product Code`,
    p.`Purpose Category`,
    p.`Term`,
    p.`Int Rate`,
    p.`Grade`,
    p.`Sub Grade`,

    -- Loan Info
    l.`Account ID`,
    l.`Loan Amount`,
    l.`Funded Amount`,
    l.`Funded Amount Inv`,
    l.`Disbursement Date`,
    l.`Loan Status`,
    l.`Repayment Type`,

    -- Repayment / Credit-Debit Info
    r.`Total Pymnt` AS `Total Credit`,
    r.`Total Rec Prncp` AS `Total Principal Repaid`,
    r.`Total Rrec int` AS `Total Interest Repaid`,
    r.`Total Fees` AS `Total Fees Paid`,
    (r.`Total Pymnt` - (r.`Total Rec Prncp` + r.`Total Rrec int` + r.`Total Fees`)) AS `Total Debit`,
    r.`Total Pymnt inv`,
    r.`Is Delinquent Loan`,
    r.`Is Default Loan`,
    r.`Delinq 2 Yrs`,
    r.`Repayment Behavior`

FROM `fact loan` l
JOIN `dim client` c   ON l.`Client id` = c.`Client id`
JOIN `dim branch` b   ON l.`BranchID` = b.`BranchID`
JOIN `dim product` p  ON l.`Product Id` = p.`Product Id`
LEFT JOIN `fact repayment` r ON l.`Account ID` = r.`Account ID`;


/*   KPIS   */
--- 1) Total Clients
 SELECT COUNT(DISTINCT `Client id`) AS Total_Clients
FROM `dim client`;

--- 2) Active Clients (at least 1 active loan)
SELECT COUNT(DISTINCT l.`Client id`) AS Active_Clients
FROM `fact loan` l
WHERE l.`Loan Status` = 'Active';

--- 3. New Clients (first loan disbursed in period)
SELECT COUNT(DISTINCT l.`Client id`) AS New_Clients
FROM `fact loan` l
WHERE l.`Disbursement Date` BETWEEN '2025-01-01' AND '2025-01-31'
AND l.`Disbursement Date` = (
    SELECT MIN(l2.`Disbursement Date`)
    FROM `fact loan` l2
    WHERE l2.`Client id` = l.`Client id`
);

--- 4. Client Retention Rate
-- Returning clients = clients with loans in both periods
WITH prev AS (
  SELECT DISTINCT `Client id` FROM `fact loan`
  WHERE `Disbursement Date` BETWEEN '2024-12-01' AND '2024-12-31'
),
curr AS (
  SELECT DISTINCT `Client id` FROM `fact loan`
  WHERE `Disbursement Date` BETWEEN '2025-01-01' AND '2025-01-31'
)
SELECT 
  (SELECT COUNT(*) FROM prev) AS Prev_Period_Clients,
  (SELECT COUNT(*) FROM curr) AS Curr_Period_Clients,
  (SELECT COUNT(*) FROM prev p JOIN curr c ON p.`Client id`=c.`Client id`) AS Returning_Clients,
  (SELECT COUNT(*) FROM prev p JOIN curr c ON p.`Client id`=c.`Client id`) * 1.0 /
  (SELECT COUNT(*) FROM prev) AS Client_Retention_Rate;

--- 5. Total Loan Amount Disbursed
SELECT SUM(`Loan Amount`) AS Total_Loan_Amount
FROM `fact loan`;

--- 6. Total Funded Amount
SELECT SUM(`Funded Amount`) AS Total_Funded_Amount
FROM `fact loan`;

--- 7. Average Loan Size
SELECT AVG(`Loan Amount`) AS Average_Loan_Size
FROM `fact loan`;

--- 8. Loan Growth %
WITH curr AS (
  SELECT SUM(`Loan Amount`) AS LoanAmt
  FROM `fact loan`
  WHERE `Disbursement Date` BETWEEN '2025-01-01' AND '2025-01-31'
),
prev AS (
  SELECT SUM(`Loan Amount`) AS LoanAmt
  FROM `fact loan`
  WHERE `Disbursement Date` BETWEEN '2024-12-01' AND '2024-12-31'
)
SELECT 
  (curr.LoanAmt - prev.LoanAmt) * 1.0 / prev.LoanAmt AS Loan_Growth_Percent
FROM curr, prev;

--- 9. Total Repayments Collected
SELECT SUM(`Total Pymnt`) AS Total_Repayments
FROM `fact repayment`;

--- 10. Principal Recovery Rate
SELECT SUM(r.`Total Rec Prncp`) * 1.0 / SUM(l.`Loan Amount`) AS Principal_Recovery_Rate
FROM `fact repayment` r
JOIN `fact loan` l ON r.`Account ID` = l.`Account ID`;

--- 11. Interest Income
SELECT SUM(`Total Rrec int`) AS Interest_Income
FROM `fact repayment`;

--- 12. Default Rate
SELECT SUM(CASE WHEN `Is Default Loan`='Y' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS Default_Rate
FROM `fact repayment`;

--- 13. Delinquency Rate
SELECT SUM(CASE WHEN `Is Delinquent Loan`='Y' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS Delinquency_Rate
FROM `fact repayment`;

--- 14. On-Time Repayment %
SELECT SUM(CASE WHEN `Repayment Behavior`='On-Time' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS OnTime_Repayment_Percent
FROM `fact repayment`;

--- 15. Loan Distribution by Branch
SELECT b.`Branch Name`, SUM(l.`Loan Amount`) AS Total_Loan_Amount
FROM `fact loan` l
JOIN `dim branch` b ON l.`BranchID`=b.`BranchID`
GROUP BY b.`Branch Name`;

--- 16. Branch Performance Category Split 
SELECT b.`Branch Performance Category`, COUNT(DISTINCT b.`BranchID`) AS Branch_Count
FROM `dim branch` b
GROUP BY b.`Branch Performance Category`;

--- 17. Product-wise Loan Volume
SELECT p.`Product Code`, SUM(l.`Loan Amount`) AS Loan_Volume
FROM `fact loan` l
JOIN `dim product` p ON l.`Product Id`=p.`Product Id`
GROUP BY p.`Product Code`;

--- 18. Product Profitability
SELECT p.`Product Code`, SUM(r.`Total Rrec int`) AS Interest_Income
FROM `fact repayment` r
JOIN `fact loan` l ON r.`Account ID` = l.`Account ID`
JOIN `dim product` p ON l.`Product Id` = p.`Product Id`
GROUP BY p.`Product Code`;
