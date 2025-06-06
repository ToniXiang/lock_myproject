            ORG 0000H
            RS BIT 0x96     ; P2.6
            EN BIT 0x97     ; P2.7
            RW BIT 0x94     ; P2.4
   SETB P3.2
   SETB IT0
   SETB EX0
   SETB EA

IPMSG:      DB "Select 5 DIGITS", 0
TEXT_S:     DB "DOOR OPENED", 0
TEXT_F:     DB "WRONG PASSWORD", 0
PASSW:      DB "12345", 0     ; 正確密碼
USERIN:     DS 5              ; 用來儲存輸入字元（30H~34H）

START:      
            SJMP MAIN_LOOP

MAIN_LOOP:
            ACALL LCD_INIT
            MOV DPTR, #IPMSG
            ACALL LCD_PRINT_LINE1   ; 顯示提示文字
            MOV R0, #30H        ; 輸入次數計數器
            MOV R2, #'0'        ; 循環字元從 '0' 開始
   SJMP INPUT_LOOP

INPUT_LOOP:
    ACALL SET_CURSOR_LINE2
    MOV A, R2
    ACALL LDAT
    ACALL DELAY_2S
    ACALL NEXT_CHAR_ROUTINE
    MOV A, 25H
    JZ INPUT_LOOP

    CLR 25H
	SETB IT0
    ACALL CHECK_PASSWORD
	
    SJMP MAIN_LOOP

; -------------------------------
; 密碼比對
; -------------------------------
CHECK_PASSWORD:
    MOV R3, #0              ; 索引 i = 0
    MOV DPTR, #PASSW        ; 指向密碼常數

CHK_LOOP:
    MOV A, R3
    ADD A, #30H
    MOV R0, A
    MOV A, @R0              ; 取出使用者輸入 USERIN[i]
    MOV 40H, A              ; 存到 RAM 40H 暫存

    ; 取出對應密碼 PASSW[i]
    MOV A, R3
    MOVC A, @A+DPTR         ; 取 ROM 中密碼
    CJNE A, 40H, WRONG      ; 和使用者輸入比較

    INC R3
    CJNE R3, #5, CHK_LOOP

    SJMP CORRECT

CORRECT:
            ACALL LCD_CLR
            MOV DPTR, #TEXT_S
            ACALL LCD_PRINT_LINE1
   ACALL DELAY_2S
            SJMP MAIN_LOOP

WRONG:
            ACALL LCD_CLR
            MOV DPTR, #TEXT_F
            ACALL LCD_PRINT_LINE1
            ACALL DELAY_2S
            SJMP MAIN_LOOP

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
            SETB 25H 
            AJMP INPUT_LOOP
   END