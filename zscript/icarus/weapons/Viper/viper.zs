class HDViper : HDHandgun
{
	enum ViperFlags
	{
		VPF_JustUnload = 1,
		VPF_HeavyFrame = 4,
		VPF_ExtendedBarrel = 8
	}

	enum ViperProperties
	{
		VPProp_Flags,
		VPProp_Chamber,
		VPProp_Mag,
	}

	override void Tick()
	{
		if (WeaponStatus[VPProp_Flags] & VPF_ExtendedBarrel)
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
		if (WeaponStatus[VPProp_Flags] & VPF_ExtendedBarrel)
		{
			BaseMass += 1.5;
		}
		if (WeaponStatus[VPProp_Flags] & VPF_HeavyFrame)
		{
			BaseMass *= 1.1;
		}
		return BaseMass;
	}

	override double WeaponBulk()
	{
		double BaseBulk = 50;
		int Mag = WeaponStatus[VPProp_Mag];
		if (Mag >= 0)
		{
			BaseBulk += HDViperMag.EncMagLoaded + Mag * HD50AEAmmo.EncRoundLoaded;
		}
		if (WeaponStatus[VPProp_Flags] & VPF_ExtendedBarrel)
		{
			BaseBulk += 15;
		}
		if (WeaponStatus[VPProp_Flags] & VPF_HeavyFrame)
		{
			BaseBulk *= 1.20;
		}
		return BaseBulk;
	}

	override string, double GetPickupSprite()
	{
		string IconString = "";
		if (WeaponStatus[VPProp_Chamber] > 0)
		{
			IconString = WeaponStatus[VPProp_Flags] & VPF_ExtendedBarrel ? "VPRXY0" : "VPRGY0";
		}
		else
		{
			IconString = WeaponStatus[VPProp_Flags] & VPF_ExtendedBarrel ? "VPRXZ0" : "VPRGZ0";
		}
		return IconString, 1.0;
	}

	override void InitializeWepStats(bool idfa)
	{
		WeaponStatus[VPProp_Chamber] = 2;
		WeaponStatus[VPProp_Mag] = 7;
	}

	override void LoadoutConfigure(string input)
	{
		if (GetLoadoutVar(input, "hframe", 1) > 0)
		{
			WeaponStatus[VPProp_Flags] |= VPF_HeavyFrame;
		}
		if (GetLoadoutVar(input, "extended", 1) > 0)
		{
			WeaponStatus[VPProp_Flags] |= VPF_ExtendedBarrel;
		}

		InitializeWepStats();
	}

	override void ForceBasicAmmo()
	{
		owner.A_TakeInventory("HD50AEAmmo");
		owner.A_TakeInventory("HDViperMag");
		owner.A_GiveInventory("HDViperMag");
	}

	override void DropOneAmmo(int amt)
	{
		if (owner)
		{
			amt = clamp(amt, 1, 10);
			if (owner.CheckInventory("HD50AEAmmo", 1))
			{
				owner.A_DropInventory("HD50AEAmmo", amt * 10);
			}
			else
			{
				owner.A_DropInventory("HDViperMag", amt);
			}
		}
	}

	action void A_CheckViperHand()
	{
		bool right = !invoker.wronghand;
		right = right && Wads.CheckNumForName("id", 0) != -1 || !right && Wads.CheckNumForName("id", 0) == -1;
		player.GetPSprite(PSP_WEAPON).sprite = GetSpriteIndex(right ? "VPRGA0" : "VP2GA0");
	}

	override string GetHelpText()
	{
		return WEPHELP_FIRESHOOT
		..WEPHELP_ALTRELOAD.."/"..WEPHELP_FIREMODE.."  Quick-Swap (if available)\n"
		..WEPHELP_RELOAD.."  Reload mag\n"
		..WEPHELP_USE.."+"..WEPHELP_RELOAD.."  Reload chamber\n"
		..WEPHELP_MAGMANAGER
		..WEPHELP_UNLOADUNLOAD;
	}

	override string PickupMessage()
	{
		string HFrameStr = WeaponStatus[VPProp_Flags] & VPF_HeavyFrame ? " heavy-framed" : "";
		string ExBarrelStr = WeaponStatus[VPProp_Flags] & VPF_ExtendedBarrel ? " extended" : "";
		return String.Format("You got the%s%s 'Viper' .50 cal. handgun. Blast 'em.", HFrameStr, ExBarrelStr);
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		if (sb.hudlevel == 1)
		{
			int NextMagLoaded = sb.GetNextLoadMag(HDMagAmmo(hpl.findinventory("HDViperMag")));
			if (NextMagLoaded >= 7)
			{
				sb.DrawImage("VPMGA0", (-46, -3),sb. DI_SCREEN_CENTER_BOTTOM, scale: (2.0, 2.0));
			}
			else if (NextMagLoaded <= 0)
			{
				sb.DrawImage("VPMGB0", (-46, -3), sb.DI_SCREEN_CENTER_BOTTOM, alpha: NextMagLoaded ? 0.6 : 1.0, scale: (2.0, 2.0));
			}
			else
			{
				sb.DrawBar("VPMGNORM", "VPMGGREY", NextMagLoaded, 7, (-46, -3), -1, sb.SHADER_VERT, sb.DI_SCREEN_CENTER_BOTTOM);
			}
			sb.DrawNum(hpl.CountInv("HDViperMag"), -43, -8, sb.DI_SCREEN_CENTER_BOTTOM);
		}
		sb.DrawWepNum(hdw.WeaponStatus[VPProp_Mag], 7);

		if(hdw.WeaponStatus[VPProp_Chamber] == 2)
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
		sb.DrawImage("VIPRFRNT", bob2, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, alpha: 0.9, scale: (0.8, 0.6));
		sb.SetClipRect(cx, cy, cw, ch);
		sb.DrawImage("VIPRBACK", bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, scale: (0.9, 0.7));
	}

	Default
	{
		+HDWEAPON.FITSINBACKPACK
		Weapon.SelectionOrder 300;
		Weapon.SlotNumber 2;
		Weapon.SlotPriority 4;
		HDWeapon.BarrelSize 13, 0.35, 0.5;
		Scale 0.5;
		Tag "'Viper' .50 cal. handgun";
		HDWeapon.Refid "vpr";
	}

	States
	{
		Spawn:
			VPRX Y 0 NoDelay A_JumpIf(invoker.WeaponStatus[VPProp_Flags] & VPF_ExtendedBarrel, 2);
			VPRG Y 0;
			#### # -1
			{
				frame = (invoker.WeaponStatus[VPProp_Chamber] == 0 ? 25 : 24);
			}
			Stop;
		Ready:
			VPRG A 0 A_CheckViperHand();
			#### A 0 A_JumpIf(invoker.WeaponStatus[VPProp_Chamber] > 0, 2);
			#### D 0;
			#### # 1 A_WeaponReady(WRF_ALL);
			Goto ReadyEnd;
		Select0:
			VPRG A 0
			{
				if (!CheckInventory("NulledWeapon", 1))
				{
					invoker.wronghand = false;
				}
				A_TakeInventory("NulledWeapon");
				A_CheckViperHand();
			}
			#### A 0 A_JumpIf(invoker.WeaponStatus[VPProp_Chamber] > 0, 2);
			#### D 0;
			#### # 0;
			Goto Select0Small;
		Deselect0:
			VPRG A 0 A_CheckViperHand();
			#### A 0 A_JumpIf(invoker.WeaponStatus[VPProp_Chamber] > 0, 2);
			#### D 0;
			#### # 0;
			Goto Deselect0Small;
		User3:
			#### A 0 A_MagManager("HDViperMag");
			Goto Ready;

		AltFire:
			Goto ChamberManual;

		Fire:
			#### # 0
			{
				if (invoker.WeaponStatus[VPProp_Chamber] == 2)
				{
					SetWeaponState("Shoot");
				}
				else if (invoker.WeaponStatus[VPProp_Mag] > 0)
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
			}
			#### C 1 Offset(0, 36)
			{
				HDFlashAlpha(128);
				A_Light1();
				A_StartSound("Viper/Fire", CHAN_WEAPON);

				bool ExtBarrel = invoker.WeaponStatus[VPProp_Flags] & VPF_ExtendedBarrel;

				double VelMult = 1.0;
				if (ExtBarrel)
				{
					VelMult += 0.15;
				}
				HDBulletActor.FireBullet(self, "HDB_50AE", spread: 1.0, speedfactor: frandom(0.99, 1.03) * VelMult);
				A_AlertMonsters();
				A_ZoomRecoil(0.99);

				double ClimbMult = 1.0;
				if (ExtBarrel)
				{
					ClimbMult -= 0.12;
				}
				if (invoker.WeaponStatus[VPProp_Flags] & VPF_HeavyFrame)
				{
					ClimbMult *= 0.75;
				}
				A_MuzzleClimb(-frandom(0., 1.8) * ClimbMult, -frandom(3.0, 5.0) * ClimbMult);

				invoker.WeaponStatus[VPProp_Chamber] = 1;
			}
			#### D 1 Offset(0, 44)
			{
				if (invoker.WeaponStatus[VPProp_Chamber] == 1)
				{
					A_EjectCasing('HDSpent50AE',-frandom(79,81),(frandom(6,6.5),0,frandom(0,1)),(10,0,0));
					invoker.WeaponStatus[VPProp_Chamber] = 0;
				}
				
				if (invoker.WeaponStatus[VPProp_Mag] <= 0)
				{
					A_StartSound("weapons/pistoldry", 8, CHANF_OVERLAP, 0.9);
					SetWeaponState("Nope");
				}
				else
				{
					A_Light0();
					invoker.WeaponStatus[VPProp_Chamber] = 2;
					invoker.WeaponStatus[VPProp_Mag]--;
					A_Refire();
				}
			}
			Goto Ready;
		Hold:
			Goto Nope;

		Reload:
			#### # 0
			{
				invoker.WeaponStatus[VPProp_Flags] &=~ VPF_JustUnload;
				bool NoMags = HDMagAmmo.NothingLoaded(self, "HDViperMag");
				if (invoker.WeaponStatus[VPProp_Mag] >= 7)
				{
					SetWeaponState("Nope");
				}
				else if (invoker.WeaponStatus[VPProp_Mag] <= 0 && (PressingUse() || NoMags))
				{
					if (CheckInventory("HD50AEAmmo", 1))
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
				invoker.WeaponStatus[VPProp_Flags] |= VPF_JustUnload;
				if (invoker.WeaponStatus[VPProp_Mag] >= 0)
				{
					SetWeaponState("RemoveMag");
				}
			}
			Goto ChamberManual;
		RemoveMag:
			#### # 1 Offset(0, 34) A_SetCrosshair(21);
			#### # 1 Offset(1, 38);
			#### # 2 Offset(2, 42);
			#### # 3 Offset(3, 46) A_StartSound("Viper/MagOut", 8, CHANF_OVERLAP);
			#### # 0
			{
				int Mag = invoker.WeaponStatus[VPProp_Mag];
				invoker.WeaponStatus[VPProp_Mag] = -1;
				if (Mag == -1)
				{
					SetWeaponState("MagOut");
				}
				else if((!PressingUnload() && !PressingReload()) || A_JumpIfInventory("HDViperMag", 0, "null"))
				{
					HDMagAmmo.SpawnMag(self, "HDViperMag", Mag);
					setweaponstate("MagOut");
				}
				else{
					HDMagAmmo.GiveMag(self, "HDViperMag", Mag);
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
				if (invoker.WeaponStatus[VPProp_Flags] & VPF_JustUnload)
				{
					SetWeaponState("ReloadEnd");
				}
				else
				{
					SetWeaponState("LoadMag");
				}
			}
		LoadMag:
			#### # 4 Offset(0, 46) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			#### # 0 A_StartSound("weapons/pocket", 9);
			#### # 5 Offset(0, 46) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			#### # 3;
			#### # 0
			{
				let Mag = HDMagAmmo(FindInventory("HDViperMag"));
				if (Mag)
				{
					invoker.WeaponStatus[VPProp_Mag] = Mag.TakeMag(true);
					A_StartSound("Viper/MagIn", 8);
				}
			}
			Goto ReloadEnd;
		ReloadEnd:
			#### # 2 Offset(3, 46);
			#### # 1 Offset(2, 42);
			#### # 1 Offset(2, 38);
			#### # 1 Offset(1, 34);
			#### # 0 A_JumpIf(!(invoker.WeaponStatus[VPProp_Flags] & VPF_JustUnload), "ChamberManual");
			Goto Nope;

		ChamberManual:
			#### # 0 A_JumpIf(!(invoker.WeaponStatus[VPProp_Flags] & VPF_JustUnload) && (invoker.WeaponStatus[VPProp_Chamber] == 2 || invoker.WeaponStatus[VPProp_Mag] <= 0), "Nope");
			#### # 3 Offset(0, 34);
			#### D 4 Offset(0, 37)
			{
				A_MuzzleClimb(frandom(0.4, 0.5), -frandom(0.6, 0.8));
				A_StartSound("Viper/SlideBack", 8);
				int Chamber = invoker.WeaponStatus[VPProp_Chamber];
				invoker.WeaponStatus[VPProp_Chamber] = 0;
				switch (Chamber)
				{
						case 1: A_EjectCasing('HDSpent50AE',-frandom(79,81),(frandom(6,6.5),0,frandom(0,1)),(10,0,0));
					case 2: A_SpawnItemEx("HD50AEAmmo", cos(pitch * 12), 0, height - 9 - sin(pitch) * 12, 1, 2, 3, 0); break;
				}

				if (invoker.WeaponStatus[VPProp_Mag] > 0)
				{
					invoker.WeaponStatus[VPProp_Chamber] = 2;
					invoker.WeaponStatus[VPProp_Mag]--;
				}
			}
			#### # 3 Offset(0, 35);
			Goto Nope;
		LoadChamber:
			#### # 0 A_JumpIf(invoker.WeaponStatus[VPProp_Chamber] > 0, "Nope");
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
				if (CheckInventory("HD50AEAmmo", 1))
				{
					A_StartSound("Viper/SlideForward", 8);
					A_TakeInventory("HD50AEAmmo", 1, TIF_NOTAKEINFINITE);
					invoker.WeaponStatus[VPProp_Chamber] = 2;
				}
			}
			#### A 2 Offset(5, 76);
			#### A 1 Offset(4, 64);
			#### A 1 Offset(3, 56);
			#### A 1 Offset(2, 48);
			#### A 2 Offset(1, 38);
			#### A 3 Offset(0, 34);
			Goto ReadyEnd;


		Firemode:
		SwapPistols:
			#### A 0 A_SwapHandguns();
			#### A 0 A_JumpIf(player.GetPSprite(PSP_WEAPON).sprite == GetSpriteIndex("VPRGA0"), "SwapPistols2");
		SwapPistols1:
			TNT1 A 0 A_Overlay(1026, "lowerleft");
			TNT1 A 0 A_Overlay(1025, "raiseright");
			TNT1 A 5;
			VPRG A 0;
			Goto Nope;
		SwapPistols2:
			TNT1 A 0 A_Overlay(1026, "lowerright");
			TNT1 A 0 A_Overlay(1025, "raiseleft");
			TNT1 A 5;
			VP2G A 0;
			Goto Nope;
		LowerLeft:
			VPRG # 0 A_WeaponBusy(true);
			#### # 1 Offset(-6, 38);
			#### # 1 Offset(-12, 48);
			#### # 1 Offset(-20, 60);
			#### # 1 Offset(-34, 76);
			#### # 1 Offset(-50, 86);
			stop;
		LowerRight:
			VP2G # 0 A_WeaponBusy(true);
			#### # 1 Offset(6, 38);
			#### # 1 Offset(12, 48);
			#### # 1 Offset(20, 60);
			#### # 1 Offset(34, 76);
			#### # 1 Offset(50, 86);
			Stop;
		RaiseLeft:
			VPRG # 0 A_WeaponBusy(false);
			#### # 1 Offset(-50, 86);
			#### # 1 Offset(-34, 76);
			#### # 1 Offset(-20, 60);
			#### # 1 Offset(-12, 48);
			#### # 1 Offset(-6, 38);
			Stop;
		RaiseRight:
			VP2G # 0 A_WeaponBusy(false);
			#### # 1 Offset(50, 86);
			#### # 1 Offset(34, 76);
			#### # 1 Offset(20, 60);
			#### # 1 Offset(12, 48);
			#### # 1 Offset(6, 38);
			Stop;
		WhyAreYouSmiling:
			#### A 0 A_WeaponBusy(true);
			#### # 1 Offset(0, 48);
			#### # 1 Offset(0, 60);
			#### # 1 Offset(0, 76);
			TNT1 A 7;
			TNT1 A 0
			{
				invoker.wronghand = !invoker.wronghand;
				A_CheckViperHand();
			}
			#### # 1 Offset(0, 76);
			#### # 1 Offset(0, 60);
			#### # 1 Offset(0, 48);
			Goto Nope;
	}
}

class ViperRandom : IdleDummy
{
	States
	{
		Spawn:
			TNT1 A 0 NoDelay
			{
				A_SpawnItemEx("HDViperMag", -3, flags: SXF_NOCHECKPOSITION);
				A_SpawnItemEx("HDViperMag", -1, flags: SXF_NOCHECKPOSITION);
				let wpn = HDViper(Spawn("HDViper", pos, ALLOW_REPLACE));
				if (!wpn)
				{
					return;
				}

				HDF.TransferSpecials(self, wpn);
				if (!random(0, 3))
				{
					wpn.WeaponStatus[wpn.VPProp_Flags] |= wpn.VPF_HeavyFrame;
				}
				if (!random(0, 3))
				{
					wpn.WeaponStatus[wpn.VPProp_Flags] |= wpn.VPF_ExtendedBarrel;
				}
				wpn.InitializeWepStats(false);
			}
			Stop;
	}
}

class HDViperMag : HDMagAmmo
{
	override string, string, name, double GetMagSprite(int thismagamt)
	{
		return (thismagamt > 0) ? "VPMGA0" : "VPMGB0", "PRNDA0", "HD50AEAmmo", 1.25;
	}

	override void GetItemsThatUseThis()
	{
		ItemsThatUseThis.Push("HDViper");
	}

	const EncMag = 12;
	const EncMagEmpty = EncMag * 0.6;
	const EncMagLoaded = EncMag * 0.2;

	Default
	{
		HDMagAmmo.MaxPerUnit 7;
		HDMagAmmo.InsertTime 9;
		HDMagAmmo.ExtractTime 6;
		HDMagAmmo.RoundType "HD50AEAmmo";
		HDMagAmmo.RoundBulk HD50AEAmmo.EncRoundLoaded;
		HDMagAmmo.MagBulk EncMagEmpty;
		Tag ".50 AE magazine";
		Inventory.PickupMessage "Picked up a .50 AE Viper magazine.";
		HDPickup.RefId "50m";
	}

	States
	{
		Spawn:
			VPMG A -1;
			Stop;
		SpawnEmpty:
			VPMG B -1
			{
				bROLLSPRITE = true;
				bROLLCENTER = true;
				roll = randompick(0, 0, 0, 0, 2, 2, 2, 2, 1, 3) * 90;
			}
			Stop;
	}
}
