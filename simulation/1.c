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
 * FM8PB53B 单片机 4MHz 加热器代码
 *
 * 适用于工频 50Hz
 *
 */
#include <reg51.h>

#define PERIOD 0x40
#define KEYPESS_LONG 200

/**
 * 三档脉冲频率
 *
 *
 */
unsigned char mode;
unsigned char counter;
unsigned char angle;

/**
 * 呼吸灯
 *
 *
 */
int timestamp;
short duty;

/**
 * 设备相关
 *
 *
 */
char is_keydown() {
    if (P0 & 0x01)
        return 0;
    return 1;
}

void set_ledb(char is_on) {
    if (is_on)
        P0 |= 0x10;
    else
        P0 &=~0x10;
}

void set_led1() {
    P0 |= 0x02;
}

void set_led2() {
    P0 |= 0x04;
}

void set_led3() {
    P0 |= 0x08;
}

void turn_off_led() {
    P0 &=~0x0E;
}

void set_pout(char is_on) {
    if (is_on)
        P1 |= 0x02;
    else
        P1 &=~0x02;
}

/**
 * 上升沿
 *
 *
 *
 */
char is_start() {
    static char prev;
    char stat = P1 & 0x01;
    char r;
    r = (stat && !prev);
    prev = stat;
    return r;
}

/**
 * 软件延时
 *
 *
 */
void delay(int i) {
    unsigned char j;
    unsigned char k;
    do {
        j = 2;
        k = 239;
        do {
            while (--k);
        } while (--j);
    } while (--i);
}

/**
 * 设置灯
 *
 *
 */
void setup_led() {
    turn_off_led();
    if (mode >= 3)
        set_led3();
    if (mode >= 2)
        set_led2();
    if (mode >= 1)
        set_led1();
}

void setup_fan() {
    if (mode)
        P1 |= 0x04;
    else
        P1 &=~0x04;
}

/**
 * 定时器中断 200us
 *
 *
 */
void timer() interrupt 1 {
    set_ledb((timestamp++ & (PERIOD - 1)) < duty && mode);
    if (mode) {
        if (is_start()) {
            angle = 0;
            /**
             * 配置脉冲
             *
             *
             */
            switch (mode) {
            case 3:
                counter = 01;
                break;
            case 2:
                counter = 17;
                break;
            case 1:
                counter = 34;
                break;
            }
        }
        if (angle < 100) {
            set_pout(angle == counter || angle == counter + 50);
            angle++;
        }
    }
}

void setup_timer() {
    TMOD &= 0xF0;
    TMOD |= 0x02;
    /**
     * 定时器 0 八位自动重载
     *
     *
     */
    TL0 = 0x38;
    TH0 = 0x38;
    TF0 = 0x00;
    TR0 = 0x01;
    ET0 = 0x01;
}

/**
 * 初始化
 *
 *
 */
void init() {
    angle = 0;
    timestamp = 0;
    duty = 0;
    mode = 0;
    
    setup_led();
    setup_fan();
    setup_timer();
}

/**
 * 主程序入口
 *
 *
 */
void main() {
    int c = 0;
    char dir;
    /**
     * 初始化
     *
     *
     */
    init();
    EA = 1;
    while (1) {
        delay(10);
        if (!is_keydown()) {
            if (c) {
                if (c < KEYPESS_LONG) {
                    mode++;
                    mode &= 3;
                    if (!mode)
                        mode = 1;
                } else
                    mode = 0;
                /**
                 * 按键消抖
                 *
                 *
                 */
                delay(80);
                setup_led();
                setup_fan();
                c = 0;
            }
        } else
            c++;
        /**
         * 呼吸灯占空比
         *
         *
         */
        if (!(duty & (PERIOD - 1)))
            dir = duty & PERIOD;
        if (dir)
            duty--;
        else
            duty++;
    }
}
