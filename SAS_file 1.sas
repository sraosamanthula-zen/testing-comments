/* 
   This SAS script processes order data from multiple sources and formats it for reporting. 
   It creates a detailed order report by joining various tables, applying formats, and calculating 
   additional fields to meet business requirements for sales and order management analysis.
*/

options compress=yes; /* Enable compression to save space */
libname hero_lib '/sasdata/Hero_Data'; /* Define library for Hero data */
libname comp_lib '/sasdata/Anshu_Data'; /* Define library for Anshu data */

LIBNAME GPCLIB ORACLE PATH=GPCPRD SCHEMA=GPCPRD AUTHDOMAIN="GPCPRD"; /* Connect to Oracle GPCPRD schema */

LIBNAME sapecc SASIOSR3 ashost="10.3.3.4" sysnr=00 language=EN Client=300  
trace=0 BatchMode=0 BUFFER_SIZE=20000000NETWEAVER AUTHDOMAIN="HeroIT SAP ECC"; /* Connect to SAP ECC system */

LIBNAME herotrgt ORACLE PATH=OLAPPROD SCHEMA=SAS_OLAP USER=SAS_OLAP  
PASSWORD="{SAS002}8041A75C0F4262A15ADF53C2495BA193"; /* Connect to Oracle OLAPPROD schema for target */

LIBNAME heroprod ORACLE PATH=OLAPPROD SCHEMA=OLAP USER=SAS_OLAP  
PASSWORD="{SAS002}8041A75C0F4262A15ADF53C2495BA193"; /* Connect to Oracle OLAPPROD schema for production */

/* Define formats for month, half-year, and quarter */
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

PROC SQL;

/* Create a detailed order report with various calculated fields */
CREATE TABLE LND_PD_ORDER_DETAIL AS

SELECT DATEPART(ORDER_DT) AS ORDER_DATE FORMAT = DATE9.,
  /* Concatenate fiscal year with a custom format */
  CAT('FY ',CATX('-',PUT(DD.CAL_YEAR,BEST4.),SUBSTR(PUT((DD.CAL_YEAR+1),BEST4.),3,2))) AS FSCL_YEAR,
  PUT(DD.FSCL_HALF,V_HY.) AS FSCL_HALF, /* Format fiscal half-year */
  PUT(DD.FSCL_QTR,V_QRTR.) AS FSCL_QTR, /* Format fiscal quarter */
  PUT(DD.CAL_MONTH,V_MONTH.) AS FSCL_MONTH, /* Format fiscal month */
  CAT(PUT(DD.CAL_MONTH,V_MONTH.),SUBSTR(PUT(DD.CAL_YEAR,BEST4.),3)) AS MONTH_YR, /* Concatenate month and year */
  ORDER_NUM AS ORDER_NBR,
  SUBSTR (ORDER_NUM,FIND (ORDER_NUM, '-') + 1,2) AS DIVISION_ID, /* Extract division ID from order number */
  SUBSTR (DIVISION_NAME, FIND (DIVISION_NAME, '-') + 2) AS DIVISION_NAME, /* Extract division name */
  SUBSTR (ORDER_NUM,1,FIND (ORDER_NUM, '-') - 1) AS PD_CODE, /* Extract PD code from order number */
  SUBSTR(ORGANIZATION_NAME, FIND (ORGANIZATION_NAME, '-') + 2) AS PD_NAME, /* Extract PD name */
  OU_NUM AS ACCOUNT_NBR,
  ACNT.SAP_CODE AS ACCOUNT_CODE,
  ACNT.NAME AS ACCOUNT_NAME,
  ACNT.CITY AS ACCOUNT_CITY,
  SUBSTR (ZONAL_OFFICE_NAME, 16) AS ZONAL_OFFICE, /* Extract zonal office name */
  SUBSTR (AREA_OFFICE_NAME, 15) AS AREA_OFFICE, /* Extract area office name */
  ODIF.ORDER_TYPE AS ORDER_TYPE,
  ODIF.STATUS_CD AS STATUS,
  ODIF.X_DLP AS RATE,
  DATEPART(ODIF.STATUS_DT) AS STATUS_DATE FORMAT = DATE9., /* Format status date */
  CANCELLED_FLG AS CNCLD_FLAG,
  CLOSED_FLG AS CLSD_FLAG,
  INT(X_TOT_REQ_QTY) AS ORDER_QTY, /* Convert total requested quantity to integer */
  (case when INT(QTY_REQ) < INT(X_TOT_REQ_QTY)
   then (today()-DATEPART(ORDER_DT)) else 0 end) as ORDER_AGE, /* Calculate order age */
  SPG.PG AS PART_GRP,
  SPG.SPG AS SUB_PART_GRP,
  PRD.PART_NUM AS PART_NBR,
  PRD.PROD_NAME AS PART_DESC,
  SPG.ABC AS PART_CAT,
  SPG.CURRENT_NC AS CURRENT_CAT,
  SPG.ACTIVE_INACTIVE AS PART_STATUS,
  INT(ODIF.LN_NUM) AS LINE_ITEM_NBR, /* Convert line number to integer */
  (INT(X_TOT_REQ_QTY) * ODIF.X_DLP) AS SALE_ORDER_AMT, /* Calculate sale order amount */
  X_CHILD_ORDER_NUM AS CHILD_ORDER_NBR,
  X_PAR_ORDER_NUM AS PAR_ORDER_NBR,
  ORD.X_CUST_CATGRY AS CUST_CAT,
  ORD.X_CUST_TYPE AS CUST_TYPE,
  PRD.X_CATEGORY_CD AS PROD_CAT,
  INT(ODIF.DISCNT_PERCENT*100)/100 AS DSCNT_PRCNTG, /* Calculate discount percentage */
  INT(ODIF.DISCNT_AMT*100)/100 AS DSCNT_AMT, /* Calculate discount amount */
  ORD.B2B_SUB_ORDER_TYPE AS SUB_ORDER_TYPE,
  INT(CASE WHEN INV.QTY IS NULL THEN 0 ELSE INV.QTY END) AS INVC_QTY, /* Handle null invoice quantity */
  (INT(CASE WHEN INV.QTY IS NULL THEN 0 ELSE INV.QTY END) * ODIF.X_DLP) AS INVOICE_VALUE /* Calculate invoice value */

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

 WHERE (ORD.ORDER_TYPE = 'Parts Sale Order')
            AND ORD.ORDER_DT >= '1NOV2019'd
            AND ORG_STATUS = 'Active'
AND ORDER_NUM LIKE '3%'
            AND CANCELLED_FLG = 'N';

QUIT;

PROC SQL;

/* Create a table of distinct child orders */
CREATE TABLE CHILD_ORDERS AS
SELECT DISTINCT CHILD_ORDER_NBR
FROM LND_PD_ORDER_DETAIL
WHERE CHILD_ORDER_NBR IS NOT NULL;

QUIT;

PROC SQL;

/* Add flags for child and parent orders */
CREATE TABLE LND_PD_ORDER_DETAIL AS
SELECT A.*,
CASE WHEN PAR_ORDER_NBR IS NOT NULL THEN 1 ELSE 0 END AS CHILD_ORDER_FLAG,
CASE WHEN CHILD_ORDER_NBR IS NOT NULL THEN 1 ELSE 0 END AS PAR_ORDER_FLAG
FROM LND_PD_ORDER_DETAIL A;

QUIT;

DATA comp_lib.RPT_GPC_PD_ORDER_SALE1 (DROP = CHILD_ORDER_NBR);
/* Define attributes for the final report dataset */
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
SET LND_PD_ORDER_DETAIL;
RUN;