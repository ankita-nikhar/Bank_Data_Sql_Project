create database main_project;
use main_project;

select * from bank_unclean_dataset_unsupervised_mysql;

rename table bank_unclean_dataset_unsupervised_mysql to bank_data;

select * from bank_data; -- orginal table --

-- FIRST THING WE WANT TO DO IS CREATE A STAGGING TABLE.
-- THIS IS THE ONE WE WILL WORK IN AND CLEAN THE DATA.
-- WE WANT A TABLE WITH THE RAW DATA IN CASE SOMETHING HAPPENS.
create table bank_data_staging
like bank_data;

insert into bank_data_staging
select * from bank_data;

select * from bank_data_staging; -- duplicate table --

-- NOW WHEN WE ARE DATA CLEANING WE USUALLY FOLLOW A FEW STEPS:
-- 1. CHECK FOR DUPLICATES AND REMOVE ANY.
-- 2. STANDARDIZE DATA AND FIX ERRORS.
-- 3. LOOK AT NULL VALUES AND SEE WHAT
-- 4. REMOVE ANY COLUMNS AND ROWS THAT ARE NOT NECCESARY

-- # 1. REMOVE DULPICATES

-- WE DID PARTITIONING
SELECT Account_ID, Customer_Name, Age,	Gender,	Transaction_Date,
   ROW_NUMBER() OVER(
   PARTITION BY Account_ID, Customer_Name, Age,	Gender,	Transaction_Date) AS ROW_NUM
   FROM bank_data;
   
   -- TO SEE  DUPLICATE ROWS
SELECT * FROM (
SELECT Account_ID, Customer_Name, Age,	Gender,	Transaction_Date,
   ROW_NUMBER() OVER(
   PARTITION BY Account_ID, Customer_Name, Age,	Gender,	Transaction_Date) AS ROW_NUM
   FROM bank_data) DUPLICATES
   WHERE ROW_NUM > 1;

-- A11653 IS A Account_ID WHICH APPERS 3 TIMES 
   select * from bank_data_staging
   where Account_id = 'A11653';
-- A11653 HAS NO DUPLICATES SOME VALUES ARE DIFFERENT
    
-- NOW CHECKING FOR ALL THE COLUMNS 
select * from (
    select Account_ID, Customer_Name, Age, Gender, Account_Type, Balance, Transaction_Amount, 
Transaction_Type, Transaction_Date, Branch, IFSC_Code, Loan_Status, Credit_Score, KYC_Status, Account_Status,
    row_number() over (
    partition by Account_ID, Customer_Name, Age, Gender, Account_Type, Balance, Transaction_Amount, 
Transaction_Type, Transaction_Date, Branch, IFSC_Code, Loan_Status, Credit_Score, KYC_Status, Account_Status)
as row_num
from bank_data_staging)
duplicates 
 where row_num > 1; 
 
-- THERE ARE NO DUPLICATES AS SOME VALUES ARE DIFFERENT 
-- BUT THERE ARE ROWS WIHTOUT Account_ID
select * from bank_data_staging;

-- DELETE ROWS WITH NULL Account_ID (2 rows affected)
UPDATE bank_data_staging
SET Account_ID = null
WHERE Account_ID= '';

DELETE FROM bank_data_staging 
WHERE Account_ID IS NULL;

select * from bank_data_staging; -- (Now 2998 rows are there)

-- # 2. STANDARDIZE DATA

-- REMOVE EXTRA SPACES
DESCRIBE bank_data_staging ;

UPDATE  bank_data_staging 
SET Account_ID = TRIM(Account_ID),
Customer_Name = TRIM(Customer_Name),
Branch = TRIM(Branch),
Gender = TRIM(Gender),
Account_Type = TRIM(Account_Type),
Balance = TRIM(Balance),
Transaction_Amount = TRIM(Transaction_Amount),
Transaction_Type = TRIM(Transaction_Type),
Transaction_Date = TRIM(Transaction_Date),
Branch = TRIM(Branch),
IFSC_Code = TRIM(IFSC_Code),
Loan_Status = TRIM(Loan_Status),
Credit_Score = TRIM(Credit_Score),
KYC_Status = TRIM(KYC_Status),
Account_Status = TRIM(Account_Status);

-- IF WE LOOK AT THE Customer_Name IT LOOKS LIKE WE HAVE SOME MISSING VALUES, LETS TAKE A LOOK AT IT (425 rows affected)
SELECT DISTINCT Customer_Name
FROM bank_data_staging
ORDER BY Customer_Name;

SELECT * FROM bank_data_staging
WHERE Customer_Name IS NULL
OR Customer_Name = ''
ORDER BY Customer_Name ;

select * from bank_data_staging;

-- WE SHOULD SET THE BLANKS TO NULL SINCE THOSE ARE TYPICALLY EASIER TO WORK WITH(425 rows affected)
UPDATE bank_data_staging
SET Customer_Name = null
WHERE Customer_Name = '';

-- NOW WE NEED TO POPULATE THOSE NULLS IF POSSIBLE(91 rows affcted)
UPDATE bank_data_staging b1
JOIN bank_data_staging b2
ON b1.Account_ID = b2.Account_ID
SET b1.Customer_Name = b2.Customer_Name
WHERE b1.Customer_Name IS NULL 
OR  b1.Customer_Name = ''
AND b2.Customer_Name IS NOT NULL
AND b2.Customer_Name != '';

-- IF WE LOOK AT THE Age IT LOOKS LIKE WE HAVE SOME MISSING VALUES, LETS TAKE A LOOK AT IT 
SELECT * FROM bank_data_staging
WHERE Age IS NULL
OR Age = ''
ORDER BY Age ;

-- WE SHOULD SET THE BLANKS TO NULL (54 rows affected)
UPDATE bank_data_staging
SET Age = null
WHERE Age = '';

-- NOW WE NEED TO POPULATE THOSE NULLS IF POSSIBLE
-- WHERE WE HAVE LIKE 2 SARA(customer_name) WITH SAME ACCOUNT_ID BUT ONLY 1 SARA HAS Age MENTIONED 
-- SO HERE WE WILL POPULATE ON BASIS OF SAME Customer_Name WITH SAME Account_ID WITH KNOWN Age (5 rows afected)
UPDATE bank_data_staging T1
JOIN bank_data_staging T2
ON T1.Account_ID = T2.Account_ID
AND T1.Customer_Name = T2.Customer_Name
SET T1.Age = T2.Age
WHERE T1.Age IS NULL 
AND T2.Age IS NOT NULL;
    
/*-- NOW WE NEED TO POPULATE THOSE NULLS IF POSSIBLE
-- WHERE WE HAVE SAME Customer_Name WITH SAME Age (45 rows affected)
UPDATE bank_data_staging T1
JOIN (
SELECT Customer_Name, AVG(Age)  as Age
FROM bank_data_staging
WHERE Age IS NOT NULL 
GROUP BY Customer_Name ) T2
ON T1.Customer_Name = T2.Customer_Name
SET T1.Age = T2.Age 
where T1.Age is null; */
-- I DONT THINK THIS IS LOGICAL SO NOT GOING WITH THIS

/*-- FIRST WE WILL STANDARDIZE Gender VALUES 
UPDATE bank_data_staging
SET Gender =
CASE 
WHEN Gender IN ('male', 'MALE', 'Male') THEN 'Male'
WHEN Gender IN ('female', 'FEMALE', 'Female') THEN 'Female'
WHEN Gender IN ('other','OTHER','Other') THEN 'Other'
ELSE 'NULL
END;*/

-- IF WE LOOK AT THE Gender IT LOOKS LIKE WE HAVE SOME MISSING VALUES, LETS TAKE A LOOK AT IT (743 rows affected)
SELECT * FROM bank_data_staging
WHERE Gender = ''
ORDER BY Gender ;

-- WE SHOULD SET THE BLANKS TO NULL (743 rows affected)
UPDATE bank_data_staging
SET Gender = NULL
WHERE Gender = '';

-- NOW WE NEED TO POPULATE THOSE NULLS IF POSSIBLE
-- HERE WE WILL POPULATE ON BASIS OF SAME Customer_Name WITH SAME ACCOUNT_ID WITH KNOWN Gender IF ANY (81 rows affected)
UPDATE bank_data_staging T1
JOIN bank_data_staging T2
ON T1.Account_ID = T2.Account_ID
AND T1.Customer_Name = T2.Customer_Name
SET T1.Gender = T2.Gender
WHERE T1.Gender IS NULL 
AND T2.Gender IS NOT NULL;

-- SO WE WILL FILL Gender WITH SAME Account_ID(266 rows affected)
/*UPDATE bank_data_staging B1
JOIN bank_data_staging B2
ON B1.Account_ID = B2.Account_ID
AND B2.Gender IS NOT NULL
SET B1.Gender = B2.Gender
WHERE B1.Gender IS NULL;*/ -- but this logic is not correct 

select * from bank_data_staging;

-- WE HAVE SOME BLANK VALUES IN Account_Type COLUMN 
-- SO WE WILL FILL THAT WITH NULL VALUES(574 rows returned)

SELECT * FROM bank_data_staging
WHERE Account_Type = ''
ORDER BY Account_Type ;

UPDATE bank_data_staging -- (574 rows affected)
SET Account_Type = NULL
WHERE Account_Type = '';

-- WE HAVE SOME BLANK VALUES IN Transaction_Type COLUMN 

SELECT * FROM bank_data_staging -- (970 rows returned)
WHERE Transaction_Type = ''
ORDER BY Transaction_Type ;

UPDATE bank_data_staging -- (970 rows affected)
SET Transaction_Type = NULL
WHERE Transaction_Type = '';

-- CONVERT DATE FORMAT 
update bank_data_staging
set Transaction_Type =
case 
-- handle M/D/YYYY or MM/DD/YYYY
when Transaction_Type regexp '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
then str_to_date(Transaction_Type, '%m/%d/%Y')

-- handle YYYY-MM-DD
when Transaction_Type regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
then Transaction_Type
-- null or invalid stays null
else null 
end;

-- WE HAVE SOME BLANK VALUES IN Transaction_Type COLUMN 

SELECT * FROM bank_data_staging -- (535 rows returned)
WHERE Branch = ''
ORDER BY Branch ;

UPDATE bank_data_staging -- (535 rows affected)
SET Branch = null
WHERE Branch = '';

-- WE HAVE SOME MISSING VALUES IN IFSC_Code
-- LETS REPLACE THE MISSING VALUES WITH NULL
SELECT * FROM bank_data_staging -- (615 rows returned)
WHERE IFSC_Code = ''
ORDER BY IFSC_Code ;

UPDATE bank_data_staging -- (615 rows affected)
SET IFSC_Code = NULL
WHERE IFSC_Code = '';

-- WE HAVE SOME MISSING VALUES IN Loan_Status
-- LETS REPLACE THE MISSING VALUES WITH NULL
SELECT * FROM bank_data_staging -- (738 rows returned)
WHERE Loan_Status = ''
ORDER BY Loan_Status ;

UPDATE bank_data_staging -- (738 rows affected)
SET Loan_Status = null
WHERE Loan_Status = '';

-- WE HAVE ONLY 1 NULL VALUE IN Credit_Score
-- SO LETS REPLACE IT WITH NULL 

SELECT * FROM bank_data_staging 
WHERE Credit_Score = ''

UPDATE bank_data_staging 
SET Credit_Score = null
WHERE Credit_Score = '';

-- NOW LETS POPULATE Loan_Status NULL VALUES USING Credit_Score 
-- MY LOGIC BEHIND IS :
-- SCORE > 700 = Approved
-- 450–700 = Pending
-- < 450 = Rejected

UPDATE bank_data_staging
SET Loan_Status =
CASE
WHEN Credit_Score >= 700 THEN 'Approved'
WHEN Credit_Score >= 450 THEN 'Pending'
ELSE 'Rejected'
END
WHERE Loan_Status IS NULL OR Loan_Status='';   
   
-- WE CAN SEE SOME BALNK VALUES IN KYC_Status
-- LETS FILL THOSE FIRST 
SELECT * FROM bank_data_staging -- (760 rows returned)
WHERE KYC_Status = '';

UPDATE bank_data_staging  -- (760 rows affected)
SET KYC_Status = null
WHERE KYC_Status = '';

-- # 3. LOOK AT NULL VALUES 

-- THERE ARE NULL VALUES in Customer_Name, Age, Gender,	Account_Type, Transaction_Amount,	
-- Transaction_Type, Branch,	IFSC_Code,	Credit_Score,	KYC_Status,	Account_Status.
-- I DONT WANT TO CHANGE THAT 
-- I LIKE HAVING THEM ALL BECAUSE IT MAKES IT EASIER FOR CALCULATIONS DURING EDA (Exploratory Data Analysis)
-- SO THERE ISN'T ANYTHING I WANT TO CHANGE WITH THE NULL VALUES

-- LET'S LOOK INTO PROBLEM STATEMENTS

-- 1. IDENTIFY HIGH-RISK CUSTOMERS
SELECT Customer_Name, Account_Type, Balance, Credit_Score,  Account_Status
from bank_data_staging
where Balance < 10000
And Credit_Score < 600
And Account_Status = 'Dormant'; -- HERE I CONSIDERED CUSTOMERS WITH LOW CREDIT SCORE, LOW BALANCE & DORMANT ACCOUNT HOLDERS AS HIGH RISK CUSTOMERS 

-- 2. DETECT FRAUDULENT TRANSACTIONS
WITH Avg_txn AS (
SELECT AVG(Transaction_Amount) AS avg_amount
 FROM bank_data_staging)
SELECT *
FROM bank_data_staging, Avg_txn
WHERE Transaction_Amount > avg_amount * 3;

-- 3. ANALYZE CUSTOMER SEGMENTATION
SELECT Customer_Name, Balance,
CASE 
WHEN Balance < 20000 THEN 'LOW INCOME SEGMENT'
WHEN Balance BETWEEN 20000 AND 70000 THEN 'MIDDLE INCOME SEGMENT'
ELSE 'HIGH INCOME SEGMENT'
END AS Customer_Segment
FROM bank_data_staging;

-- 4. IMPROVE LOAN APPROVAL DECISIONS
SELECT Account_ID, Customer_Name, Age, Balance, Credit_Score, KYC_Status, Account_Status,
CASE 
WHEN Credit_Score >= 700 AND Balance >= 50000 AND KYC_Status = 'Verified'
AND Account_Status = 'Active' AND Age BETWEEN 21 AND 50
THEN 'Approved'
WHEN Credit_Score BETWEEN 600 AND 699
THEN 'Review'
ELSE 'Rejected'
END AS Loan_Approval 
FROM bank_data_staging;

-- 5. MONITOR ACCOUNT HEALTH & INACTIVITY
WITH last_txn AS (
SELECT Account_ID, Customer_Name, Account_Status,
MAX(STR_TO_DATE(Transaction_Date,'%d/%m/%Y')) AS last_txn_date
FROM bank_data
GROUP BY Account_ID, Customer_Name, Account_Status)
SELECT Account_ID, Customer_Name, last_txn_date, Account_Status,
CASE 
WHEN Account_Status = 'Closed' THEN 'Closed'
WHEN last_txn_date < DATE_SUB(CURDATE(), INTERVAL 3 MONTH) THEN 'Inactive'
ELSE 'Active'
END AS account_health
FROM last_txn;

-- 6. EVALUATE BRANCH PERFORMANCE
SELECT Branch, COUNT(*) AS Total_txn,SUM(Transaction_Amount) AS Total_amt,
RANK() OVER (ORDER BY SUM(Transaction_Amount) DESC) AS Branch_rank,
CASE 
WHEN SUM(Transaction_Amount) >= 7500000 THEN 'High Performance'
WHEN SUM(Transaction_Amount) >= 7000000 THEN 'Medium Performance'
ELSE 'Low Performance'
END AS Performance
FROM bank_data_staging
WHERE Branch IS NOT NULL
GROUP BY Branch;

select * from bank_data_staging