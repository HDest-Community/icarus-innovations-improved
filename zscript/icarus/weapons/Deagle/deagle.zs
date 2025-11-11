class HDDEagle : HDHandgun
{
	enum DEagleFlags
	{
		DEF_JustUnload = 1,
		DEF_LightTrigger = 2,
		DEF_HeavyFrame = 4,
		DEF_ExtendedBarrel = 8
	}

	enum DEagleProperties
	{
		DEProp_Flags,
		DEProp_Chamber,
		DEProp_Mag,
	}

	override void Tick()
	{
		if (WeaponStatus[DEProp_Flags] & DEF_ExtendedBarrel)
		{
			BarrelLength = default.BarrelLength + 4;
		}

		Super.Tick();
	}

	override bool AddSpareWeapon(actor newowner) { return AddSpareWeaponRegular(newowner); }
	override HDWeapon GetSpareWeapon(actor newowner , bool reverse, bool doselect) { return GetSpareWeaponRegular(newowner, reverse, doselect); }

	override double GunMass()
	{
		double BaseMass = 10.5;
		if (WeaponStatus[DEProp_Flags] & DEF_ExtendedBarrel)
		{
			BaseMass += 1.5;
		}
		if (WeaponStatus[DEProp_Flags] & DEF_HeavyFrame)
		{
			BaseMass *= 1.1;
		}
		return BaseMass;
	}

	override double WeaponBulk()
	{
		double BaseBulk = 45;
		int Mag = WeaponStatus[DEProp_Mag];
		if (Mag >= 0)
		{
			BaseBulk += HDDEagleMag.EncMagLoaded + Mag * ENC_355_LOADED;
		}
		if (WeaponStatus[DEProp_Flags] & DEF_ExtendedBarrel)
		{
			BaseBulk += 5;
		}
		if (WeaponStatus[DEProp_Flags] & DEF_HeavyFrame)
		{
			BaseBulk *= 1.2;
		}
		return BaseBulk;
	}

	override string, double GetPickupSprite()
	{
		string DEBarrel = WeaponStatus[DEProp_Flags] & DEF_ExtendedBarrel ? "X" : "B";
		string DEFrame = WeaponStatus[DEProp_Flags] & DEF_HeavyFrame ? "H" : "F";
		string DETrigger = WeaponStatus[DEProp_Flags] & DEF_LightTrigger ? "L" : "T";
		string DEChamber = WeaponStatus[DEProp_Chamber] <= 0 ? "B" : "A";
		return "D"..DEBarrel..DEFrame..DETrigger..DEChamber.."0", 1.0;
	}

	override void InitializeWepStats(bool idfa)
	{
		WeaponStatus[DEProp_Chamber] = 2;
		WeaponStatus[DEProp_Mag] = 9;
	}

	override void LoadoutConfigure(string input)
	{
		if (GetLoadoutVar(input, "trigger", 1) > 0)
		{
			WeaponStatus[DEProp_Flags] |= DEF_LightTrigger;
		}
		if (GetLoadoutVar(input, "hframe", 1) > 0)
		{
			WeaponStatus[DEProp_Flags] |= DEF_HeavyFrame;
		}
		if (GetLoadoutVar(input, "extended", 1) > 0)
		{
			WeaponStatus[DEProp_Flags] |= DEF_ExtendedBarrel;
		}

		InitializeWepStats();
	}

	override void ForceBasicAmmo()
	{
		owner.A_TakeInventory("HDRevolverAmmo");
		owner.A_TakeInventory("HDDEagleMag");
		owner.A_GiveInventory("HDDEagleMag");
	}

	override void DropOneAmmo(int amt)
	{
		if (owner)
		{
			amt = clamp(amt, 1, 10);
			if (owner.CheckInventory("HDRevolverAmmo", 1))
			{
				owner.A_DropInventory("HDRevolverAmmo", amt * 10);
			}
			else
			{
				owner.A_DropInventory("HDDEagleMag", amt);
			}
		}
	}

	override string GetHelpText()
	{
		return WEPHELP_FIRESHOOT
		..WEPHELP_RELOAD.."  Reload mag\n"
		..WEPHELP_USE.."+"..WEPHELP_RELOAD.."  Reload chamber\n"
		..WEPHELP_MAGMANAGER
		..WEPHELP_UNLOADUNLOAD;
	}

	override string PickupMessage()
	{
		string HFrameStr = WeaponStatus[DEProp_Flags] & DEF_HeavyFrame ? " heavy-framed" : "";
		string ExBarrelStr = WeaponStatus[DEProp_Flags] & DEF_ExtendedBarrel ? " extended" : "";
		string LTriggerStr = WeaponStatus[DEProp_Flags] & DEF_LightTrigger ? " with a lighter trigger" : "";
		return String.Format("You got the%s%s Desert Eagle Mk.XIX%s. Blast 'em.", HFrameStr, ExBarrelStr, LTriggerStr);
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		if (sb.hudlevel == 1)
		{
			int NextMagLoaded = sb.GetNextLoadMag(HDMagAmmo(hpl.findinventory("HDDEagleMag")));
			if (NextMagLoaded >= 9)
			{
				sb.DrawImage("DGLMA0", (-46, -3),sb. DI_SCREEN_CENTER_BOTTOM);
			}
			else if (NextMagLoaded <= 0)
			{
				sb.DrawImage("DGLMB0", (-46, -3), sb.DI_SCREEN_CENTER_BOTTOM, alpha: NextMagLoaded ? 0.6 : 1.0);
			}
			else
			{
				sb.DrawBar("DGLMNORM", "DGLMGREY", NextMagLoaded, 9, (-46, -3), -1, sb.SHADER_VERT, sb.DI_SCREEN_CENTER_BOTTOM);
			}
			sb.DrawNum(hpl.CountInv("HDDEagleMag"), -43, -8, sb.DI_SCREEN_CENTER_BOTTOM);
		}
		sb.DrawWepNum(hdw.WeaponStatus[DEProp_Mag], 9);

		if(hdw.WeaponStatus[DEProp_Chamber] == 2)
		{
			sb.DrawRect(-19, -11, 3, 1);
		}
	}

	override void DrawSightPicture(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl, bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot)
	{
		int cx, cy, cw, ch;
		[cx, cy, cw, ch] = Screen.GetClipRect();
		sb.SetClipRect(-16 + bob.x, -4 + bob.y, 32, 16, sb.DI_SCREEN_CENTER);
		vector2 bob2 = bob * 2;
		bob2.y = clamp(bob2.y, -8, 8);
		sb.DrawImage("DGLFRNT", bob2, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, alpha: 0.9, scale: (0.8, 0.6));
		sb.SetClipRect(cx, cy, cw, ch);
		sb.DrawImage("DGLBACK", bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, scale: (0.9, 0.7));
	}

	Default
	{
		+HDWEAPON.FITSINBACKPACK
		Weapon.SelectionOrder 300;
		Weapon.SlotNumber 2;
		Weapon.SlotPriority 3;
		HDWeapon.BarrelSize 13, 0.35, 0.5;
		Scale 0.5;
		Tag "Desert Eagle Mk.XIX";
		HDWeapon.Refid "dgl";
	}

	States
	{
		RegisterSprites:
			DBFT A 0; DXFT A 0; DBHT A 0; DBFL A 0; DXFL A 0; DXHT A 0; DBHL A 0; DXHL A 0;
		Spawn:
			DBFT A 0 NoDelay
			{
				string DEBarrel = invoker.WeaponStatus[DEProp_Flags] & DEF_ExtendedBarrel ? "X" : "B";
				string DEFrame = invoker.WeaponStatus[DEProp_Flags] & DEF_HeavyFrame ? "H" : "F";
				string DETrigger = invoker.WeaponStatus[DEProp_Flags] & DEF_LightTrigger ? "L" : "T";
				sprite = GetSpriteIndex("D"..DEBarrel..DEFrame..DETrigger);
			}
		RealSpawn:
			#### # -1
			{
				frame = (invoker.WeaponStatus[DEProp_Chamber] == 0 ? 1 : 0);
			}
			Stop;
		Ready:
			DGLG A 0;
			#### A 0 A_JumpIf(invoker.WeaponStatus[DEProp_Chamber] > 0, 2);
			#### D 0;
			#### # 1 A_WeaponReady(WRF_ALL);
			Goto ReadyEnd;
		Select0:
			DGLG A 0;
			#### A 0 A_JumpIf(invoker.WeaponStatus[DEProp_Chamber] > 0, 2);
			#### D 0;
			#### # 0;
			Goto Select0Small;
		Deselect0:
			DGLG A 0;
			#### A 0 A_JumpIf(invoker.WeaponStatus[DEProp_Chamber] > 0, 2);
			#### D 0;
			#### # 0;
			Goto Deselect0Small;
		User3:
			#### A 0 A_MagManager("HDDEagleMag");
			Goto Ready;

		AltFire:
			Goto ChamberManual;

		Fire:
			#### # 0
			{
				if (invoker.WeaponStatus[DEProp_Chamber] == 2)
				{
					SetWeaponState("Shoot");
				}
				else if (invoker.WeaponStatus[DEProp_Mag] > 0)
				{
					SetWeaponState("ChamberManual");
				}
			}
			Goto Nope;
		Shoot:
			#### B 1
			{
				if (HDPlayerPawn(self))
				{
					HDPlayerPawn(self).gunbraced = false;
				}
				double ClimbMult = 1.0;
				if (invoker.WeaponStatus[DEProp_Flags] & DEF_LightTrigger)
				{
					ClimbMult -= 0.5;
				}
				if (invoker.WeaponStatus[DEProp_Flags] & DEF_ExtendedBarrel)
				{
					ClimbMult -= 0.1;
				}
				if (invoker.WeaponStatus[DEProp_Flags] & DEF_HeavyFrame)
				{
					ClimbMult *= 0.75;
				}
				A_MuzzleClimb(-frandom(0.1, 0.2) * ClimbMult, -frandom(0.2, 0.4) * ClimbMult);
			}
			#### C 1 Offset(0, 36)
			{
				HDFlashAlpha(128);
				A_Light1();
				A_StartSound("DEagle/Fire", CHAN_WEAPON);

				bool ExtBarrel = invoker.WeaponStatus[DEProp_Flags] & DEF_ExtendedBarrel;

				double VelMult = 1.0;
				if (ExtBarrel)
				{
					VelMult += 0.15;
				}
				HDBulletActor.FireBullet(self, "HDB_355", spread: 1.0, speedfactor: frandom(1.0, 1.02) * VelMult);
				A_AlertMonsters();
				A_ZoomRecoil(0.98);

				double ClimbMult = 1.0;
				if (ExtBarrel)
				{
					ClimbMult -= 0.12;
				}
				if (invoker.WeaponStatus[DEProp_Flags] & DEF_HeavyFrame)
				{
					ClimbMult *= 0.75;
				}
				A_MuzzleClimb(-frandom(0., 0.9) * ClimbMult, -frandom(1.5, 2.5) * ClimbMult);

				invoker.WeaponStatus[DEProp_Chamber] = 1;
			}
			#### D 1 Offset(0, 44)
			{
				if (invoker.WeaponStatus[DEProp_Chamber] == 1)
				{
					A_SpawnItemEx("HDSpent355", cos(pitch) * 12, 0, height - 9 - sin(pitch) * 12, vel.x, vel.y, vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH);
					invoker.WeaponStatus[DEProp_Chamber] = 0;
				}
				
				if (invoker.WeaponStatus[DEProp_Mag] <= 0)
				{
					A_StartSound("weapons/pistoldry", 8, CHANF_OVERLAP, 0.9);
					SetWeaponState("Nope");
				}
				else
				{
					A_Light0();
					invoker.WeaponStatus[DEProp_Chamber] = 2;
					invoker.WeaponStatus[DEProp_Mag]--;
					A_Refire();
				}
			}
			Goto Ready;
		Hold:
			Goto Nope;

		Reload:
			#### # 0
			{
				invoker.WeaponStatus[DEProp_Flags] &=~ DEF_JustUnload;
				bool NoMags = HDMagAmmo.NothingLoaded(self, "HDDEagleMag");
				if (invoker.WeaponStatus[DEProp_Mag] >= 9)
				{
					SetWeaponState("Nope");
				}
				else if (invoker.WeaponStatus[DEProp_Mag] <= 0 && (PressingUse() || NoMags))
				{
					if (CheckInventory("HDRevolverAmmo", 1))
					{
						SetWeaponState("LoadChamber");
					}
					else
					{
						SetWeaponState("Nope");
					}
				}
				else if (NoMags)
				{
					SetWeaponState("Nope");
				}
			}
			Goto RemoveMag;

		Unload:
			#### # 0
			{
				invoker.WeaponStatus[DEProp_Flags] |= DEF_JustUnload;
				if (invoker.WeaponStatus[DEProp_Mag] >= 0)
				{
					SetWeaponState("RemoveMag");
				}
			}
			Goto ChamberManual;
		RemoveMag:
			DRLA # 1 Offset(0, 34) A_SetCrosshair(21);
			DRLA # 1 Offset(1, 38);
			DRLB # 2 Offset(2, 42);
			DRLC # 3 Offset(3, 46) A_StartSound("DEagle/MagOut", 8, CHANF_OVERLAP);
			#### # 0
			{
				int Mag = invoker.WeaponStatus[DEProp_Mag];
				invoker.WeaponStatus[DEProp_Mag] = -1;
				if (Mag == -1)
				{
					SetWeaponState("MagOut");
				}
				else if((!PressingUnload() && !PressingReload()) || A_JumpIfInventory("HDDEagleMag", 0, "null"))
				{
					HDMagAmmo.SpawnMag(self, "HDDEagleMag", Mag);
					setweaponstate("MagOut");
				}
				else{
					HDMagAmmo.GiveMag(self, "HDDEagleMag", Mag);
					A_StartSound("weapons/pocket", 9);
					setweaponstate("PocketMag");
				}
			}
		PocketMag:
			#### ### 5 Offset(0, 46) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			Goto MagOut;
		MagOut:
			#### # 0
			{
				if (invoker.WeaponStatus[DEProp_Flags] & DEF_JustUnload)
				{
					SetWeaponState("ReloadEnd");
				}
				else
				{
					SetWeaponState("LoadMag");
				}
			}
		LoadMag:
			DRLC # 4 Offset(0, 46) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			#### # 0 A_StartSound("weapons/pocket", 9);
			DRLB # 5 Offset(0, 46) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			DRLA # 3;
			#### # 0
			{
				let Mag = HDMagAmmo(FindInventory("HDDEagleMag"));
				if (Mag)
				{
					invoker.WeaponStatus[DEProp_Mag] = Mag.TakeMag(true);
					A_StartSound("DEagle/MagIn", 8);
				}
			}
			Goto ReloadEnd;
		ReloadEnd:
			#### # 2 Offset(3, 46);
			#### # 1 Offset(2, 42);
			#### # 1 Offset(2, 38);
			#### # 1 Offset(1, 34);
			#### # 0 A_JumpIf(!(invoker.WeaponStatus[DEProp_Flags] & DEF_JustUnload), "ChamberManual");
			Goto Nope;

		ChamberManual:
			#### # 0 A_JumpIf(!(invoker.WeaponStatus[DEProp_Flags] & DEF_JustUnload) && (invoker.WeaponStatus[DEProp_Chamber] == 2 || invoker.WeaponStatus[DEProp_Mag] <= 0), "Nope");
			#### # 3 Offset(0, 34);
			#### D 4 Offset(0, 37)
			{
				A_MuzzleClimb(frandom(0.4, 0.5), -frandom(0.6, 0.8));
				A_StartSound("DEagle/SlideBack", 8);
				int Chamber = invoker.WeaponStatus[DEProp_Chamber];
				invoker.WeaponStatus[DEProp_Chamber] = 0;
				switch (Chamber)
				{
					case 1: A_SpawnItemEx("HDSpent355", cos(pitch) * 12, 0, height - 9 - sin(pitch) * 12, vel.x, vel.y, vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH); break;
					case 2: A_SpawnItemEx("HDRevolverAmmo", cos(pitch * 12), 0, height - 9 - sin(pitch) * 12, 1, 2, 3, 0); break;
				}

				if (invoker.WeaponStatus[DEProp_Mag] > 0)
				{
					invoker.WeaponStatus[DEProp_Chamber] = 2;
					invoker.WeaponStatus[DEProp_Mag]--;
				}
			}
			#### # 3 Offset(0, 35);
			Goto Nope;
		LoadChamber:
			#### # 0 A_JumpIf(invoker.WeaponStatus[DEProp_Chamber] > 0, "Nope");
			#### D 1 Offset(0, 36) A_StartSound("weapons/pocket",9);
			#### D 1 Offset(2, 40);
			#### D 1 Offset(2, 50);
			#### D 1 Offset(3, 60);
			#### D 2 Offset(5, 90);
			#### D 2 Offset(7, 80);
			#### D 2 Offset(10, 90);
			#### D 2 Offset(8, 96);
			#### D 3 Offset(6, 88)
			{
				if (CheckInventory("HDRevolverAmmo", 1))
				{
					A_StartSound("DEagle/SlideForward", 8);
					A_TakeInventory("HDRevolverAmmo", 1, TIF_NOTAKEINFINITE);
					invoker.WeaponStatus[DEProp_Chamber] = 2;
				}
			}
			#### A 2 Offset(5, 76);
			#### A 1 Offset(4, 64);
			#### A 1 Offset(3, 56);
			#### A 1 Offset(2, 48);
			#### A 2 Offset(1, 38);
			#### A 3 Offset(0, 34);
			Goto ReadyEnd;
	}
}

class DEagleRandom : IdleDummy
{
	States
	{
		Spawn:
			TNT1 A 0 NoDelay
			{
				A_SpawnItemEx("HDDEagleMag", -3, flags: SXF_NOCHECKPOSITION);
				A_SpawnItemEx("HDDEagleMag", -1, flags: SXF_NOCHECKPOSITION);
				let wpn = HDDEagle(Spawn("HDDEagle", pos, ALLOW_REPLACE));
				if (!wpn)
				{
					return;
				}

				wpn.special = special;
				for (int i = 0; i < 5; ++i)
				{
					wpn.Args[i] = Args[i];
				}
				if (!random(0, 3))
				{
					wpn.WeaponStatus[wpn.DEProp_Flags] |= wpn.DEF_LightTrigger;
				}
				if (!random(0, 3))
				{
					wpn.WeaponStatus[wpn.DEProp_Flags] |= wpn.DEF_HeavyFrame;
				}
				if (!random(0, 3))
				{
					wpn.WeaponStatus[wpn.DEProp_Flags] |= wpn.DEF_ExtendedBarrel;
				}
				wpn.InitializeWepStats(false);
			}
			Stop;
	}
}

class HDDEagleMag : HDMagAmmo
{
	override string, string, name, double GetMagSprite(int thismagamt)
	{
		return (thismagamt > 0) ? "DGLMA0" : "DGLMB0", "PRNDA0", "HDRevolverAmmo", 1.0;
	}

	override void GetItemsThatUseThis()
	{
		ItemsThatUseThis.Push("HDDEagle");
	}

	const EncMag = 12;
	const EncMagEmpty = EncMag * 0.6;
	const EncMagLoaded = EncMag * 0.2;

	Default
	{
		HDMagAmmo.MaxPerUnit 9;
		HDMagAmmo.InsertTime 9;
		HDMagAmmo.ExtractTime 6;
		HDMagAmmo.RoundType "HDRevolverAmmo";
		HDMagAmmo.RoundBulk ENC_355_LOADED;
		HDMagAmmo.MagBulk EncMagEmpty;
		Tag "Mk.XIX .355 Magazine";
		Inventory.PickupMessage "Picked up a Mk.XIX .355 magazine.";
		HDPickup.RefId "dem";
		Scale 0.5;
	}

	States
	{
		Spawn:
			DGLM A -1;
			Stop;
		SpawnEmpty:
			DGLM B -1
			{
				bROLLSPRITE = true;
				bROLLCENTER = true;
				roll = randompick(0, 0, 0, 0, 2, 2, 2, 2, 1, 3) * 90;
			}
			Stop;
	}
}
