LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)
#LOCAL_FORCE_STATIC_EXECUTABLE := true

LOCAL_SRC_FILES:= \
    main.c

LOCAL_C_INCLUDES += bionic \
$(call include-path-for, libhardware_legacy)/hardware_legacy

LOCAL_MODULE:=overlay

LOCAL_MODULE_TAGS := optional

LOCAL_STATIC_LIBRARIES := libfs_mgr libcutils libc

LOCAL_SHARED_LIBRARIES := libhardware_legacy libnetutils liblog libion 

include $(BUILD_EXECUTABLE)
