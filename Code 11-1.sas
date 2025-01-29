PROC SQL;
CREATE TABLE &EM_LIB..SAMPLE_PROPORTION_TRAIN
AS
SELECT
PERIOD
,ZIP_CODE
,COUNT(1) AS OBS
,AVG(%EM_BINARY_TARGET) AS P_EVENT
,SUM(%EM_BINARY_TARGET) AS EVENTS
FROM &EM_IMPORT_DATA
GROUP BY 
1
,2
;
QUIT;

PROC SQL;
CREATE TABLE &EM_LIB..SAMPLE_PROPORTION_VALID
AS
SELECT
PERIOD
,ZIP_CODE
,COUNT(1) AS OBS
,AVG(%EM_BINARY_TARGET) AS P_EVENT
,SUM(%EM_BINARY_TARGET) AS EVENTS
FROM &EM_IMPORT_VALIDATE
GROUP BY 
1
,2
;
QUIT;
