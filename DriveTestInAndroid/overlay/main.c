
#define LOG_TAG "Sprites"

//#define LOG_NDEBUG 0

#include "cursor.h"
#include <cutils/log.h>

#include <linux/fb.h>
#include <fcntl.h>

#define FBIOPUT_SET_CURSOR_EN    0x4609
#define FBIOPUT_SET_CURSOR_IMG    0x460a
#define FBIOPUT_SET_CURSOR_POS    0x460b
#define FBIOPUT_SET_CURSOR_CMAP    0x460c
#define FBIOPUT_GET_CURSOR_RESOLUTION    0x460d
#define FBIOPUT_GET_CURSOR_EN    0x460e


int main()
{
	int mFbHandle = 0;
 	struct fb_image img;
        int cursor_en = 1;
	int red = 0;
	int green = 0;
	int blue = 0;
	struct fbcurpos cursor_pos = {0,0};
	int x,y;
	
//打开光标
	mFbHandle = open("/dev/graphics/fb0", O_RDWR, 0);
	if(mFbHandle <= 0)
	{
		printf("open fail: /dev/graphics/fb0\n");
	}
	

#if 0
 	 property_get("cursor.hw.colour.red", propVal, "255");
         red = atoi(propVal);
         property_get("cursor.hw.colour.green", propVal, "0");
         green = atoi(propVal);
         property_get("cursor.hw.colour.blue", propVal, "0");
         blue = atoi(propVal);
#endif
	img.bg_color = 0x000000ff;
	img.fg_color = ((red<<16) + (green<<8) + blue);//0x00ff7f00;
	img.fg_color = 0x00ff7f00;

	printf("red=%d, green=%d, blue=%d, img.fg_color=0x%x", red, green, blue, img.fg_color);
        ioctl(mFbHandle, FBIOPUT_SET_CURSOR_CMAP, &img);
        ioctl(mFbHandle, FBIOPUT_SET_CURSOR_IMG, cursorImg);
        ioctl(mFbHandle, FBIOPUT_SET_CURSOR_EN, &cursor_en);

while(1)
for(x=0;x=500;x++)
for(y=0;y<500;y++)
{	
	cursor_pos.x = x;
	cursor_pos.y = y;
	ioctl(mFbHandle, FBIOPUT_SET_CURSOR_POS, &cursor_pos);
	sleep(1);
}
	return 0;

}


