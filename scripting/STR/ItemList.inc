#if defined ITEMLIST_INCLUDED
#endinput
#endif
#define ITEMLIST_INCLUDED

/**
 * @brief 武器名称表，索引 0 为 "NULL"。
 * 用于录制时根据武器实体获取索引，播放时根据索引切换武器。
 */
#define ITEMS_COUNT 27

char g_Items[ITEMS_COUNT][] =
{
	"NULL",
	"weapon_upgradepack_incendiary",
	"weapon_upgradepack_explosive",
	"weapon_pistol",
	"weapon_pistol_magnum",
	"weapon_adrenaline",
	"weapon_pain_pills",
	"weapon_vomitjar",
	"weapon_pipe_bomb",
	"weapon_molotov",
	"weapon_defibrillator",
	"weapon_first_aid_kit",
	"weapon_shotgun_chrome",
	"weapon_pumpshotgun",
	"weapon_shotgun_spas",
	"weapon_autoshotgun",
	"weapon_smg",
	"weapon_smg_silenced",
	"weapon_rifle",
	"weapon_rifle_ak47",
	"weapon_rifle_desert",
	"weapon_hunting_rifle",
	"weapon_sniper_military",
	"weapon_rifle_m60",
	"weapon_grenade_launcher",
	"weapon_chainsaw",
	"weapon_melee"
};
