            ORG 0000H

            RS BIT 0x96     ; P2.6
            EN BIT 0x97     ; P2.7
            RW BIT 0x94     ; P2.4

IPMSG:      DB "Select 5 DIGITS", 0
TEXT_S:     DB "DOOR OPENED", 0
TEXT_F:     DB "WRONG PASSWORD", 0
PASSW:      DB "12345", 0     ; 正確密碼
USERIN:     DS 5              ; 用來儲存輸入字元（30H~34H）

START:      
            ACALL LCD_INIT 
            MOV DPTR, #IPMSG
            ACALL LCD_PRINT_LINE1   ; 顯示提示文字

MAIN_LOOP:
            MOV R0, #00H        ; 輸入次數計數器
            MOV R1, #'0'        ; 循環字元從 '0' 開始

INPUT_LOOP:
            ; 顯示目前循環字元在 LCD 第二行
            ACALL SET_CURSOR_LINE2

            ; 輸出已輸入的字符 (USERIN 區段 30h 開始)
            MOV R0, #30h        ; R0 指向 USERIN[0]
DisplayLoop:
            MOV A, @R0          ; 將 USERIN[R0-30h] 的值讀入累加器
            JZ DoneDisplay      ; 若該處無字符（0），則結束顯示已輸入字符
            ACALL LDAT      ; 輸出累加器中的字符到 LCD
            INC R0
            SJMP DisplayLoop
DoneDisplay:
            ; 輸出一個空格後，再輸出當前的循環字符 R1
            MOV A, #' '        ; 空格字符
            ACALL LDAT
            MOV A, R1          ; 當前候選字符
            ACALL LDAT

            ACALL DELAY_2S      ; 等 0.5 秒

            ; 檢查是否按下 P3.2
            JB P3.2, NEXT_CHAR

            ; 若按下，儲存目前字元
            MOV A, R0
            ADD A, #30H
            MOV R1, A           ; 計算儲存地址
            MOV A, R1
            MOV @R1, A

            INC R0              ; 增加輸入字元計數
            CJNE R0, #5, NEXT_CHAR

            ; 已輸入 5 字元，進行驗證
            ACALL CHECK_PASSWORD

NEXT_CHAR:
            ACALL NEXT_CHAR_ROUTINE
            SJMP INPUT_LOOP

; -------------------------------
; 密碼比對
; -------------------------------
CHECK_PASSWORD:
    MOV R0, #0              ; 索引 i = 0
    MOV DPTR, #PASSW        ; 指向密碼常數

CHK_LOOP:
    ; A = 30H + R0（對應 USERIN[i]）
    MOV A, R0
    ADD A, #30H
    MOV R1, A
    MOV A, @R1              ; 取出使用者輸入 USERIN[i]
    MOV 40H, A              ; 存到 RAM 40H 暫存

    ; 取出對應密碼 PASSW[i]
    MOV A, R0
    MOVC A, @A+DPTR         ; 取 ROM 中密碼
    CJNE A, 40H, WRONG      ; 和使用者輸入比較

    INC R0
    CJNE R0, #5, CHK_LOOP

    SJMP CORRECT

CORRECT:
            ACALL LCD_CLR
            MOV DPTR, #TEXT_S
            ACALL LCD_PRINT_LINE1
            SJMP $

WRONG:
            ACALL LCD_CLR
            MOV DPTR, #TEXT_F
            ACALL LCD_PRINT_LINE1
            ACALL DELAY_2S
            AJMP START

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
            INC R1
            CJNE R1, #'9'+1, AF_CHECK  ; 跳到 AF_CHECK 檢查是否超過 'F'
            MOV R1, #'A'
            SJMP DONE_NEXT

AF_CHECK:
            CJNE R1, #'F'+1, DONE_NEXT ; 檢查是否超過 'F'
            MOV R1, #'0'              ; 若超過，回到 '0'

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

            END