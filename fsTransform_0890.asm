;============================================================
; ����8051�ľ�����̼���ϵͳ
; Ӳ�����ã�
;   P1.0-P1.5: ��������
;   P1.6-P1.7+P2.0-P2.3: ��������
;   P3.4: ��ԿA״ָ̬ʾ
;   P3.5: ��ԿB״ָ̬ʾ
;   P2.4-P2.5: ������Ƭѡ(�������ʾ)
;   P0: DAC0832��������
;   P2.6: DACƬѡ(����Ч)
;   P3.0-P3.1: ����ͨ��
;   P3.2: �ⲿ�ж�0(����ģʽ�л�)
;   P3.6: LEDָʾ�ź�
;============================================================

;============= �Ĵ�������־���� =============
ROW       EQU  36H        ; ������ɨ��ֵ
COLUMN    EQU  37H        ; ������ɨ��ֵ
AKEY	  EQU  38H		  ; A��Կֵ���
BKEY	  EQU  39H		  ; B��Կֵ���
P_VAL	  EQU  3AH		  ; ����������ֵ
C_VAL	  EQU  3BH		  ; ���ܺ����ֵ
TEMP 	  EQU  3CH		  ; �ݴ�ֵ
TEST      EQU  3DH		  ; ���ڲ���

DAC_CS    BIT  P2.4		  ; DAC0832Ƭѡ�ź�
SEGA  	  BIT  P3.0		  ; A���������λ
SEGB	  BIT  P3.1		  ; B���������λ
LEDA	  BIT  P3.4		  ; A�������ʾָʾ��
LEDB	  BIT  P3.5	 	  ; B�������ʾָʾ��
LED_COV   BIT  P3.2		  ; ����ֵ���ָʾ��
A_VALID	  BIT  F0		  ; A��Чλ
KEY_FLAG  BIT  00H		  ; AB��Կ�������ָʾλ
DAC_WR	  BIT  P3.6		  ; DACд���ź�

DAC_ADDR  EQU  0000H	  ; DAC�����ַ

;R3��R3Ϊ�м���ֵ
;R4��R4Ϊ�м���ֵ

;============= �ж������� =============
ORG 0000H
LJMP MAIN

ORG 0013H
LJMP EXT1_ISR

;============= �������ʼ�� =============
ORG 0030H
MAIN:
    ; ��ʼ����ջָ��
    MOV SP, #60H
	; ��ʼ��A
	MOV A, #00H
    
    ; ��ʼ���˿�״̬
    MOV P1, #0FFH        ; ���̶˿��ø�
    MOV P2, #0FFH        ; ������/DAC�����ø�

	; Ϩ�������
	MOV P0, #00H		 ; P0�˿����0

	; ���������A
	ACALL DELAY_50MS
	CLR SEGA
	; ���������B
	ACALL DELAY_50MS
	CLR SEGB

	; Ϩ��LED��
	SETB LEDA
	SETB LEDB

	; ���A��Чλ
	CLR A_VALID

	; ���A,B�ɹ������־λ
	CLR KEY_FLAG

	; ���ڲ��ԣ��ɹ���ɾ
	;SETB A_VALID

	; �ر�DAC_CSƬѡ�������ⲿѰַ
	;SETB DAC_CS
	
	; �жϴ�
	SETB EA				 ; �����ж�
	SETB EX1			 ; ���ⲿ�ж�1�ж�
	SETB IT1			 ; �ⲿ�ж�1Ϊ���ش���	 

; ����A��Կ
INPUT_A:
	ACALL KEY_SCAN				; ɨ���ֵ����

; ����B��Կ
INPUT_B:
	ACALL KEY_SCAN				; ɨ���ֵ����
	MOV P1, #0C0H				; �����ް������µ�ƽ״̬
	MOV P2, #0FFH				
	
	; A,B�߼�������ɣ�����DAC��ģת��ģʽ
	SJMP DATAINPUT

; ��������ģ�飬������ΪP_VAL�����ܽ��ΪC_VAL����������������⡣��ʱKEY_FLAG=1��A_VALID=1
DATAINPUT:
	MOV TEST, #60H				; ���ڲ����Ƿ����DATAINPUT
	ACALL KEY_SCAN			    ; ɨ���ֵ����

	; Ϊ��ֹ��·����ȫ������͵�ƽ���ٿ�P0ת��ַ����+��������
	MOV P1, #00H				  ; P1ȫ�͵�ƽ
	MOV P2, #10H				  ; P2ȫ�͵�ƽ

	ACALL DELAY_100MS			; ��ʱ�����ڷ�ʱ����P2����ֹ��ƽ���ȶ�

	ACALL DAC					; ����DAC

	;ACALL DELAY_100MS			
	;ACALL DELAY_100MS			
	ACALL DELAY_50MS			; ��ʱ250MS�ȶ�DAC

	SJMP DATAINPUT				; һ��DAC��ģת����ɽ�����һ����ֵɨ��				


	
;============= ģ��1���������ɨ��(��ɨ�跨) =============
KEY_SCAN:
	MOV P1, #0C0H
	MOV P2, #0FFH				; �ް�������
	MOV A, P2					; �ݴ�P2
	ANL A, #0FH					; ��ȡ��4λ
	RL A						
	RL A						; ����2�� �������00001111->00111100
	MOV R3, A				; �洢��ֵ��4λ
	MOV A, P1					; �ݴ�P1
	SWAP A						; ����A�ֽ� 11000000->00001100
	RR A
	RR A						; ����2�� ���������00001100->00000011
	ANL A, #03H					; ��ȡ��2λ
	ORL A, R3				; ���
	CJNE A, #3FH, VIBRATE_DETECT		;������ʱ��ת�������
	SJMP KEY_SCAN

VIBRATE_DETECT:
	ACALL DELAY_10MS			; ���а�����ʱ
	ACALL DELAY_10MS			; ���а�����ʱ
	MOV P1, #0C0H
	MOV P2, #0FFH				; �ް�������
	MOV A, P2					; �ݴ�P2
	ANL A, #0FH					; ��ȡ��4λ
	RL A						
	RL A						; ����2�� �������00001111->00111100
	MOV R3, A				; �洢��ֵ��4λ
	MOV A, P1					; �ݴ�P1
	SWAP A						; ����A�ֽ� 11000000->00001100
	RR A
	RR A						; ����2�� ���������00001100->00000011
	ANL A, #03H					; ��ȡ��2λ
	ORL A, R3					; ���
	MOV TEMP, A							; A�ݴ浽TEMP
	CJNE A, #3FH, ROWSCAN_INITIAL		; ������ʱ��ת��ɨ��
	SJMP KEY_SCAN


			
	
ROWSCAN_INITIAL:
	MOV COLUMN, A				; �洢��ֵ 						����������������������
	MOV TEMP, #00H				; ����ݴ�ֵ
	MOV P1, #0FEH				; ����ɨ�裬��P1.0��ʼ
	MOV P2, #0FFH				; ����������ȫ1
	MOV A, #0FEH				; A = 11111110
	MOV R4, #00H				; ��ʼ���м���ֵ
	MOV R2, #00H				; ��ʼ���м���ֵ
ROWSCAN:
	MOV P1, A					; A����P1
	PUSH ACC					; ��A���ж�ջ
	MOV A, P2					; �ݴ�P2
	ANL A, #0FH					; ��ȡ��4λ
	RL A						
	RL A						; ����2�� �������00001111->00111100
	MOV R3, A				; �洢��ֵ��4λ
	MOV A, P1					; �ݴ�P1
	SWAP A						; ����A�ֽ� 11000000->00001100
	RR A
	RR A						; ����2�� ���������00001100->00000011
	ANL A, #03H					; ��ȡ��2λ
	ORL A, R3				; ���
	CJNE A, #3FH, COLUMNVALUE_INITIAL		; ������ʱ��ת��ɨ����		
	CJNE R2, #05H, ROWSCAN_SHIFT	; ��������
	AJMP KEY_SCAN				; ������������ת�ؼ�ֵɨ�� 
ROWSCAN_SHIFT:
	POP ACC						; ����A
	RL A						; ����A 11111110->11111101->11111011->11110111->11101111->11011111
	INC R2						; R2�Լ�1
	SJMP ROWSCAN				; ��תɨ���г���

; �����ֵ 	R2����ŵ�ǰ��⵽����ֵ
COLUMNVALUE_INITIAL:
	POP ACC						; ���ն�ջ
	MOV DPTR, #COLUMN_TAB		; ������ͷָ��
	MOV R4, #00H				; ��ʼ��R4
	MOV A, #00H					; A���
COLUMNVALUE:
	MOVC A, @A+DPTR 				; ָ��ָ������������ȡ��ֵ
	CJNE A, COLUMN, COLUMNVALUE_SHIFT 			; ��ǰ�������ݲ�������ֵ����ʱ˵����������ֵ
	SJMP KEYCODE_CALCULATOR
COLUMNVALUE_SHIFT:
	INC R4
	MOV A, R4
	CJNE R4, #06H, COLUMNVALUE	; ������������������ɼ�û�ж�Ӧ��ֵ
	AJMP KEY_SCAN				; ��ת�ذ������

KEYCODE_CALCULATOR:
	MOV COLUMN, R4				; �洢��ֵ
	MOV ROW, R2					; �洢��ֵ
	MOV B, #06H					; ���ڳ˻�
	MOV A, ROW					; ��ȡ��ֵ
	MUL AB						; �˻�����õ���ֵ*5
	ADD A, COLUMN				; ����õ���ֵ*5+��ֵ��������
	INC A						; A�Լ�1��ʹ�ü�ֵ��Χ��Ϊ1-36

; ��Ч�Ժ�A,B�洢��������
VAME:
	JB KEY_FLAG, KEY_CRYPTO    ; ˵��A,B������ɣ���ʼ����ת����
	ACALL GCD_ENTRY				; ����GCD
	JNB A_VALID, MIDDLE_JMP		; A��36���������������ɨ��
	MOV R5, AKEY				; �ݴ�AKEY��R5
	CJNE R5, #00H, BMRY			; A�ǿ�˵����ǰ����A���뵼��A_VALID=1
	SJMP AMRY					; ��תA��Կ�洢����

MIDDLE_JMP:
	LJMP SQUAREWAVE				; ��ת�ܿ�JNB��rel����

; �洢A��Կ���ݵ�AKEY��AΪ0��������С����1��
AMRY:
	MOV AKEY, A					; �洢��ǰ��ֵ���ݵ�AKEY
	
	CLR LEDA					; ����ALED
	SETB SEGA					; ��A������ſ�

	ACALL DELAY_50MS			; ��ʱ50ms

	SJMP KEYTOSEG				; ��ת����ֵת���������

; �洢B��Կ���ݵ�BKEY
BMRY:
	MOV BKEY, A					; �洢��ǰ��ֵ���ݵ�BKEY

	CLR LEDB					; ����BLED
	SETB SEGB					; ��B������ſ�

	SETB KEY_FLAG		 		; A,B������ɱ�־

; ����ת���������
KEYTOSEG:
	MOV DPTR, #SEG_TABLE_CC		; ��������������ͷָ��
	MOVC A, @A+DPTR				; ��ȡ��Ӧ�Ĺ���������
	MOV P0, A					; ������뵽P0
	ACALL DELAY_100MS			; ��ʱ�ر�������ſ�
	CLR SEGA					; �ر�A������ſ�
	CLR SEGB					; �ر�B������ſ�
	RET							; ����������

;============= ģ��2���������ݼ����㷨 =============
; ����ת������ֵ�������㷨C=AP+B
KEY_CRYPTO:
	MOV P_VAL, A			 	; �洢����ֵPֵ��ֻ��KEY_FLAG & A_VALID=1���ܹ�����
	MOV B, AKEY				    ; ��ȡ��ԿA
	;MOV TEST, B					; ���B�Ĵ���
	MOV R1, BKEY				; ��ȡ��ԿB
	MUL AB						; �˻�����AP
	JBC PSW.2, C_OV				; OV������0��˵���������00FFH    ;;;;;;;;;;;;;;;;;;;;

	CLR C						; �����λ
	
	ADD A, R1					; �ӷ�����AP+B

	MOV B, #36					; B���36
	DIV AB						; ��⣨AP+C�� mod 36
	MOV A, B					; ���������õ�A����Ϊ���ռ���ֵC_VAL
	MOV TEMP, A					; �ȷ��õ��ݴ�

								
	JC C_OV						; C=1��˵�������	
	MOV C_VAL, TEMP				; ��ʱ����ֵ��Ч
	RET							; ����������

; ����ֵ����������������
C_OV:
	;CLR OV						; ������λ
	CLR C						; �����λ��־λ
	MOV P_VAL, #00H
	MOV C_VAL, #00H
	MOV TEMP, #00H				; ����ݴ�
	MOV B, #00H					; ���B
	ACALL COV_WAVE				; ������ָʾ����
	AJMP EXT1_ISR				; ���ø�λ����RETI��ʱ��RET�����ϲ������������жϲ�û�д򿪲�Ӱ��RETI��RET��
	
		
	
;============= ģ��3��A��黥��GCD����ģ�飨GCD(A,B)=GCD(B,A MOD B)�� =============	
GCD_ENTRY:
	JB A_VALID, GCD_EXIT		 ; A_VALID=1������ҪGCD
	MOV R0, #36					 ; R0Ϊ36�������жϻ���
	MOV R1, A				 	 ; R1��������жϵ�A��ֵ

	PUSH ACC 					 ; ����ԭ�м�ֵ  �����Ƿ���Ҫ����

	ACALL GCD					 ; ����GCD����Ž��������A

	POP ACC						 ; ����A���ڶ�ջ��ԭ�м�ֵ���ָ��ֳ�
	RET							 ; ����������	

GCD:
	; �жϻ��ʣ������㻥����A_VALID=1���������㻥����A_VALID=0
	MOV A, R1
	JZ GCD_EXIT					  ; ���AΪ0��˵������AΪ0������ϵ�����ܣ�
	CJNE A, #01H, GCD_LOOP		  ; ���A������1��A������0��֤�������ܻ��ʣ���ʼ�����ж�
	SJMP GCD_EXIT				  ; ���AΪ1������֤�����ǻ��ʣ���Ҫ�ų�1

GCD_LOOP:
	MOV A, R0					  ; R0�Ǳ�����
	MOV B, R1				   	  ; R1�ǳ���
	DIV AB						  ; A/B->A����̣�B���������������Ϊ0˵�������Լ�����
	MOV TEMP, R1				  ; ��TEMP��Ϊ������תR1��ֵ
	MOV R0, TEMP				  ; ���ʵ��R1��ֵ��R0
	MOV R1, B					  ; ���������õ�R1			ʵ��GCD(A,B)=GCD(B,A MOD B)
	CJNE R1, #00H, GCD_LOOP		  ; ������Ϊ0���������ѭ��
GCD_DONE:
	MOV A, R0					  ; A=GCD
	ACALL A_VALIDITY			  ; ����A��Ч���ж�
	RET
; ����A��Ч�Լ���
A_VALIDITY:
	CJNE A, #1, GCD_EXIT		  ; GCD!=1,�����ʣ�A_VALID=0���ֲ���
	SETB A_VALID				  ; GCD-1�����ʣ���A_VALID-1
	RET							  ; ����������

GCD_EXIT:
	RET							  ; ����������



;============= ģ��4���ⲿ�ж�1�жϴ������ģ�� =============
DAC:	

	;MOV DPTR, #DAC_ADDR			  ; ѡ��DPTRָ��DAC��ַ
	CLR DAC_WR						  ; д������DAC
	CLR DAC_CS					  ; ��DACƬѡ
	ACALL DELAY_10MS			  ; ��ʱ�ȶ�
	MOV A, C_VAL				  ; ��ȡ����ֵC_VAL
	MOV P0, A					  ; ������ֵ���
	;MOVX @DPTR, A				  ; ������ֵд��DAC����ʱP0�л���ַ����ѡ��DAC_ADDR�����л������������C_VAL��WR�Զ�����д���źţ���ʱDAC��ʼת��
	ACALL DELAY_10MS			  ; ��ʱ�ȶ�
	SETB DAC_WR					  ; ��ֹд��DAC
	SETB DAC_CS					  ; ��ֹ��DACƬѡ
	ACALL DELAY_10MS			  ; ��ʱ�ȶ�	
	RET							  ; ����������



;============= ģ��5���ⲿ�ж�1�жϴ������ģ�� =============
EXT1_ISR:
	CLR IE1							 ; ����ⲿ�ж�1�жϱ�־
	CLR C							 ; �����λ��־λ
	CLR OV							 ; ��������־λ

	MOV P_VAL, #00H
	MOV C_VAL, #00H
	MOV TEMP, #00H

	POP ACC
	POP ACC 						 ; ������������ַ
	
	MOV A, #00H						 ; A��0
	PUSH ACC
	PUSH ACC						 ; �洢��λ��ַ

	; ���A��Կ��B��Կ
	MOV AKEY, #00H		 ; ���A��Կ�洢	  ��������������������
	MOV BKEY, #00H		 ; ���B��Կ�洢		��������������������
	
	; �������
	SETB SEGA
	SETB SEGB

	RETI					 ; ��λ���ж��߼�����

;============= ģ��6����ʱ�ӳ���ģ�� =============
; 10ms��ʱ
DELAY_10MS:
    MOV R5, #20
DL1: MOV R6, #250
DL2: NOP
     NOP
     DJNZ R6, DL2
     DJNZ R5, DL1
     RET

; 50ms��ʱ
DELAY_50MS:
    MOV R7, #5
DL3: CALL DELAY_10MS
     DJNZ R7, DL3
     RET

; 100ms��ʱ
DELAY_100MS:
    MOV R7, #10
DL4: CALL DELAY_10MS
     DJNZ R7, DL3
     RET

; 500ms��ʱ
DELAY_500MS:
    MOV R0, #5
DL5: CALL DELAY_100MS
     DJNZ R0, DL4
     RET

; 1s��ʱ
DELAY_1S:
    MOV R0, #10
DL6: CALL DELAY_100MS
     DJNZ R0, DL4
     RET

; �ǻ��ʣ���A_VALID=0������ת�������300ms��ʾ
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

; ����ֵ������2s����ָʾӦ����������A,B��Կ��֤�������
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

	

;============= ģ��7����ֵ����ģ�� =============
COLUMN_TAB:
	DB 3EH, 3DH, 3BH, 37H, 2FH, 1FH		;0-5��

;----- ���ݶζ��壨��A-Z��+��1234567890����������� -----   
SEG_TABLE_CA:  
    ; ���ڴ����36�����루0-35�ż���Ӧֵ��
   DB 88H, 83H, 0C6H, 0A1H, 86H, 8EH, 0C2H, 89H, 0F0H
   DB 0F1H, 8AH, 0C7H, 0C8H, 0ABH, 0A3H, 8CH, 98H, 0CEH
   DB 0B6H, 87H, 0C1H, 0E3H, 81H, 9BH, 91H, 0A5H, 0F9H
   DB 0A4H, 0B0H, 99H, 92H, 82H, 0D8H, 80H, 90H, 0C0H

;----- ���ݶζ��壨��������� ----- 
SEG_TABLE_CC:
    ; ���ڴ����36�����루0-35�ż���Ӧֵ��
   DB 00H, 0F7H, 0FCH, 0B9H, 0DEH, 0F9H, 0F1H, 0BDH, 0F6H, 8FH ;00H���ڿճ�������λ
   DB 8EH, 0F5H, 0B8H, 0B7H, 0D4H, 0DCH, 0F3H, 0E7H, 0B1H
   DB 0C9H, 0F8H, 0BEH, 9CH, 0FEH, 0E4H, 0EEH, 0DAH, 86H
   DB 0DBH, 0CFH, 0E6H, 0EDH, 0FDH, 0A7H, 0FFH, 0EFH, 0BFH	  
END