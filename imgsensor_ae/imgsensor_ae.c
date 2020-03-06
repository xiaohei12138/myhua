#include <linux/module.h>
#include <linux/of.h>
#include <linux/of_address.h>
#include <linux/of_irq.h>
#include <linux/gpio.h>
#include <linux/platform_device.h>

#include "imgsensor_ae.h"
#define IMGSENSOR_AE_DEV_NAME "imgsensor_ae"

static int imgsensor_ae_probe(struct platform_device *dev);
static struct imgsensor_ae_pinctrl_t back_gpio_pinctrl_list[]={
	{.pinctrl_name="back_imgsensor_ae_rst_h"},
	{.pinctrl_name="back_imgsensor_ae_rst_l"},
	{.pinctrl_name="back_imgsensor_ae_pwd_h"},
	{.pinctrl_name="back_imgsensor_ae_pwd_l"},
	{.pinctrl_name="back_imgsensor_ae_vcamd_h"},
	{.pinctrl_name="back_imgsensor_ae_vcamd_l"},
	{.pinctrl_name="back_imgsensor_ae_vcama_h"},
	{.pinctrl_name="back_imgsensor_ae_vcama_l"},
	{.pinctrl_name="back_imgsensor_ae_vcamio_h"},
	{.pinctrl_name="back_imgsensor_ae_vcamio_l"},
};
static struct imgsensor_ae_pinctrl_t front_gpio_pinctrl_list[]={
	{.pinctrl_name="front_imgsensor_ae_rst_h"},
	{.pinctrl_name="front_imgsensor_ae_rst_l"},
	{.pinctrl_name="front_imgsensor_ae_pwd_h"},
	{.pinctrl_name="front_imgsensor_ae_pwd_l"},
	{.pinctrl_name="front_imgsensor_ae_vcamd_h"},
	{.pinctrl_name="front_imgsensor_ae_vcamd_l"},
	{.pinctrl_name="front_imgsensor_ae_vcama_h"},
	{.pinctrl_name="front_imgsensor_ae_vcama_l"},
	{.pinctrl_name="front_imgsensor_ae_vcamio_h"},
	{.pinctrl_name="front_imgsensor_ae_vcamio_l"},
};

static struct pinctrl *g_imgsensor_ae_pinctrl;
static const struct of_device_id imgsensor_ae_of_match[] = {
	{.compatible = "mediatek,imgsensor_ae"},
	{},
};
static struct platform_driver imgsensor_ae_driver = {
	.probe = imgsensor_ae_probe,
	.driver = {
		   .name = "imgsensor_ae",
		   .of_match_table = imgsensor_ae_of_match,
	},
};

static struct imgsensor_ae_t *g_imgsensor_ae_list[6]={0};
static struct imgsensor_ae_t *g_imgsensor_ae[2]={0};
static enum IMGSENSOR_AE_STATUS g_imgsensor_ae_status[2]={POWER_OFF};
static bool had_do_hw_check_available=false;

int imgsensor_ae_drv_add(struct imgsensor_ae_t * info)
{
	int i;

	for(i=0;i<sizeof(g_imgsensor_ae_list)/sizeof(struct imgsensor_ae_t *);i++){
		if(g_imgsensor_ae_list[i]==NULL){
			g_imgsensor_ae_list[i]=info;
			return 0;
		}
	}
	printk("imgsensor_ae_drv_add fail\n");
	return -1;
}

void camera_power_callback(int open_id,int on)
{
	int i;

	if(g_imgsensor_ae[open_id]==NULL && on && had_do_hw_check_available==false){
		for(i=0;i<sizeof(g_imgsensor_ae_list)/sizeof(struct imgsensor_ae_t *);i++){
			if((g_imgsensor_ae_list[i]!=NULL) && (g_imgsensor_ae_list[i]->layout_id==open_id)){
				g_imgsensor_ae_list[i]->hw_power(on);
				if(g_imgsensor_ae_list[i]->hw_check_available()){
					g_imgsensor_ae[open_id]=g_imgsensor_ae_list[i];
					break;
				}
			}
		}
	}

	if(g_imgsensor_ae[open_id]){
		g_imgsensor_ae[open_id]->hw_power(on);
		g_imgsensor_ae_status[open_id]=on?POWER_ON_WITCHOUT_INIT:POWER_OFF;
	}
}

static int get_imgsensor_ae_als(enum IMGSENSOR_AE_ID id)
{
	had_do_hw_check_available=true;
	if((g_imgsensor_ae[id]!=NULL)&&(g_imgsensor_ae_status[id]==POWER_ON_WITCHOUT_INIT)){
		g_imgsensor_ae[id]->init();
		g_imgsensor_ae_status[id]=POWER_ON_WITCH_INIT;
	}
	if((g_imgsensor_ae[id]!=NULL)&&(g_imgsensor_ae_status[id]==POWER_ON_WITCH_INIT)){
		return g_imgsensor_ae[id]->get_ae();
	}
	return -1;
}
static const char *get_imgsensor_ae_name(enum IMGSENSOR_AE_ID id)
{
	return  g_imgsensor_ae[id]?g_imgsensor_ae[id]->name:"NULL";
}

static ssize_t main_imgsensor_ae_show_als(struct device_driver *ddri, char *buf)
{
	return sprintf(buf, "%d\n", get_imgsensor_ae_als(BACK));
}
static ssize_t main_imgsensor_ae_show_name(struct device_driver *ddri, char *buf)
{
	return sprintf(buf, "%s\n", get_imgsensor_ae_name(BACK));
}
static ssize_t sub_imgsensor_ae_show_als(struct device_driver *ddri, char *buf)
{
	return sprintf(buf, "%d\n", get_imgsensor_ae_als(FRONT));
}
static ssize_t sub_imgsensor_ae_show_name(struct device_driver *ddri, char *buf)
{
	return sprintf(buf, "%s\n", get_imgsensor_ae_name(FRONT));
}

static DRIVER_ATTR(main_als,      S_IWUSR | S_IRUGO, main_imgsensor_ae_show_als,	NULL); 
static DRIVER_ATTR(main_name,     S_IWUSR | S_IRUGO, main_imgsensor_ae_show_name,	NULL); 
static DRIVER_ATTR(sub_als,      S_IWUSR | S_IRUGO, sub_imgsensor_ae_show_als,	NULL); 
static DRIVER_ATTR(sub_name,     S_IWUSR | S_IRUGO, sub_imgsensor_ae_show_name,	NULL); 


static int get_imgsensor_ae_info(struct platform_device *dev)
{
	int i;
	g_imgsensor_ae_pinctrl = devm_pinctrl_get(&dev->dev);
	if (IS_ERR(g_imgsensor_ae_pinctrl)){
		printk("Failed to get imgsensor_ae pinctrl.\n");
		return -1;
	}
	for(i=0;i<sizeof(back_gpio_pinctrl_list)/sizeof(struct imgsensor_ae_pinctrl_t);i++){
		back_gpio_pinctrl_list[i].pinctrl_state=pinctrl_lookup_state(g_imgsensor_ae_pinctrl, back_gpio_pinctrl_list[i].pinctrl_name);
	}
	for(i=0;i<sizeof(front_gpio_pinctrl_list)/sizeof(struct imgsensor_ae_pinctrl_t);i++){
		front_gpio_pinctrl_list[i].pinctrl_state=pinctrl_lookup_state(g_imgsensor_ae_pinctrl, front_gpio_pinctrl_list[i].pinctrl_name);
	}
	return 0;
}
void set_pinctrl_status(enum IMGSENSOR_AE_ID id,enum PINCTRL_STATUS pin_status)
{
	struct imgsensor_ae_pinctrl_t *imgsensor_pin_ctrl;

	if(id==BACK)
		imgsensor_pin_ctrl=back_gpio_pinctrl_list;
	else
		imgsensor_pin_ctrl=front_gpio_pinctrl_list;

	if (IS_ERR(g_imgsensor_ae_pinctrl)||IS_ERR(imgsensor_pin_ctrl[pin_status].pinctrl_state)) {
		return;
	}
	pinctrl_select_state(g_imgsensor_ae_pinctrl, imgsensor_pin_ctrl[pin_status].pinctrl_state);
}

static int imgsensor_ae_probe(struct platform_device *dev)
{
	int ret;
	ret= get_imgsensor_ae_info(dev);
	ret = driver_create_file(&(imgsensor_ae_driver.driver), &driver_attr_main_als);
	ret = driver_create_file(&(imgsensor_ae_driver.driver), &driver_attr_main_name);
	ret = driver_create_file(&(imgsensor_ae_driver.driver), &driver_attr_sub_als);
	ret = driver_create_file(&(imgsensor_ae_driver.driver), &driver_attr_sub_name);
	return 0;
}


static int __init imgsensor_ae_init(void)
{
	int ret;
	ret = platform_driver_register(&imgsensor_ae_driver);
	if (ret) {
		return ret;
	}
	return 0;
}

static void __exit imgsensor_ae_exit(void)
{
	return;
}


module_init(imgsensor_ae_init);
module_exit(imgsensor_ae_exit);
MODULE_AUTHOR("Liteon");
MODULE_DESCRIPTION("LTR-303ALSPS Driver");
MODULE_LICENSE("GPL");
