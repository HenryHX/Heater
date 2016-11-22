// +----------------------------------------------------------------------
// | ZYSOFT [ MAKE IT OPEN ]
// +----------------------------------------------------------------------
// | Copyright(c) 20015 ZYSOFT All rights reserved.
// +----------------------------------------------------------------------
// | Licensed( http://www.apache.org/licenses/LICENSE-2.0 )
// +----------------------------------------------------------------------
// | Author:zy_cwind<391321232@qq.com>
// +----------------------------------------------------------------------

#include <8pb53b.ash>

#define TPRIO 0x40
#define KEYPESS_LONG  200

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

mode          REG     0x10
counter       REG     0x11
angle         REG     0x12
timestamp     REG     0x13
duty          REG     0x14

s_previous    REG     0x15

/**
 * 局部变量
 * 应避免中断干扰即函数不可重入
 *
 *
 */
time_v0       REG     0x16
time_v1       REG     0x17
time_v2       REG     0x18
time_v3       REG     0x19
set_ledb_v0   REG     0x1A
set_pout_v0   REG     0x1B
is_start_v0   REG     0x1C
is_start_v1   REG     0x1D
delay_v0      REG     0x1E
delay_v1      REG     0x1F
delay_v2      REG     0x20
setup_led_v0  REG     0x21
main_v0       REG     0x22
main_v1       REG     0x23
main_v2       REG     0x24

/**
 * 定时器中断 200us
 *
 *
 */
    ORG 008H
time:
    MOVAR  time_v0
    MOVR   STATUS,    A
    MOVAR  time_v1
    BTRSS  INTFLAG  , 0
    GOTO   time_labels0
    reload
    MOVR   timestamp, A
    INCR   timestamp, R
    ANDIA  TPRIO - 1
    SUBAR  duty ,  A
    BCR    time_v2  , 0
    BTRSS  CFLAG
    GOTO   $ + 4
    MOVR   mode ,  R
    BTRSS  ZFLAG
    BSR    time_v2  , 0
    MOVR   time_v2  , A
    CALL   set_ledb
    MOVR   mode ,  R
    BTRSC  ZFLAG
    GOTO   time_labels0
    CALL   is_start
    ANDIA  0x01
    BTRSC  ZFLAG
    GOTO   time_labels1
    CLRR   angle
    MOVR   mode ,  A
    MOVAR  time_v2
    MOVIA  0x01
    DECRSZ time_v2  , R
    GOTO $ + 2
    MOVIA  0x22
    DECRSZ time_v2  , R
    GOTO $ + 2
    MOVIA  0x11
    MOVAR  counter
time_labels1:
    MOVIA  0x64
    SUBAR  angle,  A
    BTRSS  CFLAG
    GOTO   time_labels0
    MOVR   angle,  A
    INCR   angle,  R
    MOVAR  time_v2
    MOVR   counter  , A
    SUBAR  time_v2  , A
    BCR    time_v3  , 0
    BTRSC  ZFLAG
    BSR    time_v3  , 0
    MOVR   counter  , A
    ADDIA  50
    SUBAR  time_v2  , A
    BTRSC  ZFLAG
    BSR    time_v3  , 0
    MOVR   time_v3  , A
    CALL   set_pout
time_labels0:
    CLRR   INTFLAG
    MOVR   time_v1  , A
    MOVAR  STATUS
    MOVR   time_v0  , A
    RETFIE

/**
 * 板子
 *
 *
 */
is_keydown:
    MOVIA  0
    BTRSS  PORTB,  1
    RETIA  1
    RETURN

set_ledb:
    MOVAR  set_ledb_v0
    BCR    PORTB,  2
    BTRSC  set_ledb_v0 , 0
    BSR    PORTB,  2
    RETURN

set_pout:
    MOVAR  set_ledb_v0
    BCR    PORTA,  2
    BTRSC  set_ledb_v0 , 0
    BSR    PORTA,  2
    RETURN

is_start:
    BCR    is_start_v0 , 0
    BTRSC  PORTA,  3
    BSR    is_start_v0 , 0
    BCR    is_start_v1 , 0
    BTRSS  is_start_v0 , 0
    GOTO   $ + 4
    BTRSC  s_previous  , 0
    GOTO   $ + 2
    BSR    is_start_v1 , 0
    MOVR   is_start_v0 , A
    MOVAR  s_previous
    MOVR   is_start_v1 , A
    RETURN

delay:
    MOVAR  delay_v0
    MOVIA  41
    MOVAR  delay_v1
    MOVIA  10
    MOVAR  delay_v2
    DECRSZ delay_v2 , R
    GOTO   $ - 1
    DECRSZ delay_v1 , R
    GOTO   $ - 5
    DECRSZ delay_v0 , R
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
    MOVAR  setup_led_v0
    DECRSZ setup_led_v0, R
    GOTO $ + 2
    GOTO $ + 8
    DECRSZ setup_led_v0, R
    GOTO $ + 2
    GOTO $ + 4
    DECRSZ setup_led_v0, R
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

/**
 * 定时器 0 八位自动重载
 *
 *
 */
setup_timer:
    MOVIA  0x00
    OPTION
    BSR    INTEN,  0
    reload
    RETURN

/**
 * 初始化 IO
 *
 *
 */
init:
    CLRR   angle
    CLRR   timestamp
    CLRR   duty
    CLRR   mode
    MOVIA  0x08
    IOST   PORTA
    MOVIA  0x02
    IOST   PORTB
    MOVIA  0x08
    MOVAR  PORTA
    MOVIA  0x02
    MOVAR  PORTB
    CALL   setup_led
    CALL   setup_fan
    CALL   setup_timer
    RETURN

main:
    CLRR   main_v0
    CLRR   main_v1
    CALL   init
    BSR    INTEN,  7

main_labels0:
    MOVIA  0x0A
    CALL   delay
    CALL   is_keydown
    MOVAR  main_v2
    BTRSC  main_v2  , 0
    GOTO   $ + 2 //////////// down
    GOTO   $ + 3 //////////// up
    INCR   main_v0  , R
    GOTO   main_labels1
    MOVR   main_v0  , R
    BTRSC  ZFLAG
    GOTO   main_labels1
    SUBIA  KEYPESS_LONG ///// c != 0
    BTRSC  CFLAG
    GOTO   $ + 2
    GOTO   $ + 3 //////////// c < KEYPESS_LONG
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
    CLRR   main_v0
main_labels1:
    MOVR   duty ,  A
    ANDIA  TPRIO - 1
    BTRSC  ZFLAG
    BCR    main_v1  , 0
    MOVR   duty ,  A
    ANDIA  TPRIO
    BTRSS  ZFLAG
    BSR    main_v1  , 0
    BTRSS  main_v1  , 0
    GOTO   $ + 3
    DECR   duty ,  R
    GOTO   $ + 2
    INCR   duty ,  R
    GOTO   main_labels0

/**
 * 复位向量
 *
 *
 */
    ORG 3FFH
    GOTO   main
