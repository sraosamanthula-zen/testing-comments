/* 
   File Overview:
   This SAS script is designed to manage and analyze order data from multiple sources, including Oracle databases and custom data libraries. 
   It creates formatted reports and tables with detailed order information, including fiscal periods, order statuses, and product details. 
   The script addresses business requirements for tracking parts sale orders, managing child and parent orders, and generating comprehensive reports.
*/

/* Enable compression for datasets */
options compress=yes;

/* Define library references for data sources */
libname hero_lib '/sasdata/Hero_Data';  /* Library for Hero Data */
libname comp_lib '/sasdata/Anshu_Data'; /* Library for Anshu Data */

/* Define Oracle database connections */
LIBNAME GPCLIB ORACLE PATH=GPCPRD SCHEMA=GPCPRD AUTHDOMAIN="GPCPRD"; /* Connection to GPCPRD Oracle database */
LIBNAME sapecc SASIOSR3 ashost="10.3.3.4" sysnr=00 language=EN Client=300  
trace=0 BatchMode=0 BUFFER_SIZE=20000000NETWEAVER AUTHDOMAIN="HeroIT SAP ECC"; /* SAP ECC connection */
LIBNAME herotrgt ORACLE PATH=OLAPPROD SCHEMA=SAS_OLAP USER=SAS_OLAP  
PASSWORD="{SAS002}8041A75C0F4262A15ADF53C2495BA193"; /* Connection to OLAPPROD Oracle database for SAS OLAP */
LIBNAME heroprod ORACLE PATH=OLAPPROD SCHEMA=OLAP USER=SAS_OLAP  
PASSWORD="{SAS002}8041A75C0F4262A15ADF53C2495BA193"; /* Connection to OLAPPROD Oracle database for OLAP */

/* Define custom formats for months, half-years, and quarters */
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
12='Dec'; /* Format for month names */
run;

proc format;
value V_HY
1='HY-1'
2='HY-2'; /* Format for half-year periods */
run;

proc format;
value V_QRTR
1='Q1'
2='Q2'
3='Q3'
4='Q4'; /* Format for quarter periods */
run;

/* 
   Create a table with detailed order information 
   This SQL procedure gathers and formats order data, including fiscal periods, order numbers, and product details.
*/
PROC SQL;
CREATE TABLE LND_PD_ORDER_DETAIL AS
SELECT DATEPART(ORDER_DT) AS ORDER_DATE FORMAT = DATE9., /* Extract and format order date */
  CAT('FY ',CATX('-',PUT(DD.CAL_YEAR,BEST4.),SUBSTR(PUT((DD.CAL_YEAR+1),BEST4.),3,2))) AS FSCL_YEAR, /* Fiscal year calculation */
  PUT(DD.FSCL_HALF,V_HY.) AS FSCL_HALF, /* Fiscal half-year format */
  PUT(DD.FSCL_QTR,V_QRTR.) AS FSCL_QTR, /* Fiscal quarter format */
  PUT(DD.CAL_MONTH,V_MONTH.) AS FSCL_MONTH, /* Fiscal month format */
  CAT(PUT(DD.CAL_MONTH,V_MONTH.),SUBSTR(PUT(DD.CAL_YEAR,BEST4.),3)) AS MONTH_YR, /* Month-Year format */
  ORDER_NUM AS ORDER_NBR, /* Order number */
  SUBSTR (ORDER_NUM,FIND (ORDER_NUM, '-') + 1,2) AS DIVISION_ID, /* Extract division ID from order number */
  SUBSTR (DIVISION_NAME, FIND (DIVISION_NAME, '-') + 2) AS DIVISION_NAME, /* Extract division name */
  SUBSTR (ORDER_NUM,1,FIND (ORDER_NUM, '-') - 1) AS PD_CODE, /* Extract PD code from order number */
  SUBSTR(ORGANIZATION_NAME, FIND (ORGANIZATION_NAME, '-') + 2) AS PD_NAME, /* Extract PD name */
  OU_NUM AS ACCOUNT_NBR, /* Account number */
  ACNT.SAP_CODE AS ACCOUNT_CODE, /* Account SAP code */
  ACNT.NAME AS ACCOUNT_NAME, /* Account name */
  ACNT.CITY AS ACCOUNT_CITY, /* Account city */
  SUBSTR (ZONAL_OFFICE_NAME, 16) AS ZONAL_OFFICE, /* Extract zonal office name */
  SUBSTR (AREA_OFFICE_NAME, 15) AS AREA_OFFICE, /* Extract area office name */
  ODIF.ORDER_TYPE AS ORDER_TYPE, /* Order type */
  ODIF.STATUS_CD AS STATUS, /* Order status code */
  ODIF.X_DLP AS RATE, /* Order rate */
  DATEPART(ODIF.STATUS_DT) AS STATUS_DATE FORMAT = DATE9., /* Extract and format status date */
  CANCELLED_FLG AS CNCLD_FLAG, /* Cancelled flag */
  CLOSED_FLG AS CLSD_FLAG, /* Closed flag */
  INT(X_TOT_REQ_QTY) AS ORDER_QTY, /* Total requested quantity */
  (case when INT(QTY_REQ) < INT(X_TOT_REQ_QTY)
   then (today()-DATEPART(ORDER_DT)) else 0 end) as ORDER_AGE, /* Calculate order age */
  SPG.PG AS PART_GRP, /* Part group */
  SPG.SPG AS SUB_PART_GRP, /* Sub-part group */
  PRD.PART_NUM AS PART_NBR, /* Part number */
  PRD.PROD_NAME AS PART_DESC, /* Part description */
  SPG.ABC AS PART_CAT, /* Part category */
  SPG.CURRENT_NC AS CURRENT_CAT, /* Current non-current category */
  SPG.ACTIVE_INACTIVE AS PART_STATUS, /* Part status */
  INT(ODIF.LN_NUM) AS LINE_ITEM_NBR, /* Line item number */
  (INT(X_TOT_REQ_QTY) * ODIF.X_DLP) AS SALE_ORDER_AMT, /* Sale order amount */
  X_CHILD_ORDER_NUM AS CHILD_ORDER_NBR, /* Child order number */
  X_PAR_ORDER_NUM AS PAR_ORDER_NBR, /* Parent order number */
  ORD.X_CUST_CATGRY AS CUST_CAT, /* Customer category */
  ORD.X_CUST_TYPE AS CUST_TYPE, /* Customer type */
  PRD.X_CATEGORY_CD AS PROD_CAT, /* Product category */
  INT(ODIF.DISCNT_PERCENT*100)/100 AS DSCNT_PRCNTG, /* Discount percentage */
  INT(ODIF.DISCNT_AMT*100)/100 AS DSCNT_AMT, /* Discount amount */
  ORD.B2B_SUB_ORDER_TYPE AS SUB_ORDER_TYPE, /* Sub-order type */
  INT(CASE WHEN INV.QTY IS NULL THEN 0 ELSE INV.QTY END) AS INVC_QTY, /* Invoice quantity */
  (INT(CASE WHEN INV.QTY IS NULL THEN 0 ELSE INV.QTY END) * ODIF.X_DLP) AS INVOICE_VALUE /* Invoice value */
FROM HEROPROD.W_ORDER_D ORD
  LEFT JOIN HEROPROD.W_ORDERITEM_F ODIF
    ON ORD.ROW_WID = ODIF.ORDER_WID /* Join order item data */
  LEFT JOIN HEROPROD.W_INT_ORG_D ORGD
    ON ORGD.ROW_WID = ODIF.X_DIVISION_WID /* Join organization data */
  INNER JOIN HEROPROD.WC_INT_ORG_DH ORGDH
    ON ORGDH.DIVISION_ID = ORGD.INTEGRATION_ID /* Join division data */
  LEFT JOIN HEROPROD.W_PRODUCT_D PRD
    ON ODIF.PROD_WID = PRD.ROW_WID /* Join product data */
  LEFT JOIN HEROPROD.WC_PBO_PART_CAT_MASTER SPG
    ON PRD.PART_NUM = SPG.PART_NUM /* Join part category data */
  LEFT JOIN HEROPROD.W_DAY_D DD
    ON ODIF.ORDER_DT_WID = DD.ROW_WID /* Join day data */
  LEFT JOIN HEROPROD.W_ORG_D ACNT
    ON ACNT.ROW_WID = ODIF.ACCNT_WID /* Join account data */
  LEFT JOIN HEROPROD.WC_INVOICE_ITEM_F INV
    ON ODIF.ORDER_WID = INV.ORDER_WID and ODIF.PROD_WID = INV.PROD_WID /* Join invoice data */
WHERE (ORD.ORDER_TYPE = 'Parts Sale Order') /* Filter for parts sale orders */
  AND ORD.ORDER_DT >= '1NOV2019'd /* Filter for orders from November 2019 */
  AND ORG_STATUS = 'Active' /* Filter for active organizations */
  AND ORDER_NUM LIKE '3%' /* Filter for order numbers starting with 3 */
  AND CANCELLED_FLG = 'N'; /* Filter for non-cancelled orders */
QUIT;

/* 
   Create a table of distinct child orders 
   This SQL procedure extracts unique child order numbers from the detailed order table.
*/
PROC SQL;
CREATE TABLE CHILD_ORDERS AS
SELECT DISTINCT CHILD_ORDER_NBR
FROM LND_PD_ORDER_DETAIL
WHERE CHILD_ORDER_NBR IS NOT NULL; /* Filter for non-null child order numbers */
QUIT;

/* 
   Update the order detail table with flags for child and parent orders 
   This SQL procedure adds flags to indicate whether an order is a child or parent order.
*/
PROC SQL;
CREATE TABLE LND_PD_ORDER_DETAIL AS
SELECT A.*,
CASE WHEN PAR_ORDER_NBR IS NOT NULL THEN 1 ELSE 0 END AS CHILD_ORDER_FLAG, /* Flag for child orders */
CASE WHEN CHILD_ORDER_NBR IS NOT NULL THEN 1 ELSE 0 END AS PAR_ORDER_FLAG /* Flag for parent orders */
FROM LND_PD_ORDER_DETAIL A;
QUIT;

/* 
   Create a report dataset with labeled attributes 
   This DATA step prepares a report dataset with labeled attributes for easy interpretation.
*/
DATA comp_lib.RPT_GPC_PD_ORDER_SALE1 (DROP = CHILD_ORDER_NBR); /* Drop child order number from report */
ATTRIB ORDER_DATE LABEL = 'Order Date'; /* Label for order date */
ATTRIB FSCL_YEAR LABEL = 'Fiscal Year'; /* Label for fiscal year */
ATTRIB FSCL_HALF LABEL = 'Fiscal Half'; /* Label for fiscal half */
ATTRIB FSCL_QTR LABEL = 'Fiscal Quarter'; /* Label for fiscal quarter */
ATTRIB FSCL_MONTH LABEL = 'Fiscal Month'; /* Label for fiscal month */
ATTRIB ORDER_NBR LABEL = 'Order Number'; /* Label for order number */
ATTRIB DIVISION_ID LABEL = 'Division ID'; /* Label for division ID */
ATTRIB DIVISION_NAME LABEL = 'Division Name'; /* Label for division name */
ATTRIB PD_CODE LABEL = 'PD Code'; /* Label for PD code */
ATTRIB ORGANIZATION_NAME LABEL = 'PD Name'; /* Label for PD name */
ATTRIB ACCOUNT_NBR LABEL = 'Account Number'; /* Label for account number */
ATTRIB RCVR_ACNT_CODE LABEL = 'Account Code'; /* Label for account code */
ATTRIB ACCOUNT_NAME LABEL = 'Account Name'; /* Label for account name */
ATTRIB ACCOUNT_CITY LABEL = 'Account City'; /* Label for account city */
ATTRIB ZONAL_OFFICE LABEL = 'Zonal Office Name'; /* Label for zonal office name */
ATTRIB AREA_OFFICE LABEL = 'Area Office Name'; /* Label for area office name */
ATTRIB ORDER_TYPE LABEL = 'Order Type'; /* Label for order type */
ATTRIB STATUS LABEL = 'Order Line Item Status'; /* Label for order line item status */
ATTRIB CNCLD_FLAG LABEL = 'Cancelled Flag'; /* Label for cancelled flag */
ATTRIB CLSD_FLAG LABEL = 'Closed Flag'; /* Label for closed flag */
ATTRIB INVC_QTY LABEL = 'Invoice Quantity'; /* Label for invoice quantity */
ATTRIB ORDER_QTY LABEL = 'Order Quantity'; /* Label for order quantity */
ATTRIB PART_GRP LABEL = 'Part Group'; /* Label for part group */
ATTRIB SUB_PART_GRP LABEL = 'Sub Part Group'; /* Label for sub-part group */
ATTRIB PART_NBR LABEL = 'Part Number'; /* Label for part number */
ATTRIB PART_DESC LABEL = 'Part Description'; /* Label for part description */
ATTRIB PART_CAT LABEL = 'Part Category'; /* Label for part category */
ATTRIB CURRENT_CAT LABEL = 'Current Non-Current Category'; /* Label for current non-current category */
ATTRIB PART_STATUS LABEL = 'Part Status'; /* Label for part status */
ATTRIB LINE_ITEM_NBR LABEL = 'Line Item Number'; /* Label for line item number */
ATTRIB SALE_ORDER_AMT LABEL = 'Sale Order Amount'; /* Label for sale order amount */
ATTRIB INVOICE_VALUE LABEL = 'Invoice Value'; /* Label for invoice value */
ATTRIB DSCNT_PRCNTG LABEL = 'Discount Percentage'; /* Label for discount percentage */
ATTRIB DSCNT_AMT LABEL = 'Discount Amount'; /* Label for discount amount */
ATTRIB ORDER_AGE LABEL = 'Order Age'; /* Label for order age */
ATTRIB MONTH_YR LABEL = 'Month Year'; /* Label for month year */
ATTRIB STATUS_DATE LABEL = 'Status Changed Date'; /* Label for status changed date */
ATTRIB FFR LABEL = 'FFR FLAG'; /* Label for FFR flag */
ATTRIB SUB_ORDER_TYPE LABEL = 'Sub Order Type'; /* Label for sub-order type */
ATTRIB ORDER_CMPLTN_FLAG LABEL = 'Order Completion Flag'; /* Label for order completion flag */
ATTRIB CHILD_ORDER_FLAG LABEL = 'Child Order Flag'; /* Label for child order flag */
SET LND_PD_ORDER_DETAIL; /* Set data from detailed order table */
RUN;