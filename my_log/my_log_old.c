#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/device.h>
#include <linux/slab.h>
#include <linux/string.h>
static struct class *log_class;
static struct device *log_dev;
char *my_buff[100];
static int num = 0;

void add_my_log(char *s)
{
	char *buffer = NULL;
	buffer = kzalloc(sizeof(s),GFP_KERNEL);
	strcpy(buffer,s);
	my_buff[num] = buffer;
	num++;
}
EXPORT_SYMBOL(add_my_log);

static ssize_t my_log_show(struct device *dev,
		struct device_attribute *attr, char *buf)
{
	int i = 0;
	int ret = 0;
	for(i=0;i<num;i++)
	{
		ret+=sprintf(buf,"%s%s",buf,my_buff[i]);
	}
	return ret;
}

static DEVICE_ATTR(my_log,0666, my_log_show, NULL);
static int __init log_init(void)
{
	log_class = class_create(THIS_MODULE, "my_log_class");
	log_dev = device_create(log_class, NULL, 0, NULL, "my_log_device");
	device_create_file(log_dev, &dev_attr_my_log);
}
fs_initcall(log_init);

