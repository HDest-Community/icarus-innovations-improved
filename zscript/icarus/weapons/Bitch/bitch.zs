class HDBitch : HDWeapon
{
	enum BitchFlags
	{
		BTF_JustUnload = 1,
		BTF_RapidFire = 2,
		BTF_GrenadeLoaded = 4,
		BTF_GL = 8
	}

	enum BitchProperties
	{
		BTProp_Flags,
		BTProp_Chamber,
		BTProp_Mode,
		BTProp_Heat
	}

	override void PostBeginPlay()
	{
		weaponspecial = 1337;
		Super.PostBeginPlay();
	}

	override void tick()
	{
        super.tick();
        drainheat(BTProp_Heat, 1);

		if(owner && WeaponStatus[BTProp_Heat] > 50 && !(Level.time % TICRATE))
		{
			owner.damagemobj(owner, owner, random(1, 3), "electrical");
		}
		
		if (!(WeaponStatus[BTProp_Flags] & BTF_GL) && WeaponStatus[BTProp_Flags] & BTF_GrenadeLoaded)
		{
			WeaponStatus[BTProp_Flags] &= ~BTF_GrenadeLoaded;
			Actor ptr = owner ? owner : Actor(self);
			ptr.A_SpawnItemEx('HDRocketAmmo', cos(ptr.pitch) * 10, 0, ptr.height - 10 - 10 * sin(ptr.pitch), ptr.vel.x, ptr.vel.y, ptr.vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH);
			ptr.A_StartSound("weapons/grenopen", CHAN_WEAPON);
		}
    }

	override bool AddSpareWeapon(actor newowner) { return AddSpareWeaponRegular(newowner); }
	override HDWeapon GetSpareWeapon(actor newowner, bool reverse, bool doselect) { return GetSpareWeaponRegular(newowner, reverse, doselect); }
	override double GunMass()
	{
		double BaseMass = 8.5;
		if (WeaponStatus[BTProp_Flags] & BTF_GL)
		{
			BaseMass += 1.5;
		}
		if (WeaponStatus[BTProp_Flags] & BTF_GrenadeLoaded)
		{
			BaseMass += 1;
		}
		return BaseMass;
	}

	override double WeaponBulk()
	{
		double BaseBulk = 110;
		if (WeaponStatus[BTProp_Flags] & BTF_GL)
		{
			BaseBulk += 25;
		}
		if (WeaponStatus[BTProp_Flags] & BTF_GrenadeLoaded)
		{
			BaseBulk += ENC_ROCKETLOADED;
		}
		return BaseBulk;
	}

	override string PickupMessage()
	{
		string RapidStr = WeaponStatus[BTProp_Flags] & BTF_RapidFire ? Stringtable.localize("$PICKUP_BITCH_RAPID") : "";
		string GLString = WeaponStatus[BTProp_Flags] & BTF_GL ? Stringtable.localize("$PICKUP_BITCH_GL") : "";

		return Stringtable.localize("$PICKUP_BITCH_PREFIX")..RapidStr..Stringtable.Localize("$TAG_BITCH")..GLString..Stringtable.localize("$PICKUP_BITCH_SUFFIX");
	}

	override string, double GetPickupSprite()
	{
		return WeaponStatus[BTProp_Flags] & BTF_GL ? "BCHGY0" : "BCHGZ0", 1.0;
	}

	override void LoadoutConfigure(string input)
	{
		if (GetLoadoutVar(input, "rapid", 1) > 0)
		{
			WeaponStatus[BTProp_Flags] |= BTF_RapidFire;
		}
		if (GetLoadoutVar(input, "gl", 1) > 0)
		{
			WeaponStatus[BTProp_Flags] |= BTF_GL;
		}

		InitializeWepStats(false);
	}

	override void InitializeWepStats(bool idfa)
	{
		WeaponStatus[BTProp_Chamber] = 1;
		if (WeaponStatus[BTProp_Flags] & BTF_GL)
		{
			WeaponStatus[BTProp_Flags] |= BTF_GrenadeLoaded;
		}
	}

	override string GetHelpText()
	{
		LocalizeHelp();
		return 
		LWPHELP_FIRESHOOT
		..(WeaponStatus[BTProp_Flags] & BTF_GL ? LWPHELP_ALTFIRE.. Stringtable.Localize("$BITCH_HELPTEXT_1") : "")
		..(WeaponStatus[BTProp_Flags] & BTF_GL ? LWPHELP_ALTRELOAD.. Stringtable.Localize("$BITCH_HELPTEXT_2") : "")
		..(WeaponStatus[BTProp_Flags] & BTF_GL ? LWPHELP_FIREMODE.."+"..LWPHELP_UNLOAD.. Stringtable.Localize("$BITCH_HELPTEXT_3") : "")
		..LWPHELP_RELOAD..Stringtable.Localize("$BITCH_HELPTEXT_4")
		..LWPHELP_MAGMANAGER;
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		if (hdw.WeaponStatus[BTProp_Chamber] == 1)
		{
			sb.DrawRect(-22, -8, 6, 3);
			sb.DrawRect(-23, -7, 1, 1);
		}

		if (hdw.WeaponStatus[BTProp_Flags] & BTF_GL)
		{
			sb.DrawImage("ROQPA0",(-50, -4), sb.DI_SCREEN_CENTER_BOTTOM, scale: (0.6, 0.6));
			sb.DrawNum(hpl.CountInv('HDRocketAmmo'), -48, -8, sb.DI_SCREEN_CENTER_BOTTOM);
		}

		if (hdw.WeaponStatus[BTProp_Flags] & BTF_GrenadeLoaded)
		{
			sb.DrawRect(-22, -13, 6, 3);
		}
		
		if (hdw.WeaponStatus[BTProp_Flags] & BTF_RapidFire)
		{
			sb.DrawWepCounter(hdw.WeaponStatus[BTProp_Mode], -26, -5, "RBRSA3A7", "STBURAUT", "STFULAUT", "STHPRAUT");
		}
		else
		{
			sb.DrawWepCounter(hdw.WeaponStatus[BTProp_Mode], -26, -5, "RBRSA3A7", "STBURAUT", "STFULAUT");
		}
	}

	override void DropOneAmmo(int amt)
	{
		if (owner)
		{
			double OldAngle = owner.angle;
			amt = clamp(amt, 1, 10);
			if (owner.CheckInventory('FourMilAmmo', 1))
			{
				owner.A_DropInventory('FourMilAmmo', amt * 50);
				owner.angle += 15;
			}
			if (owner.CheckInventory('HDRocketAmmo', 1))
			{
				owner.A_DropInventory('HDRocketAmmo', 1);
			}
			owner.angle = OldAngle;
		}
	}

	override void DrawSightPicture(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl, bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot)
	{
		int cx, cy, cw, ch;
		[cx, cy, cw, ch] = Screen.GetClipRect();
		sb.SetClipRect(-16 + bob.x, -4 + bob.y, 32, 16, sb.DI_SCREEN_CENTER);
		vector2 bob2 = bob * 1.18;
		//bob2.y = clamp(bob2.y, -8, 8);
		sb.DrawImage("BCHFRONT", (0, -4) + bob2, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, alpha: 0.9, scale: (0.8, 0.8));
		sb.SetClipRect(cx, cy, cw, ch);
		sb.DrawImage("BCHBACK", (0, 2) + bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, scale: (0.8, 0.8));
	}

	private action void A_TryLoadChamber()
	{
		if (invoker.Storage && invoker.Storage.owner == invoker.owner && invoker.Storage.Storage)
		{
			if (invoker.WeaponStatus[BTProp_Chamber] == 0)
			{
				if (invoker.AmmoReserve && invoker.AmmoReserve.Amounts.Size() > 0 && invoker.AmmoReserve.Amounts[0] > 0)
				{
					invoker.Storage.Storage.RemoveItem(invoker.AmmoReserve, null, null, 1);
					invoker.WeaponStatus[BTProp_Chamber] = 1;
				}
				else
				{
					invoker.AmmoReserve = null;
					if (A_FindStorage())
					{
						A_TryLoadChamber();
					}
				}
			}
			return;
		}
		if (A_FindStorage())
		{
			A_TryLoadChamber();
		}
	}

	private action bool A_FindStorage()
	{
		for (Inventory Next = Inv; Next; Next = Next.Inv)
		{
			let bp = HDBackpack(Next);
			if (bp && bp.Storage)
			{
				let nma = bp.Storage.Find('FourMilAmmo');
				if (nma && nma.Amounts.Size() > 0 && nma.Amounts[0] > 0)
				{
					invoker.AmmoReserve = nma;
					invoker.Storage = bp;
					return true;
				}
			}
		}
		return false;
	}

	private HDBackpack Storage;
	private StorageItem AmmoReserve;
	private int BurstIndex;
	transient int OldFireMode;

	Default
	{
		-HDWEAPON.FITSINBACKPACK
		Weapon.SelectionOrder 300;
		Weapon.SlotNumber 4;
		Weapon.SlotPriority 1.5;
		HDWeapon.BarrelSize 25, 2, 4;
		Scale 0.75;
		Tag "$TAG_BITCH";
		HDWeapon.Refid HDLD_BITCH;
		HDWeapon.Loadoutcodes "
			\curapid - Fuller Auto Firemode
			\cugl - Grenade Launcher";
	}

	States
	{
		Spawn:
			BCHG Y 0 NoDelay A_JumpIf(invoker.WeaponStatus[BTProp_Flags] & BTF_GL, 2);
			BCHG Z 0;
			#### # -1;
			Stop;
		Ready:
			BCHG A 1
			{
				if (JustPressed(BT_FIREMODE))
				{
					invoker.OldFireMode = invoker.WeaponStatus[BTProp_Mode];
					int maxMode = invoker.WeaponStatus[BTProp_Flags] & BTF_RapidFire ? 4 : 3;
					++invoker.WeaponStatus[BTProp_Mode] %= maxMode;
				}
				invoker.BurstIndex = 0;
				A_WeaponReady(WRF_ALL & ~WRF_ALLOWUSER2);
			}
			Goto ReadyEnd;
		Select0:
			BCHG A 0;
			Goto Select0Big;
		Deselect0:
			BCHG A 0;
			Goto Deselect0Big;

		Fire:
			BCHG A 1
			{
				if (invoker.WeaponStatus[BTProp_Chamber] == 1)
				{
					SetWeaponState("Shoot");
					return;
				}
			}
			Goto Nope;
		Shoot:
			BCHG A 1
			{
				if (invoker.WeaponStatus[BTProp_Mode] == 1 || invoker.WeaponStatus[BTProp_Mode] == 3)
				{
					A_SetTics(0);
				}
			}
			BCHG B 2 Offset(0, 34)
			{
				A_Overlay(PSP_FLASH, 'Flash');

				if (invoker.WeaponStatus[BTProp_Mode] == 1 || invoker.WeaponStatus[BTProp_Mode] == 3)
				{
					A_SetTics(1);
				}
				HDBulletActor.FireBullet(self, "HDB_426");
				A_AlertMonsters();
				invoker.WeaponStatus[BTProp_Chamber] = 0;
				invoker.WeaponStatus[BTProp_Heat] += random(4, 6);
				A_StartSound("weapons/rifle", CHAN_WEAPON, volume: 0.7);
				A_ZoomRecoil(1.05);
				A_MuzzleClimb(-frandom(-0.24, 0.24), -frandom(0.3, 0.36), -frandom(-0.24, 0.24), -frandom(0.3, 0.36), -frandom(-0.24, 0.24), -frandom(0.3, 0.36));
				A_Light1();
				A_WeaponReady(WRF_NOFIRE);
			}
			BCHG A 0
			{
				if (invoker.WeaponStatus[BTProp_Chamber] <= 0)
				A_TryLoadChamber();
				if (invoker.WeaponStatus[BTProp_Heat] > 250 && !random(0, 5))
				{
					invoker.WeaponStatus[BTProp_Chamber] = 0;
				}
			}
			BCHG A 0
			{
				switch (invoker.WeaponStatus[BTProp_Mode])
				{
					case 1:
					{
						if (invoker.BurstIndex < 2)
						{
							invoker.BurstIndex++;
							A_Refire('Fire');
						}
						break;
					}
					case 2:
					{
						A_Refire('Fire');
						break;
					}
					case 3:
					{
						if (invoker.WeaponStatus[BTProp_Flags] & BTF_RapidFire)
						{
							A_Refire('Fire');
							break;
						}
					}
				}
			}
			Goto Nope;

		AltFire:
			BCHG A 0 A_JumpIf(!(invoker.WeaponStatus[BTProp_Flags] & BTF_GrenadeLoaded), 'Nope');
			BCHG A 2
			{
				// A_Overlay(PSP_FLASH, 'AltFlash');

				A_FireHDGL();
				invoker.WeaponStatus[BTProp_Flags] &= ~BTF_GrenadeLoaded;
				A_StartSound("weapons/grenadeshot", CHAN_WEAPON);
				A_ZoomRecoil(0.95);
			}
			BCHG A 2 A_MuzzleClimb(0, 0, 0, 0, -1.2, -3.0, -1.0, -2.8);
			Goto Nope;

		Flash:
			BCHF A 1 Bright
			{
				HDFlashAlpha(-16);
			}
			goto lightdone;
		// [UZ] UBGL weapons don't seem to have a flash frame?
		// AltFlash:
		// 	BCHF B 1
		// 	{
		// 		HDFlashAlpha(-16);
		// 	}
		// 	goto lightdone;

		Reload:
		ChamberManual:
			BCHG A 0 A_JumpIf(invoker.WeaponStatus[BTProp_Chamber] == 1, "Nope");
			BCHG A 2 Offset(2, 34);
			BCHG A 4 Offset(3, 38) A_StartSound("weapons/rifchamber", 8, CHANF_OVERLAP);
			BCHG A 5 Offset(4, 44)
			{
				A_WeaponBusy();
				if (invoker.WeaponStatus[BTProp_Heat] > 0 && random(0, 4))
				{
					invoker.WeaponStatus[BTProp_Chamber] = 0;
				}
				else A_TryLoadChamber();
			}
			BCHG A 2 Offset(3, 38);
			BCHG A 2 Offset(2, 34);
			BCHG A 2 Offset(0, 32);
			Goto Nope;

		Unload:
			#### A 0
			{
				invoker.WeaponStatus[BTProp_Flags] |= BTF_JustUnload;
				if (PressingFiremode() && invoker.WeaponStatus[BTProp_Flags] & BTF_GrenadeLoaded)
				{
					SetWeaponState('UnloadGL');
				}
			}
			Goto Nope;

		AltReload:
			#### A 0
			{
				invoker.WeaponStatus[BTProp_Flags] &= ~BTF_JustUnload;
				if (invoker.WeaponStatus[BTProp_Flags] & BTF_GL && !(invoker.WeaponStatus[BTProp_Flags] & BTF_GrenadeLoaded) && CheckInventory("HDRocketAmmo", 1))
				{
					SetWeaponState('UnloadGL');
				}
			}
			Goto Nope;
		UnloadGL:
			#### A 0
			{
				A_SetCrosshair(21);
				A_MuzzleClimb(-0.3, -0.3);
			}
			#### A 2 Offset(0, 34);
			#### A 1 Offset(4, 38) A_MuzzleClimb(-0.3,-0.3);
			#### A 2 Offset(8, 48)
			{
				A_StartSound("weapons/grenopen", CHAN_WEAPON, CHANF_OVERLAP);
				A_MuzzleClimb(-0.3, -0.3);

				if (invoker.WeaponStatus[BTProp_Flags] & BTF_GrenadeLoaded)
				{
					A_StartSound("weapons/grenreload", CHAN_WEAPON);
				}
			}
			#### A 8 Offset(10, 49)
			{
				if (!(invoker.WeaponStatus[BTProp_Flags] & BTF_GrenadeLoaded))
				{
					if (invoker.WeaponStatus[BTProp_Flags] & BTF_JustUnload)
					{
						A_SetTics(3);
					}
					return;
				}
				invoker.WeaponStatus[BTProp_Flags] &= ~BTF_GrenadeLoaded;
				if(!PressingUnload() || A_JumpIfInventory('HDRocketAmmo', 0, 'Null'))
				{
					A_SpawnItemEx('HDRocketAmmo', cos(pitch) * 10, 0, height - 10 - 10 * sin(pitch), vel.x, vel.y, vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH);
				}
				else
				{
					A_SetTics(20);
					A_StartSound("weapons/pocket", CHAN_WEAPON, CHANF_OVERLAP);
					A_GiveInventory('HDRocketAmmo', 1);
					A_MuzzleClimb(frandom(0.8, -0.2), frandom(0.4, -0.2));
				}
			}
			#### A 0 A_JumpIf(invoker.WeaponStatus[BTProp_Flags] & BTF_JustUnload, 'ReloadEndGL');
		LoadGL:
			#### A 2 Offset(10, 50) A_StartSound("weapons/pocket", CHAN_WEAPON,  CHANF_OVERLAP);
			#### AAA 5 Offset(10, 50) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			#### A 15 Offset(8, 50)
			{
				A_TakeInventory('HDRocketAmmo', 1, TIF_NOTAKEINFINITE);
				invoker.WeaponStatus[BTProp_Flags] |= BTF_GrenadeLoaded;
				A_StartSound("weapons/grenreload", CHAN_WEAPON);
			}
		ReloadEndGL:
			#### A 4 Offset(4, 44) A_StartSound("weapons/grenopen", CHAN_WEAPON);
			#### A 1 Offset(0, 40);
			#### A 1 Offset(0, 34) A_MuzzleClimb(frandom(-2.4, 0.2), frandom(-1.4, 0.2));
			Goto Nope;
	}
}

class BitchRandom : IdleDummy
{
	States
	{
		Spawn:
			TNT1 A 0 NoDelay
			{
				let wpn = HDBitch(Spawn("HDBitch", pos, ALLOW_REPLACE));
				if (!wpn)
				{
					return;
				}

				HDF.TransferSpecials(self, wpn);
				if (!random(0, 3))
				{
					wpn.WeaponStatus[wpn.BTProp_Flags] |= wpn.BTF_RapidFire;
				}
				if (!random(0, 3))
				{
					wpn.WeaponStatus[wpn.BTProp_Flags] |= wpn.BTF_GL;
				}
				wpn.InitializeWepStats(false);
			}
			Stop;
	}
}
