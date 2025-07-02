;============================================================
; 基于8051的矩阵键盘加密系统
; 硬件配置：
;   P1.0-P1.5: 键盘行线
;   P1.6-P1.7+P2.0-P2.3: 键盘列线
;   P3.4: 密钥A状态指示
;   P3.5: 密钥B状态指示
;   P2.4-P2.5: 锁存器片选(数码管显示)
;   P0: DAC0832数据总线
;   P2.6: DAC片选(低有效)
;   P3.0-P3.1: 串口通信
;   P3.2: 外部中断0(输入模式切换)
;   P3.6: LED指示信号
;============================================================

;============= 寄存器及标志定义 =============
ROW       EQU  36H        ; 键盘行扫描值
COLUMN    EQU  37H        ; 键盘列扫描值
AKEY	  EQU  38H		  ; A密钥值存放
BKEY	  EQU  39H		  ; B密钥值存放
P_VAL	  EQU  3AH		  ; 待加密输入值
C_VAL	  EQU  3BH		  ; 加密后输出值
TEMP 	  EQU  3CH		  ; 暂存值
TEST      EQU  3DH		  ; 用于测试

DAC_CS    BIT  P2.4		  ; DAC0832片选信号
SEGA  	  BIT  P3.0		  ; A数码管锁存位
SEGB	  BIT  P3.1		  ; B数码管锁存位
LEDA	  BIT  P3.4		  ; A数码管显示指示灯
LEDB	  BIT  P3.5	 	  ; B数码管显示指示灯
LED_COV   BIT  P3.2		  ; 加密值溢出指示灯
A_VALID	  BIT  F0		  ; A有效位
KEY_FLAG  BIT  00H		  ; AB密钥输入完成指示位
DAC_WR	  BIT  P3.6		  ; DAC写入信号

DAC_ADDR  EQU  0000H	  ; DAC外设地址

;R3：R3为行计数值
;R4：R4为列计数值

;============= 中断向量表 =============
ORG 0000H
LJMP MAIN

ORG 0013H
LJMP EXT1_ISR

;============= 主程序初始化 =============
ORG 0030H
MAIN:
    ; 初始化堆栈指针
    MOV SP, #60H
	; 初始化A
	MOV A, #00H
    
    ; 初始化端口状态
    MOV P1, #0FFH        ; 键盘端口置高
    MOV P2, #0FFH        ; 锁存器/DAC控制置高

	; 熄灭数码管
	MOV P0, #00H		 ; P0端口输出0

	; 锁存数码管A
	ACALL DELAY_50MS
	CLR SEGA
	; 锁存数码管B
	ACALL DELAY_50MS
	CLR SEGB

	; 熄灭LED灯
	SETB LEDA
	SETB LEDB

	; 清除A有效位
	CLR A_VALID

	; 清除A,B成功输入标志位
	CLR KEY_FLAG

	; 用于测试，成功即删
	;SETB A_VALID

	; 关闭DAC_CS片选，用于外部寻址
	;SETB DAC_CS
	
	; 中断打开
	SETB EA				 ; 打开总中断
	SETB EX1			 ; 打开外部中断1中断
	SETB IT1			 ; 外部中断1为边沿触发	 

; 输入A密钥
INPUT_A:
	ACALL KEY_SCAN				; 扫描键值输入

; 输入B密钥
INPUT_B:
	ACALL KEY_SCAN				; 扫描键值输入
	MOV P1, #0C0H				; 返回无按键按下电平状态
	MOV P2, #0FFH				
	
	; A,B逻辑输入完成，进入DAC数模转换模式
	SJMP DATAINPUT

; 数据输入模块，输入数为P_VAL，加密结果为C_VAL，考虑溢出后处理问题。此时KEY_FLAG=1，A_VALID=1
DATAINPUT:
	MOV TEST, #60H				; 用于测试是否进入DATAINPUT
	ACALL KEY_SCAN			    ; 扫描键值输入

	; 为防止短路，先全部输出低电平，再靠P0转地址总线+数据总线
	MOV P1, #00H				  ; P1全低电平
	MOV P2, #10H				  ; P2全低电平

	ACALL DELAY_100MS			; 延时，用于分时复用P2，防止电平不稳定

	ACALL DAC					; 调用DAC

	;ACALL DELAY_100MS			
	;ACALL DELAY_100MS			
	ACALL DELAY_50MS			; 延时250MS稳定DAC

	SJMP DATAINPUT				; 一次DAC数模转换完成进行下一个键值扫描				


	
;============= 模块1：矩阵键盘扫描(行扫描法) =============
KEY_SCAN:
	MOV P1, #0C0H
	MOV P2, #0FFH				; 无按键按下
	MOV A, P2					; 暂存P2
	ANL A, #0FH					; 提取低4位
	RL A						
	RL A						; 左移2次 正常情况00001111->00111100
	MOV R3, A				; 存储列值高4位
	MOV A, P1					; 暂存P1
	SWAP A						; 交换A字节 11000000->00001100
	RR A
	RR A						; 右移2次 正常情况下00001100->00000011
	ANL A, #03H					; 提取低2位
	ORL A, R3				; 求或
	CJNE A, #3FH, VIBRATE_DETECT		;不等于时跳转抖动检测
	SJMP KEY_SCAN

VIBRATE_DETECT:
	ACALL DELAY_10MS			; 进行按键延时
	ACALL DELAY_10MS			; 进行按键延时
	MOV P1, #0C0H
	MOV P2, #0FFH				; 无按键按下
	MOV A, P2					; 暂存P2
	ANL A, #0FH					; 提取低4位
	RL A						
	RL A						; 左移2次 正常情况00001111->00111100
	MOV R3, A				; 存储列值高4位
	MOV A, P1					; 暂存P1
	SWAP A						; 交换A字节 11000000->00001100
	RR A
	RR A						; 右移2次 正常情况下00001100->00000011
	ANL A, #03H					; 提取低2位
	ORL A, R3					; 求或
	MOV TEMP, A							; A暂存到TEMP
	CJNE A, #3FH, ROWSCAN_INITIAL		; 不等于时跳转行扫描
	SJMP KEY_SCAN


			
	
ROWSCAN_INITIAL:
	MOV COLUMN, A				; 存储列值 						；；；；；；；；；；；
	MOV TEMP, #00H				; 清除暂存值
	MOV P1, #0FEH				; 逐行扫描，从P1.0开始
	MOV P2, #0FFH				; 重新载入列全1
	MOV A, #0FEH				; A = 11111110
	MOV R4, #00H				; 初始化列计数值
	MOV R2, #00H				; 初始化行计数值
ROWSCAN:
	MOV P1, A					; A载入P1
	PUSH ACC					; 将A进行堆栈
	MOV A, P2					; 暂存P2
	ANL A, #0FH					; 提取低4位
	RL A						
	RL A						; 左移2次 正常情况00001111->00111100
	MOV R3, A				; 存储列值高4位
	MOV A, P1					; 暂存P1
	SWAP A						; 交换A字节 11000000->00001100
	RR A
	RR A						; 右移2次 正常情况下00001100->00000011
	ANL A, #03H					; 提取低2位
	ORL A, R3				; 求或
	CJNE A, #3FH, COLUMNVALUE_INITIAL		; 不等于时跳转行扫描检测		
	CJNE R2, #05H, ROWSCAN_SHIFT	; 遍历数组
	AJMP KEY_SCAN				; 数组遍历完成跳转回键值扫描 
ROWSCAN_SHIFT:
	POP ACC						; 弹出A
	RL A						; 左移A 11111110->11111101->11111011->11110111->11101111->11011111
	INC R2						; R2自加1
	SJMP ROWSCAN				; 跳转扫描行程序

; 检测列值 	R2存放着当前检测到的行值
COLUMNVALUE_INITIAL:
	POP ACC						; 弹空堆栈
	MOV DPTR, #COLUMN_TAB		; 列数组头指针
	MOV R4, #00H				; 初始化R4
	MOV A, #00H					; A清空
COLUMNVALUE:
	MOVC A, @A+DPTR 				; 指针指向数组内容提取列值
	CJNE A, COLUMN, COLUMNVALUE_SHIFT 			; 当前数组内容不等于列值，此时说明还不是列值
	SJMP KEYCODE_CALCULATOR
COLUMNVALUE_SHIFT:
	INC R4
	MOV A, R4
	CJNE R4, #06H, COLUMNVALUE	; 数组遍历，数组遍历完成即没有对应列值
	AJMP KEY_SCAN				; 跳转回按键检测

KEYCODE_CALCULATOR:
	MOV COLUMN, R4				; 存储列值
	MOV ROW, R2					; 存储行值
	MOV B, #06H					; 用于乘积
	MOV A, ROW					; 提取行值
	MUL AB						; 乘积运算得到行值*5
	ADD A, COLUMN				; 计算得到行值*5+列值，即键码
	INC A						; A自加1，使得键值范围变为1-36

; 有效性和A,B存储决定程序
VAME:
	JB KEY_FLAG, KEY_CRYPTO    ; 说明A,B输入完成，开始键码转密码
	ACALL GCD_ENTRY				; 调用GCD
	JNB A_VALID, MIDDLE_JMP		; A与36不互质则继续键盘扫描
	MOV R5, AKEY				; 暂存AKEY到R5
	CJNE R5, #00H, BMRY			; A非空说明当前不是A输入导致A_VALID=1
	SJMP AMRY					; 跳转A密钥存储程序

MIDDLE_JMP:
	LJMP SQUAREWAVE				; 中转避开JNB的rel限制

; 存储A密钥数据到AKEY，A为0（按键最小都是1）
AMRY:
	MOV AKEY, A					; 存储当前键值数据到AKEY
	
	CLR LEDA					; 点亮ALED
	SETB SEGA					; 打开A数码管门控

	ACALL DELAY_50MS			; 延时50ms

	SJMP KEYTOSEG				; 跳转到键值转换段码程序

; 存储B密钥数据到BKEY
BMRY:
	MOV BKEY, A					; 存储当前键值数据到BKEY

	CLR LEDB					; 点亮BLED
	SETB SEGB					; 打开B数码管门控

	SETB KEY_FLAG		 		; A,B输入完成标志

; 键码转换输出段码
KEYTOSEG:
	MOV DPTR, #SEG_TABLE_CC		; 共阴极段码数组头指针
	MOVC A, @A+DPTR				; 提取对应的共阴极段码
	MOV P0, A					; 输出段码到P0
	ACALL DELAY_100MS			; 延时关闭数码管门控
	CLR SEGA					; 关闭A数码管门控
	CLR SEGB					; 关闭B数码馆门控
	RET							; 返回主程序

;============= 模块2：输入数据加密算法 =============
; 键码转换加密值，加密算法C=AP+B
KEY_CRYPTO:
	MOV P_VAL, A			 	; 存储输入值P值，只有KEY_FLAG & A_VALID=1才能够进入
	MOV B, AKEY				    ; 提取密钥A
	;MOV TEST, B					; 检测B寄存器
	MOV R1, BKEY				; 提取密钥B
	MUL AB						; 乘积计算AP
	JBC PSW.2, C_OV				; OV不等于0则说明加密溢出00FFH    ;;;;;;;;;;;;;;;;;;;;

	CLR C						; 清除进位
	
	ADD A, R1					; 加法运算AP+B

	MOV B, #36					; B存放36
	DIV AB						; 求解（AP+C） mod 36
	MOV A, B					; 将余数放置到A，作为最终加密值C_VAL
	MOV TEMP, A					; 先放置到暂存

								
	JC C_OV						; C=1则说明有溢出	
	MOV C_VAL, TEMP				; 此时加密值有效
	RET							; 返回主程序

; 加密值溢出最大输出处理程序
C_OV:
	;CLR OV						; 清除溢出位
	CLR C						; 清除进位标志位
	MOV P_VAL, #00H
	MOV C_VAL, #00H
	MOV TEMP, #00H				; 清除暂存
	MOV B, #00H					; 清除B
	ACALL COV_WAVE				; 输出溢出指示方波
	AJMP EXT1_ISR				; 调用复位程序（RETI此时和RET功能上并无区别，由于中断并没有打开不影响RETI和RET）
	
		
	
;============= 模块3：A检查互质GCD程序模块（GCD(A,B)=GCD(B,A MOD B)） =============	
GCD_ENTRY:
	JB A_VALID, GCD_EXIT		 ; A_VALID=1，不需要GCD
	MOV R0, #36					 ; R0为36，用于判断互质
	MOV R1, A				 	 ; R1存放用于判断的A键值

	PUSH ACC 					 ; 保护原有键值  考虑是否需要保护

	ACALL GCD					 ; 调用GCD，存放结果放置在A

	POP ACC						 ; 弹出A存在堆栈的原有键值，恢复现场
	RET							 ; 返回主程序	

GCD:
	; 判断互质，若满足互质则A_VALID=1，若不满足互质则A_VALID=0
	MOV A, R1
	JZ GCD_EXIT					  ; 如果A为0，说明输入A为0（此体系不可能）
	CJNE A, #01H, GCD_LOOP		  ; 如果A不等于1且A不等于0，证明它可能互质，开始进行判断
	SJMP GCD_EXIT				  ; 如果A为1，不能证明它是互质，需要排除1

GCD_LOOP:
	MOV A, R0					  ; R0是被除数
	MOV B, R1				   	  ; R1是除数
	DIV AB						  ; A/B->A存放商，B存放余数，余数不为0说明还可以继续除
	MOV TEMP, R1				  ; 以TEMP作为过渡中转R1的值
	MOV R0, TEMP				  ; 组合实现R1赋值给R0
	MOV R1, B					  ; 将余数放置到R1			实现GCD(A,B)=GCD(B,A MOD B)
	CJNE R1, #00H, GCD_LOOP		  ; 余数不为0则继续进行循环
GCD_DONE:
	MOV A, R0					  ; A=GCD
	ACALL A_VALIDITY			  ; 调用A有效性判断
	RET
; 调用A有效性计算
A_VALIDITY:
	CJNE A, #1, GCD_EXIT		  ; GCD!=1,不互质，A_VALID=0保持不变
	SETB A_VALID				  ; GCD-1。互质，令A_VALID-1
	RET							  ; 返回主程序

GCD_EXIT:
	RET							  ; 返回主程序



;============= 模块4：外部中断1中断处理程序模块 =============
DAC:	

	;MOV DPTR, #DAC_ADDR			  ; 选择DPTR指定DAC地址
	CLR DAC_WR						  ; 写入允许DAC
	CLR DAC_CS					  ; 打开DAC片选
	ACALL DELAY_10MS			  ; 延时稳定
	MOV A, C_VAL				  ; 读取加密值C_VAL
	MOV P0, A					  ; 将加密值输出
	;MOVX @DPTR, A				  ; 将加密值写入DAC，此时P0切换地址总线选中DAC_ADDR，再切换数据总线输出C_VAL，WR自动发出写入信号，此时DAC开始转换
	ACALL DELAY_10MS			  ; 延时稳定
	SETB DAC_WR					  ; 禁止写入DAC
	SETB DAC_CS					  ; 禁止打开DAC片选
	ACALL DELAY_10MS			  ; 延时稳定	
	RET							  ; 返回主程序



;============= 模块5：外部中断1中断处理程序模块 =============
EXT1_ISR:
	CLR IE1							 ; 清除外部中断1中断标志
	CLR C							 ; 清除进位标志位
	CLR OV							 ; 清除溢出标志位

	MOV P_VAL, #00H
	MOV C_VAL, #00H
	MOV TEMP, #00H

	POP ACC
	POP ACC 						 ; 清除主程序弹入地址
	
	MOV A, #00H						 ; A清0
	PUSH ACC
	PUSH ACC						 ; 存储复位地址

	; 清除A密钥和B密钥
	MOV AKEY, #00H		 ; 清除A密钥存储	  ；；；；；；；；；；
	MOV BKEY, #00H		 ; 清除B密钥存储		；；；；；；；；；；
	
	; 打开数码管
	SETB SEGA
	SETB SEGB

	RETI					 ; 复位加中断逻辑开放

;============= 模块6：延时子程序模块 =============
; 10ms延时
DELAY_10MS:
    MOV R5, #20
DL1: MOV R6, #250
DL2: NOP
     NOP
     DJNZ R6, DL2
     DJNZ R5, DL1
     RET

; 50ms延时
DELAY_50MS:
    MOV R7, #5
DL3: CALL DELAY_10MS
     DJNZ R7, DL3
     RET

; 100ms延时
DELAY_100MS:
    MOV R7, #10
DL4: CALL DELAY_10MS
     DJNZ R7, DL3
     RET

; 500ms延时
DELAY_500MS:
    MOV R0, #5
DL5: CALL DELAY_100MS
     DJNZ R0, DL4
     RET

; 1s延时
DELAY_1S:
    MOV R0, #10
DL6: CALL DELAY_100MS
     DJNZ R0, DL4
     RET

; 非互质，即A_VALID=0，则跳转方波输出300ms显示
SQUAREWAVE:
	CLR LEDA
	ACALL DELAY_50MS
	SETB LEDA
	ACALL DELAY_50MS
	CLR LEDA
	ACALL DELAY_50MS
	SETB LEDA
	ACALL DELAY_50MS
	CLR LEDA
	ACALL DELAY_50MS
	SETB LEDA
	ACALL DELAY_50MS
	LJMP KEY_SCAN

; 加密值溢出输出2s方波指示应该重新输入A,B密钥保证不溢出。
COV_WAVE:
	CLR LED_COV
	ACALL DELAY_100MS
	SETB LED_COV
	ACALL DELAY_100MS
	CLR LED_COV
	ACALL DELAY_100MS
	SETB LED_COV
	ACALL DELAY_100MS
	RET	

	

;============= 模块7：列值数组模块 =============
COLUMN_TAB:
	DB 3EH, 3DH, 3BH, 37H, 2FH, 1FH		;0-5列

;----- 数据段定义（（A-Z）+（1234567890）共阳段码表） -----   
SEG_TABLE_CA:  
    ; 请在此填充36个段码（0-35号键对应值）
   DB 88H, 83H, 0C6H, 0A1H, 86H, 8EH, 0C2H, 89H, 0F0H
   DB 0F1H, 8AH, 0C7H, 0C8H, 0ABH, 0A3H, 8CH, 98H, 0CEH
   DB 0B6H, 87H, 0C1H, 0E3H, 81H, 9BH, 91H, 0A5H, 0F9H
   DB 0A4H, 0B0H, 99H, 92H, 82H, 0D8H, 80H, 90H, 0C0H

;----- 数据段定义（共阴段码表） ----- 
SEG_TABLE_CC:
    ; 请在此填充36个段码（0-35号键对应值）
   DB 00H, 0F7H, 0FCH, 0B9H, 0DEH, 0F9H, 0F1H, 0BDH, 0F6H, 8FH ;00H用于空出数组首位
   DB 8EH, 0F5H, 0B8H, 0B7H, 0D4H, 0DCH, 0F3H, 0E7H, 0B1H
   DB 0C9H, 0F8H, 0BEH, 9CH, 0FEH, 0E4H, 0EEH, 0DAH, 86H
   DB 0DBH, 0CFH, 0E6H, 0EDH, 0FDH, 0A7H, 0FFH, 0EFH, 0BFH	  
END