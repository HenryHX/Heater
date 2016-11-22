// +----------------------------------------------------------------------
// | ZYSOFT [ MAKE IT OPEN ]
// +----------------------------------------------------------------------
// | Copyright(c) 20015 ZYSOFT All rights reserved.
// +----------------------------------------------------------------------
// | Licensed( http://www.apache.org/licenses/LICENSE-2.0 )
// +----------------------------------------------------------------------
// | Author:zy_cwind<391321232@qq.com>
// +----------------------------------------------------------------------

/**
 * FM8PB53B 主频 4MHz 加热器代码
 *
 * 适用于工频 50Hz
 *
 */
#include <8pb53b.ash>

/**
 * 中断中的局部变量使用独立栈
 * 参数通过 ACC 传递
 *
 *
 */
#define TPRIO 0x40
#define KEYPESS_LONG 200
#define STACK 0x20
#define INTST 0x30

#define ZFLAG STATUS, 2
#define CFLAG STATUS, 0

/**
 * 宏
 *
 *
 */
set_led1       MACRO
    BSR    PORTA,  0
    ENDM

set_led2       MACRO
    BSR    PORTB,  7
    ENDM

set_led3       MACRO
    BSR    PORTB,  6
    ENDM

turn_off_led   MACRO
    BCR    PORTA,  0
    BCR    PORTB,  7
    BCR    PORTB,  6
    ENDM

reload         MACRO
    MOVR   INTFLAG  , 0
    ANDIA  0xFE
    MOVAR  INTFLAG
    MOVIA  0x38
    MOVAR  TMR0
    ENDM

mode       REG     0x10
counter    REG     0x11
angle      REG     0x12
timestamp  REG     0x13
duty       REG     0x14

/**
 * 静态局部变量
 *
 *
 */
s_previous REG     0x15

/**
 * 定时器中断 200us
 * 注意不污染到原来栈中的数据
 *
 *
 */
    ORG 008H
timer:
    MOVAR  INTST + 0
    MOVR   STATUS,    A
    MOVAR  INTST + 1
    BTRSS  INTFLAG  , 0
    GOTO   exittimer
    reload
    MOVR   timestamp, A
    INCR   timestamp, R
    ANDIA  TPRIO - 1
    SUBAR  duty ,  A
    BCR    INTST + 2, 2
    BTRSS  CFLAG
    GOTO   $ + 4
    MOVR   mode ,  R
    BTRSS  ZFLAG
    BSR    INTST + 2, 2
    MOVR   INTST + 2, A
    CALL   set_ledb
    MOVR   mode ,  R
    BTRSC  ZFLAG
    GOTO   exittimer
    CALL   is_start
    ANDIA  1
    BTRSC  ZFLAG
    GOTO   pout
    CLRR   angle
    MOVR   mode ,  A
    MOVAR  INTST + 2
    MOVIA  0x01
    DECRSZ INTST + 2, R
    GOTO $ + 2
    MOVIA  0x22
    DECRSZ INTST + 2, R
    GOTO $ + 2
    MOVIA  0x11
    MOVAR  counter
pout:
    MOVIA  0x64
    SUBAR  angle,  A
    BTRSS  CFLAG
    GOTO   exittimer
    MOVR   angle,  A
    INCR   angle,  R
    MOVAR  INTST + 2
    MOVR   counter  , A
    SUBAR  INTST + 2, A
    BCR    INTST + 3, 0
    BTRSC  ZFLAG
    BSR    INTST + 3, 0
    MOVR   counter  , A
    ADDIA  50
    SUBAR  INTST + 2, A
    BTRSC  ZFLAG
    BSR    INTST + 3, 0
    MOVR   INTST + 3, A
    CALL   set_pout
exittimer:
    CLRR   INTFLAG
    MOVR   INTST + 1, A
    MOVAR  STATUS
    MOVR   INTST + 0, A
    RETFIE

/**
 * 硬件相关
 *
 *
 *
 */
is_keydown:
    MOVIA  0
    BTRSC  PORTB,  1
    RETIA  1
    RETURN

set_ledb:
    MOVAR  STACK
    BCR    PORTB,  2
    BTRSC  STACK,  0
    BSR    PORTB,  2
    RETURN

set_pout:
    MOVAR  STACK
    BCR    PORTA,  2
    BTRSC  STACK,  0
    BSR    PORTA,  2
    RETURN

/**
 * 上升沿
 *
 *
 */
is_start:
    BCR    STACK,  0
    BTRSC  PORTA,  3
    BSR    STACK,  0
    BCR    STACK + 1, 0
    BTRSS  STACK,  0
    GOTO   $ + 4
    BTRSC  s_previous  , 0
    GOTO   $ + 2
    BSR    STACK + 1, 0
    MOVR   STACK,  A
    MOVAR  s_previous
    MOVR   STACK + 1, A
    RETURN

/**
 * 软件延时
 * 4T
 * 一个 CPU Cycle 是一微秒
 *
 */
delay:
    MOVAR  STACK
    MOVIA  41
    MOVAR  STACK + 1
    MOVIA  10
    MOVAR  STACK + 2
    DECRSZ STACK + 2, R
    GOTO   $ - 1
    DECRSZ STACK + 1, R
    GOTO   $ - 5
    DECRSZ STACK + 0, R
    GOTO   $ - 9
    RETURN

/**
 * 设置灯
 *
 *
 */
setup_led:
    turn_off_led
    MOVR   mode ,  A
    MOVAR  STACK
    DECRSZ STACK,  R
    GOTO $ + 2
    GOTO $ + 8
    DECRSZ STACK,  R
    GOTO $ + 2
    GOTO $ + 4
    DECRSZ STACK,  R
    RETURN
    set_led3
    set_led2
    set_led1
    RETURN

setup_fan:
    BCR    PORTA,  1
    MOVR   mode ,  R
    BTRSS  ZFLAG
    BSR    PORTA,  1
    RETURN

setup_timer:
    MOVIA  0x00
    OPTION
    BSR    INTEN,  0
    reload
    RETURN

init:
    CLRR   angle
    CLRR   timestamp
    CLRR   duty
    CLRR   mode
    CALL   setup_led
    CALL   setup_timer
    RETURN

/**
 * 主程序入口
 *
 *
 */
main:
    CLRR   STACK
    CLRR   STACK + 1
    CALL   init
    BSR    INTEN,  7
main_labels0:
    MOVIA  10
    CALL   delay
    CALL   is_keydown
    MOVAR  STACK + 2
    BTRSC  STACK + 2, 0
    GOTO   $ + 2
    GOTO   $ + 3
    INCR   STACK,  R
    GOTO   main_labels1
    MOVR   STACK,  A
    BTRSC  ZFLAG
    GOTO   main_labels1
    SUBIA  KEYPESS_LONG
    BTRSS  CFLAG
    GOTO   $ + 2
    GOTO   $ + 3
    CLRR   mode
    GOTO   main_labels2
    INCR   mode ,  A
    ANDIA  0x03
    MOVAR  mode
    MOVR   mode ,  R
    BTRSC  ZFLAG
    INCR   mode ,  R
main_labels2:
    MOVIA  80
    CALL   delay
    CALL   setup_led
    CALL   setup_fan
    CLRR   STACK
main_labels1:
    MOVR   duty ,  A
    ANDIA  TPRIO - 1
    BTRSC  ZFLAG
    BCR    STACK + 1, 0
    MOVR   duty ,  A
    ANDIA  TPRIO
    BTRSS  ZFLAG
    BSR    STACK + 1, 0
    BTRSS  STACK + 1, 0
    GOTO   $ + 3
    DECR   duty ,  R
    GOTO   $ + 2
    INCR   duty ,  R
    GOTO   main_labels0
