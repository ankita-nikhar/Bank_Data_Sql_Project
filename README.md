Banking Data Cleaning & Analytics SQL Project

Project Overview:
This project focuses on cleaning, transforming, and analyzing banking transaction data using MySQL. The dataset contains customer account details, transactions, loan information, KYC status, branch details, and account activity. The project demonstrates real-world Data Cleaning, Exploratory Data Analysis (EDA), and Business Problem Solving using SQL.

Dataset Information:
The dataset contains the following columns:
Column Name:	Description
Account_ID:	Unique account identifier
Customer_Name	:Customer full name
Age:	Customer age
Gender:	Gender of customer
Account_Type:	Savings / Current etc.
Balance:	Account balance
Transaction_Amount:	Transaction amount
Transaction_Type:	Credit/Debit
Transaction_Date:	Date of transaction
Branch:	Bank branch
IFSC_Code:	Branch IFSC code
Loan_Status:	Loan approval status
Credit_Score:	Customer credit score
KYC_Status:	KYC verification status
Account_Status:	Active / Dormant / Closed

Data Cleaning Steps:
1. Removing Duplicates
Identified duplicate rows using window functions
Deleted redundant records

3. Standardizing Data:
Fixed inconsistent company names
Cleaned industry and country fields
Trimmed unwanted spaces

3. Handling Null Values:
Replaced or removed null values where necessary
Ensured meaningful data consistency

5. Date Formatting:
Converted date column into proper SQL DATE format using STR_TO_DATE()

5. Data Transformation:
Structured dataset for better querying and analysis

Key SQL Concepts Used:
CTEs (WITH)
Window Functions (ROW_NUMBER, RANK)
Aggregate Functions
CASE Statements
JOIN Operations
NULL Handling
Data Type Conversion
Data Standardization

Project Outcomes:
✔ Cleaned and standardized raw banking data
✔ Handled missing and inconsistent values
✔ Created business-driven SQL solutions
✔ Improved data quality for analytics
✔ Built practical banking analytics use cases

Author:
Ankita Nikhar
Data Analyst (Student)
