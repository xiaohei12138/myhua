#include <linux/module.h>
#include <linux/of.h>
#include <linux/of_address.h>
#include <linux/of_irq.h>
#include <linux/gpio.h>
#include <linux/platform_device.h>

#define ATTR_FISE_INFO(dev)		\
		extern const char *get_##dev(void);		\
		const char __attribute__ ((weak)) *get_##dev(void){return "null";}			\
		static ssize_t dev##_show(struct device_driver *ddri, char *buf)			\
		{																				\
			return sprintf(buf, "%s\n", get_##dev());		\
		}																				\
		static DRIVER_ATTR( dev,      S_IWUSR | S_IRUGO, dev##_show,	NULL);


ATTR_FISE_INFO(imgsensor_name)
ATTR_FISE_INFO(alsps_name)
ATTR_FISE_INFO(touchscreen_name)
ATTR_FISE_INFO(msensor_name)
ATTR_FISE_INFO(gsensor_name)
ATTR_FISE_INFO(lcm_name)
ATTR_FISE_INFO(gyro_name)
ATTR_FISE_INFO(fingerprint_name)

ATTR_FISE_INFO(battery_current)
ATTR_FISE_INFO(charger_voltage)


struct platform_device hw_info_user_space_device = {
	.name = "hw_info",
	.id = -1,
};
static int hw_info_probe(struct platform_device *dev);
static struct platform_driver hw_info_user_space_driver = {
	.probe = hw_info_probe,
	.driver = {
		   .name = "hw_info",
	},
};
static int hw_info_probe(struct platform_device *dev)
{
	int ret;

	ret = driver_create_file(&(hw_info_user_space_driver.driver), &driver_attr_imgsensor_name);
	ret = driver_create_file(&(hw_info_user_space_driver.driver), &driver_attr_alsps_name);
	ret = driver_create_file(&(hw_info_user_space_driver.driver), &driver_attr_touchscreen_name);
	ret = driver_create_file(&(hw_info_user_space_driver.driver), &driver_attr_msensor_name);
	ret = driver_create_file(&(hw_info_user_space_driver.driver), &driver_attr_gsensor_name);
	ret = driver_create_file(&(hw_info_user_space_driver.driver), &driver_attr_lcm_name);
	ret = driver_create_file(&(hw_info_user_space_driver.driver), &driver_attr_gyro_name);
	ret = driver_create_file(&(hw_info_user_space_driver.driver), &driver_attr_fingerprint_name);
	ret = driver_create_file(&(hw_info_user_space_driver.driver), &driver_attr_battery_current);
	ret = driver_create_file(&(hw_info_user_space_driver.driver), &driver_attr_charger_voltage);
	return 0;
}


static int __init hw_info_init(void)
{
	int ret;

	ret = platform_device_register(&hw_info_user_space_device);
	if (ret) {
		return ret;
	}
	ret = platform_driver_register(&hw_info_user_space_driver);
	if (ret) {
		return ret;
	}
	return 0;
}

module_init(hw_info_init);


