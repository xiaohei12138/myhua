#include <linux/types.h>
#include <linux/errno.h>
#include <linux/time.h>
#include <linux/kernel.h>
#include <linux/poll.h>
#include <linux/proc_fs.h>
#include <linux/fs.h>
#include <linux/syslog.h>

#include <asm/uaccess.h>
#include <asm/io.h>
#include <linux/slab.h>

#include <linux/module.h>  
#include <linux/device.h>         //class_create   
    
#include <linux/interrupt.h>  //wait_event_interruptible  
#include <linux/poll.h>   //poll  
#include <linux/kernel.h>
#include <linux/mm.h>
#include <linux/tty.h>
#include <linux/tty_driver.h>
#include <linux/console.h>
#include <linux/init.h>
#include <linux/jiffies.h>
#include <linux/nmi.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/interrupt.h>			/* For in_interrupt() */
#include <linux/delay.h>
#include <linux/smp.h>
#include <linux/security.h>
#include <linux/bootmem.h>
#include <linux/memblock.h>
#include <linux/aio.h>
#include <linux/syscalls.h>
#include <linux/suspend.h>
#include <linux/kexec.h>
#include <linux/kdb.h>
#include <linux/ratelimit.h>
#include <linux/kmsg_dump.h>
#include <linux/syslog.h>
#include <linux/cpu.h>
#include <linux/notifier.h>
#include <linux/rculist.h>
#include <linux/poll.h>
#include <linux/irq_work.h>
#include <linux/utsname.h>

#include <linux/ctype.h>
#include <linux/proc_fs.h>

typedef struct QueueNode {
	char *str;
	struct QueueNode *next;
}*Node;

typedef struct queue {
	Node first;
	Node last;	
}*Queue;
static Queue Q;

void createQueue(void)
{
	Node node;
	node=(Node)kzalloc(sizeof(struct QueueNode),GFP_KERNEL);
	if(node==NULL)
	{
		return ;
	}
	node->next=NULL;
	
	Q=(Queue)kzalloc(sizeof(struct queue),GFP_KERNEL);
	if(Q==NULL)
	{
		return;
	}
	
	Q->first=node;
	Q->last=node;

	return ;
}

int isEmpty(void)
{
	if(Q->first==Q->last)
		return 1;
	else
		return 0;
}

void EnQueue(char *X)
{
	Node node;
	node=(Node)kzalloc(sizeof(struct QueueNode),GFP_KERNEL);
	if(node==NULL)
	{
		return;
	}

	node->str= kzalloc(strlen(X)+1,GFP_KERNEL);
	if(node->str==NULL)
		return;

	strcpy(node->str,X);
	node->next=NULL;
	Q->last->next=node;
	Q->last=node;
}

void DeQueue(char *dest)
{
	Node p;
	if(isEmpty())
		return;
	p=Q->first->next;
	Q->first->next=p->next;
	strcpy(dest,p->str);
	if(p==Q->last)
	{
		Q->last=Q->first;
	}

	kfree(p->str);
	kfree(p);
	return ;
}
/***************************
*
*     kmsg
*
***************************/
#include <linux/moduleparam.h>
int mylog_debug_1 = 1000;
module_param_named(mylog_debug_1, mylog_debug_1, int, S_IRUGO | S_IWUSR);



static bool first_init=false;
static DECLARE_WAIT_QUEUE_HEAD(buff_waitq);
void add_my_log(const char *fmt, ...)
{

	va_list args;
	char tmp_buff[1024];
	if(first_init==false){
		first_init=true;
		createQueue();
	}
	memset(tmp_buff,0,sizeof(tmp_buff));
	va_start(args, fmt);
	vsprintf(tmp_buff, fmt, args);
	va_end(args);
	EnQueue(tmp_buff);
	wake_up_interruptible(&buff_waitq);
}
EXPORT_SYMBOL_GPL(add_my_log);
static int kmsg_open(struct inode * inode, struct file * file)
{

	return 0;
}

static ssize_t kmsg_read(struct file *filp, char __user *buff, size_t count, loff_t *offp)
{
	char buffer[1024]={0};
	int ret;

    wait_event_interruptible(buff_waitq, isEmpty()!=1);
    DeQueue(buffer);
    ret = copy_to_user(buff,buffer,strlen(buffer));

    return strlen(buffer);
    
}

static unsigned kmsg_poll(struct file *file, poll_table *wait)
{
	 unsigned int mask = 0;

	 poll_wait(file, &buff_waitq, wait); 

	 if (isEmpty() != 1)//has_read_ready = 1, 通知系统去读
	 	 mask |= POLLIN | POLLRDNORM;

	 return mask;
}


static const struct file_operations proc_kmsg_operations = {
	.read		= kmsg_read,
	.poll		= kmsg_poll,
	.open		= kmsg_open,
};

static int __init my_proc_kmsg_init(void)
{
	if(first_init==false){
		first_init=true;
		createQueue();
	}
	proc_create("my_kmsg", S_IRUSR, NULL, &proc_kmsg_operations);
	return 0;
}
fs_initcall(my_proc_kmsg_init);
