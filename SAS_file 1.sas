/* 
   This SAS script is designed to process and transform order data from various sources into a structured format for reporting purposes.
   It fulfills the business requirement of generating detailed order reports, including fiscal information, order status, and product details.
   The script connects to multiple data sources, formats data, and creates tables for further analysis.
*/

options compress=yes; /* Enable compression for output datasets to save space */
libname hero_lib '/sasdata/Hero_Data'; /* Define library for Hero Data */
libname comp_lib '/sasdata/Anshu_Data'; /* Define library for Anshu Data */

/* Define connection to Oracle database with GPCPRD schema */
LIBNAME GPCLIB ORACLE PATH=GPCPRD SCHEMA=GPCPRD AUTHDOMAIN="GPCPRD" ;

/* Define connection to SAP ECC system */
LIBNAME sapecc SASIOSR3 ashost="10.3.3.4" sysnr=00 language=EN Client=300  
trace=0 BatchMode=0 BUFFER_SIZE=20000000NETWEAVER AUTHDOMAIN="HeroIT SAP ECC" ;

/* Define connection to Oracle database with OLAPPROD schema */
LIBNAME herotrgt ORACLE PATH=OLAPPROD SCHEMA=SAS_OLAP USER=SAS_OLAP  
PASSWORD="{SAS002}8041A75C0F4262A15ADF53C2495BA193" ;

LIBNAME heroprod ORACLE PATH=OLAPPROD SCHEMA=OLAP USER=SAS_OLAP  
PASSWORD="{SAS002}8041A75C0F4262A15ADF53C2495BA193" ;

/* Define formats for month, half-year, and quarter values */
proc format;
value V_MONTH
1='Jan'
2='Feb'
3='Mar'
4='Apr'
5='May'
6='Jun'
7='Jul'
8='Aug'
9='Sep'
10='Oct'
11='Nov'
12='Dec';
run;

proc format;
value V_HY
1='HY-1'
2='HY-2';
run;

proc format;
value V_QRTR
1='Q1'
2='Q2'
3='Q3'
4='Q4';
run;

/* Create a table with detailed order information */
PROC SQL;

CREATE TABLE LND_PD_ORDER_DETAIL AS

SELECT DATEPART(ORDER_DT) AS ORDER_DATE FORMAT = DATE9.,
/* Fiscal year calculated by concatenating calendar year and next year */
  CAT('FY ',CATX('-',PUT(DD.CAL_YEAR,BEST4.),SUBSTR(PUT((DD.CAL_YEAR+1),BEST4.),3,2))) AS FSCL_YEAR,
       PUT(DD.FSCL_HALF,V_HY.) AS FSCL_HALF, /* Fiscal half-year based on predefined format */
       PUT(DD.FSCL_QTR,V_QRTR.) AS FSCL_QTR, /* Fiscal quarter based on predefined format */
       PUT(DD.CAL_MONTH,V_MONTH.) AS FSCL_MONTH, /* Fiscal month based on predefined format */
  CAT(PUT(DD.CAL_MONTH,V_MONTH.),SUBSTR(PUT(DD.CAL_YEAR,BEST4.),3)) AS MONTH_YR, /* Month and year concatenation */
       ORDER_NUM AS ORDER_NBR, /* Order number */
       SUBSTR (ORDER_NUM,FIND (ORDER_NUM, '-') + 1,2) AS DIVISION_ID, /* Extract division ID from order number */
       SUBSTR (DIVISION_NAME, FIND (DIVISION_NAME, '-') + 2)
          AS DIVISION_NAME, /* Extract division name from division name field */
       SUBSTR (ORDER_NUM,1,FIND (ORDER_NUM, '-') - 1) AS PD_CODE, /* Extract PD code from order number */
       SUBSTR(ORGANIZATION_NAME, FIND (ORGANIZATION_NAME, '-') + 2)
 AS PD_NAME, /* Extract PD name from organization name */
  OU_NUM AS ACCOUNT_NBR, /* Account number */
  ACNT.SAP_CODE AS ACCOUNT_CODE, /* SAP account code */
  ACNT.NAME AS ACCOUNT_NAME, /* Account name */
       ACNT.CITY AS ACCOUNT_CITY, /* Account city */
       SUBSTR (ZONAL_OFFICE_NAME, 16) AS ZONAL_OFFICE, /* Extract zonal office name */
       SUBSTR (AREA_OFFICE_NAME, 15) AS AREA_OFFICE, /* Extract area office name */
       ODIF.ORDER_TYPE AS ORDER_TYPE, /* Order type */
       ODIF.STATUS_CD AS STATUS, /* Order status code */
       ODIF.X_DLP AS RATE, /* Order rate */
  DATEPART(ODIF.STATUS_DT) AS STATUS_DATE FORMAT = DATE9., /* Status date */
       CANCELLED_FLG AS CNCLD_FLAG, /* Cancelled flag */
       CLOSED_FLG AS CLSD_FLAG, /* Closed flag */
  INT(X_TOT_REQ_QTY) AS ORDER_QTY, /* Total requested quantity */
  (case when INT(QTY_REQ) < INT(X_TOT_REQ_QTY)
   then (today()-DATEPART(ORDER_DT)) else 0 end) as ORDER_AGE, /* Calculate order age if quantity requested is less than total requested */
       SPG.PG AS PART_GRP, /* Part group */
       SPG.SPG AS SUB_PART_GRP, /* Sub part group */
       PRD.PART_NUM AS PART_NBR, /* Part number */
       PRD.PROD_NAME AS PART_DESC, /* Part description */
       SPG.ABC AS PART_CAT, /* Part category */
       SPG.CURRENT_NC AS CURRENT_CAT, /* Current non-current category */
       SPG.ACTIVE_INACTIVE AS PART_STATUS, /* Part status */
       INT(ODIF.LN_NUM) AS LINE_ITEM_NBR, /* Line item number */
       (INT(X_TOT_REQ_QTY) * ODIF.X_DLP) AS SALE_ORDER_AMT, /* Calculate sale order amount */
       X_CHILD_ORDER_NUM AS CHILD_ORDER_NBR, /* Child order number */
  X_PAR_ORDER_NUM AS PAR_ORDER_NBR, /* Parent order number */
  ORD.X_CUST_CATGRY AS CUST_CAT, /* Customer category */
  ORD.X_CUST_TYPE AS CUST_TYPE, /* Customer type */
  PRD.X_CATEGORY_CD AS PROD_CAT, /* Product category */
  INT(ODIF.DISCNT_PERCENT*100)/100 AS DSCNT_PRCNTG, /* Discount percentage */
  INT(ODIF.DISCNT_AMT*100)/100 AS DSCNT_AMT, /* Discount amount */
  ORD.B2B_SUB_ORDER_TYPE AS SUB_ORDER_TYPE, /* Sub order type */
  /* Invoice quantity calculation with null check */
 INT(CASE WHEN INV.QTY IS NULL THEN 0 ELSE INV.QTY END) AS INVC_QTY,
 (INT(CASE WHEN INV.QTY IS NULL THEN 0 ELSE INV.QTY END) * ODIF.X_DLP) AS INVOICE_VALUE
/* Invoice value calculation with null check */

  FROM HEROPROD.W_ORDER_D ORD
       LEFT JOIN HEROPROD.W_ORDERITEM_F ODIF
          ON ORD.ROW_WID = ODIF.ORDER_WID
       LEFT JOIN HEROPROD.W_INT_ORG_D ORGD
          ON ORGD.ROW_WID = ODIF.X_DIVISION_WID
       INNER JOIN HEROPROD.WC_INT_ORG_DH ORGDH
          ON ORGDH.DIVISION_ID = ORGD.INTEGRATION_ID
       LEFT JOIN HEROPROD.W_PRODUCT_D PRD
          ON ODIF.PROD_WID = PRD.ROW_WID
       LEFT JOIN HEROPROD.WC_PBO_PART_CAT_MASTER SPG
          ON PRD.PART_NUM = SPG.PART_NUM
       LEFT JOIN HEROPROD.W_DAY_D DD
          ON ODIF.ORDER_DT_WID = DD.ROW_WID
       LEFT JOIN HEROPROD.W_ORG_D ACNT
          ON ACNT.ROW_WID = ODIF.ACCNT_WID
  LEFT JOIN HEROPROD.WC_INVOICE_ITEM_F INV
          ON ODIF.ORDER_WID = INV.ORDER_WID and ODIF.PROD_WID = INV.PROD_WID

 WHERE (ORD.ORDER_TYPE = 'Parts Sale Order') /* Filter for parts sale orders */
            AND ORD.ORDER_DT >= '1NOV2019'd /* Filter for orders after November 1, 2019 */
            AND ORG_STATUS = 'Active' /* Filter for active organizations */
AND ORDER_NUM LIKE '3%' /* Filter for order numbers starting with '3' */
            AND CANCELLED_FLG = 'N'; /* Filter for non-cancelled orders */

QUIT;

/* Create a table for child orders */
PROC SQL;

CREATE TABLE CHILD_ORDERS AS
SELECT DISTINCT CHILD_ORDER_NBR
FROM LND_PD_ORDER_DETAIL
WHERE CHILD_ORDER_NBR IS NOT NULL; /* Filter for non-null child order numbers */

QUIT;

/* Update the LND_PD_ORDER_DETAIL table with flags for child and parent orders */
PROC SQL;

CREATE TABLE LND_PD_ORDER_DETAIL AS
SELECT A.*,
/* Flags for child and parent orders based on presence of order numbers */
CASE WHEN PAR_ORDER_NBR IS NOT NULL THEN 1 ELSE 0 END AS CHILD_ORDER_FLAG,
CASE WHEN CHILD_ORDER_NBR IS NOT NULL THEN 1 ELSE 0 END AS PAR_ORDER_FLAG
FROM LND_PD_ORDER_DETAIL A;
/*WHERE CHILD_ORDER_NBR NOT IN (SELECT CHILD_ORDER_NBR FROM CHILD_ORDERS);*/ /* TODO: Uncomment if filtering child orders is needed */

QUIT;

/* Create a report dataset with detailed order information */
DATA comp_lib.RPT_GPC_PD_ORDER_SALE1 (DROP = CHILD_ORDER_NBR);
ATTRIB ORDER_DATE LABEL = 'Order Date';
ATTRIB FSCL_YEAR LABEL = 'Fiscal Year';
ATTRIB FSCL_HALF LABEL = 'Fiscal Half';
ATTRIB FSCL_QTR LABEL = 'Fiscal Quarter';
ATTRIB FSCL_MONTH LABEL = 'Fiscal Month';
ATTRIB ORDER_NBR LABEL = 'Order Number';
ATTRIB DIVISION_ID LABEL = 'Division ID';
ATTRIB DIVISION_NAME LABEL = 'Division Name';
ATTRIB PD_CODE LABEL = 'PD Code';
ATTRIB ORGANIZATION_NAME LABEL = 'PD Name';
ATTRIB ACCOUNT_NBR LABEL = 'Account Number';
ATTRIB RCVR_ACNT_CODE LABEL = 'Account Code';
ATTRIB ACCOUNT_NAME LABEL = 'Account Name';
ATTRIB ACCOUNT_CITY LABEL = 'Account City';
ATTRIB ZONAL_OFFICE LABEL = 'Zonal Office Name';
ATTRIB AREA_OFFICE LABEL = 'Area Office Name';
ATTRIB ORDER_TYPE LABEL = 'Order Type';
ATTRIB STATUS LABEL = 'Order Line Item Status';
ATTRIB CNCLD_FLAG LABEL = 'Cancelled Flag';
ATTRIB CLSD_FLAG LABEL = 'Closed Flag';
ATTRIB INVC_QTY LABEL = 'Invoice Quantity';
ATTRIB ORDER_QTY LABEL = 'Order Quantity';
ATTRIB PART_GRP LABEL = 'Part Group';
ATTRIB SUB_PART_GRP LABEL = 'Sub Part Group';
ATTRIB PART_NBR LABEL = 'Part Number';
ATTRIB PART_DESC LABEL = 'Part Description';
ATTRIB PART_CAT LABEL = 'Part Category';
ATTRIB CURRENT_CAT LABEL = 'Current Non-Current Category';
ATTRIB PART_STATUS LABEL = 'Part Status';
ATTRIB LINE_ITEM_NBR LABEL = 'Line Item Number';
ATTRIB SALE_ORDER_AMT LABEL = 'Sale Order Amount';
ATTRIB INVOICE_VALUE LABEL = 'Invoice Value';
ATTRIB DSCNT_PRCNTG LABEL = 'Discount Percentage';
ATTRIB DSCNT_AMT LABEL = 'Discount Amount';
ATTRIB ORDER_AGE LABEL = 'Order Age';
ATTRIB MONTH_YR LABEL = 'Month Year';
ATTRIB STATUS_DATE LABEL = 'Status Changed Date';
ATTRIB FFR LABEL = 'FFR FLAG';
ATTRIB SUB_ORDER_TYPE LABEL = 'Sub Order Type';
ATTRIB ORDER_CMPLTN_FLAG LABEL = 'Order Completion Flag';
ATTRIB CHILD_ORDER_FLAG LABEL = 'Child Order Flag';
SET LND_PD_ORDER_DETAIL; /* Set the source dataset */
RUN;