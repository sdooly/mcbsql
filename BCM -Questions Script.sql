2.
CREATE TABLE BCM_SUPPLIER (
    SUPPLIER_REF int NOT NULL AUTO_INCREMENT,
    SUPPLIER_NAME varchar(255) NOT NULL,
	SUPP_CONTACT_NAME varchar(255),
    SUPP_ADDRESS varchar(255),
    SUPP_CONTACT_NUMBER varchar(25),
	SUPP_EMAIL varchar(255),
    CONSTRAINT BCM_SUPPLIER_PK PRIMARY KEY (SUPPLIER_REF)
);

CREATE TABLE BCM_ORDER (
    ORDER_REF varchar(25) NOT NULL,
	SUPPLIER_REF int NOT NULL,
    ORDER_DATE varchar(255) NOT NULL,
    ORDER_DESCRIPTION varchar(255),
	ORDER_STATUS varchar(25),
    CONSTRAINT BCM_ORDER_PK PRIMARY KEY (ORDER_REF)
);

CREATE TABLE BCM_INVOICE (
    INVOICE_REFERENCE varchar(25) NOT NULL,
	SUPPLIER_REF int NOT NULL,
    INVOICE_DATE varchar(255) NOT NULL,
	INVOICE_STATUS varchar(25),
    INVOICE_HOLD_REASON varchar(255),
    INVOICE_DESCRIPTION varchar(25),
    CONSTRAINT BCM_INVOICE_PK PRIMARY KEY (INVOICE_REFERENCE),
	CONSTRAINT FK_BCM_INVOICE
		FOREIGN KEY (SUPPLIER_REF)
		REFERENCES BCM_SUPPLIER(SUPPLIER_REF)
);

CREATE TABLE BCM_ORDER_LINE (
    ORDER_LINE_ID int NOT NULL AUTO_INCREMENT,
    ORDER_LINE_REF Varchar(25) NOT NULL,
    ORDER_REF varchar(25) NOT NULL,
	INVOICE_REFERENCE varchar(25) NOT NULL,
    ORDER_STATUS varchar(25),
    ORDER_LINE_DESCRIPTION varchar(255),
    ORDER_LINE_AMOUNT double,
    PRIMARY KEY (ORDER_LINE_ID),
	CONSTRAINT FK_BCM_ORDER_LINE
		FOREIGN KEY (ORDER_REF)
		REFERENCES BCM_ORDER(ORDER_REF)
);

3.
CREATE PROCEDURE POPULATE_BCM_SUPPLIER
AS
INSERT INTO BCM_SUPPLIER (SUPPLIER_NAME, SUPP_CONTACT_NAME, SUPP_ADDRESS, SUPP_CONTACT_NUMBER, SUPP_EMAIL)
SELECT SUPPLIER_NAME, SUPP_CONTACT_NAME, SUPP_ADDRESS, SUPP_CONTACT_NUMBER, SUPP_EMAIL FROM XXBCM_ORDER_MGT GROUP BY SUPPLIER_NAME;
GO;
EXEC POPULATE_BCM_SUPPLIER;

INSERT INTO BCM_ORDER (ORDER_REF,SUPPLIER_REF, ORDER_DATE, ORDER_DESCRIPTION, ORDER_STATUS)
SELECT mgt.ORDER_REF, sup.SUPPLIER_REF, REPLACE(mgt.ORDER_DATE, '-',' '), mgt.ORDER_DESCRIPTION, mgt.ORDER_STATUS 
FROM `XXBCM_ORDER_MGT` as mgt INNER JOIN BCM_SUPPLIER as sup ON sup.SUPPLIER_NAME = mgt.SUPPLIER_NAME 
WHERE  mgt.`ORDER_LINE_AMOUNT` IS NULL

INSERT INTO BCM_INVOICE (INVOICE_REFERENCE, SUPPLIER_REF, INVOICE_DATE, INVOICE_STATUS, INVOICE_HOLD_REASON, INVOICE_DESCRIPTION)
SELECT mgt.`INVOICE_REFERENCE`, sup.SUPPLIER_REF, REPLACE(mgt.INVOICE_DATE, '-',' '), mgt.`INVOICE_STATUS`, mgt.`INVOICE_HOLD_REASON`, mgt.`INVOICE_DESCRIPTION` 
FROM `XXBCM_ORDER_MGT` mgt INNER JOIN BCM_SUPPLIER as sup ON mgt.SUPPLIER_NAME = sup.SUPPLIER_NAME 
WHERE `INVOICE_REFERENCE` IS NOT NULL GROUP BY `INVOICE_REFERENCE`

INSERT INTO BCM_ORDER_LINE (ORDER_LINE_REF, ORDER_REF, INVOICE_REFERENCE,ORDER_STATUS, ORDER_LINE_DESCRIPTION, ORDER_LINE_AMOUNT)
SELECT `ORDER_REF` AS ORDER_LINE_REF, SUBSTRING(`ORDER_REF`, 1, 5) AS ORDER_REF, `INVOICE_REFERENCE`,`ORDER_STATUS`,`ORDER_DESCRIPTION`, REPLACE(REPLACE(REPLACE(REPLACE(ORDER_LINE_AMOUNT, ',', ''), 'o', 0), 'I', 1),'S',5)  as Total_Amount
FROM `XXBCM_ORDER_MGT` WHERE `ORDER_LINE_AMOUNT`  IS NOT NULL


4.
    SELECT  CAST(SUBSTRING(O.ORDER_REF, 3, 3) AS INT) AS "Order Reference", 
    CONCAT(SUBSTRING(O.ORDER_DATE, 4,3),'-',SUBSTRING(O.ORDER_DATE, 10,2)) AS 'Order Period', 
    CONCAT(SUBSTRING(S.SUPPLIER_NAME, 1, 1),LOWER(RIGHT(S.SUPPLIER_NAME, 
    LENGTH(S.SUPPLIER_NAME) - 1)))  AS "Supplier Name", 
    SUM(OL.ORDER_LINE_AMOUNT) AS 'Order Total Amount' , 
    OL.INVOICE_REFERENCE AS 'Invoice Reference', 
    OL.ORDER_STATUS as 'Order Status', 
     (
    CASE 
       WHEN (OL.ORDER_STATUS = 'paid') THEN 'OK'
       WHEN(OL.ORDER_STATUS = 'Pending') THEN 'To follow up'
        ELSE 'To verify'
    END) AS Action
FROM BCM_ORDER O INNER JOIN BCM_SUPPLIER S ON S.SUPPLIER_REF = O.SUPPLIER_REF 
INNER JOIN BCM_ORDER_LINE OL ON OL.ORDER_REF = O.ORDER_REF GROUP BY OL.INVOICE_REFERENCE

5.

SELECT Order_Reference, Order_Period, Supplier_Name, Order_Total_Amount, Order_Status, Invoice_Reference  
FROM 
(SELECT  CAST(SUBSTRING(O.ORDER_REF, 3, 3) AS INT) AS "Order_Reference", 
CONCAT(SUBSTRING(O.ORDER_DATE, 4,3),'-',SUBSTRING(O.ORDER_DATE, 10,2)) AS 'Order_Period', 
CONCAT(SUBSTRING(S.SUPPLIER_NAME, 1, 1),LOWER(RIGHT(S.SUPPLIER_NAME, LENGTH(S.SUPPLIER_NAME) - 1)))  AS "Supplier_Name", 
SUM(OL.ORDER_LINE_AMOUNT) AS 'Order_Total_Amount' , OL.INVOICE_REFERENCE AS 'Invoice_Reference', OL.ORDER_STATUS as 'Order_Status', 
(
    CASE 
       WHEN (OL.ORDER_STATUS = 'paid') THEN 'OK'
       WHEN(OL.ORDER_STATUS = 'Pending') THEN 'To follow up'
        ELSE 'To verify'
    END) AS Action
FROM BCM_ORDER O INNER JOIN BCM_SUPPLIER S ON S.SUPPLIER_REF = O.SUPPLIER_REF 
INNER JOIN BCM_ORDER_LINE OL ON OL.ORDER_REF = O.ORDER_REF 
GROUP BY OL.INVOICE_REFERENCE ORDER BY Order_Total_Amount DESC LIMIT 3) AS A ORDER BY A.Order_Total_Amount ASC LIMIT 1