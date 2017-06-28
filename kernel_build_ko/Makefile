KERNELDIR :=/home5/zougui/gt_project/mt6580/6.0/together_M/base/alps/kernel-3.18
KERNELOUTDIR :=/home5/zougui/gt_project/mt6580/6.0/together_M/base/alps/out/target/product/toge6580_weg_m/obj/KERNEL_OBJ/
ARCH = arm
#CROSS_COMPILE=/home5/zougui/arm-linux-gcc/opt/FriendlyARM/toolschain/4.4.3/bin/arm-none-linux-gnueabi-
#CROSS_COMPILE=/home5/zougui/gt_project/mt6580/6.0/together_M/base/alps/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
CROSS_COMPILE=/home5/zougui/gt_project/mt6580/6.0/together_M/base/alps/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi-
obj-m += test.o
all:
	$(MAKE) -C $(KERNELOUTDIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) M=$(shell pwd) modules 
clean:
    $(MAKE) -C $(KERNELDIR) M=$(shell pwd) modules clean ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE)