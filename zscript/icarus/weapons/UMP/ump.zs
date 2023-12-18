class HDUMP : HDWeapon
{
	const UMP45ACP_LOADED = 0.85;
	enum UMPFlags
	{
		UMF_JustUnload = 1
	}

	enum UMPProperties
	{
		UMProp_Flags,
		UMProp_Chamber,
		UMProp_Mag,
		UMProp_Mode
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
		return 9.5 + 0.03 * WeaponStatus[UMProp_Mag];
	}

	override double WeaponBulk()
	{
		double BaseBulk = 110;
		int Mag = WeaponStatus[UMProp_Mag];
		if (Mag >= 0)
		{
			BaseBulk += HDUMPMag.EncMagLoaded + Mag * UMP45ACP_LOADED;
			//BaseBulk += HDUMPMag.EncMagLoaded + Mag * HD45ACPAmmo.UMP45ACP_LOADED;
		}
		return BaseBulk;
	}

	override string PickupMessage()
	{
		return Stringtable.localize("$PICKUP_UMP_PREFIX")..Stringtable.localize("$TAG_UMP")..Stringtable.localize("$PICKUP_UMP_SUFFIX");
	}

	override string, double GetPickupSprite()
	{
		return WeaponStatus[UMProp_Mag] >= 0 ? "UMPGZ0" : "UMPGY0", 1.0;
	}

	override void InitializeWepStats(bool idfa)
	{
		WeaponStatus[UMProp_Chamber] = 2;
		WeaponStatus[UMProp_Mag] = HDUMPMag.MagCapacity;
	}

	override void ForceBasicAmmo()
	{
		owner.A_TakeInventory("HD45ACPAmmo");
		owner.A_TakeInventory("HDUMPMag");
		owner.A_GiveInventory("HDUMPMag");
	}

	override void DropOneAmmo(int amt)
	{
		if (owner)
		{
			amt = clamp(amt, 1, 10);
			if (owner.CheckInventory("HD45ACPAmmo", 1))
			{
				owner.A_DropInventory("HD45ACPAmmo", amt * 10);
			}
			else
			{
				owner.A_DropInventory("HDUMPMag", amt);
			}
		}
	}

	override string GetHelpText()
	{
		return WEPHELP_FIRESHOOT
		..WEPHELP_FIREMODE.."  Semi Auto/Full Auto\n"
		..WEPHELP_RELOAD.."  Reload mag\n"
		..WEPHELP_USE.."+"..WEPHELP_RELOAD.."  Reload chamber\n"
		..WEPHELP_MAGMANAGER;
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		if (sb.hudlevel == 1)
		{
			int NextMagLoaded = sb.GetNextLoadMag(HDMagAmmo(hpl.findinventory("HDUMPMag")));
			if (NextMagLoaded >= HDUMPMag.MagCapacity)
			{
				sb.DrawImage("UMPMA0", (-46, -3),sb. DI_SCREEN_CENTER_BOTTOM);
			}
			else if (NextMagLoaded <= 0)
			{
				sb.DrawImage("UMPMB0", (-46, -3), sb.DI_SCREEN_CENTER_BOTTOM, alpha: NextMagLoaded ? 0.6 : 1.0);
			}
			else
			{
				sb.DrawBar("UMPMNORM", "UMPMGREY", NextMagLoaded, HDUMPMag.MagCapacity, (-46, -3), -1, sb.SHADER_VERT, sb.DI_SCREEN_CENTER_BOTTOM);
			}
			sb.DrawNum(hpl.CountInv("HDUMPMag"), -43, -8, sb.DI_SCREEN_CENTER_BOTTOM);
		}
		sb.DrawWepNum(hdw.WeaponStatus[UMProp_Mag], HDUMPMag.MagCapacity);

		if(hdw.WeaponStatus[UMProp_Chamber] == 2)
		{
			sb.DrawRect(-19, -11, 3, 1);
		}
		
		sb.DrawWepCounter(hdw.WeaponStatus[UMProp_Mode], -22, -10, "RBRSA3A7", "STFULAUT");
	}

	override void DrawSightPicture(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl, bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot)
	{
		int cx, cy, cw, ch;
		[cx, cy, cw, ch] = Screen.GetClipRect();
		sb.SetClipRect(-10 + bob.x, -4 + bob.y, 20, 20, sb.DI_SCREEN_CENTER);
		vector2 bob2 = bob * 1.18;
		//bob2.y = clamp(bob2.y, -8, 8);
		sb.DrawImage("UMPFRNT", (0, -4) + bob2, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, scale: (1.0, 0.8));
		sb.SetClipRect(cx, cy, cw, ch);
		sb.DrawImage("UMPBACK", (0, -4) + bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, scale: (1.0, 0.8));
	}

	private action void A_UpdateChamberFrame()
	{
		let psp = player.GetPSprite(PSP_WEAPON);
		psp.frame = invoker.WeaponStatus[UMProp_Chamber] == 0 ? 1 : 0;
	}
	
	Default
	{
		+HDWEAPON.FITSINBACKPACK
		Weapon.SelectionOrder 300;
		Weapon.SlotNumber 4;
		Weapon.SlotPriority 1.5;
		HDWeapon.BarrelSize 20, 2, 3;
		Scale 0.5;
		Tag "$TAG_UMP";
		HDWeapon.Refid HDLD_UMP;
		Inventory.PickupMessage "$PICKUP_UMP";
	}

	States
	{
		Spawn:
			UMPG Z 0 NoDelay A_JumpIf(invoker.WeaponStatus[UMProp_Mag] >= 0, 2);
			UMPG Y 0;
			#### # -1;
			Stop;
		Ready:
			UMPG A 1
			{
				A_UpdateChamberFrame();
				A_WeaponReady(WRF_ALL);
			}
			Goto ReadyEnd;
		Select0:
			UMPG A 0 A_UpdateChamberFrame();
			Goto Select0Big;
		Deselect0:
			UMPG A 0 A_UpdateChamberFrame();
			Goto Deselect0Big;
		User3:
			#### A 0 A_MagManager("HDUMPMag");
			Goto Ready;		
		Firemode:
			UMPG A 1
			{
				++invoker.WeaponStatus[UMProp_Mode] %= 2;
			}
			Goto Nope;

		Fire:
			UMPG # 0
			{
				if (invoker.WeaponStatus[UMProp_Chamber] == 2)
				{
					SetWeaponState("Shoot");
				}
				else if (invoker.WeaponStatus[UMProp_Mag] > 0)
				{
					SetWeaponState("ChamberManual");
				}
			}
			Goto Nope;
		Shoot:
			UMPG B 2
			{
				A_Overlay(PSP_FLASH, 'Flash');

				A_Light1();
				A_StartSound("UMP/Fire", CHAN_WEAPON);
				HDBulletActor.FireBullet(self, "HDB_45ACP", spread: 1.0, speedfactor: 1.1);
				A_AlertMonsters();
				A_ZoomRecoil(1.05);
				A_MuzzleClimb(-frandom(-0.5, 0.5), -frandom(0.5, 0.6), -frandom(-0.5, 0.5), -frandom(0.5, 0.6));
				invoker.WeaponStatus[UMProp_Chamber] = 1;
			}
			UMPG A 1
			{
				if (invoker.WeaponStatus[UMProp_Chamber] == 1)
				{
					A_EjectCasing('HDSpent45ACP', frandom(-1,2),(frandom(0.2,0.3),-frandom(7,7.5),frandom(0,0.2)),(0,0,-2));
					invoker.WeaponStatus[UMProp_Chamber] = 0;
				}
				
				if (invoker.WeaponStatus[UMProp_Mag] <= 0)
				{
					A_StartSound("weapons/pistoldry", 8, CHANF_OVERLAP, 0.9);
					SetWeaponState("Nope");
				}
				else
				{
					A_Light0();
					invoker.WeaponStatus[UMProp_Chamber] = 2;
					invoker.WeaponStatus[UMProp_Mag]--;
				}
			}
			UMPG A 1
			{

				switch (invoker.WeaponStatus[UMProp_Mode])
				{
					case 1:
					{
						A_Refire('Shoot');
						break;
					}
				}
			}
			Goto Nope;
		Flash:
			UMPF A 1 Bright
			{
				HDFlashAlpha(128);
			}
			goto lightdone;

		Unload:
			#### # 0
			{
				invoker.WeaponStatus[UMProp_Flags] |= UMF_JustUnload;
				if (invoker.WeaponStatus[UMProp_Mag] >= 0)
				{
					SetWeaponState('RemoveMag');
				}
				else if (invoker.WeaponStatus[UMProp_Chamber] > 0)
				{
					SetWeaponState('ChamberManual');
				}
			}
			Goto Nope;
		RemoveMag:
			UMPG # 2 Offset(0,36)
			{
				A_SetCrosshair(21);
				A_MuzzleClimb(frandom(-1.2,-2.4),frandom(1.2,2.4));
			}
			#### # 2 Offset(1,37);
			#### # 2 Offset(2,38);
			#### # 2 Offset(3,42);
			#### # 2 Offset(5,44);
			#### # 2 Offset(6,42);
			#### # 2 Offset(7,43) A_StartSound("UMP/MagOut",8);
			#### # 2 Offset(8,42);
			#### # 0
			{
				if (invoker.WeaponStatus[UMProp_Mag] > -1)
				{
					int mag = invoker.WeaponStatus[UMProp_Mag];
					invoker.WeaponStatus[UMProp_Mag] = -1;
					if ((!PressingUnload() && !PressingReload()) || A_JumpIfInventory('HDUMPMag', 0, 'null'))
					{
						HDMagAmmo.SpawnMag(self, 'HDUMPMag', mag);
					}
					else
					{
						HDMagAmmo.GiveMag(self, 'HDUMPMag', mag);
						A_StartSound("weapons/pocket", 9);
						SetWeaponState('PocketMag');
					}
				}
			}
			#### # 0 A_JumpIf(!(invoker.WeaponStatus[UMProp_Flags] & UMF_JustUnload), 'LoadMag');
			#### # 2;
			UMPG A 0 A_UpdateChamberFrame();
			Goto Nope;
		PocketMag:
			UMPG #### 5 Offset(8,42)
			{
				A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			}
			Goto MagOut;
		MagOut:
			UMPG # 0 A_JumpIf(invoker.WeaponStatus[UMProp_Flags] & UMF_JustUnload, "ReloadEnd");
			Goto LoadMag;

		Reload:
			UMPG # 0
			{
				invoker.WeaponStatus[UMProp_Flags] &=~ UMF_JustUnload;
				bool noMags = HDMagAmmo.NothingLoaded(self, 'HDUMPMag');
				if (invoker.WeaponStatus[UMProp_Mag] >= 25)
				{
					SetWeaponState('Nope');
				}
				else if (invoker.WeaponStatus[UMProp_Mag] <= 0 && (PressingUse() || noMags))
				{
					if (CheckInventory('HD45ACPAmmo', 1))
					{
						SetWeaponState('LoadChamber');
					}
					else
					{
						SetWeaponState('Nope');
					}
				}
				else if (noMags)
				{
					SetWeaponState('Nope');
				}
			}
			Goto RemoveMag;
		LoadMag:
			UMPG # 4 Offset(8,42) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			#### # 4 Offset(7,43) A_StartSound("weapons/pocket", 9);
			#### # 4 Offset(6,42) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			#### # 4 Offset(5,44);
			#### # 4 Offset(3,42);
			#### # 4 Offset(2,38);
			#### # 4 Offset(1,37) A_StartSound("UMP/MagIn", 8);
			#### # 4 Offset(0,36);
			#### A 0
			{
				let mag = HDMagAmmo(FindInventory('HDUMPMag'));
				if (mag)
				{
					invoker.WeaponStatus[UMProp_Mag] = mag.TakeMag(true);
				}
			}
			UMPG A 1 A_UpdateChamberFrame();
			UMPG # 1 Offset(0, 36) ;
			UMPG # 0 A_JumpIf(!(invoker.WeaponStatus[UMProp_Flags] & UMF_JustUnload) && (invoker.WeaponStatus[UMProp_Chamber] < 2 && invoker.WeaponStatus[UMProp_Mag] > 0), 'ChamberManual');
			Goto ReloadEnd;
		ReloadEnd:
			UMPG A 6 Offset(0,40);
			#### A 2 Offset(0,36);
			#### A 4 Offset(0,33);
			Goto Nope;

		ChamberManual:
			UMPG A 2 Offset(2, 34) A_UpdateChamberFrame();
			UMPG C 2 Offset(3, 38);
			UMPG C 3 Offset(4, 44)
			{
				if (invoker.WeaponStatus[UMProp_Chamber] > 0)
				{
					A_MuzzleClimb(frandom(0.4, 0.5), -frandom(0.6, 0.8));
					A_StartSound("UMP/SlideBack", 8);
					int chamber = invoker.WeaponStatus[UMProp_Chamber];
					invoker.WeaponStatus[UMProp_Chamber] = 0;
					switch (Chamber)
					{
						case 1: A_EjectCasing('HDSpent45ACP', frandom(-1,2),(frandom(0.2,0.3),-frandom(7,7.5),frandom(0,0.2)),(0,0,-2));
						case 2: A_SpawnItemEx('HD45ACPAmmo', cos(pitch * 12), 0, height - 9 - sin(pitch) * 12, 1, 2, 3, 0); break;
					}
				}

				if (invoker.WeaponStatus[UMProp_Mag] > 0)
				{
					invoker.WeaponStatus[UMProp_Chamber] = 2;
					invoker.WeaponStatus[UMProp_Mag]--;
					A_StartSound("UMP/SlideForward", 9);
				}
				A_UpdateChamberFrame();
			}
			UMPG A 1 Offset(3, 38);
			UMPG A 1 Offset(2, 34);
			UMPG A 1 Offset(0, 32);
			Goto Nope;

		LoadChamber:
			UMPG # 0 A_JumpIf(invoker.WeaponStatus[UMProp_Chamber] > 0, "Nope");
			#### B 1 Offset(0, 36) A_StartSound("weapons/pocket",9);
			#### B 1 Offset(2, 40);
			#### B 1 Offset(2, 50);
			#### B 1 Offset(3, 60);
			#### B 2 Offset(5, 90);
			#### B 2 Offset(7, 80);
			#### B 2 Offset(10, 90);
			#### B 2 Offset(8, 96);
			#### B 3 Offset(6, 88)
			{
				if (CheckInventory("HD45ACPAmmo", 1))
				{
					A_StartSound("UMP/SlideForward", 8);
					A_TakeInventory('HD45ACPAmmo', 1, TIF_NOTAKEINFINITE);
					invoker.WeaponStatus[UMProp_Chamber] = 2;
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

class UMPrandom : IdleDummy
{
	States
	{
		Spawn:
			TNT1 A 0 NoDelay
			{
				A_SpawnItemEx("HDUMPMag", -3, flags: SXF_NOCHECKPOSITION);
				A_SpawnItemEx("HDUMPMag", -1, flags: SXF_NOCHECKPOSITION);
				let wpn = HDUMP(Spawn("HDUMP", pos, ALLOW_REPLACE));
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

class HDUMPMag : HDMagAmmo
{

	override string PickupMessage()
	{
		return Stringtable.localize("$PICKUP_UMPMAG_PREFIX")..Stringtable.localize("$TAG_UMPMAG")..Stringtable.localize("$PICKUP_UMPMAG_SUFFIX");
	}

	override string, string, name, double GetMagSprite(int thismagamt)
	{
		return (thismagamt > 0) ? "UMPMA0" : "UMPMB0", "45RNA0", "HD45ACPAmmo", 0.75;
	}

	override void GetItemsThatUseThis()
	{
		ItemsThatUseThis.Push("HDUMP");
	}
	const UMP45ACP_LOADED = 0.85;
	const MagCapacity = 25;
	const EncMagEmpty = 9;
	const EncMagLoaded = EncMagEmpty * 0.9;

	Default
	{
		HDMagAmmo.MaxPerUnit MagCapacity;
		HDMagAmmo.InsertTime 7;
		HDMagAmmo.ExtractTime 4;
		HDMagAmmo.RoundType "HD45ACPAmmo";
		HDMagAmmo.RoundBulk UMP45ACP_LOADED;
		//HDMagAmmo.RoundBulk HD45ACPAmmo.UMP45ACP_LOADED;
		HDMagAmmo.MagBulk EncMagEmpty;
		Tag "$TAG_UMPMAG";
		HDPickup.RefId HDLD_UMPMAG;
		Scale 0.5;
	}

	States
	{
		Spawn:
			UMPM A -1;
			Stop;
		SpawnEmpty:
			UMPM B -1
			{
				bROLLSPRITE = true;
				bROLLCENTER = true;
				roll = randompick(0, 0, 0, 0, 2, 2, 2, 2, 1, 3) * 90;
			}
			Stop;
	}
}
