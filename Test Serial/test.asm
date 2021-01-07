showMes macro  mes   ; MACROS
mov ah,09
lea dx ,mes
int 21h
endm showMes

showChar macro char
mov ah,2
mov dl,char
int 21h
endm showChar

checkbuffer macro    ;;  al = asci-Coed
mov al,0         ;;  ah = scan-code
mov ah,1
int 16h
endm  checkbuffer

readChar macro  ;;  al = asci-Coed
mov al,0        ;;  ah = scan-code
mov ah,0
int 16h
endm readChar

readStr macro str
mov ah,0ah
mov dx ,offset str
int 21h
endm readStr

setCursor macro x,y,page
mov bh,page
mov dh,x
mov dl,y
mov ah,02
int 10h
endm setCursor

clearScreen macro
mov ax ,0600h
mov bh ,07
mov cx,0
mov dx,184fh
int 10h
endm clearScreen
                 
clearRow macro row
mov ax ,0600h
mov bh ,07

mov cl,0 
mov ch,row 

mov dl,79 
mov dh,row

int 10h
endm clearRow                 
 
changePage macro page
mov ah , 05h
mov al , page
int 10h
endm  changePage


scrolUpper macro 
    mov ah,6  ; function 6
    mov al,1  ; scroll by 1 line
    mov bh,7  ; normal video attribute
    mov ch,0  ; upper left Y
    mov cl,0  ; upper left X
    mov dh,12 ; lower right Y
    mov dl,79 ; lower right X
    int 10h
endm scrolUpper

scrolDown macro 
    mov ah,6  ; function 6
    mov al,1  ; scroll by 1 line
    mov bh,7  ; normal video attribute
    mov ch,13 ; upper left Y
    mov cl,0  ; upper left X
    mov dh,24 ; lower right Y
    mov dl,79 ; lower right X
    int 10h
endm scrolDown
;-----------------------------------------------------
.MODEL SMALL                                                                                                   
.STACK 64        
;------------------------------------------------------                    
.DATA
    mes db 'key is pressed $'
;------------------------------------------------------
.CODE                                                 
MAIN    PROC FAR        
    MOV AX,@DATA    
    MOV DS,AX  
    clearScreen 
    setCursor 0,0,0 

    showMes mes

    call setConfing
    mainScr:
    checkbuffer  
    jnz checkSend
    jmp chkreceive
    ;jmp lp1

    checkSend:  
    readChar
    showChar al 

    ;; check if ready To Send   jnz -> ready to send    jz --> not ready
    lp1: 
        mov dx , 3FDH           ; Line Status Register
        In al , dx              ;Read Line Status
        test al , 00100000b
        jnz sendData
        jmp chkreceive


    sendData:
        mov dx , 3F8H ; Transmit data register
        mov al,1
        out dx , al


    ;Check received Data is Ready       jz -->  not ready   ||  jnz --> ready
    chkreceive: 
        mov dx , 3FDH ; Line Status RegisterCHK: in al , dx
        test al , 1
        JnZ receive        ; Ready
        jmp mainScr

    receive:
        mov dx , 03F8H
        in al , dx
        showChar al
    jmp mainScr

mov ah,4ch
int 21h 
MAIN    ENDP
;-------------------------------------------------

    setConfing proc 
    ; Set Divisor Latch Access Bit
        mov dx,3fbh         ; Line Control Register
        mov al,10000000b    ;Set Divisor Latch Access Bit
        out dx,al           ;Out it
    ;  Set LSB byte of the Baud Rate Divisor Latch register.
        mov dx,3f8h
        mov al,0ch
        out dx,al
    ;  Set MSB byte of the Baud Rate Divisor Latch register.
        mov dx,3f9h
        mov al,00h
        out dx,al
    ;  Set port configuration
        mov dx,3fbh
        mov al,00011011b
        out dx,al
        ret 
    setConfing endp
    END MAIN        ; End of the program  
		
    