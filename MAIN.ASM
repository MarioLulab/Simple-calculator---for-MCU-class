            ;;用于按键处理模块
            INDEX_DISP   EQU    58H     ;当前要输入的数据展示在第几位
            OPTION       EQU    59H     ;开辟一块区域储存运算符

            ;;用于LED展示模块
            LED_BUF      EQU    60H     ;定义LED缓存区为60H-67H
            N_DISP       EQU    68H     ;定义当前扫描到了第几个位置,数据储存在68H

            ;;用于初始化缓存空间的函数
            BUF_HEAD     EQU   55H     ;待初始化的目标缓存头地址
            BUF_LENGTH   EQU   56H     ;待初始化的目标缓存长度
            INIT_VALUE   EQU   57H     ;初始化成的值

            ;;用于键盘扫描程序
            N_SAME       EQU    43H     ;当前检测到的键码是第几次相同
            THRESHOLD    EQU    42H     ;检测阈值

            KEYCODE      EQU    40H     ;存储的KEYCODE
            LASTCODE     EQU    41H     ;上次检测到的KEYCODE

            ;BCD码转换成HEX码的程序
            BCD_WT_HEX   EQU    50H     ;待转换成HEX的非压缩BCD码缓存区，由高到低30H-34H

            ;;计算函数CALCULATE
            FIRST_NUM    EQU   35H      ;打包好的第一个运算数35H-36H
            SECOND_NUM  EQU   37H      ;打包好的第二个运算数37H-38H
            DATA1        EQU   39H      ;相当于FIRST_NUM的一个副本
            DATA2        EQU   3BH      ;相当于SECOND_NUM的一个副本

            ;;记录上一次运算的结果，便于进行连续运算
            LAST_RESULT EQU     69H     ;69H-6AH记录上一次运算的结果(大端模式)
            ;3DH运算中间数
            BIT_2ms      BIT   01H            ;2ms定时器标志
            IS_NONSTOP   BIT   02H            ;是否是连续运算的标志

            ORG         0000H
            LJMP        INITIALIZE
            ORG         000BH
            LJMP        INTER_T0
            ORG         0010H
INITIALIZE:
            MOV     TMOD,#01H              ;;TIMER0 MODE1
            MOV     TCON,#0
            MOV     TH0,#0F8H
            MOV     TL0,#30H               ;;设定2mS延时
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
            MOV     THRESHOLD,#3    ;阈值设为10
            MOV     N_SAME,#0
            MOV     N_DISP,#0
             ;初始化LED_BUF内容为0FFH
             MOV        A,#LED_BUF
             MOV        BUF_HEAD,A
             MOV        BUF_LENGTH,#8
             MOV        INIT_VALUE,#0FFH
             LCALL      INIT_BUF
             ;LED_BUF缓存初始化完毕

             ;初始化FIRST_NUM,SECOND_NUM,DATA1,DATA2内容为00H
             MOV        A,#FIRST_NUM
             MOV        BUF_HEAD,A
             MOV        BUF_LENGTH,#8
             MOV        INIT_VALUE,#00H
             LCALL      INIT_BUF
             ;LED_BUF缓存初始化完毕

             ;初始化BCD_WT_HEX内容为00H
             MOV        A,#BCD_WT_HEX
             MOV        BUF_HEAD,A
             MOV        BUF_LENGTH,#5
             MOV        INIT_VALUE,#00H
             LCALL      INIT_BUF
             ;LED_BUF缓存初始化完毕

             CLR        F0
             CLR        F1
             CLR        BIT_2ms

             SETB    TR0
             SETB    ET0
             SETB    EA         ;开启定时器中断

;;****************
;;开启主循环
;;****************
        MAIN:
              LCALL     KEY_SCAN
              LCALL     CHECK_KEY
              JNB       BIT_2ms, $
              CLR       BIT_2ms
              SJMP      MAIN





;; ****************
;; 2ms定时器中断复位
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
;;初始化缓存空间函数
;;INPUT:BUF_HEAD 目标缓存头地址; BUF_LENGTH 目标缓存长度 ;INIT_VALUE 初始化的值
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
;;键盘扫描程序
;;INPUT:P1
;;OUTPUT:KEYCODE
;;INFLUENCE:LASTCODE 上次采样的键码,N_SAME 当前采集到的相同键码的次数,THRESHOLD
;;          DPTR 用于查表
;;定义： "+" 0AH
;;       "-" 0BH
;;       "×"  0CH
;;       "/"  0DH
;;       "#"  0EH 确认键
;;       "*"  0FH 退格键
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
         ;;当同一个键码采集到了THRESHOLD次，则可认为采集正确
         MOV    KEYCODE,LASTCODE

         KEY_EXIT:
         INC      N_SAME
         RET

         GET_NEXT:
         JC       KEY_EXIT      ;C=1，说明N_SAME<THRESHOLD，需要N_SAME自加
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
         DB  0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0EH,0FFH,0FFH,0FFH,00H,0FFH,09H,0FH,0FFH     ;B0H-BFH   "#"设为等于号,"*"设为退格键
         DB  0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH ;C0H-CFH
         DB  0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,08H,0FFH,0FFH,0FFH,07H,0FFH,06H,05H,0FFH     ;D0H-DFH
         DB  0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,04H,0FFH,0FFH,0FFH,03H,0FFH,02H,01H,0FFH     ;E0H-EFH


;;*********************************
;;按键处理程序
;;功能：如果按键是数字，那么扔入显示缓存区LED_BUF;
;;如果按键是运算符加减乘除，那么把输入该运算符之前的所有数据打包放入FIRST_NUM -- FIRST_NUM+1(大端),把运算符放入OPTION，并清除LED_BUF.让LED_BUF为运算符OPTION；
;;如果按键是确认键，那么把确认键之前的显示缓存区LED_BUF数据打包放入SECOND_NUM -- SECOND_NUM+1(大端),并清除LED_BUF并且跳转入运算程序; 运算程序把结果显示在LED上，并且把INDEX_DISP置为0，OPTION置为0FFH，FIRST_NUM,SECOND_NUM均置为00H，这些均是初值
;;如果按键是退格键,那么把显示缓存区数据的最末尾数据清除
;;INPUT:KEYCODE,INDEX_DISP
;;OUTPUT:NONE
;;INFLUENCE:LED_BUF,R0,R1.
;;*********************************8


CHECK_KEY:
          MOV   A,KEYCODE
          CJNE  A,#0FFH,IS_CODE ;如果记录下的按键不是0FFH，说明有按键按下，进入IS_CODE程序;如果记录下的按键是0FFH，说明没有按键按下，直接离开,返回主循环
          RET
IS_CODE:  RL A
          MOV DPTR,#TAB_IS_CODE
          JMP @A+DPTR

;用散转程序来转移，判断按键是什么类型
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


IS_NUMBER:                                    ;无论FIRST_NUM有没有被赋值，当输入到第二个数据时，总会把显示的运算符给清除，换为第二个数据的第一个值
             MOV        A,INDEX_DISP
             ADD        A,#LED_BUF
             MOV        R0,A
             MOV        @R0,KEYCODE
             INC        INDEX_DISP
             RET

IS_OPTION:   MOV        OPTION,KEYCODE
             JB         IS_NONSTOP,CONTINUOUS_OP        ;如果这是对上次的结果进行连续运算，那么则跳到CONTINUOUS_OP
             DEC        INDEX_DISP
             MOV        A,#BCD_WT_HEX
             ADD        A,INDEX_DISP
             MOV        R0,A        ;把转换区的地址扔给R0
             MOV        A,#LED_BUF
             ADD        A,INDEX_DISP
             MOV        R1,A        ;把要打包的数的地址扔给R1
             INC        INDEX_DISP  ;运算符之前的数的位数
LOOP_IS_OPTION:
             MOV        A,@R1       ;把要打包的数取出
             MOV        @R0,A       ;把要打包的数放到BCD2HEX转换缓存区
             DEC        R0
             DEC        R1
             DJNZ       INDEX_DISP,LOOP_IS_OPTION
             ;
             LCALL      BCD2HEX      ;把要打包的数据进行BCD2HEX的转换

             MOV        INDEX_DISP,#0
             MOV        R0,#BCD_WT_HEX  ;把转换结果的首位地址存放在R0
             MOV        R1,#FIRST_NUM   ;把存放第一个运算数的区域的首位地址存放在R1
             MOV        A,@R0
             MOV        @R1,A
             INC        R0
             INC        R1
             MOV        A,@R0
             MOV        @R1,A           ;把输入该运算符之前的所有数据已经打包放入了FIRST_NUM -- FIRST_NUM+1

             ;清空BCD_WT_HEX的缓存
             MOV        A,#BCD_WT_HEX
             MOV        BUF_HEAD,A
             MOV        BUF_LENGTH,#5
             MOV        INIT_VALUE,#00H
             LCALL      INIT_BUF
             ;BCD_WT_HEX缓存清空完毕

             LCALL      DISP_OPTION     ;转入展示运算符的程序
             RET
CONTINUOUS_OP:

             MOV        R0,#LAST_RESULT
             MOV        R1,#FIRST_NUM
             MOV        A,@R0
             MOV        @R1,A
             INC        R0
             INC        R1
             MOV        A,@R0
             MOV        @R1,A           ;把上一次的运算结果放到FIRST_NUM -- FIRST_NUM+1的区域
             CLR        IS_NONSTOP
             MOV        INDEX_DISP,#0
             LCALL      DISP_OPTION
             RET

IS_ENTER:    SETB       IS_NONSTOP
             DEC        INDEX_DISP
             MOV        A,#BCD_WT_HEX
             ADD        A,INDEX_DISP
             MOV        R0,A        ;把转换区的地址扔给R0
             MOV        A,LED_BUF
             ADD        A,INDEX_DISP
             MOV        R1,A        ;把要打包的数的地址扔给R1
             INC        INDEX_DISP  ;运算符之前的数的位数

LOOP_IS_ENTER:
             MOV        A,@R1       ;把要打包的数取出
             MOV        @R0,A       ;把要打包的数放到BCD2HEX转换缓存区
             DEC        R0
             DEC        R1
             DJNZ       INDEX_DISP,LOOP_IS_ENTER
             ;
             LCALL      BCD2HEX      ;把要打包的数据进行BCD2HEX的转换

             MOV        INDEX_DISP,#0
             MOV        R0,#BCD_WT_HEX  ;把转换结果的首位地址存放在R0
             MOV        R1,#SECOND_NUM   ;把存放第一个运算数的区域的首位地址存放在R1
             MOV        A,@R0
             MOV        @R1,A
             INC        R0
             INC        R1
             MOV        A,@R0
             MOV        @R1,A           ;把输入该运算符之前的所有数据已经打包放入了SECOND_NUM -- SECOND_NUM+1

             ;清空BCD_WT_HEX的缓存
             MOV        A,#BCD_WT_HEX
             MOV        BUF_HEAD,A
             MOV        BUF_LENGTH,#5
             MOV        INIT_VALUE,#00H
             LCALL      INIT_BUF
             ;BCD_WT_HEX缓存清空完毕

             ;清空LED_BUF
             MOV        A,#LED_BUF
             MOV        BUF_HEAD,A
             MOV        BUF_LENGTH,#8
             MOV        INIT_VALUE,#0FFH
             LCALL      INIT_BUF
             ;LED_BUF缓存清空完毕

             LCALL      CALCULATE       ;调用CALCULATE模块进行计算,并展示结果

             ;初始化相关参数
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
;;展示运算符的程序
;;思路：先调用INIT_BUF初始化LED_BUF,再让LED显示运算符
;;INPUT:OPTION
;;OUTPUT:NONE
;;INFLUENCE:LED_BUF
;;*************************
DISP_OPTION:
            MOV A,#LED_BUF
            MOV BUF_HEAD,A
            MOV BUF_LENGTH,#8
            MOV INIT_VALUE,#0FFH
            LCALL  INIT_BUF       ;清空LED_BUF显示缓存区

            MOV    A,OPTION
            MOV    LED_BUF,A      ;把要显示的运算符扔给LED_BUF
            RET
;;***************************************
;;计算函数CALCULATE.根据输入数据和OPTION计算出结果后，进行HEX TO BCD的转换后输入到LED_BUF
;;INPUT:FIRST_NUM,FIRST_NUM+1;SECOND_NUM,SECOND_NUM+1;OPTION
;;OUTPUT:F1,结果符号正负。F1=1，说明为负；F1=0，说明为正。有溢出,F0=1,无溢出F0=0
;;INFLUENCE:LED_BUF,F1,R0,R1,R2,R3,R4,R5,R6,R7
;;开辟一片区域DATA1,DATA2大端形式作为FIRST_NUM和SECOND_NUM的副本，避免操作对源操作数的影响
;乘法的最大结果不能超过65535


CALCULATE:
              ;先对会受影响的寄存器和地址作初始化
              ;初始化LED_BUF
              MOV        A,#LED_BUF
              MOV        BUF_HEAD,A
              MOV        BUF_LENGTH,#8
              MOV        INIT_VALUE,#0FFH
              LCALL      INIT_BUF
              ;LED_BUF初始化完毕
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
              ;初始化完毕

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
              MOV       A,#0            ;第一个运算数字放入了R2,R3，第二个运算数字放入了R4,R5.由高位到低位
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
;带符号加法或减法程序.实现DATA1-DATA2或者DATA1+DATA2
;INPUT:DATA1的高位放在R2，DATA1的低位放在R3;R2.7为符号位
;      DATA2的高位放在R4，DATA2的低位放在R5;R4.7为符号位
;OUTPUT:R6,R7 .R6存放高字节结果,R7存放低字节结果,F1存放结果的符号位
;INFLUENCE:F0,F1,R0,R1
;;*******************************
BSUBB:
        MOV     A,R4
        CPL     ACC.7
        MOV     R4,A

BADD:
        MOV     A,R2
        MOV     C,ACC.7        ;将被加数符号位保存在F0中
        MOV     F0,C
        MOV     A,R2
        XRL     A,R4
        MOV     C,ACC.7       ;将被加数和加数符号的比较结果放到F1中。相同则为0，不同则为1.
        MOV     F1,C
        MOV     A,R2
        CLR     ACC.7
        MOV     R2,A
        MOV     A,R4
        CLR     ACC.7
        MOV     R4,A            ;取被加数数值和加数数值

        JB      F1,JIAN      ;判断被加数和加数的符号位是否相同。相同则跳到JIA，不同则跳到JIAN

   JIA:
        MOV     A,R3
        ADD     A,R5
        MOV     R7,A
        MOV     A,R2
        ADDC    A,R4
        MOV     R6,A
        JB      ACC.7,YCCL   ;ACC.7=1说明此时有溢出
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
        CPL     F0              ;被加数符号位取反，然后把符号位重新扔回F0
        LJMP    RET0
  RET0:
        MOV     A,R6
        MOV     C,F0
        MOV     ACC.7,C
        MOV     R6,A           ;加减法运算结束。R6存放高字节结果，R6.7为符号位；R7存放低字节结果
        CLR     F1
        CLR     F0

        MOV     A,R6
        JB      ACC.7,SETB_F1    ;如果结果是负数，那么跳转到SEB_F1,把F1置为1
        LJMP    TO_RESULT

  SETB_F1:
        SETB    F1       ;R6的第七位是1,说明是负数，把F1置为1
        ANL     A,#7FH   ;滤去R6的符号位，避免给显示结果造成错误。此时R6的符号位已经储存在了F1中
        MOV     R6,A


          ;把存在R6,R7的结果扔到DATA1,DATA1+1区域内
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
        LJMP    RESULT2LED      ;记录下运算的结果后,跳转到RESULT2LED模块，将结果转换为BCD码后显示出来


MULTIPLE:
        ;匹配乘法模块的接口
        MOV     DATA1,R2
        MOV     DATA2,R4
        MOV     R0,#DATA1
        INC     R0
        MOV     A,R3
        MOV     @R0,A
        MOV     R0,#DATA2
        INC     R0
        MOV     A,R5
        MOV     @R0,A    ;把待运算的数据都放到了DATA1,DATA2的空间里
        MOV     R0,#0
        MOV     R2,#0
        MOV     R3,#0
        MOV     R4,#0
        MOV     R5,#0    ;此时，带运算的数据都放到了DATA1,DATA2空间里.接口匹配完毕
;**************
;两字节乘法程序
;INPUT:DATA1,DATA2
;INFLUENCE:R0,R1,R2,R3,R4,R5,R6,A,B
;OUTPUT: DATA1,DATA1+1,由高字节到低字节.由于规定运算出的结果<65536,所以最后的结果仅为两字节
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
        MOV     R5,A    ;至此，所求得的四个字节已求完毕
                        ;为防止到第四个字节仍有进位，我们把其可能的进位存在R5中

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
        MOV     @R1,A   ;至此，乘法的结果已经放到了DATA1,DATA1+1,DATA2,DATA2+1里头。由低位到高位存储

        MOV     R0,#DATA2
        INC     R0
        MOV     DATA1,@R0
        MOV     R0,#DATA1
        INC     R0
        MOV     @R0,DATA2 ;至此，乘法的结果由高位到低位存储在了DATA1,DATA1+1中

        LJMP    RESULT2LED

;***********************
;两字节无符号整数除法.实现DATA1/DATA2
;INPUT: R6,R7:被除数高低字节;R4,R5：除数高低字节
;OUTPUT: R6,R7执行后最终商数;R2,R3执行后最终余数
;INFLUENCE: R1:循环次数计数器;F0溢出标志；60H，运算过程中间数
;************************
DIVIDE:
        MOV     A,R2
        MOV     R6,A
        MOV     A,R3
        MOV     R7,A    ;匹配接口
        MOV     R0,#0
        MOV     R1,#0
        MOV     R2,#0
        MOV     R3,#0   ;初始化寄存器
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
TORESULT_DIVIDE:    ;把运算结果存储在DATA1,DATA1+1中，由高位到低位
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
;把结果放到LED_BUF的程序
;思路：先将结果转换成非压缩BCD码，然后从非0的最高位开始把BCD码放入LED_BUF
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
        MOV     R7,#0   ;运算结束后，仅保留F0,F1的值，Ri寄存器全部初始化

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
        SETB    IS_NONSTOP      ;完成本次运算之后，把结果的HEX存放到LAST_RESULT区域，并且将IS_NONSTOP置1
        LCALL   HEX2BCD ;调用HEX2BCD，将运算结果转换为BCD码
DELETE_ZERO:
      ;功能：删除30H -- 34H的高位的零，以免LED显示会出现错误
      ;INPUT:30H,31H,32H,33H,34H:BCD码的万千百十个位
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
      JNB    F0,RESULT_IS_POSITIVE        ;如果结果是负数，那么展示负号;如果是正数，即F0=0,那么跳转到展示正数
RESULT_IS_NEGATIVE:
      MOV    @R1,#0BH                 ;第一位显示负号
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



;双字节无符号HEX转换为BCD码
;INPUT:R7,R6:原HEX码高低字节
;INFLUENCE: R5,R4,R3,R2
;OUTPUT:30H,31H,32H,33H,34H:BCD码的万千百十个位
HEX2BCD:
       ;计算万位
       MOV      R5,#27H
       MOV      R4,#10H
       LCALL    DIV_INT
       MOV      A,R6
       MOV      30H,A

       ;计算千位
       MOV      A,R3
       MOV      R7,A
       MOV      A,R2
       MOV      R6,A
       MOV      R5,#03H
       MOV      R4,#0E8H
       LCALL    DIV_INT
       MOV      A,R6
       MOV      31H,A

       ;计算百位
       MOV      A,R3
       MOV      R7,A
       MOV      A,R2
       MOV      R6,A
       MOV      R5,#00H
       MOV      R4,#64H
       LCALL    DIV_INT
       MOV      A,R6
       MOV      32H,A

       ;计算十位
       MOV      A,R3
       MOV      R7,A
       MOV      A,R2
       MOV      R6,A
       MOV      R5,#00H
       MOV      R4,#0AH
       LCALL    DIV_INT
       MOV      A,R6
       MOV      33H,A

       ;赋值个位
       MOV      A,R2
       MOV      34H,A
       RET
       ;两字节无符号整数除法
       ;INPUT: R7,R6:被除数高低字节;R5,R4：除数高低字节
       ;OUTPUT: R7,R6执行后最终商数;R3,R2执行后最终余数
       ;INFLUENCE: R1:循环次数计数器;F0溢出标志；60H，运算过程中间数
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
;五位无符号非压缩BCD码(<65536)转换为两位HEX
;INPUT:BCD码由高到低(addr0-addr4) BCD_WT_HEX -- BCD_WT_HEX+4
;OUTPUT:HEX由高到低(addr0-addr1)  BCD_WT_HEX -- BCD_WT_HEX+1
;INFLUENCE:R0,输入数据指针;R3,R4;A,B;R5
;;******************************
BCD2HEX:
        MOV     R0,#BCD_WT_HEX      ;数据指针
        MOV     R2,#04H  ;循环次数
        MOV     R4,BCD_WT_HEX
        MOV     R3,#0

LOOP_BCD2HEX:
        INC  R0
        LCALL  BCDA
        DJNZ   R2,LOOP_BCD2HEX
        MOV    31H,R4         ;最后结果的低位放在BCD缓存区的第1位
        MOV    BCD_WT_HEX,R3  ;最后结果的高位放在BCD缓存区的第0位
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

