;Amir Derzy
IDEAL
MODEL small
STACK 100h
DATASEG
; --------------------------
; Your variables here
; --------------------------
	calcmode db 0
	modeinsturctions db 'modes: 1-COMP, 2-EQN$'
	invalidmodemsg db 'INVALID mode, enter VALID mode$'
	instructions db 'Enter a ONE action mathematical equation and press the ,=, button to have the calculator answer it. By pressing the EXIT button at ANY time the calculator will close.$'
	actionlist db 'mode(m), addition(+), substraction(-), multeplication(*), division(/), factorial(!), power(^) and square root (s)$'
	pabtc db 'press any button to continue...$'
	pabtc2 db 'press right click to continue...$'
	x dw 0
	y dw 0
	mousebuttonposition db 0
	filename db 'calcimg.bmp',0
	filehandle dw ?
	Header db 54 dup (0)
	Palette db 256*4 dup (0)
	ScrLine db 320 dup (0)
	ErrorMsg1 db 'Error', 13, 10 ,'$'
	input1 dw 0,0
	action db 0
	input2 dw 0,0
	twoinputminus db 0
	input10mul dw 10
	currentdigit dw 0
	divsaveax dw 0
	divsavecx dw 0
	errortype db 0
	errord0msg db 'Dividing by 0 is ILLEGAL...$'
	errorfactmsg db 'Factorials should be a 1 digit positive number such as: 6,2...$'
	errorinputmsg db 'One of the number you entered is INVALID.$'
	errorinputmsg2 db 'You entered an INVALID char.$'
	errorinputmsg3 db 'You entered an INVALID mathematical equation.$'
	erroroutputtoolarge db 'The output was too large.$'
	errorsqrtminusmsg db 'cant find square root of a NEGATIVE number$'
	errorminusminusmsg db '-- is INVALID$'
	output dd 0
	largeroutput dd 0
	largeroutputcheck db 0
	sqrtinput dw 0
	sqrtinput2 dw 0
	undefined db 'undefined$'
	poweroutput dd 0
	powerloopvar dw 0
	subboolean db 0
	sqrteqinsturctions db 'aX^2 + bX + cX = 0; enter a, b and c and press space after typing the number to confirm it$'
	a dw 0
	b dw 0
	c dw 0
	mc db 0
	am db 0
	bm db 0
	cm db 0
	b4ac dw 0
	bminus dw 0
	bminusandb4ac dw 0
	x1msg db 'X1=$'
	x2msg db 'X2=$'
	finaleq dw 0
CODESEG
proc OpenFile
	; Open file
	mov ah, 3Dh
	xor al, al
	mov dx, offset filename
	int 21h
	jc openerror
	mov [filehandle], ax
	ret
	openerror :
	mov dx, offset ErrorMsg1
	mov ah, 9h
	int 21h
	ret
endp OpenFile
proc ReadHeader
	; Read BMP file header, 54 bytes
	mov ah, 3fh
	mov bx, [filehandle]
	mov cx, 54
	mov dx, offset Header
	int 21h
	ret
endp ReadHeader
proc ReadPalette
	; Read BMP file color palette, 256 colors * 4 bytes (400h)
	mov ah, 3fh
	mov cx, 400h
	mov dx, offset Palette
	int 21h
	ret
endp ReadPalette
proc CopyPal
	; Copy the colors palette to the video memory
	; The number of the first color should be sent to port 3C8h
	; The palette is sent to port 3C9h
	mov si, offset Palette
	mov cx, 256
	mov dx, 3C8h
	mov al, 0
	; Copy starting color to port 3C8h
	out dx, al
	; Copy palette itself to port 3C9h
	inc dx
	PalLoop:
	; Note: Colors in a BMP file are saved as BGR values rather than RGB .
	mov al,[si+2] ; Get red value .
	shr al,2 ; Max. is 255, but video palette maximal
	; value is 63. Therefore dividing by 4.
	out dx, al ; Send it .
	mov al, [si+1] ; Get green value .
	shr al, 2
	out dx, al ; Send it .
	mov al, [si] ; Get blue value .
	shr al, 2
	out dx, al ; Send it .
	add si, 4 ; Point to next color .
	; (There is a null chr. after every color.)
	loop PalLoop
	ret
endp CopyPal
proc CopyBitmap
	; BMP graphics are saved upside-down .
	; Read the graphic line by line (200 lines in VGA format),
	; displaying the lines from bottom to top.
	mov ax, 0A000h
	mov es, ax
	mov cx, 200
	PrintBMPLoop :
	push cx
	; di = cx*320, point to the correct screen line
	mov di,cx
	shl cx,6
	shl di,8
	add di,cx
	; Read one line
	mov ah, 3fh
	mov cx, 320
	mov dx, offset ScrLine
	int 21h
	; Copy one line into video memory
	cld ; Clear direction flag, for movsb
	mov cx, 320
	mov si, offset ScrLine
	rep movsb
	pop cx
	loop PrintBMPLoop
	ret
endp CopyBitmap
proc drawcalc
	mov ax, 13h
	int 10h
	call OpenFile
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
	ret
endp
proc mouseinput
startmouseinput:
	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx
	xor di, di
	dec di
initiatemousetakeinput:
	mov [currentdigit], 0
	mov ax, '$$'
	push ax
	inc di
mousetakeinput:
	cmp di, 2
	jl mousestart
	jmp mouseendinput
mousestart:
	mov [mousebuttonposition], 0
	mov ax, 0
	int 33h
	mov ax, 1
	int 33h
waitforClick:
	xor bx, bx
	mov ax, 3
	int 33h
	cmp bx, 0
	je waitforClick
	mov [y], dx
	xor dx, dx
	mov ax, cx
	mov [x], 2
	div [x]
	mov [x], ax
	add [x], 20
	xor dx, dx
	;errormousecheck
	cmp [x], 180
	jne modebuttoncheck
	cmp [y], 100
	jne modebuttoncheck
	jmp mousestart
	;mode button check
modebuttoncheck:
	cmp [y], 179
	jl ycheck1
	cmp [y], 194
	jg ycheck1
	cmp [x], 31
	jl ycheck1
	cmp [x], 45
	jg ycheck1
	jmp modebuttton
ycheck1:
	cmp [y], 45
	jl ycheck2
	cmp [y], 75
	jg ycheck2
	add [mousebuttonposition], 1
	jmp xcheck1
ycheck2:
	cmp [y], 81
	jl ycheck3
	cmp [y], 110
	jg ycheck3
	add [mousebuttonposition], 2
	jmp xcheck1
ycheck3:
	cmp [y], 117
	jl ycheck4
	cmp [y], 153
	jg ycheck4
	add [mousebuttonposition], 3
	jmp xcheck1
ycheck4:
	cmp [y], 159
	jl nobutton
	cmp [y], 196
	jg nobutton
	add [mousebuttonposition], 4
	jmp xcheck1
nobutton:
	mov [mousebuttonposition], 0
	jmp mousestart
xcheck1:
	cmp [x], 49
	jl xcheck2
	cmp [x], 86
	jg xcheck2
	add [mousebuttonposition], 10
	jmp mousepositioncheck1
xcheck2:
	cmp [x], 92
	jl xcheck3
	cmp [x], 132
	jg xcheck3
	add [mousebuttonposition], 20
	jmp mousepositioncheck1
xcheck3:
	cmp [x], 138
	jl xcheck4
	cmp [x], 172
	jg xcheck4
	add [mousebuttonposition], 30
	jmp mousepositioncheck1
xcheck4:
	cmp [x], 178
	jl xcheck5
	cmp [x], 214
	jg xcheck5
	add [mousebuttonposition], 40
	jmp mousepositioncheck1
xcheck5:
	cmp [x], 220
	jl nobutton
	cmp [x], 260
	jg nobutton
	add [mousebuttonposition], 50
	jmp mousepositioncheck1
mousepositioncheck1:
	cmp [mousebuttonposition], 34
	jne mousepositioncheck3
	mov [action], 'q'
	jmp mouseendinput
modebuttton:
	mov [action], 'm'
	jmp mouseendinput
mousepositioncheck3:
	cmp [mousebuttonposition], 14
	jne mousepositioncheck4
	mov dl, '='
	mov ah, 2h
	int 21h
	jmp mouseequationened
mousepositioncheck4:
	cmp [mousebuttonposition], 52
	jne mouseactioncheck
	pop bx
	push bx
	cmp bx, '$$'
	jne mouseactioncheck
	mov dl, '-'
	mov ah, 2h
	int 21h
	jmp minuscheck1
minuscheck1:
	cmp di, 0
	jne minuscheck2
	cmp [input1+2], 1
	je minuserror
	jmp mouseminusinput1
minuscheck2:
	cmp [input2+2], 1
	je minuserror
	jmp mouseminusinput1
minuserror:
	mov [errortype], 4
	jmp mouseendinput
mouseactioncheck:
	cmp [action], 0
	je mousepositioncheck5
	jmp mousepositionnumcheck1
mousepositioncheck5:
	cmp [mousebuttonposition], 11
	jne mousepositioncheck6
	mov [action], '!'
	mov dl, [action]
	mov ah, 2h
	int 21h
	inc di
	jmp mousestartinputasembl
mousepositioncheck6:
	cmp [mousebuttonposition], 13
	jne mousepositioncheck7
	mov [action], 's'
	mov dl, [action]
	mov ah, 2h
	int 21h
	inc di
	jmp mousestartinputasembl
mousepositioncheck7:
	cmp [mousebuttonposition], 12
	jne mousepositioncheck8
	mov [action], '^'
	mov dl, [action]
	mov ah, 2h
	int 21h
	jmp mousestartinputasembl
mousepositioncheck8:
	cmp [mousebuttonposition], 51
	jne mousepositioncheck9
	mov [action], '+'
	mov dl, [action]
	mov ah, 2h
	int 21h
	jmp mousestartinputasembl
mousepositioncheck9:
	cmp [mousebuttonposition], 52
	jne mousepositioncheck10
	mov [action], '-'
	mov dl, [action]
	mov ah, 2h
	int 21h
	jmp mousestartinputasembl
mousepositioncheck10:
	cmp [mousebuttonposition], 53
	jne mousepositioncheck11
	mov [action], '*'
	mov dl, [action]
	mov ah, 2h
	int 21h
	jmp mousestartinputasembl
mousepositioncheck11:
	cmp [mousebuttonposition], 54
	jne mousepositionnumcheck1
	mov [action], '/'
	mov dl, [action]
	mov ah, 2h
	int 21h
	jmp mousestartinputasembl
mousepositionnumcheck1:
	cmp [mousebuttonposition], 21
	jne mousepositionnumcheck2
	mov dl, '1'
	jmp mousepushnum
mousepositionnumcheck2:
	cmp [mousebuttonposition], 31
	jne mousepositionnumcheck3
	mov dl, '2'
	jmp mousepushnum
mousepositionnumcheck3:
	cmp [mousebuttonposition], 41
	jne mousepositionnumcheck4
	mov dl, '3'
	jmp mousepushnum
mousepositionnumcheck4:
	cmp [mousebuttonposition], 22
	jne mousepositionnumcheck5
	mov dl, '4'
	jmp mousepushnum
mousepositionnumcheck5:
	cmp [mousebuttonposition], 42
	jne mousepositionnumcheck6
	mov dl, '5'
	jmp mousepushnum
mousepositionnumcheck6:
	cmp [mousebuttonposition], 23
	jne mousepositionnumcheck7
	mov dl, '6'
	jmp mousepushnum
mousepositionnumcheck7:
	cmp [mousebuttonposition], 33
	jne mousepositionnumcheck8
	mov dl, '7'
	jmp mousepushnum
mousepositionnumcheck8:
	cmp [mousebuttonposition], 43
	jne mousepositionnumcheck9
	mov dl, '8'
	jmp mousepushnum
mousepositionnumcheck9:
	cmp [mousebuttonposition], 24
	jne mousepositionnumcheck0
	mov dl, '9'
	jmp mousepushnum
mousepositionnumcheck0:
	cmp [mousebuttonposition], 44
	je mouseinput0
	jmp mousestart
mouseinput0:
	mov dl, '0'
	jmp mousepushnum
mousepushnum:
	mov ah, 2h
	int 21h
	sub dl, '0'
	push dx
	jmp mousestart
mousestartinputasembl: ;assmbles number
	xor cx, cx
mouseinputasembl:
	xor dx, dx
	xor ax, ax
	pop ax
	cmp ax, '$$'
	jne mouseinputasemblloop
	jmp mousenumerrorcheck
mouseinputasemblloop:
	cmp [currentdigit], cx
	je mouseinputasemblend
mousemul10inputloop:
	mul [input10mul]
	inc cx
	jmp mouseinputasemblloop
mouseinputasemblend:
	cmp dx, 0
	jne mouseinputerror
	xor cx, cx
	inc [currentdigit]
	cmp di, 0
	je mouseinput1asembl
	add [input2], ax
	jmp mouseinputasembl
mouseinput1asembl:
	add [input1], ax
	jmp mouseinputasembl
mouseinputerror: ; errors
	mov [errortype], 3
	jmp mouseendinput
mouseinputerror2:
	mov [errortype], 4
	jmp mouseendinput
mouseinputerror3:
	mov [errortype], 5
	jmp mouseendinput
mouseequationened:
	cmp [action], 0
	je mouseinputerror3
	jmp mousestartinputasembl
mousenumerrorcheck:
	cmp [currentdigit], 0
	je mouseinputerror
	jmp initiatemousetakeinput
mouseminusinput1:
	cmp di, 0
	jne mouseminusinput2
	mov [input1+2], 1
	jmp mousestart
mouseminusinput2:
	mov [input2+2], 1
	jmp mousestart
mouseendinput:
	pop ax
	cmp ax, '$$'
	jne mouseendinput
	ret
endp
proc print
pstart:
	cmp [subboolean], 1
	je printsub
pcon: ;moves the output to dx:ax
	mov ax, '$$'
	push ax
	mov si, offset output
	mov ax, [si]
	mov dx, [si+2]
	mov bx, 10
	mov cx, 1
	cmp [sqrtinput], cx
	jge squaredouble
	cmp [sqrtinput2], cx
	jge squaredouble
	jmp disasembl
squaredouble:
	div bx
	cmp dx, 0
	je disasembl
	push dx
	mov cx, '.'
	push cx
	mov cx, 1
	mul cx
disasembl: ;dissassembles the number to its digits
	div bx
	push dx
	mul cx
	cmp ax, 0
	jne disasembl
asmble: ;prints the number
	pop ax
	cmp ax, '$$'
	je exitprintlabel
	cmp ax, '.'
	je pdot
	add al, '0'
	mov dl, al
	mov ah, 2h
	int 21h
	jmp asmble
pdot: ; prints after dot (ex, 1.5 , 9.2)
	mov dl, al
	mov ah, 2h
	int 21h
	jmp asmble
printsub:
	mov dl, '-'
	mov ah, 2h 
	int 21h
	dec [subboolean]
	jmp pcon
exitprintlabel:
	ret
endp
proc largerprint
largerpstart: ;moves the output to dx:ax
	cmp [subboolean], 1
	je largerprintsub
largerpcon:
	mov ax, '$$'
	push ax
	mov si, offset output
	mov ax, [si]
	mov dx, [si+2] 
halv: ; splits output
	mov bx, 10000
	div bx
	mov si, offset largeroutput
	mov [si], ax
	mov ax, dx
	mov cx, 1
	mul cx
	mov bx, 10
largerdisasemblA: ;dissassembles the number to its digits
	div bx
	push dx
	mul cx
	inc [largeroutputcheck]
	cmp ax, 0
	jne largerdisasemblA
halvcheck: ; checks validity of dissassembled first half
	mov si, offset largeroutput
	mov ax, [si]
	cmp ax, 0
	je largerasmble
	cmp [largeroutputcheck], 4
	je largerdisasemblCon
	xor cx, cx
	mov cl, 4
	sub cl, [largeroutputcheck]
	xor bx, bx
halvfix:
	push bx
	loop halvfix
largerdisasemblCon:
	mov cx, 1
	mov bx, 10
	mov si, offset largeroutput
	mov ax, [si]
	mov dx, [si+2]
largerdisasemblB: ;dissassembles the number to its digits
	div bx
	push dx
	mul cx
	cmp ax, 0
	jne largerdisasemblB
largerasmble: ;prints the number
	mov [largeroutputcheck], 0 
	pop ax
	cmp ax, '$$'
	je largerexitprintlabel
	add al, '0'
	mov dl, al
	mov ah, 2h
	int 21h
	jmp largerasmble
largerprintsub:
	mov dl, '-'
	mov ah, 2h 
	int 21h
	dec [subboolean]
	jmp largerpcon
largerexitprintlabel:
	ret
endp
proc power
	cmp [input2], 0
	jne powernot0
	mov si, offset output
	mov al, 1
	mov [si], al
	jmp powerendlabel
powernot0:
	cmp [input2], 1
	jne powernot1
	mov si, offset output
	mov ax, [input1]
	mov [si], ax
	jmp powerendlabel
powernot1:
	xor cx, cx
	mov cl, 1
	xor dx, dx
	mov ax, [input2]
	dec ax
	mov [powerloopvar], ax
	mov ax, [input1]
	mov bx, [input1]
mulpowerloop:
	mul bx
	mov si, offset output
	add [si], ax
	add [si+2], dx
	;
	mov si, offset poweroutput
	mov ax, [si+2]
	;
	mul bx
	cmp dx, 0
	je powerproccon
	jmp powerendlabel
powerproccon:
	mov si, offset output
	add [si+2], ax
	dec [powerloopvar]
	cmp [powerloopvar], 0
	je powerendlabel
	;
	mov si, offset output
	mov ax, [si]
	mov dx, [si+2]
	mov si, offset poweroutput
	mov [si], ax
	mov [si+2], dx
	xor ax, ax
	xor dx, dx
	mov si, offset output
	mov [si], ax
	mov [si+2], dx
	mov si, offset poweroutput
	mov ax, [si]
	jmp mulpowerloop
powerendlabel:
	ret
endp
proc factorial
	mov ax, 1
	mov cx, 1
	mov bx, [input2]
factloop:
	mul cx
	inc cx
	dec bx
	cmp bx, 0
	jle factt
	jmp factloop
factt:
	mov si, offset output
	mov [si], ax
	mov [si+2], dx
	ret
endp
proc sqrt
	mov bx, 100
	mul bx
	mov [sqrtinput], ax
	mov [sqrtinput2], dx
	xor ax, ax
	xor bx, bx
	xor dx, dx
squareroot:
	cmp ax, [sqrtinput]
	ja squareroot2
sqroot:
	inc bx
	mov ax, bx
	mul bx
	jmp squareroot
squareroot2:
	cmp dx, [sqrtinput2]
	jae endsqroot
	jmp sqroot
endsqroot:
	dec bx
	ret
endp
proc sqrteqinput
sqrtstartinput:
	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx
	xor di, di
	dec di
sqrtstarttakeinput:
	mov [mc], 0
	mov [currentdigit], 0
	mov ax, '$$'
	push ax
	inc di
sqrttakeinput:
	cmp di, 3
	jl sqrttakeinputcon
	jmp sqrtendinput
sqrttakeinputcon:
	mov ah, 1h
	int 21h
sqrtoutinputcheck:
	cmp al, ' '
	jne sqrtendinputcheck
	jmp sqrtstartinputasembl
sqrtendinputcheck:
	cmp al, 'q'
	jne sqrtmodeinputcheck
	mov [calcmode], 'q'
	jmp sqrtendinput
sqrtmodeinputcheck:
	cmp al, 'm'
	jne sqrtminusinputcheck
	mov [calcmode], 'm'
	jmp sqrtendinput
sqrtminusinputcheck:
	cmp al, '-'
	jne sqrtinputnumcheck1
	cmp [mc], 1
	jne sqrtminusinputcc
	jmp sqrtinputerror4
sqrtminusinputcc:
	mov [mc], 1
	jmp sqrtminusin1
sqrtinputnumcheck1:
	cmp al, '0'
	jge sqrtinputnumcheck2
	jmp sqrtinputerror
sqrtinputnumcheck2:
	cmp al, '9'
	jle sqrtstackinput
	jmp sqrtinputerror
sqrtstackinput:
	xor ah, ah
	sub al, '0'
	push ax
	jmp sqrttakeinputcon
sqrtstartinputasembl:
	xor cx, cx
sqrtinputasembl:
	xor dx, dx
	xor ax, ax
	pop ax
	cmp ax, '$$'
	jne sqrtinputasemblloop
	jmp sqrtnumerrorcheck
sqrtinputasemblloop:
	cmp [currentdigit], cx
	je sqrtinputasemblend
sqrtmul10inputloop:
	mul [input10mul]
	inc cx
	jmp sqrtinputasemblloop
sqrtinputasemblend:
	cmp dx, 0
	jne sqrtinputerror
sqrtinputasemblendcon:
	xor cx ,cx
	cmp di, 0
	jne sqrtinput1asembl
	add [a], ax
	xor ax, ax
	inc [currentdigit]
	jmp sqrtinputasembl
sqrtinput1asembl:
	cmp di, 1
	jne sqrtinput2asmbel
	add [b], ax
	xor ax, ax
	inc [currentdigit]
	jmp sqrtinputasembl
sqrtinput2asmbel:
	add [c], ax
	xor ax, ax
	inc [currentdigit]
	jmp sqrtinputasembl
sqrtinputerror:
	mov [errortype], 3
	jmp sqrtendinput
sqrtinputerror2:
	mov [errortype], 4
	jmp sqrtendinput
sqrtinputerror3:
	mov [errortype], 5
	jmp sqrtendinput
sqrtinputerror4:
	mov [errortype], 7
	jmp sqrtendinput
sqrtnumerrorcheck:
	cmp [currentdigit], 0
	je sqrtinputerror
	jmp sqrtstarttakeinput
sqrtminusin1:
	cmp di, 0
	jne sqrtminusin2
	mov [am], 1
	jmp sqrttakeinputcon
sqrtminusin2:
	cmp di, 1
	jne sqrtminusin3
	mov [bm], 1
	jmp sqrttakeinputcon
sqrtminusin3:
	mov [cm], 1
	jmp sqrttakeinputcon
sqrtendinput:
	pop ax
	cmp ax, '$$'
	jne sqrtendinput
	ret
endp
start:
	mov ax, @data
	mov ds, ax
; --------------------------
; Your code here
; --------------------------
instructionlabel: ;displays instructions
	mov dx, offset instructions
	mov ah, 9h
	int 21h
	mov dx, offset actionlist
	mov ah, 9h
	int 21h
	mov dl, 0ah
	mov ah, 2h
	int 21h 
	mov dx, offset pabtc
	mov ah, 9h
	int 21h
	mov ah, 1h
	int 21h
inputlabel: ;resets all variables and takes input
	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx
	mov [input1], ax
	mov [input1+2], ax
	mov [sqrtinput], ax
	mov [sqrtinput2], ax
	mov [action], 0
	mov [input2], ax
	mov [input2+2], ax
	mov [errortype], 0
	mov [twoinputminus], 0
	mov si, offset output
	mov [si], ax
	mov [si+2], ax
	mov si, offset poweroutput
	mov [si], ax
	mov [si+2], ax
	call drawcalc ; draws calculator
	call mouseinput ;calls input
	cmp [input1+2], 1
	je minusinputlabel
	jmp errorcheck
minusinputlabel:
	mov [twoinputminus], 1
errorcheck: ;checks for errors and action
	cmp [errortype], 0 
	je exitcheck
	jmp errormsg
exitcheck:
	cmp [action], 'q'
	jne modecheck
	jmp exitlabel
modecheck:
	cmp [action], 'm'
	jne actioncheck1
	jmp modeselect
actioncheck1:
	cmp [action], '+'
	jne actioncheck2
	jmp addition
actioncheck2:
	cmp [action], '-'
	jne actioncheck3
	jmp substraction
actioncheck3:
	cmp [action], '*'
	jne actioncheck4
	jmp multeplication
actioncheck4:
	cmp [action], '/'
	jne actioncheck5
	jmp division
actioncheck5:
	cmp [action], '!'
	jne actioncheck6
	jmp factcheck
actioncheck6:
	cmp [action], '^'
	jne actioncheck7
	jmp power1
actioncheck7:
	cmp [action], 's'
	jne actioncheck6
	jmp sqrtact
addition: ;calculates addition
	cmp [twoinputminus], 1
	je additioncon1
	cmp [input1+2], 1
	je additionminus
additionminuscheck:
	cmp [input2+2], 1
	jne additioncon1
	jmp substractioncon
additionminus:
	mov ax, [input1]
	mov bx, [input2]
	mov [input1], bx
	mov [input2], ax
	jmp substractioncon
additioncon1:
	mov ax, [input1]
	add ax, [input2]
	cmp ax, [input1]
	jl additionbig
	cmp ax, [input2]
	jl additionbig
	jmp additioncon2
additionbig:
	mov dx, 1
	jmp additioncon2
additioncon2:
	mov si, offset output
	mov [si], ax
	mov [si+2], dx
	cmp [twoinputminus], 1
	jne additionprint
	mov [subboolean], 1
additionprint:
	call print
	jmp graphicalrerun
substraction: ;calculates substraction
	cmp [input1+2], 1
	jne substractionminuscheck
	cmp [input2+2], 1
	je substractioncon
	mov [twoinputminus], 1
	jmp additioncon1
substractionminuscheck:
	cmp [input2+2], 1
	jne substractioncon
	jmp additioncon1
substractionminus:
	mov ax, [input1]
	mov bx, [input2]
	mov [input1], bx
	mov [input2], ax
substractioncon:
	mov ax, [input1]
	sub ax, [input2]
	mov si, offset output
	cmp ax, 0
	jl minusprint
	mov [si], ax
	call print
	jmp graphicalrerun
minusprint: ;prints negative output like -3 
	neg ax
	mov [si], ax
	inc [subboolean]
	call print
	jmp graphicalrerun
multeplication: ;calculates multeplication
	cmp [input1+2], 1
	je negmulteplication
	cmp [input2+2], 1
	je negmulteplicationcon
multeplicationcon:
	mov ax, [input1]
	mul [input2]
	mov si, offset output
	mov [si], ax
	mov [si+2], dx
	jmp printlabel
negmulteplication:
	cmp [input2+2], 1
	je multeplicationcon
negmulteplicationcon:
	mov [subboolean], 1
	jmp multeplicationcon
division: ;calculates division
	cmp [input2], 0
	jne divisioncon
	mov [errortype], 0
	jmp errormsg
divisioncon:
	cmp [input1+2], 1
	je negdivision
	cmp [input2+2], 1
	je negdivisioncon
divisioncon2:
	mov cx, 1
	mov ax, [input1]
	xor dx, dx
	div [input2]
	mov [divsaveax], dx
	mul cx
	mov si, offset output
	mov [si], ax
	mov [si+2], dx
	call print
	cmp [divsaveax], 0
	jne divmods
	jmp graphicalrerun
negdivision:
	cmp [input2+2], 1
	je divisioncon2
negdivisioncon:
	mov [subboolean], 1
	jmp divisioncon2
divmods: ;print mod if available
	mov dl, '.'
	mov ah, 2h
	int 21h
	mov [divsavecx], 0
divmod:
	cmp [divsavecx], 5
	jge divend
	mov ax, [divsaveax]
	xor dx, dx
	mul bx
	div [input2]
	mov [divsaveax], dx
	xor dx, dx
	div bx
	cmp dx, 0
	je divmodcon
	add dl, '0'
	mov ah, 2h
	int 21h
divmodcon:
	inc [divsavecx]
	cmp [divsaveax], 0
	jne divmod
divend:
	jmp graphicalrerun
factcheck: ;factorial checks
	mov [errortype], 1
	cmp [input2], 0
	jge factcheck1
	jmp errormsg
factcheck1:
	cmp [input2], 9
	jle factcheck2
	jmp errormsg
factcheck2:
	cmp [input1+2], 1
	jne fact
	mov [errortype], 1
	jmp errormsg
fact: ;factorial
	mov dl, '='
	mov ah, 2h 
	int 21h
	call factorial
	call largerprint
	jmp graphicalrerun
power1: ;power checks
	cmp [input1], 0
	je power0check
power0check:
	cmp [input2], 0
	je power00
	jmp powercon
powercon:
	cmp [input1+2], 1
	je powerinput1neg
powercon2:
	cmp [input2+2], 1
	je powerinput2neg
powercon3: ;power
	call power
	jmp printlabel
power00: ;prints INVALID if 0^0 is entered
	mov dl, '='
	mov ah, 2h 
	int 21h
	mov dx, offset undefined
	mov ah, 9h 
	int 21h
	jmp graphicalrerun
powerinput1neg: ;prints a neg output
	mov ax, [input2]
	mov bx, 2
	div bx
	cmp dx, 0
	je powercon2
	mov [subboolean], 1
	jmp powercon2
powerinput2neg: ;prints a neg power like 9^-3
	mov dl, '1'
	mov ah, 2h 
	int 21h
	mov dl, '/'
	mov ah, 2h 
	int 21h
	jmp powercon3
sqrtact: ;square root checks
	cmp [input1+2], 0
	je sqrtactcon
	mov [errortype], 6
	jmp errormsg
sqrtactcon: ; square root
	mov ax, [input2]
	call sqrt
	mov si, offset output
	mov [si], bx
	call print
	jmp graphicalrerun
printlabel: ;errorchcker and printer
	mov si, offset output
	mov dx, [si+2]
	cmp dx, 26beh
	jge outputtoolarge
	cmp dx, 1
	jge printlabel2
	call print
	jmp graphicalrerun
printlabel2:
	call largerprint
	jmp graphicalrerun
outputtoolarge:
	mov [errortype], 5
	jmp errormsg
errormsg:; hub of error msgs
	mov ah, 0
	mov al, 2
	int 10h
error1: ;diving by 0 error
	cmp [errortype], 0
	jne error2
	mov dx, offset errord0msg
	jmp errormodejmp
error2: ;factorial not 1 digit error
	cmp [errortype], 1
	jne error3
	mov dx, offset errorfactmsg
	jmp errormodejmp
error3: ;invalid number
	cmp [errortype], 2
	jne error4
	mov dx, offset errorinputmsg
	jmp errormodejmp
error4: ;invalid char
	cmp [errortype], 3
	jne error5
	mov dx, offset errorinputmsg2
	jmp errormodejmp
error5: ;invalid mathematical equation
	cmp [errortype], 4
	jne error6
	mov dx, offset errorinputmsg3
	jmp errormodejmp
error6: ;output is too large
	cmp [errortype], 5
	jne error7
	mov dx, offset erroroutputtoolarge
	jmp errormodejmp
error7: ;square root of a negative number
	cmp [errortype], 6
	jne error8
	mov dx, offset errorsqrtminusmsg
	jmp errormodejmp
error8: ;typing 2 minuses one after another in sqrtequation mode
	cmp [errortype], 7
	jne error9
	mov dx, offset errorminusminusmsg
	jmp errormodejmp
error9:
errormodejmp: ;jumps to the current calculator mode
	mov ah, 9h
	int 21h
	mov dx, offset pabtc
	mov ah, 9h
	int 21h
	mov ah, 1h
	int 21h
	cmp [calcmode], 1
	jne errormodejmp1
	jmp instructionlabel
errormodejmp1:
	cmp [calcmode], 2
	jne errormodejmp2
	jmp sqrteqstartinstructions
errormodejmp2:
rerun: ;jumps to start of calculator
	mov dl, 0ah
	mov ah, 2h
	int 21h
	mov dx, offset pabtc
	mov ah, 9h
	int 21h
	mov ah, 1h
	int 21h
	mov ah, 0
	mov al, 2
	int 10h
	jmp inputlabel
graphicalrerun:
	mov dl, 0ah
	mov ah, 2h
	int 21h
	mov dx, offset pabtc2
	mov ah, 9h
	int 21h
	mov ax, 0
	int 33h
	mov ax, 1
	int 33h
graphicalrerunwaitforClick:
	xor bx, bx
	mov ax, 3
	int 33h
	cmp bx, 2
	jne graphicalrerunwaitforClick
	jmp inputlabel
modeselect: ;modeselect msg
	mov ah, 0
	mov al, 2
	int 10h
	mov dx, offset modeinsturctions
	mov ah, 9h
	int 21h
	mov dl, 0ah
	mov ah, 2h
	int 21h
modeselectin: ;takes mode
	mov ah, 1h
	int 21h
	mov [calcmode], al
	sub [calcmode], '0'
	cmp al, '1' ;checks mode
	jne modeselectin2
	mov dl, 0ah
	mov ah, 2h
	int 21h
	jmp instructionlabel
modeselectin2: ;checks mode
	cmp al, '2'
	jne modeselectin3
	mov dl, 0ah
	mov ah, 2h
	int 21h
	jmp sqrteqstartinstructions
modeselectin3: ;mode is invalid
	mov dx, offset invalidmodemsg
	mov ah, 9h
	int 21h
	jmp modeselectin
sqrteqstartinstructions: ;square root equation
	mov dl, 0ah
	mov ah, 2h
	int 21h
	mov dx, offset sqrteqinsturctions
	mov ah, 9h
	int 21h
	mov dl, 0ah
	mov ah, 2h
	int 21h
startsqrteq: ;resets variables of sqrt equation mode
	xor ax, ax
	mov [errortype], 0
	mov [a], ax
	mov [b], ax
	mov [c], ax
	mov [mc], 0
	mov [am], 0
	mov [bm], 0
	mov [cm], 0
	mov [b4ac], ax
	mov [bminus], ax
	mov [bminusandb4ac], ax
	mov [finaleq], ax
	call sqrteqinput
	cmp [calcmode], 'm' ;checks for switching mode, exiting calculator and errors
	jne startsqrteq1
	jmp modeselect
startsqrteq1:
	cmp [calcmode], 'q'
	jne sqrteqcon
	jmp exitlabel
sqrteqcon:
	cmp [errortype], 0
	je sqrteqcone
	jmp errormsg
sqrteqcone: ;calculations
	mov dl, 0ah
	mov ah, 2h
	int 21h 
	mov ax, [b]
	mov bx, [b]
	mul bx
	cmp dx, 0
	je sqrteqcon1
	jmp exitlabel
sqrteqcon1:
	mov [b4ac], ax
	mov ax, 4
	mov bx, [a]
	mul bx
	cmp dx, 0
	je sqrteqcon2
	jmp exitlabel
sqrteqcon2:
	mov bx, [c]
	mul bx
	cmp dx, 0
	je sqrteqcon3
	jmp exitlabel
sqrteqcon3:
	cmp [am], 0
	jg aneg1
	cmp [cm], 0
	jg cneg1
sqrteqcon4:
	sub [b4ac], ax
	jmp sqrteqcon5
aneg1:
	cmp [cm], 0
	jg sqrteqcon4
	add [b4ac], ax
	jmp sqrteqcon5
cneg1:
	add [b4ac], ax
	jmp sqrteqcon5
sqrteqcon5:
	cmp [b4ac], 0
	jge sqrteqcon6
	mov [errortype], 6
	jmp errormsg
sqrteqcon6:
	mov ax, [b4ac]
	call sqrt
	mov [b4ac], bx
	xor dx ,dx
	mov ax, bx
	mov ax, [b]
	mov bx, 10
	mul bx
	cmp dx, 0
	je sqrteqcon7
	jmp exitlabel
sqrteqcon7:
	cmp [bm], 0
	jg bneg
	neg ax
	mov [bminus], ax
	jmp X1
bneg:
	mov [bminus], ax
	jmp X1
X1: ;calculates and prints X1
	mov ax, [bminus]
	add ax, [b4ac]
	mov [bminusandb4ac], ax
	mov ax, [a]
	mov bx, 2
	mul bx
	cmp dx, 0
	je X1con
	jmp exitlabel
X1con:
	mov cx, ax
	mov ax, [bminusandb4ac]
	cmp ax, 0
	jl X1neg
	cmp [am], 0
	je X1con2
	mov [subboolean], 1
X1con2:
	div cx
	mov [finaleq], ax
	mov dx, offset x1msg
	mov ah, 9h
	int 21h
	cmp [finaleq], 0
	jne X1print
	mov [subboolean], 0
X1print:
	mov si, offset output
	mov ax, [finaleq]
	mov [si], ax
	call print
	jmp X2
X1neg:
	neg ax
	mov [subboolean], 1
	jmp X1con2
X2: ;calculates and prints X2
	mov [subboolean], 0
	mov dl, 0ah
	mov ah, 2h
	int 21h
	mov ax, [bminus]
	sub ax, [b4ac]
	mov [bminusandb4ac], ax
	mov ax, [a]
	mov bx, 2
	mul bx
	cmp dx, 0
	je X2con
	jmp exitlabel
X2con:
	mov cx, ax
	mov ax, [bminusandb4ac]
	cmp ax, 0
	jl X2neg
	cmp [am], 0
	je X2con2
	cmp ax, 0
	jl X2con2
	mov [subboolean], 1
X2con2:
	div cx
	cmp [finaleq], ax
	je exitlabel
	cmp [am], 1
	je X2neg2
X2con3:
	mov [finaleq], ax
	mov dx, offset x2msg
	mov ah, 9h
	int 21h
	cmp [finaleq], 0
	jne X2print
	mov [subboolean], 0
X2print:
	mov si, offset output
	mov ax, [finaleq]
	mov [si], ax
	call print
	jmp sqrtrerun
X2neg:
	neg ax
	mov [subboolean], 1
	jmp X2con2
X2neg2:
	cmp [subboolean], 0
	je X2con3
	mov [subboolean], 0
	jmp X2con3
sqrtrerun:
	mov dl, 0ah
	mov ah, 2h
	int 21h
	jmp startsqrteq
exitlabel:
	mov ah, 0
	mov al, 2
	int 10h
exit:
	mov ax, 4c00h
	int 21h
END start
