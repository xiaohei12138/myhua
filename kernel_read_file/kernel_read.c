int load_dtb_to_mem(const char *name, void **blob)
{
	ssize_t ret;
	u32 count;
	struct fdt_header dtbhead;
	loff_t pos = 0;
	struct file *fdtb;


	fdtb = filp_open(name, O_RDONLY, 0644);
	if (IS_ERR(fdtb)) {
		DRM_ERROR("%s open file error\n", __func__);
		return PTR_ERR(fdtb);
	}

	ret = kernel_read(fdtb, &dtbhead, sizeof(dtbhead), &pos);
	pos = 0;
	count = ntohl(dtbhead.totalsize);
	*blob = kzalloc(count, GFP_KERNEL);
	if (*blob == NULL) {
		filp_close(fdtb, NULL);
		return -ENOMEM;
	}
	ret = kernel_read(fdtb, *blob, count, &pos);

	if (ret != count) {
		DRM_ERROR("Read to mem fail: ret %zd size%x\n", ret, count);
		kfree(*blob);
		*blob = NULL;
		filp_close(fdtb, NULL);
		return ret < 0 ? ret : -ENODEV;
	}

	filp_close(fdtb, NULL);

	return 0;
}
void test(void){
	ret = load_dtb_to_mem("/data/lcd.dtb", &blob);
	if (ret < 0) {
		pr_err("parse lcd dtb file failed\n");
		return -EINVAL;
	}


}
