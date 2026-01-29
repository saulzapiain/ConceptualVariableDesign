DATA ABT (DROP=_F _RC)  ;

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
                HH.REPLACE();
                OUTPUT;
                _F = .;
           END;
           ELSE OUTPUT;               
     END;

     DO _RC = HI.FIRST() BY 0 WHILE (_RC = 0);
           IF _F NE 1 THEN DO;
           END;
           _RC = HI.NEXT();
     END;

STOP;
RUN;



