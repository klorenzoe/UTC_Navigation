.MODEL Small
.DATA
    ;Declarar mensajes
    ;Mensajes del menu
    instructions DB 'Ingrese el numero de la opcion que desee: $'
    option1 DB '1. consultar la hora del sistema $'
    option2 DB '2. consultar hora con UTC especifico $'
    option3 DB '3. husos horarios almacenados $'
    notFount DB 'no se encontro la opcion $'
    dayModifiable DB ?
    dayNameModificableH DB ?
    dayNameModificableL DB ?
    dayNameNumber DB 0 ; 0. domingo.......... 7.Sabado
    monthModifiable DB ?
    yearModifiable DB ?
    yearModifiableL DB ?
    yearModifiableH DB ?
    hourModifiable DB ?
    minuteModifiable DB ?
    secondModifiable DB ?
    ;Mensajes auxiliares
    entryUTC DB 'Ingrese UTC: $'
    chooseUTCSaved DB 'Ingrese el numero de el huso a consultar: $'
    india DB '1. India UTC-5:30$'
    alemania DB '2. Alemania UTC+1$'
    costaEsteEU DB '3. Costa este de los Estados Unidos UTC-4$'
    argentina DB '4. Argentina UTC-3$'
    japon DB '5. Japon UTC+9$'
    custonUTC DB 'UTC custom $'
    exit DB '6. Salir de este menu $'

    debugg DB 'debugg $'

    ;Variables UTC
    SignUTC DB 0
    UnitUTC DB 0
    TensUTC DB 0
    UTCMovement DB ?

    ;Constantes días de la semana
    day DB      ?
    daySet DB      ' SUNDAY $  ',  ' MONDAY $ '
            DB      '   TUESDAY $  ',  '  WEDNESDAY $ '
            DB      ' THURSDAY $  ',  ' FRIDAY $ '
            DB      ' SATURDAY $  '
    
    ;Variables auxiliares
    aux DB ?
    auxCount DB 0
    returnLabelCode DB 0 ;1. ShowOptionUTCTimesSaved, 2. PrintAndGotoMenu 3. ShowSpecificTimeUTC 4. PrintAndGotoMenuMain
    ; CR Equ 0DH
    ; LF Equ 0AH
    ; NL Equ 00H
    ; MsgX db 32H Dup (0)
.CODE
Program:
;Obtiene los valores del segmento de datos var1 y var2
    MOV AX, @DATA ;Obtiene que se le asign? a este segmento
    MOV DS, AX ;Esa va a ser el Data segment, por eso se asigna a DS

Menu:
;Imprimir el menu
    ;CALL ClearScreen
    CALL PrintEnter
    CALL ClearValues
    MOV DX, offset instructions
    CALL PrintString ;Imprimo las instrucciones
    MOV DX, offset option1 ;imprimo la opción 1
    CALL PrintString
    MOV DX, offset option2 ;imprimo la opción 2
    CALL PrintString
    MOV DX, offset option3 ;imprimo la opción 3
    CALL PrintString
        
 ;Leer la respuesta del menú        
    CALL ReadDigit

    ;swith que busque que opción fue elegida
    ;OPTION 1
    CMP AL, 1d
    JE ShowSystemTime ;si escogió la opción uno, salta a este
    ;OPTION 2
    CMP AL, 2d
    JE  InitializeUTC2 
    ;OPTION 3
    CMP AL, 3d
    JE InitializeUTC
    ;OPTION DEFAULT
    JMP NotFoundOption

;*************************Etiquetas de acciones del menú **************************
;OPTION 1
ShowSystemTime:
  CALL PrintCurrentTime
JMP Menu

;OPTION 2
InitializeUTC2:
    MOV returnLabelCode, 3d
    JMP Add6ToGTQSystemUTC

ShowSpecificTimeUTC:
    MOV returnLabelCode, 4d
    CALL GetUTCConditions
    CMP SignUTC, '-'
    JE JmpIfNegative
    CMP SignUTC, '+'
    JE JmpIfPositive

JmpIfNegative:
    CALL SubstractUTCValue
JmpIfPositive:
    CALL AddUTCValue
;OPTION3
InitializeUTC:
    MOV returnLabelCode, 1d
    JMP Add6ToGTQSystemUTC

ShowOptionUTCTimesSaved:
    CALL SubMenuUTCSaved ;La opcion esta guardada en AL
    MOV returnLabelCode, 2d
    MOV aux, AL
    CALL PrintEnter
    MOV AL, aux
    ;Option 3.1 India
    CMP AL, 1d
    JE IndiaTime ;si escogió la opción uno, salta a este
    ;Option 3.2 Alemania
    CMP AL, 2d
    JE AlemaniaTime
    ;Option 3.3 Costa este de los EU
    CMP AL, 3d
    JE  CostaTime
    ;Option 3.4 Argentina
    CMP AL, 4d
    JE  ArgentinaTime
    ;Option 3.5 Japon
    CMP AL, 5d
    JE  JaponTime
    ;Option 3.6 Exit
    CMP AL, 6d
    JE ExitSubmenu
    ;OPTION DEFAULT
JMP NotFoundOption

EndCalculateDateAux:
    CMP returnLabelCode, 1d
    JE ShowOptionUTCTimesSaved
    CMP returnLabelCode, 2d
    JE PrintAndGotoMenu
    CMP returnLabelCode, 3d
    JE ShowSpecificTimeUTC
    CMP returnLabelCode, 4d
    JE PrintAndGotoMenuMAIN

;**** Submenu de husos
IndiaTime: ;UTC-5:30
    JMP InitializeUTC
AlemaniaTime: ;UTC+1
    MOV UTCMovement, 1d
    CALL AddUTCValue
    JMP InitializeUTC
CostaTime: ;UTC-4
    MOV UTCMovement, 4d
    CALL SubstractUTCValue
    JMP InitializeUTC
ArgentinaTime: ;UTC-3
    MOV UTCMovement, 3d
    CALL SubstractUTCValue
    JMP InitializeUTC
JaponTime: ;UTC+9
    MOV UTCMovement, 9d
    CALL AddUTCValue
    JMP InitializeUTC
ExitSubmenu:
JMP Menu


PrintAndGotoMenuMAIN PROC NEAR
    CALL PrintModifiableDate
    CALL ReadDigit
    JMP Menu
    RET
    PrintAndGotoMenuMAIN ENDP

;-->PrintResult&GotoMenu
PrintAndGotoMenu PROC NEAR
    CALL PrintModifiableDate
    CALL ReadDigit
    JMP ShowOptionUTCTimesSaved
    RET
    PrintAndGotoMenu ENDP
;**** End Submenu de husos

;OPTION DEFAULT
NotFoundOption:
    MOV DX, offset notFount
    CALL PrintString
    CALL ReadDigit
JMP Menu


;Procedimientos para los calculos del UTC °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

AddDay PROC NEAR
;Cambio el valor del string del nombre
    CALL AddDayToNameString
;Cambio el valor de la hora
    MOV AL, hourModifiable
    ADD AL, UTCMovement
    SUB AL, 24d
    MOV hourModifiable, AL

;Evaluo las condiciones del dia
    CMP dayModifiable, 28d
    JE CaseFebraryOnInc ;Incrementar un día de febrero, evaluar si es momento de pasarse a marzo
    CMP dayModifiable, 30d
    JE CaseMoth30DaysOnInc ;Incrementar el mes, solo si el mes no tiene más de 30 días
    CMP dayModifiable, 31d
    JE CaseMoth31DaysOnInc ;Es necesario incrementar un mes cuando ya hay 31 días
    ;si no entro en alguno de los casos anteriores, se suma un día simple
    ADD dayModifiable, 1d
    JMP EndCalculateDate
    RET ;Nunca llegará a este punto
    AddDay ENDP

AddMonth:
    MOV dayModifiable, 1d
    CMP monthModifiable, 12d
    JE CaseChangeYear ;Si es el mes de diciembre y se necesita aumentar un mes, entonces, se aumenta el año
    ;De lo contrario solo se suma al mes
    ADD monthModifiable, 1d
    JMP EndCalculateDate

CaseChangeYear:
    MOV monthModifiable, 1d
    ADD yearModifiable, 1d
    JMP EndCalculateDate

CaseFebraryOnInc:
    CMP monthModifiable, 2d
    JE AddMonth ;si es febrero salta al siguiente mes
    ADD dayModifiable, 1d ;si no, suma uno al día
    JMP EndCalculateDate

CaseMoth30DaysOnInc:
    CMP monthModifiable, 4d
    JE AddMonth ;si es abril, cambia de mes, porque no tiene 31 días
    CMP monthModifiable, 6d
    JE AddMonth ;si es junio, cambia de mes, porque no tiene 31 días
    CMP monthModifiable, 9d
    JE AddMonth ;si es septiembre, cambia de mes, porque no tiene 31 días
    CMP monthModifiable, 11d
    JE AddMonth ;si es noviembre, cambia de mes, porque no tiene 31 días
    ADD dayModifiable, 1d ;si no, suma uno al día
    JMP EndCalculateDate

CaseMoth31DaysOnInc:
    JE AddMonth
    JMP EndCalculateDate

SubDay PROC NEAR
    ;restar un dia al string del nombre
    CALL SubDayToNameString

    ;Cambio el valor de la hora
    MOV AL, hourModifiable ;AL contiene la hora del sistema
    MOV BL, UTCMovement
    MOV aux, BL ;aux contiene el utc requerido
    SUB aux, AL ;Aux almacena el resultado de la resta
    MOV BL, 24d
    SUB BL, aux
    MOV hourModifiable, BL ;ahora la hora esta restada

    ;Modificar el día
    CMP dayModifiable, 1d
    JE CaseDecMoth ;si es el primer día del mes, y le quiero restar un día, se tiene que cambiar de mes y ver que día es
    ;Si es cualquier otro día, solo se resta un día
    SUB dayModifiable, 1d
    JMP EndCalculateDate
    RET ;Nunca llegará a este punto
    subDay ENDP

SubMothTo31Days: ;Resta un mes y deja el día en 31
    MOV dayModifiable, 31d
    ;si es enero y reduce a diciembre, es necesario restar un año
    CMP monthModifiable, 1d
    JE CaseDecYear
    ;si es cualquier otro mes, solo se resta uno
    SUB monthModifiable, 1d
    JMP EndCalculateDate

SubMothTo30Days: ;Resta un mes y deja el día en 30
    MOV dayModifiable, 30d
    SUB monthModifiable, 1d
    JMP EndCalculateDate
SubMothTo28Days: ;Resta un mes y deja el día en 28
    MOV dayModifiable, 28d
    SUB monthModifiable, 1d
    JMP EndCalculateDate

CaseDecYear:
    MOV monthModifiable, 1d
    SUB yearModifiable, 1d
    JMP EndCalculateDate
CaseDecMoth:
    ;Dec to month of 31 days
    CMP monthModifiable, 01d
    JE SubMothTo31Days ;Si es enero, pasa a diciembre, que tiene 31 dias
    CMP monthModifiable, 02d
    JE SubMothTo31Days ;Si es febrero, pasa a enero que tiene 31 dias
    CMP monthModifiable, 04d
    JE SubMothTo31Days ;Si es abril pasa a marzo que tiene 31 dias
    CMP monthModifiable, 06d
    JE SubMothTo31Days ;Si es junio pasa a mayo que tiene 31 dias
    CMP monthModifiable, 08d
    JE SubMothTo31Days ;Si es agosto pasa julio que tiene 31 dias
    CMP monthModifiable, 09d
    JE SubMothTo31Days ;Si es septiembre pasa a agosto que tiene 31 dias
    CMP monthModifiable, 11d
    JE SubMothTo31Days ;Si es noviembre pasa a octubre que tiene 31 dias
    ;Dec to month of 30 days
    CMP monthModifiable, 5d
    JE  SubMothTo30Days ;Si es mayo, reduce a abril que tiene 30 dias
    CMP monthModifiable, 7d
    JE  SubMothTo30Days ;Si es julio, reduce a junio que tien 30 dias
    CMP monthModifiable, 10d
    JE  SubMothTo30Days ;Si es octubre, reduce a septiembre que tiene 30 dias
    CMP monthModifiable, 12d
    JE  SubMothTo30Days ;Si es diciembre, reduce a noviembre que tiene 30 dias
    ;Dec to moth of 28 days
    JMP SubMothTo28Days


EndCalculateDate:
;Este método salta a la posición donde fue llamado, segun el código de la labelCode
    JMP EndCalculateDateAux ;Tuve que declarar un salto extra porque daba error de fuera de rango 

; Este metodo suma cualquier UTC, es necesario
; que el corrimiento se encuentren en la variables UTCMovement
AddUTCValue PROC NEAR
    CALL SaveCurrentTimeOnModifiableVariables ;obtener la información del sistema
    CALL PrintModifiableDate

    CALL ClearValues
    MOV AL, hourModifiable ;AL tiene la hora guardada
    MOV BL, UTCMovement
    MOV aux, BL ;Aux tiene la hora que hay que sumar

    ADD aux, AL
    CMP aux, 23d ;Si se pasa de 23 es necesario sumar un día
    JG AddDayAux ;Fue necesario crear un aux porque daba fuera de rango
    
    ;Si no, solo suma
    ADD hourModifiable, BL

    JMP EndCalculateDate
    RET
    AddUTCValue ENDP

; Este metodo resta cualquier corrimiento utc, es necesario
; que el corrimiento se guarde en UTCMovement
SubstractUTCValue PROC NEAR
    CALL SaveCurrentTimeOnModifiableVariables ;obtener la información del sistema
    CALL PrintModifiableDate
    CALL ClearValues
    MOV AL, hourModifiable ; En AL se encuentra la hora
    MOV BL, UTCMovement
    MOV aux, BL ;En aux se encuentra el corrimiento

    SUB AL, Aux
    CMP AL, 0
    JL subDayAux ;Si la resta es menor a cero es necesario cambiar un dia

    ;Si no, solo se resta la cantidad normalmente
    SUB hourModifiable, BL
    JMP EndCalculateDate
    RET
    SubstractUTCValue ENDP

;END Procedimientos para los calculos del UTC °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

;Métodos auxiliares<.................................................................
;procedimientos para optimizar saltos
addDayAux:
    JMP AddDay
subDayAux:
    JMP subDay

PrintCurrentTime PROC NEAR
    CALL ReadDigit
    CALL ClearValues
    CALL SaveCurrentTimeOnModifiableVariables
    CALL PrintModifiableDate
    RET
    PrintCurrentTime ENDP

GetUTCConditions PROC NEAR 
    CALL ReadDigit
    CALL ClearValues
    ;Pedir un UTC específico
    MOV DX, offset entryUTC
    CALL PrintString
    ;Leer la respuesta del usuario
    CALL ReadCharacter ;U
    CALL ReadCharacter ;T
    CALL ReadCharacter ;C
    CALL ReadCharacter ; - or +
    MOV SignUTC, AL
    CALL ReadDigit ; 0
    MOV TensUTC, AL
    CALL ReadDigit ; 6
    MOV UnitUTC, AL
    ;Almacenar el numero completo en UTCMovement
    MOV AL, 10d
    MUL TensUTC
    ADD AL, UnitUTC
    MOV UTCMovement, AL
    CALL PrintEnter
    RET
    GetUTCConditions ENDP

SubMenuUTCSaved PROC NEAR
    CALL PrintEnter
    MOV DX, offset chooseUTCSaved
    CALL PrintString
    MOV DX, offset India
    CALL PrintString
    MOV DX, offset alemania
    CALL PrintString
    MOV DX, offset costaEsteEU
    CALL PrintString
    MOV DX, offset argentina
    CALL PrintString
    MOV DX, offset japon
    CALL PrintString
    MOV DX, offset exit
    CALL PrintString
    CALL ReadDigit
    RET 
    SubMenuUTCSaved ENDP

PrintModifiableDate PROC NEAR
    ;date
    CALL ClearValues
    MOV AL, dayModifiable
    CALL DisplayNumber
    MOV DL, '-'
    CALL PrintDL
    MOV AL, monthModifiable
    CALL DisplayNumber
    MOV DL, '-'
    CALL PrintDL
    MOV DL, yearModifiableH
    CALL PrintDigit ;Imprimir primer digito del año

    MOV DL, yearModifiableL
    CALL PrintDigit ;imprimir segundo dígito del año

    ;Time
    MOV DL, ','
    CALL PrintDL
    MOV AL, hourModifiable
    CALL DisplayNumber
    MOV DL, ':'
    CALL PrintDL
    MOV AL, minuteModifiable
    CALL DisplayNumber
    MOV DL, ':'
    CALL PrintDL
    MOV AL, secondModifiable
    CALL DisplayNumber
    
    ;Day on letters
    MOV DL, ','
    CALL PrintDL
    MOV DL, dayNameModificableL
    MOV DH, dayNameModificableH
    CALL PrintString
    RET
    PrintModifiableDate ENDP
 

SaveCurrentTimeOnModifiableVariables PROC NEAR
    ;Read system date
    MOV AH, 2AH 
    INT 21h ;interrupción para traer la fecha del sistema
    MOV dayModifiable, DL ;Guardar el día
    MOV monthModifiable, DH ;Guardar el mes

    MOV AX, CX
    ADD AX, 0F830H
    AAM
    MOV yearModifiableH, AH ;Guardar el año
    MOV yearModifiableL,  AL

    MOV AL, 10d
    MUL yearModifiableH
    MOV yearModifiable, AL
    MOV AL, yearModifiableL
    ADD yearModifiable, AL ;guardo todo el numero en yearmodifiable

    CALL ClearValues
    ;Read system time
    MOV AH, 2CH
    INT 21h ;Interrupcion
    MOV aux, DL
    MOV hourModifiable, CH ;Guardar horas
    MOV minuteModifiable, CL ;Guardar minutos
    MOV CL, aux
    MOV secondModifiable, CL ;Guardar segundos
    CALL ClearValues

    ;Interrupcion que trae al día
    MOV     AX,0600H
    MOV     AH,2AH
    INT     21H ;El dia esta en AL
    MOV dayNameNumber, AL
    CALL GetWeekDayNameString
    MOV dayNameModificableH, DH
    MOV dayNameModificableL, DL ;Guardo el nombre
    RET
    SaveCurrentTimeOnModifiableVariables ENDP

AddDayAux2:
    JMP AddDayAux
    
Add6ToGTQSystemUTC PROC NEAR
    CALL SaveCurrentTimeOnModifiableVariables ;obtener la información del sistema
    CALL ClearValues
    MOV AL, hourModifiable
    MOV aux, 6d
    MOV UTCMovement, 6d
    ADD aux, AL
    CMP aux, 23d
    JG AddDayAux2 ;Fue necesario crear un aux porque daba fuera de rango
    ADD hourModifiable, 6d
    JMP EndCalculateDate
    RET ;nunca llega a este punto
    Add6ToGTQSystemUTC ENDP

;procedimientos genericos
PrintString PROC NEAR
    ;Es necesario tener el registro en DX
    XOR AX, AX
    MOV AH, 09H
    INT 21H
    CALL PrintEnter
    RET
    PrintString ENDP
 
 PrintDigit PROC NEAR
    ;Es necesario tener el registro en DL
    XOR AX, AX
    ADD DL, 30h
    MOV AH, 02H
    INT 21H
    RET
PrintDigit ENDP

PrintDL PROC NEAR
    ;Es necesario tener el registro en DL
    XOR AX, AX
    MOV AH, 02H
    INT 21H
    RET
    PrintDL ENDP
 
ReadDigit PROC NEAR
    ;El numero se encontrara en AL
    XOR AX, AX
    MOV AH, 01h
    INT 21h
    SUB AL, 30h
    RET
    ReadDigit ENDP

ReadCharacter PROC NEAR
    ;El numero se encontrara en AL
    XOR AX, AX
    MOV AH, 01h
    INT 21h
    RET
    ReadCharacter ENDP

ClearValues PROC NEAR
    XOR AX, AX
    XOR BX, BX
    XOR DX, DX
    XOR CX, CX
    RET    
    ClearValues ENDP

PrintEnter PROC NEAR
    MOV DL, 10
    MOV AH, 02h
    INT 21h
    MOV DL, 13
    MOV AH, 02h
    INT 21h
    RET
    PrintEnter ENDP

DisplayNumber PROC NEAR
    AAM
    ADD AX, 3030H
    MOV BX, AX
    MOV DL, AH
    MOV AH, 2
    INT 21h
    MOV DL, BL
    MOV AH, 2
    INT 21h
    RET
    DisplayNumber ENDP

;begin: Metodos para encontrar el día de la semana
GetWeekDayNameString PROC NEAR
    ;Necesita que el número de día este en AL
    ;Se almacena en DX
    MOV AL, dayNameNumber
    MOV     day,DL ;Ingresa el día del mes a esta variable
    MOV     BL, 12d
    MUL     BL ;Multiplica 12 por el día de la semana
    LEA     DX,daySet 
    ADD     DX,AX
    RET
    GetWeekDayNameString ENDP

AddDayToNameString PROC NEAR
    CMP dayNameNumber, 7d
    JE CaseSaturday7
    ;Si no, solo sumar un dia
    ADD dayNameNumber, 1d
    returnAdd:
    CALL WhenSumDayActualiceHL
    RET
    AddDayToNameString ENDP

SubDayToNameString PROC NEAR
    CMP dayNameNumber, 0d
    JE CaseSunday0
    ;Si no, solo restar un dia
    SUB dayNameNumber, 1d
    returnSub:
    CALL WhenSumDayActualiceHL
    RET
    SubDayToNameString ENDP

CaseSunday0:
    MOV dayNameNumber, 7d
    JMP returnAdd
CaseSaturday7:
    MOV dayNameNumber, 0d
    JMP returnSub
; PrintWeekDay PROC NEAR
;     MOV  BL, 12d
;     MUL     BL
;     LEA     DX,daySet
;     ADD     DX,AX
;     MOV     AH,09H
;     INT     21H
;     RET
;     PrintWeekDay ENDP
;End métodos para encontrar los días de la semana

; ClearScreen PROC NEAR
;    mov ax,0b800h
;    mov es,ax
;    mov di,0
;    mov al,' '
;    mov ah,07d
;    loop_clear_12:
;         mov word ptr es:[di],ax
;         inc di
;         inc di
;         cmp di,4000
;         jle loop_clear_12
;         ret
; ClearScreen ENDP

WhenSumDayActualiceHL PROC NEAR
    CALL ClearValues
    CALL GetWeekDayNameString
    MOV dayNameModificableH, DH
    MOV dayNameModificableL, DL ;Guardo el nombre
    RET
    WhenSumDayActualiceHL ENDP

DEBUG PROC NEAR
    MOV DX, OFFSET debugg
    CALL PrintString
    RET
DEBUG ENDP
;.........................................................
EndProgram:
    MOV AH, 4ch ;Asigno a AH la interrupci?n que permite terminar la anterior interrupci?n
    INT 21H ;Ejecutamos
.STACK
END Program