            ORG 0000H
            LJMP START

            ORG 0003H
            LJMP INT0_ISR

IPMSG:      DB "Select 3 DIGITS", 0
TEXT_S:     DB "DOOR OPENED", 0
TEXT_F:     DB "WRONG PASSWORD", 0
PASSW:      DB "123", 0     ; 正確密碼
USERIN:     DS 3              ; 用來儲存輸入字元（30H~34H）
	        RS BIT 0x96     ; P2.6
            EN BIT 0x97     ; P2.7
            RW BIT 0x94     ; P2.4

START:      
            SETB P3.2
            SETB IT0
            SETB EX0
            SETB EA
			MOV R4, #0

MAIN_LOOP:
            ACALL LCD_INIT
            MOV DPTR, #IPMSG
            ACALL LCD_PRINT_LINE1   ; 顯示提示文字
            MOV R0, #30H        ; 輸入次數計數器
            MOV R2, #'0'        ; 循環字元從 '0' 開始
			MOV R5, #0
			CLR 25H

INPUT_LOOP:
			ACALL SET_CURSOR_LINE2
			MOV A, R2
			ACALL LDAT
			ACALL DELAY_2S
			CJNE R5, #0, HANDLE_ISR
			ACALL NEXT_CHAR_ROUTINE
			SJMP INPUT_LOOP
; -------------------------------
; 中斷執行 儲存當前字元到 USERIN[i]
; -------------------------------
HANDLE_ISR:
			MOV A, R4
            ADD A, #30H
            MOV R0, A
            MOV A, R2
            MOV @R0, A
            INC R4

            CJNE R4, #3, MAIN_LOOP

            ; == 剛儲存完全部，開始比對 ==
            ACALL CHECK_PASSWORD
            ACALL CLEAR_USERIN
            MOV R4, #0
			SJMP MAIN_LOOP

; -------------------------------
; 密碼比對
; -------------------------------
CHECK_PASSWORD:
			MOV R3, #0
			MOV DPTR, #PASSW

CHK_LOOP:
			MOV A, R3
			ADD A, #30H
			MOV R0, A
			MOV A, @R0
			MOV 40H, A

			MOV A, R3
			MOVC A, @A+DPTR
			CJNE A, 40H, WRONG

			INC R3
			CJNE R3, #3, CHK_LOOP   ; 比對完 3 碼就跳出
			SJMP CORRECT

CORRECT:
			ACALL LCD_CLR
			MOV DPTR, #TEXT_S
			ACALL LCD_PRINT_LINE1
			ACALL DELAY_2S
			RET

WRONG:
			ACALL LCD_CLR
			MOV DPTR, #TEXT_F
			ACALL LCD_PRINT_LINE1
			ACALL DELAY_2S
			RET
CLEAR_USERIN:
            MOV R1, #5
            MOV R0, #30H
CLR_LOOP:
            MOV @R0, #0
            INC R0
            DJNZ R1, CLR_LOOP
            RET

; -------------------------------
; LCD 初始與控制
; -------------------------------
LCD_INIT:
            MOV A, #38H
            ACALL LCMD
            MOV A, #0CH
            ACALL LCMD
            MOV A, #06H
            ACALL LCMD
            MOV A, #01H
            ACALL LCMD
            MOV A, #02H
            ACALL LCMD
            RET

LCD_CLR:
            MOV A, #01H
            ACALL LCMD
            RET

LCD_PRINT_LINE1:
            ACALL SET_CURSOR_LINE1
LCD_PRINT:
            CLR A
            MOVC A, @A+DPTR
            JZ DONE_PRINT
            ACALL LDAT
            INC DPTR
            SJMP LCD_PRINT
DONE_PRINT:
            RET

SET_CURSOR_LINE1:
            MOV A, #80H
            ACALL LCMD
            RET

SET_CURSOR_LINE2:
            MOV A, #0C0H
            ACALL LCMD
            RET

LDAT:
            MOV P0, A
            SETB RS
            CLR RW
            SETB EN
            ACALL DELAY
            CLR EN
            RET

LCMD:
            MOV P0, A
            CLR RS
            CLR RW
            SETB EN
            ACALL DELAY
            CLR EN
            RET

; -------------------------------
; 下一個字元 '0'~'9','A'~'F' 循環
; -------------------------------
NEXT_CHAR_ROUTINE:
            INC R2
            CJNE R2, #'9'+1, AF_CHECK  ; 跳到 AF_CHECK 檢查是否超過 'F'
            MOV R2, #'A'
            SJMP DONE_NEXT

AF_CHECK:
            CJNE R2, #'F'+1, DONE_NEXT ; 檢查是否超過 'F'
            MOV R2, #'0'              ; 若超過，回到 '0'

DONE_NEXT:
            RET

; -------------------------------
; 延遲副程式
; -------------------------------
DELAY_2S:
            ACALL DELAY
            ACALL DELAY
            ACALL DELAY
            ACALL DELAY
            RET

DELAY:
            MOV R7, #255
D1:         MOV R6, #255
D2:         DJNZ R6, D2
            DJNZ R7, D1
            RET

INT0_ISR:
			MOV R5, #1
            SETB 25H 
            RETI
   END