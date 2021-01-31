
EXTRN VALUE1:BYTE
EXTRN VALUE2:BYTE
PUBLIC W
public status
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;::::::::::::::::::::::::::: Here are the helper macros used in the program :::::::::::::::::::::::::
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                             DATA 
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
.MODEL SMALL
.STACK 64
.DATA
value db ?  
status db 0
sendChat    db '-  you sent chat invitaion to .. $'
sendPlay    db '-  you send a playing invitaion to $'

receiveChat db '-  you received chat invitaion from .. $'
receiveChat2 db ' press f1 to accept $'

receivePlay db '-  you received a playing invitaion from .. $'
receivePlay2 db ' press f2 to accept $'

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                             CODE 
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
.CODE

W proc far
     mov ax,@data
     mov ds,ax
mov ah,0
mov value1,ah
mov value2,ah

mov dx,3fbh 			; Line Control Register
mov al,10000000b		;Set Divisor Latch Access Bit
out dx,al

;Set LSB byte of the Baud Rate Divisor Latch register.
mov dx,3f8h			
mov al,0ch			
out dx,al

;Set MSB byte of the Baud Rate Divisor Latch register.
mov dx,3f9h
mov al,00h
out dx,al

;Set port configuration
mov dx,3fbh
mov al,00011011b
out dx,al   
; here is the main loop which will detect the current mode
Send_or_recieve:
		; check if key is pressed 
		mov ah,1    
		int 16h
		; if yes :
		jnz call_send
		; if No
		jz call_recieve

    call_send:

		mov ah,0                       ;read char from keyboard buffer
		int 16h 

		mov value,al 
        mov dx,3FDH 		        ; Line Status Register
		In al , dx 	                ;Read Line Status
		test al , 00100000b         ; if ready for sending
		jz call_recieve             ; Not empty
		mov dx , 3F8H		        ; Transmit data register
		mov al,value        
		out dx , al  
                          
		cmp al,65   ;f1                     ; stop reading if the current char was Enter with ascii code == 0DH
        JZ master_chat 
        cmp al,66   ;f2
        jmp master_game
        cmp al,67   ;escape
        jmp master_escape


master_chat: mov ah,1
mov  value1,ah
    mov ah,09
    lea dx ,sendChat
    int 21h

jmp here

master_game: mov ah,2
mov  value1,ah
    mov ah,09
    lea dx ,sendPlay
    int 21h


jmp here

master_escape: mov ah,4
mov  value1,ah

here:
cmp value2,0
jz call_recieve
CMP VALUE1,0
JZ call_send
jmp labell

	call_recieve:
	mov ah,1                        ;if key is pressed while receiving jmp to sending mode 
	int 16h
	jnz check
    jmp bla

check: cmp value1,0
jz call_send

bla: mov dx , 3FDH		            ; Line Status Register
	in al , dx 
	test al , 1
	JZ call_recieve           


	mov dx , 03F8H
	in al , dx 
	mov value,al              ;check if the recieved data is ESC key exit chat mode
	CMP value,65
	JZ  chat
    cmp value,66
    jz game
    cmp value,67
    jz scape
    jmp call_recieve

temp: call check_2
jmp call_send 
;;;;;;;;;;;  
temp2: jmp call_recieve

;;;;;;;;;;;
chat:
mov ah,1
mov VALUE2,ah
    mov ah,09
    lea dx ,receiveChat
    int 21h

    mov ah,09
    lea dx ,receiveChat2
    int 21h

    JMP labell
game:
mov ah,2
mov VALUE2,ah
    mov ah,09
    lea dx ,receivePlay
    int 21h

    mov ah,09
    lea dx ,receivePlay2
    int 21h


    jmp labell

scape:
mov ah,4
mov VALUE2,ah
jmp labell



labell:
cmp value1,0
jz temp
call check_1
cmp value2,0
jz temp2
ret
W endp
;;;;;;;;;;;
check_1 proc
cmp status,0
jz chn
ret
chn:mov ah,1
mov status,1
ret
check_1 endp

check_2 proc
cmp status,0
jz chn2
ret
chn2:mov ah,2
mov status,2
ret
check_2 endp
;----------------------------------------
END W
