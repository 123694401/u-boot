// SPDX-License-Identifier: GPL-2.0+
/*
 * (C) Copyright 2016 Rockchip Electronics Co., Ltd
 */

#include <common.h>
#include <syscon.h>
#include <dm.h>
#include <env.h>
#include <log.h>
#include <spl_gpio.h>
#include <asm/io.h>
#include <power/regulator.h>

#include <asm/arch-rockchip/clock.h>
#include <asm/arch-rockchip/cru.h>
#include <asm/arch-rockchip/gpio.h>
#include <asm/arch-rockchip/grf_rk3399.h>
#include <asm/arch-rockchip/hardware.h>
#include <linux/bitops.h>

#ifndef CONFIG_SPL_BUILD
int board_early_init_f(void)
{
	struct udevice *regulator;
	int ret;

	ret = regulator_get_by_platname("vcc5v0_host", &regulator);
	if (ret) {
		debug("%s vcc5v0_host init fail! ret %d\n", __func__, ret);
		goto out;
	}

	ret = regulator_set_enable(regulator, true);
	if (ret)
		debug("%s vcc5v0-host-en set fail! ret %d\n", __func__, ret);
out:
	return 0;
}

#else

#define PMUGRF_BASE	0xff320000
#define GPIO0_BASE	0xff720000


#endif

#ifdef CONFIG_MISC_INIT_R
int misc_init_r(void)
{
	struct rk3399_grf_regs *grf =
	    syscon_get_first_range(ROCKCHIP_SYSCON_GRF);

	/**
	 * Some SSD's to work on rock960 would require explicit
	 * domain voltage change, so BT565 is in 1.8v domain
	 */
	rk_setreg(&grf->io_vsel, BIT(0));

	return 0;
}
#endif
