            ORG 0000H
            LJMP START
            ORG 0003H
            LJMP INT0_ISR
			ORG 0013H
            LJMP INT1_ISR

TEXT1: 		DB "PASSWORD BASED",0      ; 開機畫面第一行
TEXT2:		DB "SECURITY SYSTEM",0     ; 開機畫面第二行
MSG_PREFIX:    DB "Select ", 0
MSG_SUFFIX:    DB " DIGITS", 0
TEXT_S:     DB "DOOR OPENED", 0
TEXT_F:     DB "WRONG PASSWORD", 0
TEXT_S1:	DB "ACCESS - GRANTED",0    ; 成功訊息第一行
TEXT_S2:	DB "DOOR OPENED",0         ; 成功訊息第二行
TEXT_F1:	DB "WRONG PASSWORD",0      ; 失敗訊息第一行
TEXT_F2:	DB "ACCESS DENIED",0       ; 失敗訊息第二行
RESET_MSG: DB "INPUT CLEARED", 0
PASSW:      DB "123", 0     ; 正確密碼
USERIN:     DS 3              ; 用來儲存輸入字元（30H~34H）
	        RS BIT 0x96     ; P2.6
            EN BIT 0x97     ; P2.7
            RW BIT 0x94     ; P2.4

START:    
			ACALL LCD_INIT
			MOV DPTR,#TEXT1     ; 載入「PASSWORD BASED」
			ACALL LCD_PRINT
			ACALL LINE2
			MOV DPTR,#TEXT2     ; 載入「SECURITY SYSTEM」
			ACALL LCD_PRINT  
			ACALL Delay_2S;
            SETB P3.2
            SETB IT0
            SETB EX0
            SETB EA
			SETB EX1
            SETB IT1
			MOV R4, #0

MAIN_LOOP:
			SETB EX1
            SETB IT1
            ACALL LCD_INIT
            ACALL SHOW_REMAINING_DIGITS
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

SHOW_REMAINING_DIGITS:
            ACALL SET_CURSOR_LINE1

            ; 顯示 "Select "
            MOV DPTR, #MSG_PREFIX
            ACALL LCD_PRINT

            ; 顯示剩餘次數 = 3 - R4
            CLR C
            MOV A, #3
            SUBB A, R4
            ADD A, #30H
            ACALL LDAT

            ; 顯示 " DIGITS"
            MOV DPTR, #MSG_SUFFIX
            ACALL LCD_PRINT

            RET
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
			ACALL LCD_INIT
			MOV DPTR, #TEXT_S1
			ACALL LCD_PRINT
			MOV DPTR, #TEXT_S2
			ACALL LINE2
			ACALL LCD_PRINT
			ACALL DELAY_2S
			RET

WRONG:
			ACALL LCD_INIT
			MOV DPTR, #TEXT_F1
			ACALL LCD_PRINT
			MOV DPTR, #TEXT_F2
			ACALL LINE2
			ACALL LCD_PRINT
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
LINE2:
   MOV A,#0C0H
   ACALL LCMD
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
            CLR IE0
            RETI
INT1_ISR:
			ACALL LCD_INIT
			MOV DPTR, #RESET_MSG
			ACALL LCD_PRINT
			ACALL DELAY_2S
            ACALL CLEAR_USERIN
            MOV R4, #0     
            CLR IE1        
            LJMP MAIN_LOOP 
   END