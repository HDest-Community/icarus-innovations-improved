version "4.8"

class Six12Handler : EventHandler
{
	override void CheckReplacement(ReplaceEvent e)
	{
		if (!e.Replacement)
		{
			return;
		}

		switch (e.Replacement.GetClassName())
		{
			case 'ShotgunReplaces':
				if (random[sxtwlvrand]() <= 32)
				{
					e.Replacement = "Six12Random";
				}
				break;
			case 'SSGReplaces':
				if (random[sxtwlvrand]() <= 48)
				{
					e.Replacement = "Six12Random";
				}
				break;
			case 'ShellRandom':
				if (random[sxtwlvrand]() <= 16)
				{
					e.Replacement = "HDSix12MagSlugs";
				}
				break;
			case 'ShellRandom':
				if (random[sxtwlvrand]() <= 16)
				{
					e.Replacement = "HDSix12MagShells";
				}
				break;
		}
	}

	override void WorldThingSpawned(WorldEvent e)
	{
		let Six12Ammo = HDAmmo(e.Thing);
		if (!Six12Ammo)
		{
			return;
		}
		if (Six12Ammo.GetClassName() == 'HDSlugAmmo')
		{
			Six12Ammo.ItemsThatUseThis.Push("HDSix12");
		}
		if (Six12Ammo.GetClassName() == 'HDShellAmmo')
		{
			Six12Ammo.ItemsThatUseThis.Push("HDSix12");
		}
	}
}

class HDSix12 : HDWeapon
{
	enum Six12Flags
	{
		STF_JustUnload = 1
	}

	enum Six12Properties
	{
		STProp_Flags,
		STProp_Mag,
		STProp_MagType,
		STProp_LoadType,
		STProp_SpentShells
	}

	override void PostBeginPlay()
	{
		weaponspecial = 1337; // [Ace] UaS sling compatibility.
		Super.PostBeginPlay();
	}

	override bool AddSpareWeapon(actor newowner) { return AddSpareWeaponRegular(newowner); }
	override HDWeapon GetSpareWeapon(actor newowner, bool reverse, bool doselect) { return GetSpareWeaponRegular(newowner, reverse, doselect); }
	override double GunMass()
	{
		double RndMass = WeaponStatus[STProp_MagType] == 0 ? 0.04 : 0.06;
		double MagMass = WeaponStatus[STProp_MagType] == 0 ? HDSix12MagShells.EncMagLoaded * 0.1 : HDSix12MagSlugs.EncMagLoaded * 0.1;
		return 6 + (WeaponStatus[STProp_Mag] > -1 ? MagMass + RndMass * WeaponStatus[STProp_Mag] : 0);
	}

	override double WeaponBulk()
	{
		double BaseBulk = 125;
		int Mag = WeaponStatus[STProp_Mag];
		if (Mag >= 0)
		{
			BaseBulk += (WeaponStatus[STProp_MagType] == 0 ? HDSix12MagShells.EncMagLoaded : HDSix12MagSlugs.EncMagLoaded) + Mag * ENC_SHELLLOADED;
		}
		return BaseBulk;
	}
	
	override string, double GetPickupSprite()
	{
		string PrimMagFrame = WeaponStatus[STProp_MagType] == 0 ? "B" : "S";
		string SecMagFrame = WeaponStatus[STProp_Mag] == -1 ? "E" : "F";
		return "ST"..PrimMagFrame..SecMagFrame.."A0", 1.0;
	}
	override void LoadoutConfigure(string input)
	{
		if (GetLoadoutVar(input, "slugs", 1) > 0)
		{
			WeaponStatus[STProp_MagType] = 1;
		}

		InitializeWepStats(false);
	}
	override void InitializeWepStats(bool idfa)
	{
		WeaponStatus[STProp_Mag] = WeaponStatus[STProp_MagType] == 0 ? HDSix12MagShells.MagCapacity : HDSix12MagSlugs.MagCapacity;
	}

	override string GetHelpText()
	{
		return WEPHELP_FIRE.. "  Fire Weapon\n"
		..WEPHELP_RELOAD.."  Load Shell Magazine\n"
		..WEPHELP_ALTRELOAD.."  Load Slug Magazine\n"
		..WEPHELP_UNLOAD.. "  Unload loaded Magazine\n"
		..WEPHELP_MAGMANAGER.. "  Shell Mags\n"
		.."("..WEPHELP_USE..")+"..WEPHELP_MAGMANAGER.. "  Slug Mags\n";
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		if (sb.hudlevel == 1)
		{
			int NextShellMag = sb.GetNextLoadMag(HDMagAmmo(hpl.FindInventory("HDSix12MagShells")));
			if (NextShellMag > 0)
			{
				sb.DrawImage("STMBA0", (-45, -10),sb. DI_SCREEN_CENTER_BOTTOM, scale: (1.25, 1.25));
			}
			else
			{
				sb.DrawImage("STMBB0", (-45, -10), sb.DI_SCREEN_CENTER_BOTTOM, alpha: NextShellMag ? 0.6 : 1.0, scale: (1.25, 1.25));
			}
			sb.DrawNum(hpl.CountInv("HDSix12MagShells"), -44, -8, sb.DI_SCREEN_CENTER_BOTTOM); 

			int NextSlugMag = sb.GetNextLoadMag(HDMagAmmo(hpl.FindInventory("HDSix12MagSlugs")));
			if (NextSlugMag > 0)
			{
				sb.DrawImage("STMSA0", (-62, -10),sb. DI_SCREEN_CENTER_BOTTOM, scale: (1.25, 1.25));
			}
			else
			{
				sb.DrawImage("STMSB0", (-62, -10), sb.DI_SCREEN_CENTER_BOTTOM, alpha: NextSlugMag ? 0.6 : 1.0, scale: (1.25, 1.25));
			}
			sb.DrawNum(hpl.CountInv("HDSix12MagSlugs"), -60, -8, sb.DI_SCREEN_CENTER_BOTTOM);
		}
		
		if (hdw.WeaponStatus[STProp_Mag] >= 0)
		{
			vector2 CylinderPos = (0, 0);
			for (int i = 0; i < 6; ++i)
			{
				double DrawAngle = i * (360.0 / 6.0) - 180;
				vector2 DrawPos = CylinderPos + (sin(drawangle), cos(DrawAngle)) * 7;
				Color ShellCol = WeaponStatus[STProp_MagType] == 0 ? Color(255, 167, 0, 0) : Color(255, 0, 165, 215);
				sb.Fill(hdw.WeaponStatus[STProp_Mag] > i ? ShellCol : Color(200, 30, 26, 24), DrawPos.x -28, DrawPos.y -21, 4,4, sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_RIGHT);
			}
		}
	}
	
	override void DrawSightPicture(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl, bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot)
	{
		int cx, cy, cw, ch;
		[cx, cy, cw, ch] = Screen.GetClipRect();
		sb.SetClipRect(-16 + bob.x, -8 + bob.y, 32, 16, sb.DI_SCREEN_CENTER);
		vector2 bob2 = bob * 2;
		bob2.y = clamp(bob2.y, -8, 8);
		sb.DrawImage("STLVFRNT", bob2, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, alpha: 0.9, scale: (0.6, 0.6));
		sb.SetClipRect(cx, cy, cw, ch);
		sb.DrawImage("STLVBACK", bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, scale: (0.9, 0.8));
	}

	override void DropOneAmmo(int amt)
	{
		if (owner)
		{
			double OldAngle = owner.angle;

			amt = clamp(amt, 1, 10);
			if (owner.CheckInventory("HDSlugAmmo", 1))
			{
				owner.A_DropInventory("HDSlugAmmo", amt * 4);
				owner.angle += 15;
			}
			else
			{
				owner.A_DropInventory("HDSix12MagSlugs", amt);
				owner.angle += 15;
			}

			if (owner.CheckInventory("HDShellAmmo", 1))
			{
				owner.A_DropInventory("HDShellAmmo", amt * 4);
			}
			else
			{
				owner.A_DropInventory("HDSix12MagShells", amt);
			}

			owner.angle = OldAngle;
		}
	}

	Default
	{
		+HDWEAPON.FITSINBACKPACK
		Weapon.SelectionOrder 300;
		Weapon.SlotNumber 3;
		Weapon.SlotPriority 3;
		HDWeapon.BarrelSize 24, 1, 2;
		Scale 0.5;
		Tag "Six12 Shotgun";
		HDWeapon.Refid "612";
		Inventory.PickupMessage "You picked up the Six12 Shotgun";
		HDWeapon.Loadoutcodes "
			\cuslugs - Loaded with Slug Mag";
	}

	States
	{
		RegisterSprites:
			STBE A 0; STBF A 0; STSE A 0; STSF A 0;

		Spawn:
			STBF A 0 NoDelay
			{
				string PrimMagFrame = invoker.WeaponStatus[STProp_MagType] == 0 ? "B" : "S";
				string SecMagFrame = invoker.WeaponStatus[STProp_Mag] == -1 ? "E" : "F";
				sprite = GetSpriteIndex("ST"..PrimMagFrame..SecMagFrame);
			}
		RealSpawn:
			#### A -1;
			Stop;
		Ready:
			STLG A 1 A_WeaponReady(WRF_ALLOWRELOAD | WRF_ALLOWUSER3 | WRF_ALLOWUSER1 | WRF_ALLOWUSER4);
			Goto ReadyEnd;
		Select0:
			STLG A 0;
			Goto Select0Big;
		Deselect0:
			STLG A 0;
			Goto Deselect0Big;
		User3:
			STLG A 0 A_MagManager(PressingUse() ? "HDSix12MagSlugs" : "HDSix12MagShells");
			Goto Ready;

		Fire:
			STLG A 0
			{
				int Mag = invoker.WeaponStatus[STProp_Mag];
				if (Mag > 0)
				{
					SetWeaponState("RealFire");
					return;
				}
			}
			Goto Nope;
		RealFire:
			STLG A 2;
			STLF A 1 Offset(0, 35) Bright
			{
				int MType = invoker.WeaponStatus[STProp_MagType];
				if (MType == 0)
				{
					Hunter.Fire(self, 7);
				}
				else
				{
					HDBulletActor.FireBullet(self, "HDB_SLUG", speedfactor: 1.15);
				}
				invoker.WeaponStatus[STProp_SpentShells]++;
				invoker.WeaponStatus[STProp_Mag]--;
				A_AlertMonsters();
				A_StartSound("Six12/Fire", CHAN_WEAPON, pitch: (MType == 0 ? 0.9 : 1.0));
				A_ZoomRecoil(0.995);
				A_MuzzleClimb(-frandom(1, 1.2), -frandom(1.5, 2.0), -frandom(1, 1.2), -frandom(1.5, 2.0));
				A_Light1();
			}
			STLG A 2
			{
				if (invoker.WeaponStatus[STProp_Mag] <= 0)
				{
					SetWeaponState("Nope");
				}
				else
				{
					A_Light0();
				}
			}
			Goto Hold;
		Hold:
			STLG A 1;
			STLG A 0 A_Refire();
			Goto Ready;
			
		Unload:
			STLG A 0
			{
				invoker.WeaponStatus[STProp_Flags] |= STF_JustUnload;
				if (invoker.WeaponStatus[STProp_Mag] >= 0)
				{
					SetWeaponState("UnMag");
				}
			}
			Goto Nope;

		Reload:
		AltReload:
			STLG A 0
			{
				invoker.WeaponStatus[STProp_Flags] &= ~STF_JustUnload;
				
				int loadType = invoker.WeaponStatus[STProp_LoadType] = !PressingAltReload() ? 0 : 1;
				bool noMags = HDMagAmmo.NothingLoaded(self, loadType == 0 ? 'HDSix12MagShells' : 'HDSix12MagSlugs');
				if (loadType == 0 && noMags)
				{
					loadType = invoker.WeaponStatus[STProp_LoadType] = 1;
					noMags = HDMagAmmo.NothingLoaded(self, 'HDSix12MagSlugs');
					if (noMags)
					{
						SetWeaponState('Nope');
						return;
					}
				}

				int curMagType = invoker.WeaponStatus[STProp_MagType];
				int magAmt = invoker.WeaponStatus[STProp_Mag];

				if (loadType == curMagType && magAmt >= (loadType == 0 ? HDSix12MagShells.MagCapacity : HDSix12MagSlugs.MagCapacity))
				{
					SetWeaponState('Nope');
				}
			}
			Goto UnMag;

		UnMag:
			STLG A 2 Offset(0, 34);
			STLG A 2 Offset(5, 38);
			STLG A 2 Offset(10, 42);
			STLG A 4 Offset(20, 46)
			{
				A_StartSound("Six12/MagOut", 8);
				A_MuzzleClimb(0.3, 0.4);
			}
			STLG A 2 Offset(26, 52) A_MuzzleClimb(0.3, 0.4);
			STLG A 2 Offset(26, 54) A_MuzzleClimb(0.3, 0.4);
			STLG A 0
			{
				int MagAmount = invoker.WeaponStatus[STProp_Mag];
				if (MagAmount == -1)
				{
					SetWeaponState("MagOut");
					return;
				}

				int MType = invoker.WeaponStatus[STProp_MagType];
				invoker.WeaponStatus[STProp_Mag] = -1;

				// [Ace] Dump out all the spent shells.
				for (int i = 0; i < invoker.WeaponStatus[STProp_SpentShells]; ++i)
				{
					A_SpawnItemEx(MType == 0 ? 'HDSpentShell' : 'HDSpentSlug', 6 * cos(pitch), 0, height / 2 + 6, vel.x + frandom(-0.5, 0.5), 0.5 + vel.y + frandom(-0.5, 0.5), vel.z, 0, SXF_ABSOLUTEVELOCITY | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH);
				}
				invoker.WeaponStatus[STProp_SpentShells] = 0;

				class<HDMagAmmo> WhichMag = MType == 0 ? 'HDSix12MagShells' : 'HDSix12MagSlugs';
				if ((!PressingUnload() && !PressingReload() && !PressingAltReload()) || A_JumpIfInventory(WhichMag, 0, "Null"))
				{
					HDMagAmmo.SpawnMag(self, WhichMag, MagAmount);
					SetWeaponState("MagOut");
				}
				else
				{
					HDMagAmmo.GiveMag(self, WhichMag, MagAmount);
					A_StartSound("weapons/pocket", 9);
					SetWeaponState("PocketMag");
				}
			}
		PocketMag:
			STLG AAAAAA 5 Offset(30, 54) A_MuzzleClimb(frandom(0.2, -0.8),frandom(-0.2, 0.4));
		MagOut:
			STLG A 0
			{
				if (invoker.WeaponStatus[STProp_Flags] & STF_JustUnload)
				{
					SetWeaponState("ReloadEnd");
				}
			}
		LoadMag:
			STLG A 0 A_StartSound("weapons/pocket", 9);
			STLG A 6 offset(32, 55) A_MuzzleClimb(frandom(0.2, -0.8), frandom(-0.2, 0.4));
			STLG A 7 offset(32, 52) A_MuzzleClimb(frandom(0.2, -0.8), frandom(-0.2, 0.4));
			STLG A 10 offset(30, 50);
			STLG A 3 offset(30, 49)
			{
				int LType = invoker.WeaponStatus[STProp_LoadType];
				class<HDMagAmmo> WhichMag = (LType == 0 ? 'HDSix12MagShells' : 'HDSix12MagSlugs');
				let Mag = HDMagAmmo(FindInventory(WhichMag));
				if (Mag)
				{
					invoker.WeaponStatus[STProp_Mag] = Mag.TakeMag(true);
					invoker.WeaponStatus[STProp_MagType] = LType;
					A_StartSound("Six12/MagIn", 8, CHANF_OVERLAP);
				}
			}
			Goto ReloadEnd;

		ReloadEnd:
			STLG A 4 Offset(30, 52);
			STLG A 3 Offset(20, 46);
			STLG A 2 Offset(10, 42);
			STLG A 2 Offset(5, 38);
			STLG A 1 Offset(0, 34);
			Goto Ready;
	}
}

class Six12Random : IdleDummy
{
	States
	{
		Spawn:
			TNT1 A 0 NoDelay
			{
				A_SpawnItemEx("HDSix12MagShells", -3,flags: SXF_NOCHECKPOSITION);
				A_SpawnItemEx("HDSix12MagSlugs", 6,flags: SXF_NOCHECKPOSITION);
				let wpn = HDSix12(Spawn("HDSix12", pos, ALLOW_REPLACE));
				if (!wpn)
				{
					return;
				}

				HDF.TransferSpecials(self, wpn);
				
				wpn.WeaponStatus[wpn.STProp_MagType] = randompick[sxtwlvrand](0, 0, 0, 1);
				
				wpn.InitializeWepStats(false);
			}
			Stop;
	}
}


class HDSix12MagShells : HDMagAmmo
{
	override string, string, name, double GetMagSprite(int thismagamt)
	{
		string magsprite;
		if(thismagamt==6)magsprite="STMBI0";
		else if(thismagamt==5)magsprite="STMBH0";
		else if(thismagamt==4)magsprite="STMBG0";
		else if(thismagamt==3)magsprite="STMBF0";
		else if(thismagamt==2)magsprite="STMBE0";
		else if(thismagamt==1)magsprite="STMBD0";
		else magsprite="STMBC0";
		return magsprite,"SHL1A0","HDShellAmmo",0.5;
	}

	override void GetItemsThatUseThis()
	{
		ItemsThatUseThis.Push("HDSix12");
	}

	const MagCapacity = 6;
	const EncMagEmpty = 10;
	const EncMagLoaded = EncMagEmpty * 0.9;

	Default
	{
		HDMagAmmo.MaxPerUnit MagCapacity;
		HDMagAmmo.InsertTime 10;
		HDMagAmmo.ExtractTime 8;
		HDMagAmmo.RoundType "HDShellAmmo";
		HDMagAmmo.RoundBulk ENC_SHELLLOADED;
		HDMagAmmo.MagBulk EncMagEmpty;
		Tag "Six12 Shell Mag";
		Inventory.PickupMessage "Picked up a Six12 Shell Magazine.";
		HDPickup.RefId "6sh";
		Scale 0.5;
	}

	States
	{
		Spawn:
			STMB A -1;
			Stop;
		SpawnEmpty:
			STMB B -1
			{
				bROLLSPRITE = true;
				bROLLCENTER = true;
				roll = randompick(0, 0, 0, 0, 2, 2, 2, 2, 1, 3) * 90;
			}
			Stop;
	}
}

class HDSix12MagSlugs : HDMagAmmo
{
	override string, string, name, double GetMagSprite(int thismagamt)
	{
		string magsprite;
		if(thismagamt==6)magsprite="STMSI0";
		else if(thismagamt==5)magsprite="STMSH0";
		else if(thismagamt==4)magsprite="STMSG0";
		else if(thismagamt==3)magsprite="STMSF0";
		else if(thismagamt==2)magsprite="STMSE0";
		else if(thismagamt==1)magsprite="STMSD0";
		else magsprite="STMSC0";
		return magsprite,"SLG1A0","HDSlugAmmo",0.5;
	}

	override void GetItemsThatUseThis()
	{
		ItemsThatUseThis.Push("HDSix12");
	}

	const MagCapacity = 6;
	const EncMagEmpty = 15;
	const EncMagLoaded = EncMagEmpty * 0.9;

	Default
	{
		HDMagAmmo.MaxPerUnit MagCapacity;
		HDMagAmmo.InsertTime 10;
		HDMagAmmo.ExtractTime 8;
		HDMagAmmo.RoundType "HDSlugAmmo";
		HDMagAmmo.RoundBulk ENC_SHELLLOADED;
		HDMagAmmo.MagBulk EncMagEmpty;
		Tag "Six12 Slug Mag";
		Inventory.PickupMessage "Picked up a Six12 Slug Magazine";
		HDPickup.RefId "6sl";
		Scale 0.5;
	}

	States
	{
		Spawn:
			STMS A -1;
			Stop;
		SpawnEmpty:
			STMS B -1
			{
				bROLLSPRITE = true;
				bROLLCENTER = true;
				roll = randompick(0, 0, 0, 0, 2, 2, 2, 2, 1, 3) * 90;
			}
			Stop;
	}
}