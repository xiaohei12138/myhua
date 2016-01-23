#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/delay.h>
#include <linux/poll.h>
#include <linux/irq.h>
#include <asm/irq.h>
#include <linux/interrupt.h>
#include <asm/uaccess.h>
#include <mach/regs-gpio.h>
#include <mach/hardware.h>
#include <linux/platform_device.h>
#include <linux/cdev.h>
#include <linux/miscdevice.h>
#include <linux/mm.h>
#include <asm/io.h>  //ioremap()
 
volatile unsigned long *gpfcon;
volatile unsigned long *gpfdat;
 
static DECLARE_WAIT_QUEUE_HEAD(button_waitq);    //声明等待队列
 
/* 中断事件标志, 中断服务程序将它置1，poll_key_read将它清0 */
static volatile int ev_press = 0;
 
//引脚描述结构
struct pin_desc{
    unsigned int pin;
    unsigned int key_val;
};
 
 
/* 键值: 按下时, 0x01, 0x02, 0x03, 0x04 */
/* 键值: 松开时, 0x81, 0x82, 0x83, 0x84 */
static unsigned char key_val;
 
struct pin_desc pins_desc[4] = {
    {S3C2410_GPF0, 0x01},
    {S3C2410_GPF1, 0x02},
    {S3C2410_GPF2, 0x03},
    {S3C2410_GPF4, 0x04},
};
 
 
static unsigned poll_key_poll(struct file *file, poll_table *wait)
{
    unsigned int mask = 0;
    poll_wait(file, &button_waitq, wait); // 不会立即休眠,将进程放入等待队列 button_waitq
 
    if (ev_press)
        mask |= POLLIN | POLLRDNORM;
 
    return mask;   //如果没有按键按下，就返回 0 。就是系统调用 poll 的返回值
}
 
 
/*
  * 确定按键值
  */
static irqreturn_t buttons_irq(int irq, void *dev_id)
{
    struct pin_desc * pindesc = (struct pin_desc *)dev_id;
    unsigned int pinval;
     
    pinval = s3c2410_gpio_getpin(pindesc->pin);
 
    if (pinval)
    {
        /* 松开 */
        key_val = 0x80 | pindesc->key_val;
    }
    else
    {
        /* 按下 */
        key_val = pindesc->key_val;
    }
 
    ev_press = 1;                  /* 表示中断发生了 */
    wake_up_interruptible(&button_waitq);   /* 唤醒休眠的进程 */
 
     
    return IRQ_RETVAL(IRQ_HANDLED);
}
/*打开的时候注册中断*/
static int poll_key_open(struct inode *inode, struct file *file)
{
    request_irq(IRQ_EINT0,  buttons_irq, IRQ_TYPE_EDGE_BOTH, "S1", &pins_desc[0]);
    request_irq(IRQ_EINT1,  buttons_irq, IRQ_TYPE_EDGE_BOTH, "S2", &pins_desc[1]);
    request_irq(IRQ_EINT2,  buttons_irq, IRQ_TYPE_EDGE_BOTH, "S3", &pins_desc[2]);
    request_irq(IRQ_EINT4,  buttons_irq, IRQ_TYPE_EDGE_BOTH, "S4", &pins_desc[3]);  
 
    return 0;
}
 
ssize_t poll_key_read(struct file *file, char __user *buf, size_t size, loff_t *ppos)
{
    if (size != sizeof(key_val))
        return -EINVAL;
 
    /* 如果没有按键动作, 休眠 */
    wait_event_interruptible(button_waitq, ev_press);
 
    /* 如果有按键动作, 返回键值 */
    copy_to_user(buf, &key_val, sizeof(key_val));
    ev_press = 0;
     
    return 1;
}
 
 
int poll_key_close(struct inode *inode, struct file *file)
{
    free_irq(IRQ_EINT0, &pins_desc[0]);
    free_irq(IRQ_EINT1, &pins_desc[1]);
    free_irq(IRQ_EINT2, &pins_desc[2]);
    free_irq(IRQ_EINT4, &pins_desc[3]);
    return 0;
}
 
 
static struct file_operations key_fops = {
    .owner   =  THIS_MODULE,    /* 这是一个宏，推向编译模块时自动创建的__this_module变量 */
    .open    =  poll_key_open,     
    .read    =  poll_key_read,     
    .release =  poll_key_close,
    .poll    =  poll_key_poll,     
};
 
 
int major;
static int poll_key_init(void)
{
    major = register_chrdev(0, "mykey", &key_fops);
    gpfcon = (volatile unsigned long *)ioremap(0x56000050, 16);
    gpfdat = gpfcon + 1;
    printk("This is my poll_key_driver Loaded  ---===>>>  \n");
    return 0;
}
 
static void poll_key_exit(void)
{
    unregister_chrdev(major, "mykey");
    printk("This is my pll_key_driver UN_Loaded  ---===>>>  \n");
    iounmap(gpfcon);
}
 
 
module_init(poll_key_init);
 
module_exit(poll_key_exit);
 
MODULE_LICENSE("GPL");
