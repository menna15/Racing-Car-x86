;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;::::::::::::::::::::::::::: Here are the helper macros used in the program :::::::::::::::::::::::::
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;clear the lower half of the screen 
clear_lower MACRO
   
mov ax,060Ch
mov bh,40h
mov ch,13     
mov cl,0        
mov dh,24    
mov dl,79 
int 10h 
  
ENDM clear_lower
;-----------------------------------------
; clear the upper half of the screen
clear_upper MACRO
   
mov ax,060Dh
mov bh,04h
mov ch,0       
mov cl,0       
mov dh,12    
mov dl,79
int 10h 
ENDM clear_upper 
;-----------------------------------------
;         to set the cursor 
set_cursor MACRO x,y
mov ah,2
mov bh,0
mov dl,x
mov dh,y
int 10h
ENDM set_cursor
;-----------------------------------------
; to save the cursor of in two variables representing x,y for sending mode
save_cursor_sending MACRO 
mov ah,3h
mov bh,0h
int 10h
mov X_sending,dl
mov Y_sending,dh
ENDM save_cursor_sending 
;-----------------------------------------
; to save the cursor of in two variables representing x,y for receiving mode
save_cursor_receiving MACRO 
mov ah,3h
mov bh,0h
int 10h
mov X_receiving,dl
mov Y_receiving,dh
ENDM save_cursor_receiving 
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                             DATA 
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
.MODEL SMALL
.STACK 64
.DATA
 
value db ?           ; used for sending or receiving
X_sending db 0       ; initially 0
Y_sending db 0       ; initially 0
X_receiving db 0     ; initially 0
Y_receiving db 0Dh   ; initially 0Dh == 13 considered form the half part of the screen                                    


;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;                             CODE 
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
.CODE

main proc far
     mov ax,@data
     mov ds,ax


call set_configurations
   ; change to text mode 
   mov ah, 0      
   mov al, 3
   int 10h
   
call split_screenU
call split_screenL

; here is the main loop which will detect the current mode
Send_or_recieve:
		; check if key is pressed 
		mov ah,1    
		int 16h
		; if yes :
		jnz call_send
		; if No
		jz Receive

    call_send:

		mov ah,0                       ;read char from keyboard buffer
		int 16h 

		mov value,al                   ; move the char into value
		cmp al,0DH                     ; stop reading if the current char was Enter with ascii code == 0DH
        jz jump_next_line              ; if yes enter is pressed --> send the sentence and jump to the new line
        jnz Complete                   ; if no, complete reading
;-----------------------------------------
; because of the error of jump out of range 
Receive: jmp call_recieve
;-----------------------------------------
	jump_next_line:
		CMP Y_sending,12               ;check if it is the end of the half screen
		jz  clear_half                 ; if yes clear the upper half
		jnz scroll                     ; if no scroll one line 
        clear_half: clear_upper
		call split_screenU
        mov X_sending,0                
        mov Y_sending,0
        set_cursor X_sending,Y_sending  ;set the cursor manually to 0,0
        jmp display_char
 
        scroll: inc Y_sending    
        mov X_sending,0

    Complete:
		set_cursor X_sending,Y_sending      ;setting the cursor
		CMP X_sending,79                   ; check if it is the end of the line
		JZ Check_y
		jnz display_char

		Check_y:CMP Y_sending,12           ; if reached the end of the half upper screen
		JNZ display_char
		clear_upper
		call split_screenU
		mov X_sending,0                    ;set the cursor manually to 0,0 after clearing the screen
		mov Y_sending,0
		set_cursor X_sending,Y_sending

		jmp display_char               
		
	display_char: mov ah,2          
		mov dl,value
		int 21h

		; sending is done now
		mov dx,3FDH 		        ; Line Status Register
		AGAIN: In al , dx 	        ;Read Line Status
		test al , 00100000b         ; if ready for sending
		jz call_recieve             ; Not empty
		mov dx , 3F8H		        ; Transmit data register
		mov al,value        
		out dx , al                 ; sending the data
		CMP al,27                   ; if ESC == 27 pressed end chat currently 
		JZ end_chat
		save_cursor_sending         ; we need to save the cursor here for later

	jmp Send_or_recieve             ; repeating ...

	end_chat:jmp exit

	recall:jmp call_send

	call_recieve:
	mov ah,1                        ;if key is pressed while receiving jmp to sending mode 
	int 16h
	jnz recall

	mov dx , 3FDH		            ; Line Status Register
	in al , dx 
	test al , 1
	JZ call_recieve           


	mov dx , 03F8H
	in al , dx 
	mov value,al              ;check if the recieved data is ESC key exit chat mode
	CMP value,27
	JZ  end_chat                  ; exit chat 

	CMP value,0Dh             ;check if the key is enter then start displaying on our screen
	JNZ continue              ; if not continue receiving
	JZ jump_new_Line_R        ; if yes  print and jump to the next line


	jump_new_Line_R:
	cmp Y_receiving,24
	JZ Clear_half_R
	jnz Scroll_R
	Clear_half_R: clear_lower
	call split_screenL
	mov X_receiving,0
	mov Y_receiving,0DH
	set_cursor X_receiving,Y_receiving
	jmp Print

	Scroll_R:
	inc Y_receiving
	mov X_receiving,0

	continue:
	set_cursor X_receiving,Y_receiving
	CMP X_receiving,79
	JZ Check_y_R
	jnz Print

	Check_y_R: cmp Y_receiving,24
	jnz Print
	clear_lower
	call split_screenL
	mov X_receiving,0
	mov Y_receiving,0Dh
	set_cursor X_receiving,Y_receiving

	Print:mov ah,2
	mov dl,value
	int 21h

	save_cursor_receiving

	jmp Send_or_recieve

exit:
mov ah, 4ch
int 21h
main endp
;--------------------------
set_configurations proc
; set divisor latch access bit
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
ret
;--------------------------------
;--------------------------------
split_screenU proc

   mov ah,6       ; function 6
   mov al,0       ; scroll by 1 line    
   mov bh,30h     ; normal video attribute         
   mov ch,0       ; upper left Y =0
   mov cl,0       ; upper left X =0
   mov dh,12      ; lower right Y= 12
   mov dl,79      ; lower right X = 79
   int 10h           
ret
split_screenL proc
   ;----------
   mov ah,6        ; function 6
   mov al,0        ; scroll by 1 line    
   mov bh,72h      ; normal video attribute         
   mov ch,13       ; upper left Y = 13
   mov cl,0        ; upper left X = 0
   mov dh,24       ; lower right Y = 24
   mov dl,79       ; lower right X  = 79
   int 10h   
   ret   
;----------------------------------------
END MAIN
