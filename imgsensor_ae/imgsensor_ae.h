#ifndef __IMGSENSOR_AE_H_
#define __IMGSENSOR_AE_H_

#include <linux/pinctrl/pinctrl.h>

enum IMGSENSOR_AE_ID{
	BACK=0,
	FRONT=1
};
enum IMGSENSOR_AE_STATUS{
	POWER_OFF=0,
	POWER_ON_WITCHOUT_INIT,
	POWER_ON_WITCH_INIT,
};
struct imgsensor_ae_t{
	const char *name;
	int (*hw_power)(int on);
	int (*init)(void);
	int (*get_ae)(void);
	enum IMGSENSOR_AE_ID layout_id;
	bool (*hw_check_available)(void);
};

struct imgsensor_ae_pinctrl_t{
	const char *pinctrl_name;
	struct pinctrl_state *pinctrl_state;
};
enum PINCTRL_STATUS{
	RST_H=0,
	RST_L,
	PWD_H,
	PWD_L,
	VCAMD_H,
	VCAMD_L,
	VCAMA_H,
	VCAMA_L,
	VCAMIO_H,
	VCAMIO_L
};
extern int imgsensor_ae_drv_add(struct imgsensor_ae_t * info);
extern void set_pinctrl_status(enum IMGSENSOR_AE_ID id,enum PINCTRL_STATUS pin_status);
#endif
