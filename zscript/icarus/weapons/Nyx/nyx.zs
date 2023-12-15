class HDNyx : HDHandgun
{
	enum NyxFlags
	{
		NXF_JustUnload = 1
	}

	enum NyxProperties
	{
		NXProp_Flags,
		NXProp_Chamber,
		NXProp_Mag,
		NXProp_Mode
	}

	override bool AddSpareWeapon(actor newowner) { return AddSpareWeaponRegular(newowner); }
	override HDWeapon GetSpareWeapon(actor newowner , bool reverse, bool doselect) { return GetSpareWeaponRegular(newowner, reverse, doselect); }

	override double GunMass()
	{
		return 12 + 0.03 * WeaponStatus[NXProp_Mag];
	}

	override double WeaponBulk()
	{
		double BaseBulk = 40;
		int Mag = WeaponStatus[NXProp_Mag];
		if (Mag >= 0)
		{
			BaseBulk += HDNyxMag.EncMagLoaded + Mag * ENC_355_LOADED;
		}
		return BaseBulk;
	}

	override string PickupMessage()
	{
		return Stringtable.localize("$PICKUP_NYX_PREFIX")..Stringtable.localize("$TAG_NYX")..Stringtable.localize("$PICKUP_NYX_SUFFIX");
	}

	override string, double GetPickupSprite()
	{
		string NChamber = WeaponStatus[NXProp_Chamber] <= 0 ? "E" : "C";
		return "NYXP"..NChamber.."0", 1.0;
	}

	override void InitializeWepStats(bool idfa)
	{
		WeaponStatus[NXProp_Chamber] = 2;
		WeaponStatus[NXProp_Mag] = HDNyxMag.MagCapacity;
	}

	override void ForceBasicAmmo()
	{
		owner.A_TakeInventory("HDRevolverAmmo");
		owner.A_TakeInventory("HDNyxMag");
		owner.A_GiveInventory("HDNyxMag");
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
				owner.A_DropInventory("HDNyxMag", amt);
			}
		}
	}

	override string GetHelpText()
	{
		return WEPHELP_FIRESHOOT
		..WEPHELP_FIREMODE.."  Semi Auto/Burst\n"
		..WEPHELP_RELOAD.."  Reload mag\n"
		..WEPHELP_USE.."+"..WEPHELP_RELOAD.."  Reload chamber\n"
		..WEPHELP_MAGMANAGER;
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		if (sb.hudlevel == 1)
		{
			int NextMagLoaded = sb.GetNextLoadMag(HDMagAmmo(hpl.findinventory("HDNyxMag")));
			if (NextMagLoaded >= HDNyxMag.MagCapacity)
			{
				sb.DrawImage("NYXMA0", (-46, -3),sb. DI_SCREEN_CENTER_BOTTOM);
			}
			else if (NextMagLoaded <= 0)
			{
				sb.DrawImage("NYXMB0", (-46, -3), sb.DI_SCREEN_CENTER_BOTTOM, alpha: NextMagLoaded ? 0.6 : 1.0);
			}
			else
			{
				sb.DrawBar("NYXMNORM", "NYXMGREY", NextMagLoaded, HDNyxMag.MagCapacity, (-46, -3), -1, sb.SHADER_VERT, sb.DI_SCREEN_CENTER_BOTTOM);
			}
			sb.DrawNum(hpl.CountInv("HDNyxMag"), -43, -8, sb.DI_SCREEN_CENTER_BOTTOM);
		}
		sb.DrawWepNum(hdw.WeaponStatus[NXProp_Mag], HDNyxMag.MagCapacity);

		if(hdw.WeaponStatus[NXProp_Chamber] == 2)
		{
			sb.DrawRect(-19, -11, 3, 1);
		}
		
		sb.DrawWepCounter(hdw.WeaponStatus[NXProp_Mode], -22, -10, "RBRSA3A7", "STBURAUT");
	}

	override void DrawSightPicture(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl, bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot)
	{
		int cx, cy, cw, ch;
		[cx, cy, cw, ch] = Screen.GetClipRect();
		sb.SetClipRect(-16 + bob.x, -4 + bob.y, 32, 13, sb.DI_SCREEN_CENTER);
		vector2 bob2 = bob * 2;
		bob2.y = clamp(bob2.y, -8, 8);
		sb.DrawImage("NYXFRNT", bob2, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, alpha: 0.9, scale: (0.8, 0.6));
		sb.SetClipRect(cx, cy, cw, ch);
		sb.DrawImage("NYXBACK", bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, scale: (0.8, 0.7));
	}

	Private Int BurstIndex;
	
	Default
	{
		+HDWEAPON.FITSINBACKPACK
		Weapon.SelectionOrder 300;
		Weapon.SlotNumber 2;
		Weapon.SlotPriority 3;
		HDWeapon.BarrelSize 15, 0.5, 0.5;
		Scale 0.5;
		Tag "$TAG_NYX";
		HDWeapon.Refid HDLD_NYX;
		Inventory.PickupMessage "$PICKUP_NYX";
	}

	States
	{
		Spawn:
			NYXP C 0 NoDelay;
			#### # -1
			{
				frame = invoker.WeaponStatus[NXProp_Chamber] == 0 ? 4 : 2;
			}
			Stop;
		Ready:
			NYXG A 0 A_JumpIf(invoker.WeaponStatus[NXProp_Chamber] > 0, 2);
			#### D 0;
			#### # 1
			{
				invoker.BurstIndex = 0;
				A_WeaponReady(WRF_ALL);
			}
			Goto ReadyEnd;
		Select0:
			NYXG A 0 A_JumpIf(invoker.WeaponStatus[NXProp_Chamber] > 0, 2);
			#### D 0;
			#### # 0;
			Goto Select0Small;
		Deselect0:
			NYXG A 0 A_JumpIf(invoker.WeaponStatus[NXProp_Chamber] > 0, 2);
			#### D 0;
			#### # 0;
			Goto Deselect0Small;
		User3:
			NYXG A 0 A_MagManager("HDNyxMag");
			Goto Ready;
		
		Firemode:
			NYXG A 1
			{
				++invoker.WeaponStatus[NXProp_Mode] %= 2;
			}
			Goto Nope;

		Fire:
			NYXG A 0
			{
				if (invoker.WeaponStatus[NXProp_Chamber] == 2)
				{
					SetWeaponState("Pull");
				}
				else if (invoker.WeaponStatus[NXProp_Mag] > 0)
				{
					SetWeaponState("ChamberManual");
				}
			}
			Goto Nope;
		Pull:
			NYXG B 1;
		Shoot:
			NYXG B 1 Offset(0, 38)
			{
				A_Overlay(PSP_FLASH, 'Flash');
				
				A_Light1();
				A_StartSound("Nyx/Fire", CHAN_WEAPON);
				HDBulletActor.FireBullet(self, "HDB_355", spread: 1.0, speedfactor: frandom(1.10, 1.15));
				A_AlertMonsters();
				A_ZoomRecoil(0.98);
				invoker.WeaponStatus[NXProp_Chamber] = 1;
			}
		Recoil:
			NYXG D 1 Offset(0, 34)
			{
				if (invoker.WeaponStatus[NXProp_Mode] == 1)
				{
					A_MuzzleClimb(-frandom(0.1, 0.3), -frandom(0.1, 0.3), -frandom(0.1, 0.3), -frandom(0.1, 0.3), -frandom(0.1, 0.3), -frandom(0.1, 0.3), -frandom(0.1, 0.5), -frandom(1.0, 2.5));
				}
				else
				{
					A_MuzzleClimb(-frandom(0.1, 0.5), -frandom(1.0, 1.5));
				}
				A_EjectCasing("HDSpent355",frandom(-1,2),(-frandom(2,3),frandom(0,0.2),frandom(0.4,0.5)),(-2,0,-1));
				invoker.WeaponStatus[NXProp_Chamber] = 0;

				if (invoker.WeaponStatus[NXProp_Mag] <= 0)
				{
					A_StartSound("weapons/pistoldry", 8, CHANF_OVERLAP, 0.9);
					SetWeaponState("Nope");
				}

				if (invoker.WeaponStatus[NXProp_Mag] > 0)
				{
					invoker.WeaponStatus[NXProp_Chamber] = 2;
					invoker.WeaponStatus[NXProp_Mag]--;
				}
				
				A_WeaponReady(WRF_NOFIRE);
			}
			#### B 0
			{
				switch (invoker.WeaponStatus[NXProp_Mode])
				{
					case 1:
					{
						if (invoker.BurstIndex < 2)
						{
							invoker.BurstIndex++;
							SetWeaponState("Shoot");
						}
						break;
					}
				}
			}
			Goto Nope;
		Flash:
			NYXG C 1 Bright
			{
				HDFlashAlpha(128);
			}
			goto lightdone;

		Reload:
			#### # 0
			{
				invoker.WeaponStatus[NXProp_Flags] &=~ NXF_JustUnload;
				bool NoMags = HDMagAmmo.NothingLoaded(self, "HDNyxMag");
				if (invoker.WeaponStatus[NXProp_Mag] >= HDNyxMag.MagCapacity)
				{
					SetWeaponState("Nope");
				}
				else if (invoker.WeaponStatus[NXProp_Mag] <= 0 && (PressingUse() || NoMags))
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
				invoker.WeaponStatus[NXProp_Flags] |= NXF_JustUnload;
				if (invoker.WeaponStatus[NXProp_Mag] >= 0)
				{
					SetWeaponState("RemoveMag");
				}
			}
			Goto ChamberManual;
		RemoveMag:
			NRLA # 2 Offset(0, 34) A_SetCrosshair(21);
			NRLA # 2 Offset(1, 38);
			NRLB # 4 Offset(2, 42);
			NRLC # 6 Offset(3, 46) A_StartSound("Nyx/MagOut", 8, CHANF_OVERLAP);
			#### # 0
			{
				int Mag = invoker.WeaponStatus[NXProp_Mag];
				invoker.WeaponStatus[NXProp_Mag] = -1;
				if (Mag == -1)
				{
					SetWeaponState("MagOut");
				}
				else if((!PressingUnload() && !PressingReload()) || A_JumpIfInventory("HDNyxMag", 0, "null"))
				{
					HDMagAmmo.SpawnMag(self, "HDNyxMag", Mag);
					setweaponstate("MagOut");
				}
				else{
					HDMagAmmo.GiveMag(self, "HDNyxMag", Mag);
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
				if (invoker.WeaponStatus[NXProp_Flags] & NXF_JustUnload)
				{
					SetWeaponState("ReloadEnd");
				}
				else
				{
					SetWeaponState("LoadMag");
				}
			}
		LoadMag:
			NRLC # 4 Offset(0, 46) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			#### # 0 A_StartSound("weapons/pocket", 9);
			NRLB # 5 Offset(0, 46) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			NRLA # 3;
			#### # 0
			{
				let Mag = HDMagAmmo(FindInventory("HDNyxMag"));
				if (Mag)
				{
					invoker.WeaponStatus[NXProp_Mag] = Mag.TakeMag(true);
					A_StartSound("Nyx/MagIn", 8);
				}
			}
			Goto ReloadEnd;
		ReloadEnd:
			#### # 2 Offset(3, 46);
			#### # 1 Offset(2, 42);
			#### # 1 Offset(2, 38);
			#### # 1 Offset(1, 34);
			#### # 0 A_JumpIf(!(invoker.WeaponStatus[NXProp_Flags] & NXF_JustUnload), "ChamberManual");
			Goto Nope;

		ChamberManual:
			#### # 0 A_JumpIf(!(invoker.WeaponStatus[NXProp_Flags] & NXF_JustUnload) && (invoker.WeaponStatus[NXProp_Chamber] == 2 || invoker.WeaponStatus[NXProp_Mag] <= 0), "Nope");
			#### # 3 Offset(0, 34);
			#### D 4 Offset(0, 37)
			{
				A_MuzzleClimb(frandom(0.4, 0.5), -frandom(0.6, 0.8));
				A_StartSound("Nyx/SlideBack", 8);
				int Chamber = invoker.WeaponStatus[NXProp_Chamber];
				invoker.WeaponStatus[NXProp_Chamber] = 0;
				switch (Chamber)
				{
					case 1: A_EjectCasing("HDSpent355",frandom(-1,2),(-frandom(2,3),frandom(0,0.2),frandom(0.4,0.5)),(-2,0,-1)); break;
					case 2: A_SpawnItemEx("HDRevolverAmmo", cos(pitch * 12), 0, height - 9 - sin(pitch) * 12, 1, 2, 3, 0); break;
				}

				if (invoker.WeaponStatus[NXProp_Mag] > 0)
				{
					invoker.WeaponStatus[NXProp_Chamber] = 2;
					invoker.WeaponStatus[NXProp_Mag]--;
				}
			}
			#### # 3 Offset(0, 35);
			Goto Nope;
		LoadChamber:
			#### # 0 A_JumpIf(invoker.WeaponStatus[NXProp_Chamber] > 0, "Nope");
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
					A_StartSound("Nyx/SlideForward", 8);
					A_TakeInventory("HDRevolverAmmo", 1, TIF_NOTAKEINFINITE);
					invoker.WeaponStatus[NXProp_Chamber] = 2;
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

class nyxrandom : IdleDummy
{
	States
	{
		Spawn:
			TNT1 A 0 NoDelay
			{
				A_SpawnItemEx("HDNyxMag", -3, flags: SXF_NOCHECKPOSITION);
				A_SpawnItemEx("HDNyxMag", -1, flags: SXF_NOCHECKPOSITION);
				let wpn = HDNyx(Spawn("HDNyx", pos, ALLOW_REPLACE));
				if (!wpn)
				{
					return;
				}

				HDF.TransferSpecials(self, wpn);
				
				wpn.InitializeWepStats(false);
			}
			Stop;
	}
}

class HDNyxMag : HDMagAmmo
{
	override string, string, name, double GetMagSprite(int thismagamt)
	{
		return (thismagamt > 0) ? "NYXMA0" : "NYXMB0", "PRNDA0", "HDRevolverAmmo", 1.0;
	}

	override void GetItemsThatUseThis()
	{
		ItemsThatUseThis.Push("HDNyx");
	}

	const MagCapacity = 12;
	const EncMagEmpty = 3;
	const EncMagLoaded = EncMagEmpty * 0.8;

	Default
	{
		HDMagAmmo.MaxPerUnit MagCapacity;
		HDMagAmmo.InsertTime 7;
		HDMagAmmo.ExtractTime 4;
		HDMagAmmo.RoundType "HDRevolverAmmo";
		HDMagAmmo.RoundBulk ENC_355_LOADED;
		HDMagAmmo.MagBulk EncMagEmpty;
		Tag "$TAG_NYXMAG";
		Inventory.PickupMessage "$PICKUP_NYXMAG";
		HDPickup.RefId HDLD_NYX_MAG;
		Scale 0.5;
	}

	States
	{
		Spawn:
			NYXM A -1;
			Stop;
		SpawnEmpty:
			NYXM B -1
			{
				bROLLSPRITE = true;
				bROLLCENTER = true;
				roll = randompick(0, 0, 0, 0, 2, 2, 2, 2, 1, 3) * 90;
			}
			Stop;
	}
}
