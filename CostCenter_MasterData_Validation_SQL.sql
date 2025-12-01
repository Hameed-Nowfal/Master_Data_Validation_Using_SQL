------------------------------------------------------------------------Descripton ----------------------------------------------------------------------------
/*
The file contains SQL Queries to Perform:
	1. CREATE CostCenter Export and CostCenter ITK Tables.
	2. INSERT Data into the above mentioned 2 Tables from CSV files.
	3. SELECT Queries to View the data inside the tables and thier Counts.
	4. TRUNCATE Queries to Remove the data inside the tables without affecting the Table structure.
	5. DROP Queries to Delete the Entire Table structure itself.
	6. Check if the data Is:
		a. Match.
		b. MisMatch.
	7. Plus checks if the Export file has entries which is not there in ITK file('Not Sent') and if any of ITK file entries is Not Loaded in system ('Not Loaded')

CostCenter Data Full Load Process Explanation:
	1. Assume that a CostCenter ITK Load file with "500" entries is sent to Ariba.
	2. Once the Load is completed, the CostCenter File is Exported from the system which has "500" Entries as well.
	3. Now in ideal case:
		a. Count of Export File Entries = Count of ITK Load File Entries i.e. 500 = 500
		c. The Data Present in ITK Load File Entry must "Match" exactly with the Data Present in Export File Entry.
	4. In a non-ideal scenario any of above mentioned points may be false which can be identified with help of the SQL queries below.


*/
------------------------------------------------------------------------Descripton ------------------------------------------------------------------------------

--------------------------------------------------------------------------START ---------------------------------------------------------------------------------

BULK INSERT "CostCenterExport"
FROM 'D:\...\CostCenterExport.csv'
WITH
(	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '0x0a',
	CODEPAGE = '65001',
	FORMAT='CSV',
	FIRSTROW=2	);

BULK INSERT CostCenterITKLoad
FROM 'D:\...\CostCenterITKLoad.csv'
WITH
(       FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        CODEPAGE = '65001',
        FORMAT='CSV',
        FIRSTROW=2				);

-- Data Selection, Count, Truncation and Table Drop Queries --

SELECT * FROM "CostCenterExport";
SELECT * FROM "CostCenterITKLoad";

SELECT COUNT(*) AS "CostCenterExport_Count" FROM "CostCenterExport";
SELECT COUNT(*) AS "CostCenterITKLoad_Count" FROM "CostCenterITKLoad";

TRUNCATE TABLE "CostCenterExport";
TRUNCATE TABLE "CostCenterITKLoad";

DROP TABLE "CostCenterExport";
DROP TABLE "CostCenterITKLoad";

---------------------------------Master Data Validation by Table Comparison ----------------------------------------------------------------------------------------

WITH CostCenterValidation AS (

SELECT

"E"."BUKRS" AS "Export BUKRS",
"I"."BUKRS" AS "ITK BUKRS",
CASE
	WHEN "E"."BUKRS" IS NULL AND "I"."BUKRS" IS NULL THEN 'Match - Both NULL'
	WHEN "E"."BUKRS" = "I"."BUKRS" THEN 'Match'
	WHEN "E"."BUKRS" IS NULL AND "I"."BUKRS" IS NOT NULL THEN 'Not Loaded'
	WHEN "E"."BUKRS" IS NOT NULL AND "I"."BUKRS" IS NULL THEN 'Not Sent'
	ELSE 'MISMatch'
END AS "BUKRS Comparison",

"E"."KOSTL" AS "Export KOSTL",
"I"."KOSTL" AS "ITK KOSTL",
CASE
	WHEN "E"."KOSTL" IS NULL AND "I"."KOSTL" IS NULL THEN 'Match - Both NULL'
	WHEN "E"."KOSTL" = "I"."KOSTL" THEN 'Match'
	WHEN "E"."KOSTL" IS NULL AND "I"."KOSTL" IS NOT NULL THEN 'Not Loaded'
	WHEN "E"."KOSTL" IS NOT NULL AND "I"."KOSTL" IS NULL THEN 'Not Sent'
	ELSE 'MISMatch'
END AS "KOSTL Comparison",

"E"."PurchasingUnit" AS "Export PurchasingUnit",
"I"."PurchasingUnit" AS "ITK PurchasingUnit",
CASE
	WHEN "E"."PurchasingUnit" IS NULL AND "I"."PurchasingUnit" IS NULL THEN 'Match - Both NULL'
	WHEN "E"."PurchasingUnit" = "I"."PurchasingUnit" THEN 'Match'
	WHEN "E"."PurchasingUnit" IS NULL AND "I"."PurchasingUnit" IS NOT NULL THEN 'Not Loaded'
	WHEN "E"."PurchasingUnit" IS NOT NULL AND "I"."PurchasingUnit" IS NULL THEN 'Not Sent'
	ELSE 'MISMatch'
END AS "PurchasingUnit Comparison"

FROM "CostCenterExport" AS "E"
FULL JOIN "CostCenterITKLoad" AS "I"
ON
"E"."BUKRS" = "I"."BUKRS"
AND
"E"."KOSTL" = "I"."KOSTL"
AND
"E"."PurchasingUnit" = "I"."PurchasingUnit"

)

SELECT 

CONCAT_WS('', 
        CASE WHEN "BUKRS Comparison" NOT IN ('Match','Match - Both NULL') THEN 'BUKRS' ELSE '' END,
        CASE WHEN "KOSTL Comparison" NOT IN ('Match','Match - Both NULL') THEN ' - KOSTL' ELSE '' END,
        CASE WHEN "PurchasingUnit Comparison" NOT IN ('Match','Match - Both NULL') THEN ' - PurchasingUnit' ELSE '' END
    ) AS ERROR_COLUMNS,
*

FROM CostCenterValidation
WHERE

(
"BUKRS Comparison" NOT IN ('Match','Match - Both NULL')
OR "KOSTL Comparison" NOT IN ('Match','Match - Both NULL')
OR "PurchasingUnit Comparison" NOT IN ('Match','Match - Both NULL')
)							-- Added this condition to exclude Matching Entries

ORDER BY
"Export BUKRS",
"Export KOSTL",
"Export PurchasingUnit",
"ITK BUKRS",
"ITK KOSTL",
"ITK PurchasingUnit"
----------------------------------------------------------------------END-----------------------------------------------------------------------------------------------
