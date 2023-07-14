class HDUSP : HDHandgun
{
	const USP45ACP_LOADED = 0.85;
	enum USPFlags
	{
		USF_JustUnload = 1
	}

	enum USPProperties
	{
		USProp_Flags,
		USProp_Chamber,
		USProp_Mag
	}

	override bool AddSpareWeapon(actor newowner) { return AddSpareWeaponRegular(newowner); }
	override HDWeapon GetSpareWeapon(actor newowner , bool reverse, bool doselect) { return GetSpareWeaponRegular(newowner, reverse, doselect); }

	override double GunMass()
	{
		return 10 + 0.03 * WeaponStatus[USProp_Mag];
	}

	override double WeaponBulk()
	{
		double BaseBulk = 40;
		int Mag = WeaponStatus[USProp_Mag];
		if (Mag >= 0)
		{
			BaseBulk += HDUSPMag.EncMagLoaded + Mag * USP45ACP_LOADED;
		}
		return BaseBulk;
	}

	override string PickupMessage()
	{
		return Stringtable.localize("$PICKUP_USP_PREFIX")..Stringtable.localize("$TAG_USP")..Stringtable.localize("$PICKUP_USP_SUFFIX");
	}

	override string, double GetPickupSprite()
	{
		string USPChamber = WeaponStatus[USProp_Chamber] <= 0 ? "Z" : "Y";
		return "USPG"..USPChamber.."0", 0.4;
	}

	override void InitializeWepStats(bool idfa)
	{
		WeaponStatus[USProp_Chamber] = 2;
		WeaponStatus[USProp_Mag] = HDUSPMag.MagCapacity;
	}

	override void ForceBasicAmmo()
	{
		owner.A_TakeInventory("HD45ACPAmmo");
		owner.A_TakeInventory("HDUSPMag");
		owner.A_GiveInventory("HDUSPMag");
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
				owner.A_DropInventory("HDUSPMag", amt);
			}
		}
	}

	override string GetHelpText()
	{
		return WEPHELP_FIRESHOOT
		..WEPHELP_RELOAD.."  Reload mag\n"
		..WEPHELP_USE.."+"..WEPHELP_RELOAD.."  Reload chamber\n"
		..WEPHELP_MAGMANAGER;
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		if (sb.hudlevel == 1)
		{
			int NextMagLoaded = sb.GetNextLoadMag(HDMagAmmo(hpl.findinventory("HDUSPMag")));
			if (NextMagLoaded >= HDUSPMag.MagCapacity)
			{
				sb.DrawImage("USPMA0", (-46, -3),sb. DI_SCREEN_CENTER_BOTTOM);
			}
			else if (NextMagLoaded <= 0)
			{
				sb.DrawImage("USPMB0", (-46, -3), sb.DI_SCREEN_CENTER_BOTTOM, alpha: NextMagLoaded ? 0.6 : 1.0);
			}
			else
			{
				sb.DrawBar("USPMNORM", "USPMGREY", NextMagLoaded, HDUSPMag.MagCapacity, (-46, -3), -1, sb.SHADER_VERT, sb.DI_SCREEN_CENTER_BOTTOM);
			}
			sb.DrawNum(hpl.CountInv("HDUSPMag"), -43, -8, sb.DI_SCREEN_CENTER_BOTTOM);
		}
		sb.DrawWepNum(hdw.WeaponStatus[USProp_Mag], HDUSPMag.MagCapacity);

		if(hdw.WeaponStatus[USProp_Chamber] == 2)
		{
			sb.DrawRect(-19, -11, 3, 1);
		}
	}

	override void DrawSightPicture(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl, bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot)
	{
		int cx, cy, cw, ch;
		[cx, cy, cw, ch] = Screen.GetClipRect();
		sb.SetClipRect(-16 + bob.x, -4 + bob.y, 32, 13, sb.DI_SCREEN_CENTER);
		vector2 bob2 = bob * 2;
		bob2.y = clamp(bob2.y, -8, 8);
		sb.DrawImage("USPFRNT", bob2, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, alpha: 0.9, scale: (0.8, 0.6));
		sb.SetClipRect(cx, cy, cw, ch);
		sb.DrawImage("USPBACK", bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, scale: (0.8, 0.7));
	}

	private action void A_UpdateSlideFrame()
	{
		let psp = player.GetPSprite(PSP_WEAPON);
		psp.frame = invoker.WeaponStatus[USProp_Chamber] == 0 ? 1 : 0;
	}

	private action void A_UpdateReloadSprite()
	{
		let psp = player.GetPSprite(PSP_WEAPON);
		psp.sprite = GetSpriteIndex(invoker.WeaponStatus[USProp_Chamber] == 0 ? "USPE" : "USPR");
	}
	
	Default
	{
		+HDWEAPON.FITSINBACKPACK
		Weapon.SelectionOrder 300;
		Weapon.SlotNumber 2;
		Weapon.SlotPriority 3;
		HDWeapon.BarrelSize 15, 0.5, 0.5;
		Scale 0.5;
		Tag "$TAG_USP";
		HDWeapon.Refid HDLD_USP;
	}

	States
	{
		RegisterSprites:
			USPR A 0; USPE A 0;

		Spawn:
			USPG Y 0 NoDelay;
			#### # -1
			{
				frame = (invoker.WeaponStatus[USProp_Chamber] == 0 ? 25 : 24);
			}
			Stop;
		Ready:
			USPG A 1
			{
				A_UpdateSlideFrame();
				A_WeaponReady(WRF_ALL);
			}
			Goto ReadyEnd;
		Select0:
			USPG A 0 A_UpdateSlideFrame();
			Goto Select0Small;
		Deselect0:
			USPG A 0 A_UpdateSlideFrame();
			Goto Deselect0Small;
		User3:
			#### A 0 A_MagManager("HDUSPMag");
			Goto Ready;

		Fire:
			USPG # 0
			{
				if (invoker.WeaponStatus[USProp_Chamber] == 2)
				{
					SetWeaponState("Shoot");
				}
				else if (invoker.WeaponStatus[USProp_Mag] > 0)
				{
					SetWeaponState("ChamberManual");
				}
			}
			Goto Nope;
		Shoot:
			USPF A 1
			{
				HDFlashAlpha(128);
				A_Light1();
				A_StartSound("USP/Fire", CHAN_WEAPON);
				HDBulletActor.FireBullet(self, "HDB_45ACP", spread: 1.0);
				A_AlertMonsters();
				A_ZoomRecoil(1.05);
				A_MuzzleClimb(-frandom(0.1, 0.5), -frandom(1.0, 2.5));
				invoker.WeaponStatus[USProp_Chamber] = 1;
			}
			USPG B 1
			{
				if (invoker.WeaponStatus[USProp_Chamber] == 1)
				{
					A_EjectCasing('HDSpent45ACP',frandom(-1,2),(-frandom(2,3),frandom(0,0.2),frandom(0.4,0.5)),(-2,0,-1));
					invoker.WeaponStatus[USProp_Chamber] = 0;
				}
				
				if (invoker.WeaponStatus[USProp_Mag] <= 0)
				{
					A_StartSound("weapons/pistoldry", 8, CHANF_OVERLAP, 0.9);
					SetWeaponState("Nope");
				}
				else
				{
					A_Light0();
					invoker.WeaponStatus[USProp_Chamber] = 2;
					invoker.WeaponStatus[USProp_Mag]--;
				}
			}
			USPG A 1;
			Goto Nope;

		Reload:
			#### # 0
			{
				invoker.WeaponStatus[USProp_Flags] &=~ USF_JustUnload;
				bool noMags = HDMagAmmo.NothingLoaded(self, 'HDUSPMag');
				if (invoker.WeaponStatus[USProp_Mag] >= 12)
				{
					SetWeaponState('Nope');
				}
				else if (invoker.WeaponStatus[USProp_Mag] <= 0 && (PressingUse() || noMags))
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

		Unload:
			#### # 0
			{
				invoker.WeaponStatus[USProp_Flags] |= USF_JustUnload;
				if (invoker.WeaponStatus[USProp_Mag] >= 0)
				{
					SetWeaponState('RemoveMag');
				}
				else if (invoker.WeaponStatus[USProp_Chamber] > 0)
				{
					SetWeaponState('ChamberManual');
				}
			}
			Goto Nope;
		RemoveMag:
			#### A 2 Offset(0, 34)
			{
				A_SetCrosshair(21);
				A_UpdateReloadSprite();
			}
			#### B 2 Offset(1, 38);
			#### C 2 Offset(2, 42);
			#### C 5 Offset(3, 46)
			{
				if (invoker.WeaponStatus[USProp_Mag] > -1)
				{
					A_StartSound("USP/MagOut", 8, CHANF_OVERLAP);
					int mag = invoker.WeaponStatus[USProp_Mag];
					invoker.WeaponStatus[USProp_Mag] = -1;
					if ((!PressingUnload() && !PressingReload()) || A_JumpIfInventory('HDUSPMag', 0, 'null'))
					{
						HDMagAmmo.SpawnMag(self, 'HDUSPMag', mag);
					}
					else
					{
						HDMagAmmo.GiveMag(self, 'HDUSPMag', mag);
						A_StartSound("weapons/pocket", 9);
						SetWeaponState('PocketMag');
					}
				}
			}
			#### C 0 A_JumpIf(!(invoker.WeaponStatus[USProp_Flags] & USF_JustUnload), 'LoadMag');
			#### B 2 Offset(1, 38);
			USPG A 0 A_UpdateSlideFrame();
			Goto Nope;

		PocketMag:
			#### CCCC 5 A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			Goto RemoveMag + 4;
			
		LoadMag:
			#### C 2 Offset(3, 46) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			#### C 2 Offset(3, 46) A_StartSound("weapons/pocket", 9);
			#### C 3 Offset(3, 46) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			#### C 3 Offset(2, 42);
			#### B 2 Offset(1, 38) A_StartSound("USP/MagIn", 8);
			#### A 3 Offset(0, 34)
			{
				let mag = HDMagAmmo(FindInventory('HDUSPMag'));
				if (mag)
				{
					invoker.WeaponStatus[USProp_Mag] = mag.TakeMag(true);
				}
			}
			USPG A 1 A_UpdateSlideFrame();
			USPG # 1 Offset(0, 32);
			USPG # 0 A_JumpIf(!(invoker.WeaponStatus[USProp_Flags] & USF_JustUnload) && (invoker.WeaponStatus[USProp_Chamber] < 2 && invoker.WeaponStatus[USProp_Mag] > 0), 'ChamberManual');
			Goto Nope;

		ChamberManual:
			USPG # 3 Offset(0, 34) A_UpdateSlideFrame();
			USPG # 4 Offset(0, 37)
			{
				if (invoker.WeaponStatus[USProp_Chamber] > 0)
				{
					A_MuzzleClimb(frandom(0.4, 0.5), -frandom(0.6, 0.8));
					A_StartSound("USP/SlideBack", 8);
					int chamber = invoker.WeaponStatus[USProp_Chamber];
					invoker.WeaponStatus[USProp_Chamber] = 0;
					switch (Chamber)
					{
						case 1: A_EjectCasing('HDSpent45ACP',frandom(-1,2),(-frandom(2,3),frandom(0,0.2),frandom(0.4,0.5)),(-2,0,-1));
						case 2: A_SpawnItemEx('HD45ACPAmmo', cos(pitch * 12), 0, height - 9 - sin(pitch) * 12, 1, 2, 3, 0); break;
					}
				}

				if (invoker.WeaponStatus[USProp_Mag] > 0)
				{
					invoker.WeaponStatus[USProp_Chamber] = 2;
					invoker.WeaponStatus[USProp_Mag]--;
					A_StartSound("USP/SlideForward", 9);
				}
				A_UpdateSlideFrame();
			}
			USPG # 3 Offset(0, 35);
			Goto Nope;

		LoadChamber:
			#### # 0 A_JumpIf(invoker.WeaponStatus[USProp_Chamber] > 0, "Nope");
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
					A_StartSound("USP/SlideForward", 8);
					A_TakeInventory('HD45ACPAmmo', 1, TIF_NOTAKEINFINITE);
					invoker.WeaponStatus[USProp_Chamber] = 2;
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

class USPrandom : IdleDummy
{
	States
	{
		Spawn:
			TNT1 A 0 NoDelay
			{
				A_SpawnItemEx("HDUSPMag", -3, flags: SXF_NOCHECKPOSITION);
				A_SpawnItemEx("HDUSPMag", -1, flags: SXF_NOCHECKPOSITION);
				let wpn = HDUSP(Spawn("HDUSP", pos, ALLOW_REPLACE));
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

class HDUSPMag : HDMagAmmo
{
	override string PickupMessage()
	{
		return Stringtable.localize("$PICKUP_USPMAG_PREFIX")..Stringtable.localize("$TAG_USPMAG")..Stringtable.localize("$PICKUP_USPMAG_SUFFIX");
	}

	override string, string, name, double GetMagSprite(int thismagamt)
	{
		return (thismagamt > 0) ? "USPMA0" : "USPMB0", "45RNA0", "HD45ACPAmmo", 0.75;
	}

	override void GetItemsThatUseThis()
	{
		ItemsThatUseThis.Push("HDUSP");
	}
	const USP45ACP_LOADED = 0.85;
	const MagCapacity = 12;
	const EncMagEmpty = 3;
	const EncMagLoaded = EncMagEmpty * 0.8;

	Default
	{
		HDMagAmmo.MaxPerUnit MagCapacity;
		HDMagAmmo.InsertTime 7;
		HDMagAmmo.ExtractTime 4;
		HDMagAmmo.RoundType "HD45ACPAmmo";
		HDMagAmmo.RoundBulk USP45ACP_LOADED;
		HDMagAmmo.MagBulk EncMagEmpty;
		Tag "$TAG_USPMAG";
		HDPickup.RefId HDLD_USPMAG;
		Scale 0.5;
	}

	States
	{
		Spawn:
			USPM A -1;
			Stop;
		SpawnEmpty:
			USPM B -1
			{
				bROLLSPRITE = true;
				bROLLCENTER = true;
				roll = randompick(0, 0, 0, 0, 2, 2, 2, 2, 1, 3) * 90;
			}
			Stop;
	}
}
