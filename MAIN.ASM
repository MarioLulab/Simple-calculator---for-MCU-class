            ;;���ڰ�������ģ��
            INDEX_DISP   EQU    58H     ;��ǰҪ���������չʾ�ڵڼ�λ
            OPTION       EQU    59H     ;����һ�����򴢴������

            ;;����LEDչʾģ��
            LED_BUF      EQU    60H     ;����LED������Ϊ60H-67H
            N_DISP       EQU    68H     ;���嵱ǰɨ�赽�˵ڼ���λ��,���ݴ�����68H

            ;;���ڳ�ʼ������ռ�ĺ���
            BUF_HEAD     EQU   55H     ;����ʼ����Ŀ�껺��ͷ��ַ
            BUF_LENGTH   EQU   56H     ;����ʼ����Ŀ�껺�泤��
            INIT_VALUE   EQU   57H     ;��ʼ���ɵ�ֵ

            ;;���ڼ���ɨ�����
            N_SAME       EQU    43H     ;��ǰ��⵽�ļ����ǵڼ�����ͬ
            THRESHOLD    EQU    42H     ;�����ֵ

            KEYCODE      EQU    40H     ;�洢��KEYCODE
            LASTCODE     EQU    41H     ;�ϴμ�⵽��KEYCODE

            ;BCD��ת����HEX��ĳ���
            BCD_WT_HEX   EQU    50H     ;��ת����HEX�ķ�ѹ��BCD�뻺�������ɸߵ���30H-34H

            ;;���㺯��CALCULATE
            FIRST_NUM    EQU   35H      ;����õĵ�һ��������35H-36H
            SECOND_NUM  EQU   37H      ;����õĵڶ���������37H-38H
            DATA1        EQU   39H      ;�൱��FIRST_NUM��һ������
            DATA2        EQU   3BH      ;�൱��SECOND_NUM��һ������

            ;;��¼��һ������Ľ�������ڽ�����������
            LAST_RESULT EQU     69H     ;69H-6AH��¼��һ������Ľ��(���ģʽ)
            ;3DH�����м���
            BIT_2ms      BIT   01H            ;2ms��ʱ����־
            IS_NONSTOP   BIT   02H            ;�Ƿ�����������ı�־

            ORG         0000H
            LJMP        INITIALIZE
            ORG         000BH
            LJMP        INTER_T0
            ORG         0010H
INITIALIZE:
            MOV     TMOD,#01H              ;;TIMER0 MODE1
            MOV     TCON,#0
            MOV     TH0,#0F8H
            MOV     TL0,#30H               ;;�趨2mS��ʱ
            MOV     KEYCODE,#0FFH
            MOV     LASTCODE,#0FFH
            MOV     R0,#0
            MOV     R1,#0
            MOV     R2,#0
            MOV     R3,#0
            MOV     R4,#0
            MOV     R5,#0
            MOV     R6,#0
            MOV     R7,#0
            MOV     OPTION,#0FFH
            MOV     INDEX_DISP,#0
            MOV     THRESHOLD,#3    ;��ֵ��Ϊ10
            MOV     N_SAME,#0
            MOV     N_DISP,#0
             ;��ʼ��LED_BUF����Ϊ0FFH
             MOV        A,#LED_BUF
             MOV        BUF_HEAD,A
             MOV        BUF_LENGTH,#8
             MOV        INIT_VALUE,#0FFH
             LCALL      INIT_BUF
             ;LED_BUF�����ʼ�����

             ;��ʼ��FIRST_NUM,SECOND_NUM,DATA1,DATA2����Ϊ00H
             MOV        A,#FIRST_NUM
             MOV        BUF_HEAD,A
             MOV        BUF_LENGTH,#8
             MOV        INIT_VALUE,#00H
             LCALL      INIT_BUF
             ;LED_BUF�����ʼ�����

             ;��ʼ��BCD_WT_HEX����Ϊ00H
             MOV        A,#BCD_WT_HEX
             MOV        BUF_HEAD,A
             MOV        BUF_LENGTH,#5
             MOV        INIT_VALUE,#00H
             LCALL      INIT_BUF
             ;LED_BUF�����ʼ�����

             CLR        F0
             CLR        F1
             CLR        BIT_2ms

             SETB    TR0
             SETB    ET0
             SETB    EA         ;������ʱ���ж�

;;****************
;;������ѭ��
;;****************
        MAIN:
              LCALL     KEY_SCAN
              LCALL     CHECK_KEY
              JNB       BIT_2ms, $
              CLR       BIT_2ms
              SJMP      MAIN





;; ****************
;; 2ms��ʱ���жϸ�λ
;; INPUT: NONE
;; OUTPUT: NONE
;; INFLUENCE: BIT_2ms
;; ****************
INTER_T0:
    MOV     TH0, #0F8H
    MOV     TL0, #30H
    SETB    BIT_2ms
    RETI

;;*****************
;;��ʼ������ռ亯��
;;INPUT:BUF_HEAD Ŀ�껺��ͷ��ַ; BUF_LENGTH Ŀ�껺�泤�� ;INIT_VALUE ��ʼ����ֵ
;;OUTPUT:NONE
;;INFLUENCE: R0,R1
;;*****************

INIT_BUF:
          MOV   R0,BUF_HEAD
          MOV   R1,BUF_LENGTH
LOOP_CLEAR:
          MOV   @R0,INIT_VALUE
          INC   R0
          DJNZ  R1,LOOP_CLEAR
          RET


;;******************
;;����ɨ�����
;;INPUT:P1
;;OUTPUT:KEYCODE
;;INFLUENCE:LASTCODE �ϴβ����ļ���,N_SAME ��ǰ�ɼ�������ͬ����Ĵ���,THRESHOLD
;;          DPTR ���ڲ��
;;���壺 "+" 0AH
;;       "-" 0BH
;;       "��"  0CH
;;       "/"  0DH
;;       "#"  0EH ȷ�ϼ�
;;       "*"  0FH �˸��
;;*****************

KEY_SCAN:
         MOV    P1,#0F0H
         NOP
         MOV    A,P1
         ANL    A,#0F0H
         MOV    B,A
         MOV    P1,#0FH
         NOP
         MOV    A,P1
         ANL    A,#0FH
         ORL    A,B
         MOV    DPTR,#TAB_KEY
         MOVC   A,@A+DPTR
         CJNE   A,LASTCODE,GET_NEW_KEY
         MOV    A,N_SAME
         CJNE   A,THRESHOLD,GET_NEXT
         ;;��ͬһ������ɼ�����THRESHOLD�Σ������Ϊ�ɼ���ȷ
         MOV    KEYCODE,LASTCODE

         KEY_EXIT:
         INC      N_SAME
         RET

         GET_NEXT:
         JC       KEY_EXIT      ;C=1��˵��N_SAME<THRESHOLD����ҪN_SAME�Լ�
         RET

         GET_NEW_KEY:
         MOV        LASTCODE,A
         MOV        N_SAME,#0
         RET




TAB_KEY: DB  0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;00-0FH
         DB  0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;10H-1FH
         DB  0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;20H-2FH
         DB  0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;30H-3FH
         DB  0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;40H-4FH
         DB  0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;50H-5FH
         DB  0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;60H-6FH
         DB  0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0DH,0FFH,0FFH,0FFH,0CH,0FFH,0BH,0AH,0FFH     ;70H-7FH
         DB  0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;80H-8FH
         DB  0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;90H-9FH
         DB  0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;A0H-AFH
         DB  0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0EH,0FFH,0FFH,0FFH,00H,0FFH,09H,0FH,0FFH     ;B0H-BFH   "#"��Ϊ���ں�,"*"��Ϊ�˸��
         DB  0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;C0H-CFH
         DB  0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,08H,0FFH,0FFH,0FFH,07H,0FFH,06H,05H,0FFH     ;D0H-DFH
         DB  0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,04H,0FFH,0FFH,0FFH,03H,0FFH,02H,01H,0FFH     ;E0H-EFH


;;*********************************
;;������������
;;���ܣ�������������֣���ô������ʾ������LED_BUF;
;;���������������Ӽ��˳�����ô������������֮ǰ���������ݴ������FIRST_NUM -- FIRST_NUM+1(���),�����������OPTION�������LED_BUF.��LED_BUFΪ�����OPTION��
;;���������ȷ�ϼ�����ô��ȷ�ϼ�֮ǰ����ʾ������LED_BUF���ݴ������SECOND_NUM -- SECOND_NUM+1(���),�����LED_BUF������ת���������; �������ѽ����ʾ��LED�ϣ����Ұ�INDEX_DISP��Ϊ0��OPTION��Ϊ0FFH��FIRST_NUM,SECOND_NUM����Ϊ00H����Щ���ǳ�ֵ
;;����������˸��,��ô����ʾ���������ݵ���ĩβ�������
;;INPUT:KEYCODE,INDEX_DISP
;;OUTPUT:NONE
;;INFLUENCE:LED_BUF,R0,R1.
;;*********************************8


CHECK_KEY:
          MOV   A,KEYCODE
          CJNE  A,#0FFH,IS_CODE ;�����¼�µİ�������0FFH��˵���а������£�����IS_CODE����;�����¼�µİ�����0FFH��˵��û�а������£�ֱ���뿪,������ѭ��
          RET
IS_CODE:  RL A
          MOV DPTR,#TAB_IS_CODE
          JMP @A+DPTR

;��ɢת������ת�ƣ��жϰ�����ʲô����
TAB_IS_CODE: AJMP       IS_NUMBER
             AJMP       IS_NUMBER
             AJMP       IS_NUMBER
             AJMP       IS_NUMBER
             AJMP       IS_NUMBER
             AJMP       IS_NUMBER
             AJMP       IS_NUMBER
             AJMP       IS_NUMBER
             AJMP       IS_NUMBER
             AJMP       IS_NUMBER
             AJMP       IS_OPTION
             AJMP       IS_OPTION
             AJMP       IS_OPTION
             AJMP       IS_OPTION
             AJMP       IS_ENTER
             AJMP       IS_BACKSPACE


IS_NUMBER:                                    ;����FIRST_NUM��û�б���ֵ�������뵽�ڶ�������ʱ���ܻ����ʾ����������������Ϊ�ڶ������ݵĵ�һ��ֵ
             MOV        A,INDEX_DISP
             ADD        A,#LED_BUF
             MOV        R0,A
             MOV        @R0,KEYCODE
             INC        INDEX_DISP
             RET

IS_OPTION:   MOV        OPTION,KEYCODE
             JB         IS_NONSTOP,CONTINUOUS_OP        ;������Ƕ��ϴεĽ�������������㣬��ô������CONTINUOUS_OP
             DEC        INDEX_DISP
             MOV        A,#BCD_WT_HEX
             ADD        A,INDEX_DISP
             MOV        R0,A        ;��ת�����ĵ�ַ�Ӹ�R0
             MOV        A,#LED_BUF
             ADD        A,INDEX_DISP
             MOV        R1,A        ;��Ҫ��������ĵ�ַ�Ӹ�R1
             INC        INDEX_DISP  ;�����֮ǰ������λ��
LOOP_IS_OPTION:
             MOV        A,@R1       ;��Ҫ�������ȡ��
             MOV        @R0,A       ;��Ҫ��������ŵ�BCD2HEXת��������
             DEC        R0
             DEC        R1
             DJNZ       INDEX_DISP,LOOP_IS_OPTION
             ;
             LCALL      BCD2HEX      ;��Ҫ��������ݽ���BCD2HEX��ת��

             MOV        INDEX_DISP,#0
             MOV        R0,#BCD_WT_HEX  ;��ת���������λ��ַ�����R0
             MOV        R1,#FIRST_NUM   ;�Ѵ�ŵ�һ�����������������λ��ַ�����R1
             MOV        A,@R0
             MOV        @R1,A
             INC        R0
             INC        R1
             MOV        A,@R0
             MOV        @R1,A           ;������������֮ǰ�����������Ѿ����������FIRST_NUM -- FIRST_NUM+1

             ;���BCD_WT_HEX�Ļ���
             MOV        A,#BCD_WT_HEX
             MOV        BUF_HEAD,A
             MOV        BUF_LENGTH,#5
             MOV        INIT_VALUE,#00H
             LCALL      INIT_BUF
             ;BCD_WT_HEX����������

             LCALL      DISP_OPTION     ;ת��չʾ������ĳ���
             RET
CONTINUOUS_OP:

             MOV        R0,#LAST_RESULT
             MOV        R1,#FIRST_NUM
             MOV        A,@R0
             MOV        @R1,A
             INC        R0
             INC        R1
             MOV        A,@R0
             MOV        @R1,A           ;����һ�ε��������ŵ�FIRST_NUM -- FIRST_NUM+1������
             CLR        IS_NONSTOP
             MOV        INDEX_DISP,#0
             LCALL      DISP_OPTION
             RET

IS_ENTER:    SETB       IS_NONSTOP
             DEC        INDEX_DISP
             MOV        A,#BCD_WT_HEX
             ADD        A,INDEX_DISP
             MOV        R0,A        ;��ת�����ĵ�ַ�Ӹ�R0
             MOV        A,LED_BUF
             ADD        A,INDEX_DISP
             MOV        R1,A        ;��Ҫ��������ĵ�ַ�Ӹ�R1
             INC        INDEX_DISP  ;�����֮ǰ������λ��

LOOP_IS_ENTER:
             MOV        A,@R1       ;��Ҫ�������ȡ��
             MOV        @R0,A       ;��Ҫ��������ŵ�BCD2HEXת��������
             DEC        R0
             DEC        R1
             DJNZ       INDEX_DISP,LOOP_IS_ENTER
             ;
             LCALL      BCD2HEX      ;��Ҫ��������ݽ���BCD2HEX��ת��

             MOV        INDEX_DISP,#0
             MOV        R0,#BCD_WT_HEX  ;��ת���������λ��ַ�����R0
             MOV        R1,#SECOND_NUM   ;�Ѵ�ŵ�һ�����������������λ��ַ�����R1
             MOV        A,@R0
             MOV        @R1,A
             INC        R0
             INC        R1
             MOV        A,@R0
             MOV        @R1,A           ;������������֮ǰ�����������Ѿ����������SECOND_NUM -- SECOND_NUM+1

             ;���BCD_WT_HEX�Ļ���
             MOV        A,#BCD_WT_HEX
             MOV        BUF_HEAD,A
             MOV        BUF_LENGTH,#5
             MOV        INIT_VALUE,#00H
             LCALL      INIT_BUF
             ;BCD_WT_HEX����������

             ;���LED_BUF
             MOV        A,#LED_BUF
             MOV        BUF_HEAD,A
             MOV        BUF_LENGTH,#8
             MOV        INIT_VALUE,#0FFH
             LCALL      INIT_BUF
             ;LED_BUF����������

             LCALL      CALCULATE       ;����CALCULATEģ����м���,��չʾ���

             ;��ʼ����ز���
             MOV        INDEX_DISP,#0
             MOV        OPTION,#0FFH

             MOV        A,#FIRST_NUM
             MOV        BUF_HEAD,A
             MOV        BUF_LENGTH,#2
             MOV        INIT_VALUE,#00H
             LCALL      INIT_BUF

             MOV        A,#SECOND_NUM
             MOV        BUF_HEAD,A
             MOV        BUF_LENGTH,#2
             MOV        INIT_VALUE,#00H
             LCALL      INIT_BUF

             RET

IS_BACKSPACE:
             MOV        A,#LED_BUF
             DEC        INDEX_DISP
             ADD        A,INDEX_DISP
             MOV        R0,A
             MOV        @R0,#0FFH

             RET



;;*************************
;;չʾ������ĳ���
;;˼·���ȵ���INIT_BUF��ʼ��LED_BUF,����LED��ʾ�����
;;INPUT:OPTION
;;OUTPUT:NONE
;;INFLUENCE:LED_BUF
;;*************************
DISP_OPTION:
            MOV A,#LED_BUF
            MOV BUF_HEAD,A
            MOV BUF_LENGTH,#8
            MOV INIT_VALUE,#0FFH
            LCALL  INIT_BUF       ;���LED_BUF��ʾ������

            MOV    A,OPTION
            MOV    LED_BUF,A      ;��Ҫ��ʾ��������Ӹ�LED_BUF
            RET
;;***************************************
;;���㺯��CALCULATE.�����������ݺ�OPTION���������󣬽���HEX TO BCD��ת�������뵽LED_BUF
;;INPUT:FIRST_NUM,FIRST_NUM+1;SECOND_NUM,SECOND_NUM+1;OPTION
;;OUTPUT:F1,�������������F1=1��˵��Ϊ����F1=0��˵��Ϊ���������,F0=1,�����F0=0
;;INFLUENCE:LED_BUF,F1,R0,R1,R2,R3,R4,R5,R6,R7
;;����һƬ����DATA1,DATA2�����ʽ��ΪFIRST_NUM��SECOND_NUM�ĸ��������������Դ��������Ӱ��
;�˷�����������ܳ���65535


CALCULATE:
              ;�ȶԻ���Ӱ��ļĴ����͵�ַ����ʼ��
              ;��ʼ��LED_BUF
              MOV        A,#LED_BUF
              MOV        BUF_HEAD,A
              MOV        BUF_LENGTH,#8
              MOV        INIT_VALUE,#0FFH
              LCALL      INIT_BUF
              ;LED_BUF��ʼ�����
              CLR       F1
              CLR       F0
              MOV       R0,#0
              MOV       R1,#0
              MOV       R2,#0
              MOV       R3,#0
              MOV       R4,#0
              MOV       R5,#0
              MOV       R6,#0
              MOV       R7,#0
              ;��ʼ�����

              MOV       R2,FIRST_NUM
              MOV       R0,#FIRST_NUM
              INC       R0
              MOV       A,@R0
              MOV       R3,A

              MOV       R4,SECOND_NUM
              MOV       R0,#SECOND_NUM
              INC       R0
              MOV       A,@R0
              MOV       R5,A
              MOV       R0,#0
              MOV       A,#0            ;��һ���������ַ�����R2,R3���ڶ����������ַ�����R4,R5.�ɸ�λ����λ
JUDGE_OPTION:
              MOV       R0,#0
              MOV       R1,#0
              MOV       R6,#0
              MOV       R7,#0
              MOV       A,OPTION
              RL        A
              MOV       DPTR,#TAB_OPTION
              JMP       @A+DPTR

TAB_OPTION:
           AJMP         RET_ALL
           AJMP         RET_ALL
           AJMP         RET_ALL
           AJMP         RET_ALL
           AJMP         RET_ALL
           AJMP         RET_ALL
           AJMP         RET_ALL
           AJMP         RET_ALL
           AJMP         RET_ALL
           AJMP         RET_ALL
           AJMP         BADD
           AJMP         BSUBB
           AJMP         MULTIPLE
           AJMP         DIVIDE
;;*****************************
;�����żӷ����������.ʵ��DATA1-DATA2����DATA1+DATA2
;INPUT:DATA1�ĸ�λ����R2��DATA1�ĵ�λ����R3;R2.7Ϊ����λ
;      DATA2�ĸ�λ����R4��DATA2�ĵ�λ����R5;R4.7Ϊ����λ
;OUTPUT:R6,R7 .R6��Ÿ��ֽڽ��,R7��ŵ��ֽڽ��,F1��Ž���ķ���λ
;INFLUENCE:F0,F1,R0,R1
;;*******************************
BSUBB:
        MOV     A,R4
        CPL     ACC.7
        MOV     R4,A

BADD:
        MOV     A,R2
        MOV     C,ACC.7        ;������������λ������F0��
        MOV     F0,C
        MOV     A,R2
        XRL     A,R4
        MOV     C,ACC.7       ;���������ͼ������ŵıȽϽ���ŵ�F1�С���ͬ��Ϊ0����ͬ��Ϊ1.
        MOV     F1,C
        MOV     A,R2
        CLR     ACC.7
        MOV     R2,A
        MOV     A,R4
        CLR     ACC.7
        MOV     R4,A            ;ȡ��������ֵ�ͼ�����ֵ

        JB      F1,JIAN      ;�жϱ������ͼ����ķ���λ�Ƿ���ͬ����ͬ������JIA����ͬ������JIAN

   JIA:
        MOV     A,R3
        ADD     A,R5
        MOV     R7,A
        MOV     A,R2
        ADDC    A,R4
        MOV     R6,A
        JB      ACC.7,YCCL   ;ACC.7=1˵����ʱ�����
   WYC:    LJMP    RET0

   YCCL:   INC     R0
        LJMP    RET0

   JIAN:   CLR     C
        MOV     A,R3
        SUBB    A,R5
        MOV     R7,A
        MOV     A,R2
        SUBB    A,R4
        JC      YJW
  WJW:    MOV     R6,A
        LJMP    RET0
  YJW:    CLR     C
        MOV     R6,A
        MOV     A,R7
        CPL     A
        ADD     A,#1
        MOV     R7,A
        MOV     A,R6
        CPL     A
        ADDC    A,#0
        MOV     ACC.7,#0
        MOV     R6,A
        CPL     F0              ;����������λȡ����Ȼ��ѷ���λ�����ӻ�F0
        LJMP    RET0
  RET0:
        MOV     A,R6
        MOV     C,F0
        MOV     ACC.7,C
        MOV     R6,A           ;�Ӽ������������R6��Ÿ��ֽڽ����R6.7Ϊ����λ��R7��ŵ��ֽڽ��
        CLR     F1
        CLR     F0

        MOV     A,R6
        JB      ACC.7,SETB_F1    ;�������Ǹ�������ô��ת��SEB_F1,��F1��Ϊ1
        LJMP    TO_RESULT

  SETB_F1:
        SETB    F1       ;R6�ĵ���λ��1,˵���Ǹ�������F1��Ϊ1
        ANL     A,#7FH   ;��ȥR6�ķ���λ���������ʾ�����ɴ��󡣴�ʱR6�ķ���λ�Ѿ���������F1��
        MOV     R6,A


          ;�Ѵ���R6,R7�Ľ���ӵ�DATA1,DATA1+1������
  TO_RESULT:
        MOV     A,R6
        MOV     DATA1,A
        MOV     R0,#DATA1
        INC     R0
        MOV     A,R7
        MOV     @R0,A
        MOV     R6,#0
        MOV     R7,#0
        MOV     R0,#0
        LJMP    RESULT2LED      ;��¼������Ľ����,��ת��RESULT2LEDģ�飬�����ת��ΪBCD�����ʾ����


MULTIPLE:
        ;ƥ��˷�ģ��Ľӿ�
        MOV     DATA1,R2
        MOV     DATA2,R4
        MOV     R0,#DATA1
        INC     R0
        MOV     A,R3
        MOV     @R0,A
        MOV     R0,#DATA2
        INC     R0
        MOV     A,R5
        MOV     @R0,A    ;�Ѵ���������ݶ��ŵ���DATA1,DATA2�Ŀռ���
        MOV     R0,#0
        MOV     R2,#0
        MOV     R3,#0
        MOV     R4,#0
        MOV     R5,#0    ;��ʱ������������ݶ��ŵ���DATA1,DATA2�ռ���.�ӿ�ƥ�����
;**************
;���ֽڳ˷�����
;INPUT:DATA1,DATA2
;INFLUENCE:R0,R1,R2,R3,R4,R5,R6,A,B
;OUTPUT: DATA1,DATA1+1,�ɸ��ֽڵ����ֽ�.���ڹ涨������Ľ��<65536,�������Ľ����Ϊ���ֽ�
;***************
        MOV     R0,#DATA1
        MOV     R1,#DATA2

        MOV     A,@R0
        MOV     B,@R1
        MUL     AB
        MOV     R6,A
        MOV     R2,B

        INC     R0
        MOV     A,@R0
        MOV     B,@R1
        MUL     AB
        ADD     A,R2
        MOV     R2,A
        MOV     A,B
        ADDC    A,#0
        MOV     R3,A
        CLR     C

        DEC     R0
        INC     R1
        MOV     A,@R0
        MOV     B,@R1
        MUL     AB
        ADD     A,R2
        MOV     R2,A
        MOV     A,B
        ADDC    A,R3
        MOV     R3,A
        MOV     A,R4
        ADDC    A,#0
        MOV     R4,A
        CLR     C

        INC     R0
        MOV     A,@R0
        MOV     B,@R1
        MUL     AB
        ADDC    A,R3
        MOV     R3,A
        MOV     A,B
        ADDC    A,R4
        MOV     R4,A

        MOV     A,#0
        ADDC    A,#0
        MOV     R5,A    ;���ˣ�����õ��ĸ��ֽ��������
                        ;Ϊ��ֹ�����ĸ��ֽ����н�λ�����ǰ�����ܵĽ�λ����R5��

        MOV     A,R2
        MOV     @R0,A

        DEC     R0
        MOV     A,R6
        MOV     @R0,A

        DEC     R1
        MOV     A,R3
        MOV     @R1,A

        INC     R1
        MOV     A,R4
        MOV     @R1,A   ;���ˣ��˷��Ľ���Ѿ��ŵ���DATA1,DATA1+1,DATA2,DATA2+1��ͷ���ɵ�λ����λ�洢

        MOV     R0,#DATA2
        INC     R0
        MOV     DATA1,@R0
        MOV     R0,#DATA1
        INC     R0
        MOV     @R0,DATA2 ;���ˣ��˷��Ľ���ɸ�λ����λ�洢����DATA1,DATA1+1��

        LJMP    RESULT2LED

;***********************
;���ֽ��޷�����������.ʵ��DATA1/DATA2
;INPUT: R6,R7:�������ߵ��ֽ�;R4,R5�������ߵ��ֽ�
;OUTPUT: R6,R7ִ�к���������;R2,R3ִ�к���������
;INFLUENCE: R1:ѭ������������;F0�����־��60H����������м���
;************************
DIVIDE:
        MOV     A,R2
        MOV     R6,A
        MOV     A,R3
        MOV     R7,A    ;ƥ��ӿ�
        MOV     R0,#0
        MOV     R1,#0
        MOV     R2,#0
        MOV     R3,#0   ;��ʼ���Ĵ���
        CLR     F0
        CLR     F1
        MOV     A,R5
        JNZ     ZERO_DIVIDE
        MOV     A,R4
        JZ      OVERFLOW_DIVIDE

  ZERO_DIVIDE:
        CLR     A
        MOV     R2,A
        MOV     R3,A
        MOV     A,R6
        JNZ     START_DIVIDE
        MOV     A,R7
        JNZ     START_DIVIDE
        LJMP    JIESHU_DIVIDE

  START_DIVIDE:
        MOV     R1,#10H
  LOOP_DIVIDE:
        CLR     C
        MOV     A,R7
        RLC     A
        MOV     R7,A
        MOV     A,R6
        RLC     A
        MOV     R6,A
        MOV     A,R2
        RLC     A
        MOV     R2,A
        MOV     A,R3
        RLC     A
        MOV     R3,A
        MOV     A,R2
        SUBB    A,R5
        MOV     R0,A
        MOV     A,R3
        SUBB    A,R4
        MOV     60H,A
        JC      NEXT_DIVIDE
        MOV     A,#01H
        ORL     A,R7
        MOV     R7,A
        MOV     A,R0
        MOV     R2,A
        MOV     R3,60H
        AJMP    NEXT1_DIVIDE

  NEXT_DIVIDE:
        MOV     A,#0FEH
        ANL     A,R7
        MOV     R7,A

  NEXT1_DIVIDE:
        DJNZ    R1,LOOP_DIVIDE
        LJMP    JIESHU_DIVIDE

  OVERFLOW_DIVIDE:
         SETB   F0
         LJMP   TORESULT_DIVIDE

  JIESHU_DIVIDE:
         CLR    C
TORESULT_DIVIDE:    ;���������洢��DATA1,DATA1+1�У��ɸ�λ����λ
        MOV     A,R6
        MOV     DATA1,A
        MOV     R0,#DATA1
        INC     R0
        MOV     A,R7
        MOV     @R0,A
        MOV     R6,#0
        MOV     R7,#0
        MOV     R0,#0
        LJMP    RESULT2LED




;************************
;�ѽ���ŵ�LED_BUF�ĳ���
;˼·���Ƚ����ת���ɷ�ѹ��BCD�룬Ȼ��ӷ�0�����λ��ʼ��BCD�����LED_BUF
;INPUT:DATA1,DATA1+1,DATA2,DATA2+1,F0,F1
;OUTPUT:NONE
;INFLUENCE:LED_BUF;30H,31H,32H,33H,34H,R2,R3,R4,R5,R6,R7
;*************************
RESULT2LED:
        MOV     R0,#0
        MOV     R1,#0
        MOV     R2,#0
        MOV     R3,#0
        MOV     R4,#0
        MOV     R5,#0
        MOV     R6,#0
        MOV     R7,#0   ;��������󣬽�����F0,F1��ֵ��Ri�Ĵ���ȫ����ʼ��

        MOV     R0,#DATA1
        MOV     A,@R0
        MOV     R7,A
        INC     R0
        MOV     A,@R0
        MOV     R6,A
        MOV     R1,#LAST_RESULT
        MOV     A,R7
        MOV     @R1,A
        INC     R1
        MOV     A,R6
        MOV     @R1,A
        SETB    IS_NONSTOP      ;��ɱ�������֮�󣬰ѽ����HEX��ŵ�LAST_RESULT���򣬲��ҽ�IS_NONSTOP��1
        LCALL   HEX2BCD ;����HEX2BCD����������ת��ΪBCD��
DELETE_ZERO:
      ;���ܣ�ɾ��30H -- 34H�ĸ�λ���㣬����LED��ʾ����ִ���
      ;INPUT:30H,31H,32H,33H,34H:BCD�����ǧ��ʮ��λ
      ;OUTPUT:LED_BUF
      ;INFLUENCE:R0,R1,R2
      MOV   R0,#30H
      MOV   R2,#5
LOOP_CHECK:
      CJNE  @R0,#00H,TO_LEDBUF
      INC   R0
      DJNZ  R2,LOOP_CHECK         
      LJMP  RESULT_IS_ZERO
      MOV    R1,#LED_BUF
TO_LEDBUF:
      JNB    F0,RESULT_IS_POSITIVE        ;�������Ǹ�������ôչʾ����;�������������F0=0,��ô��ת��չʾ����
RESULT_IS_NEGATIVE:
      MOV    @R1,#0BH                 ;��һλ��ʾ����
      INC    R1
RESULT_IS_POSITIVE:
      MOV    A,@R0
      MOV    @R1,A
      INC    R0
      INC    R1
      DJNZ   R2,RESULT_IS_POSITIVE
      RET
RESULT_IS_ZERO:
      MOV      LED_BUF,#00H
      RET


RET_ALL:RET



;˫�ֽ��޷���HEXת��ΪBCD��
;INPUT:R7,R6:ԭHEX��ߵ��ֽ�
;INFLUENCE: R5,R4,R3,R2
;OUTPUT:30H,31H,32H,33H,34H:BCD�����ǧ��ʮ��λ
HEX2BCD:
       ;������λ
       MOV      R5,#27H
       MOV      R4,#10H
       LCALL    DIV_INT
       MOV      A,R6
       MOV      30H,A

       ;����ǧλ
       MOV      A,R3
       MOV      R7,A
       MOV      A,R2
       MOV      R6,A
       MOV      R5,#03H
       MOV      R4,#0E8H
       LCALL    DIV_INT
       MOV      A,R6
       MOV      31H,A

       ;�����λ
       MOV      A,R3
       MOV      R7,A
       MOV      A,R2
       MOV      R6,A
       MOV      R5,#00H
       MOV      R4,#64H
       LCALL    DIV_INT
       MOV      A,R6
       MOV      32H,A

       ;����ʮλ
       MOV      A,R3
       MOV      R7,A
       MOV      A,R2
       MOV      R6,A
       MOV      R5,#00H
       MOV      R4,#0AH
       LCALL    DIV_INT
       MOV      A,R6
       MOV      33H,A

       ;��ֵ��λ
       MOV      A,R2
       MOV      34H,A
       RET
       ;���ֽ��޷�����������
       ;INPUT: R7,R6:�������ߵ��ֽ�;R5,R4�������ߵ��ֽ�
       ;OUTPUT: R7,R6ִ�к���������;R3,R2ִ�к���������
       ;INFLUENCE: R1:ѭ������������;F0�����־��60H����������м���
  DIV_INT:
        MOV     R0,#0
        MOV     R1,#0
        MOV     R2,#0
        MOV     R3,#0
        CLR     F0
        CLR     F1
        MOV     A,R5
        JNZ     ZERO
        MOV     A,R4
        JZ      OVERFLOW

     ZERO:
        CLR     A
        MOV     R2,A
        MOV     R3,A
        MOV     A,R7
        JNZ     START
        MOV     A,R6
        JNZ     START
        LJMP    JIESHU

     START:
        MOV     R1,#10H
     LOOP:
        CLR     C
        MOV     A,R6
        RLC     A
        MOV     R6,A
        MOV     A,R7
        RLC     A
        MOV     R7,A
        MOV     A,R2
        RLC     A
        MOV     R2,A
        MOV     A,R3
        RLC     A
        MOV     R3,A
        MOV     A,R2
        SUBB    A,R4
        MOV     R0,A
        MOV     A,R3
        SUBB    A,R5
        MOV     60H,A
        JC      NEXT
        MOV     A,#01H
        ORL     A,R6
        MOV     R6,A
        MOV     A,R0
        MOV     R2,A
        MOV     R3,60H
        AJMP    NEXT1

     NEXT:
        MOV     A,#0FEH
        ANL     A,R6
        MOV     R6,A

     NEXT1:
        DJNZ    R1,LOOP
        LJMP    JIESHU

     OVERFLOW:
         SETB   F0
         RET


     JIESHU:
         CLR    C
         RET
;;*****************************
;��λ�޷��ŷ�ѹ��BCD��(<65536)ת��Ϊ��λHEX
;INPUT:BCD���ɸߵ���(addr0-addr4) BCD_WT_HEX -- BCD_WT_HEX+4
;OUTPUT:HEX�ɸߵ���(addr0-addr1)  BCD_WT_HEX -- BCD_WT_HEX+1
;INFLUENCE:R0,��������ָ��;R3,R4;A,B;R5
;;******************************
BCD2HEX:
        MOV     R0,#BCD_WT_HEX      ;����ָ��
        MOV     R2,#04H  ;ѭ������
        MOV     R4,BCD_WT_HEX
        MOV     R3,#0

LOOP_BCD2HEX:
        INC  R0
        LCALL  BCDA
        DJNZ   R2,LOOP_BCD2HEX
        MOV    31H,R4         ;������ĵ�λ����BCD�������ĵ�1λ
        MOV    BCD_WT_HEX,R3  ;������ĸ�λ����BCD�������ĵ�0λ
        RET

BCDA:   MOV     A,R4
        MOV     B,#10
        MUL     AB
        MOV     R4,A
        MOV     R5,B
        MOV     B,#10
        MOV     A,R3
        MUL     AB
        ADD     A,R5
        MOV     R3,A
        MOV     A,R4
        ADD     A,@R0
        MOV     R4,A
        MOV     A,R3
        ADDC    A,#0
        MOV     R3,A
        RET
