;*
;* LFNToSFN
;* Developer: EvolSoft
;* Website: http://www.evolsoft.tk
;* Date: 05/01/2016 01:19 PM (UTC)
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
;mov BYTE [bx], '$'

mov ah, 09h
mov dx, back
int 21h

; Input -> Short File Name (SFN)
; (Moving input memory content to freemem to keep the original content of input)
; 1. Convert to UPPERCASE
; 2. Replace not supported characters in SFN with "_"
; 3. Trim input and strip all leading periods
; 4. Check if filename is greater than 11 characters

cmp BYTE [si], '.'
mov al, 1
mov di, freemem
mov al, 0						; ~n Required? (0 = No, 1 = Yes)
mov bh, 0 						; Char Counter
add si, 2

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

; Trim input and strip all leading periods (3)
exitSFN:						; Exit SFN Loop
mov BYTE [si], '$'
dec di							; DI - 1 because last DI char is 0x00
mov WORD [sfnend], di			; Store DI (no push for interrupt use)
mov di, freemem
call TrimString
mov di, WORD [sfnend]			; Restore DI
call iTrimString
mov WORD [sfnend], di
mov di, freemem
xor dx, dx
mov dl, BYTE [trimpos]
add di, dx
call StripLeadingPeriods
; Check if filename is greater than 11 character (4)
cmp bh, 11
jg addNumTail
SFNNext:
mov di, WORD [sfnend]			; Restore DI
mov bl, 0						; Prepare BL for loop
mov si, sfnextension
call ParseFileExtension
mov di, freemem
xor dx, dx
mov dl, BYTE [trimpos]
add di, dx
mov bl, 0						; Prepare BL for loop
call ParseFileName
mov di, freemem
xor dx, dx
mov dl, BYTE [trimpos]
add di, dx
mov bh, 8						; FileName size without extension
sub bh, bl						; BH = BH - BL = FileName characters
jmp SFNNext2

addNumTail:
mov al, 1
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

iTrimString:					; Inverse Trim String (Right to Left) (Move DI to last no space character)
cmp BYTE [di-1], 20h
jne iTrimString.end
dec di
jmp iTrimString
iTrimString.end:
ret

; Strip all leading periods
StripLeadingPeriods:			; Strip all leading periods
cmp BYTE [di], 2Eh
jne StripLeadingPeriods.end
inc di
dec bh 							; Remove periods from input length
inc BYTE [trimpos]
jmp StripLeadingPeriods
StripLeadingPeriods.end:
ret

ParseFileName:
;cmp BYTE [di], 0
;je ParseFileName.addSpaces
cmp BYTE [di], 2Eh
je ParseFileName.addSpaces
inc bl
cmp bl, bh
je ParseFileName.end
inc di
jmp ParseFileName

ParseFileName.end:
ret

ParseFileName.addSpaces:
mov bh, 8
sub bh, bl
mov bl, 0
ParseFileName.addSpacesL:
cmp bh, 0
je ParseFileName.end
;mov al, 1
mov BYTE [di], ' '
inc bl
inc di
cmp bl, bh
jl ParseFileName.addSpacesL
ret

ParseFileExtension:
cmp BYTE [di], 2Eh
je ParseFileExtension.getExtension
dec di
inc bl
cmp bl, bh
je ParseFileExtension.end
jmp ParseFileExtension
ParseFileExtension.end:
; mov BYTE [si], 20h
; mov BYTE [si + 1], 20h
; mov BYTE [si + 2], 20h
; mov di, freemem
; xor dx, dx
; mov dl, BYTE [trimpos]
; add di, dx
; add di, 9
; mov BYTE [di], 20h
; mov ah, BYTE [si]
; mov BYTE [di + 1], ah
; mov ah, BYTE [si + 1]
; mov BYTE [di + 2], ah
; mov ah, BYTE [si + 2]
; mov BYTE [di + 3], ah
; add di, 4
; mov WORD [sfnend], di
ret
ParseFileExtension.getExtension:
cmp bl, 1
je ParseFileExtension.getExtension0
cmp bl, 2
je ParseFileExtension.getExtension1
cmp bl, 3
je ParseFileExtension.getExtension2
cmp bl, 4
jge ParseFileExtension.getExtension3

ParseFileExtension.getExtension0:
mov BYTE [si], 20h
mov BYTE [si + 1], 20h
mov BYTE [si + 2], 20h
jmp ParseFileExtension.ends

ParseFileExtension.getExtension1:
mov ah, BYTE [di + 1]
mov BYTE [si], ah
mov BYTE [si + 1], 20h
mov BYTE [si + 2], 20h
jmp ParseFileExtension.ends

ParseFileExtension.getExtension2:
mov ah, BYTE [di + 1]
mov BYTE [si], ah
mov ah, BYTE [di + 2]
mov BYTE [si + 1], ah
mov BYTE [si + 2], 20h
jmp ParseFileExtension.ends

ParseFileExtension.getExtension3:
mov ah, BYTE [di + 1]
mov BYTE [si], ah
mov ah, BYTE [di + 2]
mov BYTE [si + 1], ah
mov ah, BYTE [di + 3]
mov BYTE [si + 2], ah
jmp ParseFileExtension.ends

ParseFileExtension.ends:
mov di, freemem
xor dx, dx
mov dl, BYTE [trimpos]
add di, dx
add di, 8
mov BYTE [di], 2Eh
mov ah, BYTE [si]
mov BYTE [di + 1], ah
mov ah, BYTE [si + 1]
mov BYTE [di + 2], ah
mov ah, BYTE [si + 2]
mov BYTE [di + 3], ah
add di, 4
mov WORD [sfnend], di
ret

SFNNext2:						; Check ~n flag (AL)
mov dx, 0
mov cx, 1
cmp al, 1
je SFNNumLoop
jmp SFNNext3


SFNNum:
cmp bh, 1						; If BH <= 1 (= FileName is 7 or 8 characters) Then Overwrite last two characters of filename with ~n
jle SFNOverNumLoop				
jmp SFNNumLoop					; Else Append ~n to filename

SFNOverNumLoop:						; Write ~n function
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
int 21h							; DOS Interrupt 21h Function 4eh: Find 1st matching file. Check if file exists: if yes, increase the counter
pop cx
inc cx
jnc SFNOverNumLoop
jmp SFNNext3

SFNNumLoop:


SFNNext3:						; Print SFN
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

exit:

mov ax, 4c00h
int 21h

back: db 0x0A, 0x0D, "Input: $"
input: db 0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
sfn: db 0x0A, 0x0D, 0x0A, "SFN: $"
lfn: db 0x0A, 0x0D, 0x0A, "LFN: $"
testx: db "OK$"
sfnextension: db 0, 0, 0
sfnend: dw 0
trimpos: db 0
freemem: times 256 db 0
