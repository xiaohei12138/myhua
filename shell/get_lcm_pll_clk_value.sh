#! /bin/bash
# basic usage of 'bc' tool in Bash.

echo "使用大分辨率的lcm 屏"
echo "GPS frequency : 1575 MHz"
echo "please input lcm info: "

echo -ne "LCM_WIDTH  : "
read LCM_WIDTH
echo -ne "LCM_HEIGHT : "
read LCM_HEIGHT
echo -ne "LCM_LINE : "
read LCM_LINE


PLL_CLK=$[$LCM_WIDTH*$LCM_HEIGHT*12/10*24*60/$LCM_LINE]
PLL_CLK=$[$PLL_CLK/2]
PLL_CLK=$[$PLL_CLK/1000/1000]



#PLL_CLK=295
#BIT_TIME=$(echo "1/$PLL_CLK/LCM_LINE"|bc)
BIT_TIME=$(echo "scale=7 ; (1/($PLL_CLK*2)) * 1000 / $LCM_LINE" | bc)

#Pixel_clk=(1/(bit_time*Pixel Format))*1000;
PIXEL_CLK=$(echo "scale=7 ; (1/($BIT_TIME*24)) * 1000 " | bc)


PIXEL_CLK_N=$(echo "scale=0 ; ($PIXEL_CLK/1)" | bc)

#得出大约的倍频数
#GPS_CLK_XN1=$(echo "scale=0; 1575/$PIXEL_CLK_N"|bc)
GPS_CLK_XN1=$[1575/$PIXEL_CLK_N] 

echo "LCM_WIDTH : $LCM_WIDTH "
echo "LCM_HEIGHT : $LCM_HEIGHT "
echo "LCM_LINE : $LCM_LINE "
echo "PLL_CLK : $PLL_CLK "
echo "BIT_TIME : $BIT_TIME "
echo "PIXEL_CLK : $PIXEL_CLK "
echo "GPS_CLK_XN1 : $GPS_CLK_XN1"


GPS_CLK_DESENSOR_0_1=$(echo "scale=2 ; (1575.0/($GPS_CLK_XN1-1))" | bc)
GPS_CLK_DESENSOR_0_0=$(echo "scale=2 ; ($GPS_CLK_DESENSOR_0_1-1.0)" | bc)
GPS_CLK_DESENSOR_0_2=$(echo "scale=2 ; ($GPS_CLK_DESENSOR_0_1+1.0)" | bc)
echo "GPS 干扰倍频房范围 ：$GPS_CLK_DESENSOR_0_0 ~$GPS_CLK_DESENSOR_0_2"


GPS_CLK_DESENSOR_1_1=$(echo "scale=2 ; (1575.0/$GPS_CLK_XN1)" | bc)
GPS_CLK_DESENSOR_1_0=$(echo "scale=2 ; ($GPS_CLK_DESENSOR_1_1-1.0)" | bc)
GPS_CLK_DESENSOR_1_2=$(echo "scale=2 ; ($GPS_CLK_DESENSOR_1_1+1.0)" | bc)
echo "GPS 干扰倍频房范围 ：$GPS_CLK_DESENSOR_1_0 ~$GPS_CLK_DESENSOR_1_2"



GPS_CLK_DESENSOR_2_1=$(echo "scale=2 ; (1575.0/($GPS_CLK_XN1+1))" | bc)
GPS_CLK_DESENSOR_2_0=$(echo "scale=2 ; ($GPS_CLK_DESENSOR_2_1-1.0)" | bc)
GPS_CLK_DESENSOR_2_2=$(echo "scale=2 ; ($GPS_CLK_DESENSOR_2_1+1.0)" | bc)
echo "GPS 干扰倍频房范围 ：$GPS_CLK_DESENSOR_2_0 ~$GPS_CLK_DESENSOR_2_2"


if [ $(echo "scale=0 ; ($GPS_CLK_DESENSOR_0_0*100/1.0)" | bc) -lt $(echo "scale=0 ; ($GPS_CLK_DESENSOR_1_2*100/1.0)" | bc) ] ;
then  
	echo "no support this resolution"
	echo "the PLL_CLK about is $PLL_CLK  then fps is 60"
	exit
fi


#Pixel_clk=(1/(bit_time*Pixel Format))*1000;
GPS_NO_DESENSOR_BIT_TIME_0_0=$(echo "scale=7 ; (1/(($GPS_CLK_DESENSOR_0_0/1000)*24))" | bc)
GPS_NO_DESENSOR_BIT_TIME_1_2=$(echo "scale=7 ; (1/(($GPS_CLK_DESENSOR_1_2/1000)*24))" | bc)

#bit_time = (1/(PLL_CLOCK*2))*1000/Line_num;
GPS_NO_DESENSOR_PLL_CLK_0_0=$(echo "scale=7 ; (1/($GPS_NO_DESENSOR_BIT_TIME_0_0*$LCM_LINE/1000)/2)" | bc)
GPS_NO_DESENSOR_PLL_CLK_1_2=$(echo "scale=7 ; (1/($GPS_NO_DESENSOR_BIT_TIME_1_2*$LCM_LINE/1000)/2)" | bc)
echo "推荐PLL范围 $GPS_NO_DESENSOR_PLL_CLK_1_2 ~ $GPS_NO_DESENSOR_PLL_CLK_0_0"




GPS_NO_DESENSOR_BIT_TIME_1_0=$(echo "scale=7 ; (1/(($GPS_CLK_DESENSOR_1_0/1000)*24))" | bc)
GPS_NO_DESENSOR_BIT_TIME_2_2=$(echo "scale=7 ; (1/(($GPS_CLK_DESENSOR_2_2/1000)*24))" | bc)


GPS_NO_DESENSOR_PLL_CLK_1_0=$(echo "scale=7 ; (1/($GPS_NO_DESENSOR_BIT_TIME_1_0*$LCM_LINE/1000)/2)" | bc)
GPS_NO_DESENSOR_PLL_CLK_2_2=$(echo "scale=7 ; (1/($GPS_NO_DESENSOR_BIT_TIME_2_2*$LCM_LINE/1000)/2)" | bc)
echo "推荐PLL范围 $GPS_NO_DESENSOR_PLL_CLK_2_2 ~ $GPS_NO_DESENSOR_PLL_CLK_1_0"



#GPS_CLK_DESENSOR_0=$(echo "scale=7 ; ($GPS_CLK_XN1)" | bc)


