.MODEL small
.DATA
     mode db 18 ;640 x 480
     x_center dw 300
     y_center dw 200
     y_value dw 0
     x_value dw 100
     decision dw 1
     colour db 3 ;1=blue
.CODE
start:
 MOV AX, @DATA ;Obtiene que se le asign? a este segmento
 MOV DS, AX ;Esa va a ser el Data segment, por eso se asigna a DS
   
;=============================
 mov ah,00 ;subfunction 0
 mov al,mode ;select mode 18 
 int 10h ;call graphics interrupt
;==========================
 mov bx, x_value
 sub decision, bx


drawcircle:
 mov al,colour ;colour goes in al
 mov ah,0ch

 mov cx, x_value ;Octonant 1  |
 add cx, x_center ;( x_value + x_center,  y_value + y_center)
 mov dx, y_value
 add dx, y_center
 int 10h

 mov cx, x_value ;Octonant 4 |  |
 neg cx
 add cx, x_center ;( -x_value + x_center,  y_value + y_center)
 int 10h

 mov cx, y_value ;Octonant 2 | _|
 add cx, x_center ;( y_value + x_center,  x_value + y_center)
 mov dx, x_value
 add dx, y_center
 int 10h
 
                 ;               
 mov cx, y_value ;Octonant 3 |_ _|
 neg cx
 add cx, x_center ;( -y_value + x_center,  x_value + y_center)
 int 10h

                    ;            |
 mov cx, x_value ;Octonant 7 |_ _|
 add cx, x_center ;( x_value + x_center,  -y_value + y_center)
 mov dx, y_value
 neg dx
 add dx, y_center
 int 10h
 ;                           |   |
 mov cx, x_value ;Octonant 5 |_ _|
 neg cx
 add cx, x_center ;( -x_value + x_center,  -y_value + y_center)
 int 10h
 ;                              _
 ;                           |   |
 mov cx, y_value ;Octonant 8 |_ _|
 add cx, x_center ;( y_value + x_center,  -x_value + y_center)
 mov dx, x_value
 neg dx
 add dx, y_center
 int 10h
                               
 ;                            _ _
 ;                           |   |
 mov cx, y_value ;Octonant 6 |_ _|
 neg cx
 add cx, x_center ;( -y_value + x_center,  -x_value + y_center)
 int 10h
 
 inc y_value

condition1:
mov cx, y_value
 mov ax, 2
 imul cx
 add cx, 1
 inc cx
 add decision, cx
 mov bx, y_value
 mov dx, x_value
 cmp bx, dx
 ja readkey
 jmp drawcircle
;==========================
readkey:
 mov ah,00
 int 16h ;wait for keypress
 
endd:
 mov ah,00 ;again subfunc 0
 mov al,03 ;text mode 3
 int 10h ;call int
 mov ah,04ch
 mov al,00 ;end program normally
 int 21h 

END Start
.STACK
