;*
;* LFNToSFN
;* Developer: EvolSoft
;* Website: http://www.evolsoft.tk
;* Date: 03/01/2016 03:12 PM (UTC)
;* Edit and use this code as you like in your OS
;*

org 100h

mov ah, 0ah
mov dx, input
int 21h

mov bx, dx
mov si, dx
add bl, BYTE [si + 1]
add bx, 2
mov BYTE [bx], '$'

mov ah, 09h
mov dx, back
int 21h

mov ax, input
add ax, 2
mov si, ax


; Input -> Short File Name (SFN)
; (Moving input memory content to freemem to keep the original content of input)
; 1. Convert to UPPERCASE
; 2. Replace not supported characters in SFN with "_"
; 3. Trim input

cmp BYTE [si], '.'
mov al, 1
mov di, freemem
mov al, 0						; ~n Required? (0 = No, 1 = Yes)
mov bh, 0 						; Char Counter

; Convert to UPPERCASE (1) and replace not supported characters (2)
SFNLoop:						; Input to SFN (char by char)
mov ah, BYTE [si]
mov BYTE [di], ah
cmp BYTE [si], 5Ah
jg ToUPPER
cmp BYTE [si], 2Ch
je SFNreplaceNotSupportedE
cmp BYTE [si], 0
je exitSFN
inc si
inc di
inc bh
jmp SFNLoop

ToUPPER:						; Convert to UPPERCASE function
sub BYTE [di], 20h
inc si
inc di
inc bh
jmp SFNLoop


SFNreplaceNotSupportedE:		; Replace a character not supported with "_"
mov BYTE [di], 5Fh
inc di
inc si
inc bh
mov al, 1
jmp SFNLoop

exitSFN:						; Exit SFN Loop
dec di							; DI - 1 because last DI char is 0x00
mov WORD [trimbkp], di			; Store DI (no push for interrupt use)
mov di, freemem
call TrimString
mov di, WORD [trimbkp]			; Restore DI
call iTrimString
cmp bh, 11
jg SFNSetN
jmp SFNNext 

TrimString:						; Trim String (Left to Right)
cmp BYTE [di], 20h
jne TrimString.end
inc di
dec bh 							; Remove spaces from input length
inc BYTE [trimpos]
jmp TrimString
TrimString.end:
ret

iTrimString:						; Inverse Trim String (Right to Left) (Move DI to last no space character)
cmp BYTE [di-1], 20h
jne iTrimString.end
dec di
jmp iTrimString
iTrimString.end:
ret

SFNSetN:						; Set ~n function
mov al, 1

SFNNext:						; Check ~n flag (AL)
mov dx, 0
mov cx, 1
cmp al, 1
je SFNNumLoop
jmp SFNNext2

SFNNumLoop:						; Write ~n function
mov BYTE [di-2], '~'
mov dx, cx
add dh, 30h
add dl, 30h
mov BYTE [di-1], dl
mov BYTE [di], 0
mov ah, 4eh
mov dx, freemem
add dl, BYTE [trimpos]
push cx
mov cx, 10h
int 21h
pop cx
inc cx
jnc SFNNumLoop
jmp SFNNext2

SFNNext2:						; Print SFN
mov BYTE [si], '$'
mov BYTE [di], '$'

mov ah, 09h
mov dx, input
add dx, 2
int 21h

mov ah, 09h
mov dx, sfn
add dx, 2
int 21h

mov ah, 09h
mov dx, freemem
add dl, BYTE [trimpos]
int 21h

mov ah, 09h
mov dx, testx
int 21h


mov ax, 4c00h
int 21h

back: db 0x0A, 0x0D, "Input: $"
input: db 0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
sfn: db 0x0A, 0x0D, 0x0A, "SFN: $"
lfn: db 0x0A, 0x0D, 0x0A, "LFN: $"
testx: db "OK$"
trimbkp: dw 0
trimpos: db 0
freemem: db 0
