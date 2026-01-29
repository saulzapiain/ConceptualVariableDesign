DATA ABT (DROP=_F _RC)  ;

     RETAIN TIMESTART;
     TIMESTART=DATETIME();

	 IF 0 THEN SET INPUT_TABLE;

     DCL HASH HH (HASHEXP: 16, ORDERED: 'A');
     DCL HITER HI ('HH');
     HH.DEFINEKEY ('SUBJECT_ID');
     HH.DEFINEDATA ('NEW_VARIABLE','_F');
     HH.DEFINEDONE () ;

     DO UNTIL (EOF2);
           SET INPUT_TABLE (KEEP=SUBJECT_ID NEW_VARIABLE) END = EOF2;
           _F = .;
           HH.ADD();
     END;

     DO UNTIL(EOF);
           SET ABT END = EOF;
           CALL MISSING(NEW_VARIABLE);
           IF HH.FIND() = 0 THEN DO;
                _F = 1;
				HITS+1;
                HH.REPLACE();
                OUTPUT;
                _F = .;
           END;
           ELSE OUTPUT;   
        /*____________________________________START_COUNTER__________________________________________________*/           
                 K+1;
                 IF MOD(K,200000)=0 THEN
                       DO;
                            TIMEEND = DATETIME();
                            TIMEDIFF = SUM(TIMEEND, -TIMESTART);
                            ELAPSED =  PUT(TIMEDIFF, TIME8.);
                            START = PUT(TIMESTART,DATETIME16.);
                            END = PUT(TIMEEND,DATETIME16.);
                            COUNTER=PUT(K,COMMA24.);
                            HITSF=PUT(HITS,COMMA24.);
                            RC02 = DOSUBL(CATX(' ','SYSECHO "R:',COUNTER,' H:',HITSF,' E:',ELAPSED,'";'));
                       END;
                 DROP TIMESTART TIMEEND TIMEDIFF ELAPSED START END K COUNTER HITS RC02;  
        /*____________________________________END_COUNTER___________________________________________________*/  
     END;

     DO _RC = HI.FIRST() BY 0 WHILE (_RC = 0);
           IF _F NE 1 THEN DO;
           END;
           _RC = HI.NEXT();
     END;

STOP;
RUN;



