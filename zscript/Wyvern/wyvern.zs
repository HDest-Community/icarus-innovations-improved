class HDWyvern : HDWeapon
{
	enum WyvernFlags
	{
		WVF_Double = 1,
		WVF_FromPockets = 2,
		WVF_JustUnload = 4,
		WVF_Autoloader = 8
	}

	enum WyvernProperties
	{
		WVProp_Flags,
		WVProp_LeftChamber,
		WVProp_RightChamber,
		WVProp_SideSaddles
	}

	override void PostBeginPlay()
	{
		weaponspecial = 1337; // [Ace] UaS sling compatibility.

		Super.PostBeginPlay();
	}

	override bool AddSpareWeapon(actor newowner) { return AddSpareWeaponRegular(newowner); }
	override HDWeapon GetSpareWeapon(actor newowner , bool reverse, bool doselect) { return GetSpareWeaponRegular(newowner, reverse, doselect); }
	override double GunMass()
	{
		double BaseMass = 6;
		if (WeaponStatus[WVProp_LeftChamber] == 1)
		{
			BaseMass += 0.2;
		}
		if (WeaponStatus[WVProp_RightChamber] == 1)
		{
			BaseMass += 0.2;
		}
		BaseMass += 0.2 * WeaponStatus[WVProp_SideSaddles];
		return BaseMass;
	}
	override double WeaponBulk()
	{
		double BaseBulk = 110;
		if (WeaponStatus[WVProp_LeftChamber] == 1)
		{
			BaseBulk += ENC_50OMG_LOADED * 0.75;
		}
		if (WeaponStatus[WVProp_RightChamber] == 1)
		{
			BaseBulk += ENC_50OMG_LOADED * 0.75;
		}
		BaseBulk += ENC_50OMG_LOADED * WeaponStatus[WVProp_SideSaddles] * 0.75;
		return BaseBulk;
	}
	override string, double GetPickupSprite()
	{
		string BaseSprite = "WYVZ";
		int Rounds = WeaponStatus[WVProp_SideSaddles];
		string Frame = "G";
		switch (WeaponStatus[WVProp_SideSaddles] / 2)
		{
			case 6: Frame = "A"; break;
			case 5: Frame = "B"; break;
			case 4: Frame = "C"; break;
			case 3: Frame = "D"; break;
			case 2: Frame = "E"; break;
			case 1: Frame = "F"; break;
		}
		return BaseSprite..Frame.."0", 0.9;
	}
	override void LoadoutConfigure(string input)
	{
		InitializeWepStats();
		if (GetLoadoutVar(input, "auto", 1) > 0)
		{
			WeaponStatus[WVProp_Flags] |= WVF_Autoloader;
		}
	}
	override void InitializeWepStats(bool idfa)
	{
		WeaponStatus[WVProp_LeftChamber] = 1;
		WeaponStatus[WVProp_RightChamber] = 1;
		WeaponStatus[WVProp_SideSaddles] = MaxSideRounds;
	}
	override void DropOneAmmo(int amt)
	{
		if (owner)
		{
			amt = clamp(amt, 1, 10);
			owner.A_DropInventory("HD50OMGAmmo", amt * 10);
		}
	}
	override string GetHelpText()
	{
		return WEPHELP_FIRE.."  Shoot Left\n"
		..WEPHELP_ALTFIRE.."  Shoot Right\n"
		..WEPHELP_RELOAD.."  Reload (side saddles first)\n"
		..WEPHELP_ALTRELOAD.."  Reload (pockets only)\n"
		..WEPHELP_FIREMODE.."  Hold to force double shot\n"
		..WEPHELP_FIREMODE.."+"..WEPHELP_RELOAD.."  Load side saddles\n"
		..WEPHELP_UNLOADUNLOAD;
	}
	override string PickupMessage()
	{
		string autoStr = WeaponStatus[WVProp_Flags] & WVF_Autoloader ? "autoloading " : "";
		return String.Format("You picked up the %s'Wyvern' .50 cal. double barreled rifle.", autoStr);
	}
	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		if (sb.hudlevel == 1)
		{
			sb.DrawImage("OG10A0", (-47, -10), sb.DI_SCREEN_CENTER_BOTTOM);
			sb.DrawNum(hpl.CountInv("HD50OMGAmmo"), -46, -8, sb.DI_SCREEN_CENTER_BOTTOM);
		}
		vector2 ShellOff = (-31, -18);
		
		if (hdw.WeaponStatus[WVProp_Flags] & WVF_DOUBLE)
		{
			ShellOff = (-27, -22);
			sb.DrawImage("STBURAUT", (-23, -17), sb.DI_SCREEN_CENTER_BOTTOM);
		}

		if (hdw.WeaponStatus[WVProp_LeftChamber] == 1)
		{
			sb.DrawRect(ShellOff.x, -16, 2, 7);
		}
		else if (hdw.WeaponStatus[WVProp_LeftChamber] == 0)
		{
			sb.DrawRect(ShellOff.x, -12, 2, 3);
		}

		if (hdw.WeaponStatus[WVProp_RightChamber] == 1)
		{
			sb.DrawRect(ShellOff.y, -16, 2, 7);
		}
		else if (hdw.WeaponStatus[WVProp_RightChamber] == 0)
		{
			sb.DrawRect(ShellOff.y, -12, 2, 3);
		}
		
		for (int i = hdw.WeaponStatus[WVProp_SideSaddles]; i > 0; --i)
		{
			sb.DrawRect(-11 - i * 2, -7, 1, 5);
		}
	}
	override void DrawSightPicture(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl, bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot)
	{
		int cx, cy, cw, ch;
		int ScaledYOffset = 48;
		int ScaledWidth = 89;

		[cx, cy, cw, ch] = Screen.GetClipRect();
		sb.SetClipRect(-16 + bob.x, -4 + bob.y, 32, 12, sb.DI_SCREEN_CENTER);
		vector2 bob2 = bob * 3;
		bob2.y = clamp(bob2.y, -8, 8);
		sb.DrawImage("FRNTSITE", bob2, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, alpha: 0.9, scale: (0.7, 1.0));
		sb.SetClipRect(cx, cy, cw, ch);
		sb.DrawImage("DBBAKSIT", bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP);
	}

	protected action void A_WyvernFire(int barrel)
	{
		A_Light2();
		A_ZoomRecoil(0.9);
		DistantNoise.Make(self, "world/shotgunfar");
		A_AlertMonsters();
		let psp = player.GetPSprite(PSP_WEAPON);
		if (barrel & 1)
		{
			psp.frame = invoker.WeaponStatus[WVProp_RightChamber] == 1 ? 0 : 1;
			A_MuzzleClimb(0, 0, -0.2, -0.8, -frandom(0.5, 0.9), -frandom(3.2, 4.0), -frandom(0.5, 0.9), -frandom(3.2, 4.0));
			HDBulletActor.FireBullet(self, "HDB_50OMG");
			invoker.WeaponStatus[WVProp_LeftChamber] = 0;
			A_StartSound("Wyvern/Fire", CHAN_WEAPON, CHANF_OVERLAP);
		}
		if (barrel & 2)
		{
			psp.frame = invoker.WeaponStatus[WVProp_LeftChamber] == 1 ? 2 : 3;
			A_MuzzleClimb(0, 0, 0.2, -0.8, frandom(0.5, 0.9), -frandom(3.2, 4.0), frandom(0.5, 0.9), -frandom(3.2, 4.0));
			HDBulletActor.FireBullet(self, "HDB_50OMG");
			invoker.WeaponStatus[WVProp_RightChamber] = 0;
			A_StartSound("Wyvern/Fire", CHAN_WEAPON, CHANF_OVERLAP);
		}
		if (barrel & 1 && barrel & 2)
		{
			psp.frame = 4;
		}
	}

	protected action void A_CheckIdleHammer()
	{
		let psp = player.GetPSprite(PSP_WEAPON);
		if (invoker.WeaponStatus[WVProp_LeftChamber] == 1 && invoker.WeaponStatus[WVProp_RightChamber] == 1)
		{
			psp.frame = 0;
		}
		else if (invoker.WeaponStatus[WVProp_LeftChamber] == 1)
		{
			psp.frame = 1;
		}
		else if (invoker.WeaponStatus[WVProp_RightChamber] == 1)
		{
			psp.frame = 2;
		}
		else
		{
			psp.frame = 3;
		}
	}

	const MaxSideRounds = 12;
	private transient CVar SwapBarrels;

	Default
	{
		-HDWEAPON.FITSINBACKPACK
		Weapon.SelectionOrder 300;
		Weapon.SlotNumber 8;
		Weapon.SlotPriority 4;
		HDWeapon.BarrelSize 30, 1, 1;
		Scale 0.55;
		Weapon.BobRangeX 0.18;
		Weapon.BobRangeY 0.7;
		Tag "Wyvern";
		HDWeapon.Refid "wyv";
	}


	States
	{
		Spawn:
			WYVZ ABCDEFG -1 NoDelay
			{
				frame = 6 - invoker.WeaponStatus[WVProp_SideSaddles] / 2;
			}
		Select0:
			WYVG D 0;
			Goto Select0Small;
		Deselect0:
			WYVG D 0;
			Goto Deselect0Small;
		Fire:
		AltFire:
			WYVG # 0 A_ClearRefire();
		Ready:
			WYVG # 1
			{
				A_CheckIdleHammer();

				if (PressingFiremode())
				{
					invoker.WeaponStatus[WVProp_Flags] |= WVF_Double;
					if (PressingReload() && invoker.WeaponStatus[WVProp_SideSaddles] < MaxSideRounds)
					{
						invoker.WeaponStatus[WVProp_Flags] &= ~WVF_Double;
						SetWeaponState('ReloadSS');
						return;
					}
				}
				else 
				{
					invoker.WeaponStatus[WVProp_Flags] &= ~WVF_Double;
				}

				// [Ace] I know there's a better way to do all this. I just don't care enough to do it.
				// It's going to take too much time to figure it out for exactly no benefit at all whatsoever.
				if (invoker.WeaponStatus[WVProp_Flags] & WVF_Double && (PressingFire() || PressingAltfire()))
				{
					if (invoker.WeaponStatus[WVProp_LeftChamber] == 1 && invoker.WeaponStatus[WVProp_RightChamber] == 1)
					{
						SetWeaponState('ShootBoth');
						return;
					}
					else if (invoker.WeaponStatus[WVProp_LeftChamber] == 1)
					{
						SetWeaponState('ShootLeft');
						return;
					}
					else if (invoker.WeaponStatus[WVProp_RightChamber] == 1)
					{
						SetWeaponState('ShootRight');
						return;
					}
					else
					{
						SetWeaponState('Nope');
						return;
					}
				}

				if (!invoker.SwapBarrels)
				{
					invoker.SwapBarrels = CVar.GetCVar("hd_swapbarrels", player);
				}
				bool Swap = invoker.SwapBarrels && invoker.SwapBarrels.GetBool();
				if ((!Swap && PressingFire() || Swap && PressingAltfire()) && invoker.WeaponStatus[WVProp_LeftChamber] == 1)
				{
					SetWeaponState('ShootLeft');
					return;
				}
				if ((!Swap && PressingAltFire() || Swap && PressingFire()) && invoker.WeaponStatus[WVProp_RightChamber] == 1)
				{
					SetWeaponState('ShootRight');
					return;
				}

				A_WeaponReady((WRF_ALL | WRF_NOFIRE) & ~WRF_ALLOWUSER2);
			}
			WYVG # 0 A_WeaponReady();
			Goto ReadyEnd;

		ShootLeft:
			WYVF # 1 Bright A_WyvernFire(1);
			WYVG # 1 Offset(0, 44) A_CheckIdleHammer();
			WYVG # 1 Offset(0, 38);
			Goto Ready;
		ShootRight:
			WYVF # 1 Bright A_WyvernFire(2);
			WYVG # 1 Offset(0, 44) A_CheckIdleHammer();
			WYVG # 1 Offset(0, 38);
			Goto Ready;
		ShootBoth:
			WYVF # 1 Bright A_WyvernFire(3);
			WYVG # 1 Offset(0, 52) A_CheckIdleHammer();
			WYVG # 1 Offset(0, 42);
			WYVG # 1 Offset(0, 36);
			Goto Ready;

		AltReload:
			WYVG # 0
			{
				if (CountInv("HD50OMGAmmo") > 0 && (invoker.WeaponStatus[WVProp_LeftChamber] < 1 || invoker.WeaponStatus[WVProp_RightChamber] < 1))
				{
					invoker.WeaponStatus[0] |= WVF_FromPockets;
					invoker.WeaponStatus[0] &= ~WVF_JustUnload;
				}
				else
				{
					SetWeaponState('Nope');
				}
			}
			Goto ReloadStart;
		Reload:
			WYVG # 0
			{
				if(invoker.WeaponStatus[WVProp_LeftChamber] > 0 && invoker.WeaponStatus[WVProp_RightChamber] > 0)
				{
					SetWeaponState('ReloadSS');
				}

				invoker.WeaponStatus[WVProp_Flags] &= ~WVF_JustUnload;

				if (invoker.WeaponStatus[WVProp_SideSaddles] > 0)
				{
					invoker.WeaponStatus[WVProp_Flags] &= ~WVF_FromPockets;
				}
				else if (CountInv("HD50OMGAmmo") > 0)
				{
					invoker.WeaponStatus[WVProp_Flags] |= WVF_FromPockets;
				}
				else
				{
					SetWeaponState('Nope');
				}
			}
			Goto ReloadStart;
		Unload:
			WYVG # 2 Offset(0, 34)
			{
				if (invoker.WeaponStatus[WVProp_SideSaddles] > 0)
				{
					SetWeaponState('UnloadSS');
				}
				else
				{
					invoker.WeaponStatus[WVProp_Flags] |= WVF_JustUnload;
				}
			}
			Goto UnloadStart;

		ReloadStart:
		UnloadStart:
			WYVG # 2 Offset(0, 34);
			WYVG # 1 Offset(0, 40);
			WYVG # 3 Offset(0, 46);
			WYVG # 5 Offset(0, 47) A_StartSound("Wyvern/Open", 8);
			WYVR A 4 Offset(0, 46) A_MuzzleClimb(frandom(0.6, 1.2), frandom(0.6, 1.2), frandom(0.6, 1.2), frandom(0.6, 1.2), frandom(1.2, 2.4), frandom(1.2, 2.4));
			WYVR B 3 Offset(0, 36)
			{
				for (int i = 0; i < 2; ++i)
				{
					int Chamber = invoker.WeaponStatus[WVProp_LeftChamber + i];
					invoker.WeaponStatus[WVProp_LeftChamber + i] = -1;
					
					if (Chamber == 1)
					{
						A_EjectCasing("HDSpent50OMG", frandom(-5,5),(frandom(0.25,0.6),-frandom(7,7.5),frandom(0,0.2)),(0,0,-2));
					}
					else if (Chamber == 0)
					{
						A_EjectCasing("HDSpent50OMG", frandom(-5,5),(frandom(0.25,0.6),-frandom(7,7.5),frandom(0,0.2)),(0,0,-2));
					}
				}
			}
			WYVR B 2 Offset(1, 34);
			WYVR B 2 Offset(2, 34);
			WYVR B 2 Offset(4, 34);
			WYVR B 8 Offset(0, 36)
			{
				if (invoker.WeaponStatus[WVProp_Flags] & WVF_JustUnload)
				{
					SetWeaponState('UnloadEnd');
					return;
				}

				if (invoker.WeaponStatus[WVProp_Flags] & WVF_FromPockets)
				{
					A_StartSound("weapons/pocket", 9);
				}
				else
				{
					if (invoker.WeaponStatus[WVProp_Flags] & WVF_Autoloader && invoker.WeaponStatus[WVProp_SideSaddles] > 0)
					{
						invoker.WeaponStatus[WVProp_SideSaddles]--;
						invoker.WeaponStatus[WVProp_LeftChamber] = 1;
						if (invoker.WeaponStatus[WVProp_SideSaddles] > 0)
						{
							invoker.WeaponStatus[WVProp_SideSaddles]--;
							invoker.WeaponStatus[WVProp_RightChamber] = 1;
						}
						SetWeaponState('UnloadEndQuick');
						return;
					}
					SetWeaponState('ReloadContinue');
				}
			}
			WYVR B 4 Offset(2, 35);
			WYVR B 4 Offset(0, 35);
			WYVR B 4 Offset(0, 34);
		ReloadContinue:
			WYVR C 5 Offset(1, 35);
			WYVR C 2 Offset(0, 36);
			WYVR D 2 Offset(0, 40);
			WYVR D 1 Offset(0, 46);
			WYVR E 2 Offset(0, 54);
			TNT1 A 4
			{
				int HandRounds = 0;
				if (invoker.WeaponStatus[WVProp_Flags] & WVF_FromPockets)
				{
					HandRounds = min(2, CountInv("HD50OMGAmmo"));
					if (HandRounds > 0)
					{
						A_TakeInventory("HD50OMGAmmo", HandRounds);
					}
				}
				else
				{
					HandRounds = min(2, invoker.WeaponStatus[WVProp_SideSaddles]);
					invoker.WeaponStatus[WVProp_SideSaddles] -= HandRounds;
				}

				if (HandRounds == 0)
				{
					A_SetTics(0);
					return;
				}

				while (HandRounds > 0)
				{
					invoker.WeaponStatus[WVProp_RightChamber - (HandRounds - 1)] = 1;
					HandRounds--;
				}
			}
			TNT1 A 4 A_StartSound("Wyvern/Insert", 8);
			WYVR F 2 Offset(0, 46) A_StartSound("Wyvern/Close", 9);
			WYVR F 1 Offset(0, 42);
			WYVG D 2 Offset(0, 42);
			WYVG D 2;
			Goto Ready;

		ReloadSS:
			WYVG # 0 A_JumpIf(invoker.WeaponStatus[WVProp_SideSaddles] >= MaxSideRounds,"Nope");
			WYVG # 1 Offset(1, 34);
			WYVG # 2 Offset(2, 34);
			WYVG # 3 Offset(3, 36);
		ReloadSSRestart:
			WYVG # 6 Offset(3, 35);
			WYVG # 9 Offset(4, 34) A_StartSound("weapons/pocket", 9);
		ReloadSSLoop:
			WYVG # 0
			{
				if (invoker.WeaponStatus[WVProp_SideSaddles] == 6)
				{
					SetWeaponState('ReloadSSEnd');
				}

				int HandRounds = min(2, CountInv("HD50OMGAmmo"));
				if (HandRounds < 1)
				{
					SetWeaponState("ReloadSSEnd");
					return;
				}
				HandRounds = min(HandRounds, max(1, health / 20), MaxSideRounds - invoker.WeaponStatus[WVProp_SideSaddles]);
				invoker.WeaponStatus[WVProp_SideSaddles] += HandRounds;
				A_TakeInventory("HD50OMGAmmo", HandRounds, TIF_NOTAKEINFINITE);
			}
		ReloadSSEnd:
			WYVG # 4 Offset(3, 34);
			WYVG # 0
			{
				if (invoker.WeaponStatus[SHOTS_SIDESADDLE] < MaxSideRounds && (PressingReload() || PressingAltReload()) && CountInv("HD50OMGAmmo") > 0)
				{
					SetWeaponState("ReloadSSRestart");
				}
			}
			WYVG # 3 Offset(2, 34);
			WYVG # 1 Offset(1, 34);
			Goto Nope;

		UnloadSS:
			WYVG # 2 Offset(2, 34) A_JumpIf(invoker.WeaponStatus[WVProp_SideSaddles] == 0, "Nope");
			WYVG # 1 Offset(3, 36);
		UnloadSSLoop:
			WYVG # 4 Offset(4, 36);
			WYVG # 4 Offset(5, 37)
			{
				int HandRounds = clamp(invoker.WeaponStatus[WVProp_SideSaddles], 0, 2);
				if (HandRounds == 0)
				{
					return;
				}
				A_StartSound("weapons/pocket", 9);

				invoker.WeaponStatus[WVProp_SideSaddles] -= HandRounds;
				int MaxPocket = min(HandRounds, HDPickup.MaxGive(self, "HD50OMGAmmo", ENC_50OMG));
				if (MaxPocket > 0 && PressingUnload())
				{
					A_SetTics(16);
					HandRounds -= MaxPocket;
					A_GiveInventory("HD50OMGAmmo", MaxPocket);
				}
				else
				{
					while (HandRounds > 0)
					{
						if (PressingUnload() && A_JumpIfInventory("HD50OMGAmmo", 0, "Null"))
						{
							HandRounds--;
							HDF.Give(self, "HD50OMGAmmo", 1);
							A_SetTics(16);
						}
						else
						{
							HandRounds--;
							A_SpawnItemEx("HDLoose50OMG", cos(pitch) * 0.5, 1, height - 7 - sin(pitch) * 1, cos(pitch) * cos(angle) * frandom(1, 2) + vel.x, cos(pitch) * sin(angle) * frandom(1, 2) + vel.y, -sin(pitch) + vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH);
						}
					}
				}
			}
			WYVG # 3 Offset(4, 36)
			{
				if (invoker.WeaponStatus[SHOTS_SIDESADDLE] > 0 && !PressingFire() && !PressingAltfire() && !PressingReload())
				{
					SetWeaponState("UnloadSSLoop");
				}
			}
			WYVG # 3 Offset(4, 35);
			WYVG # 2 Offset(3, 35);
			WYVG # 1 Offset(2, 34);
			Goto Nope;
		UnloadEnd:
			WYVR B 5;
		UnloadEndQuick:
			WYVR B 2 Offset(0, 46) A_StartSound("Wyvern/Close", 9);
			WYVR B 1 Offset(0, 42);
			WYVG B 2 Offset(0, 42);
			WYVG D 1;
			Goto Nope;
	}
}

class WyvernRandom : IdleDummy
{
	States
	{
		Spawn:
			TNT1 A 0 NoDelay
			{
				A_SpawnItemEx("HD50OMGBoxPickup", -3, flags: SXF_NOCHECKPOSITION);
				let wpn = HDWyvern(Spawn("HDWyvern", pos, ALLOW_REPLACE));
				if (!wpn)
				{
					return;
				}
				if (!random(0, 3))
				{
					wpn.WeaponStatus[wpn.WVProp_Flags] |= wpn.WVF_Autoloader;
				}
				HDF.TransferSpecials(self, wpn);
				wpn.InitializeWepStats(false);
			}
			Stop;
	}
}