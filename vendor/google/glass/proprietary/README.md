# GlassPorts Proprietary Files

This directory contains proprietary binary blobs required for Google Glass hardware support.

## Required Files

Due to licensing restrictions, proprietary files cannot be distributed with GlassPorts. You must extract these files from an original Google Glass device or factory image.

### Extraction Methods

1. **From a connected device:**
   ```bash
   cd vendor/google/glass
   ./extract-files.sh -d
   ```

2. **From a factory image:**
   ```bash
   cd vendor/google/glass
   ./extract-files.sh /path/to/factory-image.zip
   ```

## File List

### Graphics (PowerVR SGX540)
- `vendor/lib/egl/libEGL_POWERVR_SGX540_120.so`
- `vendor/lib/egl/libGLESv1_CM_POWERVR_SGX540_120.so`
- `vendor/lib/egl/libGLESv2_POWERVR_SGX540_120.so`
- `vendor/lib/libglslcompiler.so`
- `vendor/lib/libIMGegl.so`
- `vendor/lib/libpvr2d.so`
- `vendor/lib/libpvrANDROID_WSEGL.so`
- `vendor/lib/libPVRScopeServices.so`
- `vendor/lib/libsrv_init.so`
- `vendor/lib/libsrv_um.so`
- `vendor/lib/libusc.so`
- `vendor/lib/hw/gralloc.omap4.so`
- `vendor/lib/hw/hwcomposer.omap4.so`
- `vendor/lib/hw/memtrack.omap4.so`

### Camera (TI DUCATI)
- `vendor/lib/hw/camera.omap4.so`
- `vendor/lib/libcamera.so`
- `vendor/lib/libion_ti.so`
- `vendor/lib/libipcutils.so`
- `vendor/lib/libmm_osal.so`
- `vendor/lib/libOMX_Core.so`
- `vendor/lib/libOMX.TI.DUCATI1.VIDEO.DECODER.so`
- `vendor/lib/libOMX.TI.DUCATI1.VIDEO.H264E.so`
- `vendor/lib/libOMX.TI.DUCATI1.VIDEO.MPEG4E.so`
- `vendor/lib/libomx_rpc.so`
- `vendor/lib/librcm.so`
- `vendor/lib/libsysmgr.so`
- `vendor/lib/libtimemmgr.so`

### Audio
- `vendor/lib/hw/audio.primary.omap4.so`
- `vendor/lib/libasound.so`

### Sensors
- `vendor/lib/hw/sensors.glass.so`
- `vendor/lib/libmllite.so`
- `vendor/lib/libmlplatform.so`
- `vendor/lib/libmpl.so`

### Firmware
- `vendor/firmware/ducati-m3.bin` - DSP/ISP firmware
- `vendor/firmware/ti-connectivity/wl12xx-fw-5.bin` - WiFi firmware
- `vendor/firmware/ti-connectivity/wl1271-nvs.bin` - WiFi calibration
- `vendor/firmware/ti-connectivity/TIInit_7.6.15.bts` - Bluetooth init
- `vendor/firmware/bcm4330.hcd` - Bluetooth firmware

## Legal Notice

These proprietary files are copyrighted by their respective owners (Google, Texas Instruments, Imagination Technologies, etc.). They are not included in this repository and must be obtained from legitimate sources.

Use of these files is subject to the terms and conditions of the original licenses. GlassPorts does not provide, distribute, or endorse the unauthorized distribution of proprietary software.
