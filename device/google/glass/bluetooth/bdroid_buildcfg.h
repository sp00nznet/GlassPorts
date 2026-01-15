/*
 * GlassPorts Bluetooth Configuration
 * Google Glass Explorer Edition
 */

#ifndef _BDROID_BUILDCFG_H
#define _BDROID_BUILDCFG_H

#define BTM_DEF_LOCAL_NAME   "GlassPorts"
#define BTA_DM_COD {0x26, 0x04, 0x00} /* WEARABLE_WRIST_WATCH */

#define BLE_VND_INCLUDED     TRUE
#define BTIF_HF_SERVICES    (BTA_HSP_SERVICE_MASK)
#define BTIF_HF_SERVICE_NAMES  { BTIF_HSAG_SERVICE_NAME, NULL }

#define PAN_NAP_DISABLED     TRUE
#define BTA_AR_INCLUDED      FALSE
#define BTA_AV_INCLUDED      TRUE
#define BTA_AV_SINK_INCLUDED FALSE

#endif
