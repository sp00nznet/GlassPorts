/*
 * GlassPorts Kernel Board File
 * Google Glass Explorer Edition - TI OMAP4430
 *
 * This file contains the board-specific initialization for Google Glass
 */

#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/platform_device.h>
#include <linux/io.h>
#include <linux/gpio.h>
#include <linux/i2c.h>
#include <linux/i2c/twl.h>
#include <linux/regulator/machine.h>
#include <linux/regulator/fixed.h>
#include <linux/wl12xx.h>
#include <linux/mmc/host.h>

#include <asm/mach-types.h>
#include <asm/mach/arch.h>
#include <asm/mach/map.h>

#include "common.h"
#include "hsmmc.h"
#include "mux.h"
#include "control.h"

/* GPIO definitions for Glass hardware */
#define GLASS_GPIO_WIFI_PMENA       54
#define GLASS_GPIO_WIFI_IRQ         53
#define GLASS_GPIO_BT_EN            55
#define GLASS_GPIO_CAMERA_RESET     83
#define GLASS_GPIO_PRISM_EN         84
#define GLASS_GPIO_TOUCHPAD_IRQ     85
#define GLASS_GPIO_LED_R            186
#define GLASS_GPIO_LED_G            187
#define GLASS_GPIO_LED_B            188

/* WiFi configuration for WL1271 */
static struct wl12xx_platform_data glass_wlan_data __initdata = {
    .irq = OMAP_GPIO_IRQ(GLASS_GPIO_WIFI_IRQ),
    .board_ref_clock = WL12XX_REFCLOCK_38,
    .board_tcxo_clock = WL12XX_TCXOCLOCK_38_4,
};

/* WiFi regulator */
static struct regulator_consumer_supply glass_vmmc5_supply[] = {
    REGULATOR_SUPPLY("vmmc", "omap_hsmmc.4"),
};

static struct regulator_init_data glass_vmmc5 = {
    .constraints = {
        .valid_ops_mask = REGULATOR_CHANGE_STATUS,
    },
    .num_consumer_supplies = ARRAY_SIZE(glass_vmmc5_supply),
    .consumer_supplies = glass_vmmc5_supply,
};

static struct fixed_voltage_config glass_vwlan = {
    .supply_name = "vwl1271",
    .microvolts = 1800000,
    .gpio = GLASS_GPIO_WIFI_PMENA,
    .startup_delay = 70000,
    .enable_high = 1,
    .enabled_at_boot = 0,
    .init_data = &glass_vmmc5,
};

static struct platform_device glass_vwlan_device = {
    .name = "reg-fixed-voltage",
    .id = 1,
    .dev = {
        .platform_data = &glass_vwlan,
    },
};

/* MMC configuration */
static struct omap2_hsmmc_info glass_mmc[] = {
    {
        .mmc        = 1,
        .caps       = MMC_CAP_4_BIT_DATA | MMC_CAP_8_BIT_DATA,
        .gpio_wp    = -EINVAL,
        .gpio_cd    = -EINVAL,
        .nonremovable = true,
    },
    {
        .mmc        = 5,
        .caps       = MMC_CAP_4_BIT_DATA | MMC_CAP_POWER_OFF_CARD,
        .gpio_wp    = -EINVAL,
        .gpio_cd    = -EINVAL,
        .nonremovable = true,
    },
    {}
};

/* I2C devices on bus 1 */
static struct i2c_board_info __initdata glass_i2c1_boardinfo[] = {
    {
        I2C_BOARD_INFO("twl6040", 0x4b),
    },
};

/* I2C devices on bus 2 - Sensors */
static struct i2c_board_info __initdata glass_i2c2_boardinfo[] = {
    {
        I2C_BOARD_INFO("mpu6050", 0x68),
        .irq = OMAP_GPIO_IRQ(45),
    },
    {
        I2C_BOARD_INFO("ak8975", 0x0c),
    },
    {
        I2C_BOARD_INFO("bmp280", 0x76),
    },
    {
        I2C_BOARD_INFO("apds9960", 0x39),
    },
};

/* I2C devices on bus 3 - Touchpad */
static struct i2c_board_info __initdata glass_i2c3_boardinfo[] = {
    {
        I2C_BOARD_INFO("cyttsp4_i2c", 0x24),
        .irq = OMAP_GPIO_IRQ(GLASS_GPIO_TOUCHPAD_IRQ),
    },
};

/* I2C devices on bus 4 - Camera */
static struct i2c_board_info __initdata glass_i2c4_boardinfo[] = {
    {
        I2C_BOARD_INFO("ov5640", 0x3c),
    },
};

/* Platform devices */
static struct platform_device *glass_devices[] __initdata = {
    &glass_vwlan_device,
};

/* MUX configuration */
static void __init glass_mux_init(void)
{
    /* WiFi */
    omap_mux_init_gpio(GLASS_GPIO_WIFI_PMENA, OMAP_PIN_OUTPUT);
    omap_mux_init_gpio(GLASS_GPIO_WIFI_IRQ, OMAP_PIN_INPUT);

    /* Bluetooth */
    omap_mux_init_gpio(GLASS_GPIO_BT_EN, OMAP_PIN_OUTPUT);

    /* Camera */
    omap_mux_init_gpio(GLASS_GPIO_CAMERA_RESET, OMAP_PIN_OUTPUT);

    /* Prism display */
    omap_mux_init_gpio(GLASS_GPIO_PRISM_EN, OMAP_PIN_OUTPUT);

    /* Touchpad */
    omap_mux_init_gpio(GLASS_GPIO_TOUCHPAD_IRQ, OMAP_PIN_INPUT);

    /* RGB LED */
    omap_mux_init_gpio(GLASS_GPIO_LED_R, OMAP_PIN_OUTPUT);
    omap_mux_init_gpio(GLASS_GPIO_LED_G, OMAP_PIN_OUTPUT);
    omap_mux_init_gpio(GLASS_GPIO_LED_B, OMAP_PIN_OUTPUT);
}

/* I2C initialization */
static int __init glass_i2c_init(void)
{
    omap_register_i2c_bus(1, 400, glass_i2c1_boardinfo,
                          ARRAY_SIZE(glass_i2c1_boardinfo));
    omap_register_i2c_bus(2, 400, glass_i2c2_boardinfo,
                          ARRAY_SIZE(glass_i2c2_boardinfo));
    omap_register_i2c_bus(3, 400, glass_i2c3_boardinfo,
                          ARRAY_SIZE(glass_i2c3_boardinfo));
    omap_register_i2c_bus(4, 400, glass_i2c4_boardinfo,
                          ARRAY_SIZE(glass_i2c4_boardinfo));
    return 0;
}

/* WiFi initialization */
static void __init glass_wifi_init(void)
{
    int ret;

    ret = gpio_request_one(GLASS_GPIO_WIFI_IRQ, GPIOF_IN, "wl12xx_irq");
    if (ret < 0) {
        pr_err("glass: failed to request WiFi IRQ GPIO\n");
        return;
    }

    wl12xx_set_platform_data(&glass_wlan_data);
}

/* Board initialization */
static void __init glass_init(void)
{
    pr_info("GlassPorts: Initializing Google Glass board\n");

    glass_mux_init();
    glass_i2c_init();
    glass_wifi_init();

    platform_add_devices(glass_devices, ARRAY_SIZE(glass_devices));

    omap_hsmmc_init(glass_mmc);

    pr_info("GlassPorts: Board initialization complete\n");
}

/* Board identification */
static void __init glass_reserve(void)
{
    omap_reserve();
}

MACHINE_START(GLASS, "Google Glass Explorer Edition")
    .atag_offset    = 0x100,
    .reserve        = glass_reserve,
    .map_io         = omap4_map_io,
    .init_early     = omap4430_init_early,
    .init_irq       = gic_init_irq,
    .init_machine   = glass_init,
    .init_time      = omap4_local_timer_init,
    .restart        = omap44xx_restart,
MACHINE_END
