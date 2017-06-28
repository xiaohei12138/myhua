#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/types.h>
#include <linux/errno.h>
#include <linux/time.h>
#include <linux/poll.h>
#include <linux/proc_fs.h>
#include <linux/fs.h>
#include <linux/syslog.h>
static int __init my_module_init(void)
{
	printk("haha\n");
	return 0;
}
static void __exit my_module_exit(void)
{
	printk(".....\n");
}
module_init(my_module_init);
module_exit(my_module_exit);