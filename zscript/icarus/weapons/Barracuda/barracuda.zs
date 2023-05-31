class HDBarracuda : HDSix12
{
	enum BarracudaFlags
	{
		BRF_JustUnload = 1,
		BRF_Double = 2
	}

	enum BarracudaProperties
	{
		BRProp_Flags,
		BRProp_MagLeft,
		BRProp_MagRight,
		BRProp_MagType,
		BRProp_LoadType,
		BRProp_OpSide,
		BRProp_SpentShellsLeft,
		BRProp_SpentShellsRight
	}

	override double GunMass()
	{
		double TotalMass;
		for (int i = 0; i <= 1; ++i)
		{
			double RndMass = WeaponStatus[BRProp_MagType] & (1 << i) ? 0.06 : 0.04;
			double MagMass = WeaponStatus[BRProp_MagType] & (1 << i) ? HDSix12MagSlugs.EncMagLoaded * 0.1 : HDSix12MagShells.EncMagLoaded * 0.1;
			TotalMass += WeaponStatus[BRProp_MagLeft + i] > -1 ? MagMass + RndMass * WeaponStatus[BRProp_MagLeft + i] : 0;
		}
		return 5 + TotalMass;
	}
	
	override double WeaponBulk()
	{
		double BaseBulk = 110;
		for (int i = 0; i <= 1; ++i)
		{
			int Mag = WeaponStatus[BRProp_MagLeft + i];
			if (Mag >= 0)
			{
				BaseBulk += (WeaponStatus[BRProp_MagType] & (1 << i) ? HDSix12MagSlugs.EncMagLoaded : HDSix12MagShells.EncMagLoaded) + Mag * ENC_SHELLLOADED;
			}
		}
		return BaseBulk;
	}

	// [Ace] Used only for MagType and LoadType.
	private action void A_SetMagType(int which, bool slugs)
	{
	    if (slugs)
	    {
	        invoker.WeaponStatus[BRProp_MagType] |= 1 << which;
	    }
	    else
	    {
	        invoker.WeaponStatus[BRProp_MagType] &= ~(1 << which);
	    }
	}
	
	override string, double GetPickupSprite()
	{
		string LeftMag = "A";
		string RightMag = "A";
		if (WeaponStatus[BRProp_MagRight] == -1)
		{
			if (WeaponStatus[BRProp_MagLeft] > -1)
			{
				LeftMag = WeaponStatus[BRProp_MagType] & 1 ? "S" : "B";
			}
		}
		else
		{
			RightMag = WeaponStatus[BRProp_MagType] & 2 ? "S" : "B";
		}
		return "BS"..RightMag..LeftMag.."A0", 1.0;
	}
	override void LoadoutConfigure(string input)
	{
		if (GetLoadoutVar(input, "lslugs", 1) > 0)
		{
			A_SetMagType(0, true);
		}

		if (GetLoadoutVar(input, "rslugs", 1) > 0)
		{
			A_SetMagType(1, true);
		}

		InitializeWepStats(false);
	}
	override void InitializeWepStats(bool idfa)
	{
		WeaponStatus[BRProp_MagLeft] = WeaponStatus[BRProp_MagType] & 1 ? HDSix12MagSlugs.MagCapacity : HDSix12MagShells.MagCapacity;
		WeaponStatus[BRProp_MagRight] = WeaponStatus[BRProp_MagType] & 2 ? HDSix12MagSlugs.MagCapacity : HDSix12MagShells.MagCapacity;
	}

	override string GetHelpText()
	{
		return WEPHELP_FIRE.. "  Fire Weapon\n"
		..WEPHELP_FIREMODE.."  Hold to force double shot\n"
		..WEPHELP_RELOAD.."  Load Shell Magazine (Left Side)\n"
		..WEPHELP_ALTRELOAD.."  Load Slug Magazine (Left Side)\n"
		..WEPHELP_USE.."+"..WEPHELP_RELOAD.."  Load Shell Magazine (Right Side)\n"
		..WEPHELP_USE.."+"..WEPHELP_ALTRELOAD.."  Load Slug Magazine (Right Side)\n"
		..WEPHELP_UNLOAD.. "  Unload Left Magazine\n"
		..WEPHELP_USE.."+"..WEPHELP_UNLOAD.."  Unload Right Magazine\n"
		..WEPHELP_USER3.. "  Mag Manager (Shell Mags)\n"
		..WEPHELP_USE.."+"..WEPHELP_USER3.. "  Mag Manager (Slug Mags)";
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		if (sb.hudlevel == 1)
		{
			int NextShellMag = sb.GetNextLoadMag(HDMagAmmo(hpl.FindInventory("HDSix12MagShells")));
			if (NextShellMag > 0)
			{
				sb.DrawImage("STMBA0", (-27, -10),sb. DI_SCREEN_CENTER_BOTTOM, scale: (1.25, 1.25));
			}
			else
			{
				sb.DrawImage("STMBB0", (-27, -10), sb.DI_SCREEN_CENTER_BOTTOM, alpha: NextShellMag ? 0.6 : 1.0, scale: (1.25, 1.25));
			}
			sb.DrawNum(hpl.CountInv("HDSix12MagShells"), -24, -8, sb.DI_SCREEN_CENTER_BOTTOM); 

			int NextSlugMag = sb.GetNextLoadMag(HDMagAmmo(hpl.FindInventory("HDSix12MagSlugs")));
			if (NextSlugMag > 0)
			{
				sb.DrawImage("STMSA0", (-47, -10),sb. DI_SCREEN_CENTER_BOTTOM, scale: (1.25, 1.25));
			}
			else
			{
				sb.DrawImage("STMSB0", (-47, -10), sb.DI_SCREEN_CENTER_BOTTOM, alpha: NextSlugMag ? 0.6 : 1.0, scale: (1.25, 1.25));
			}
			sb.DrawNum(hpl.CountInv("HDSix12MagSlugs"), -44, -8, sb.DI_SCREEN_CENTER_BOTTOM);
		}

		for (int side = 0; side <= 1; ++side)
		{
			if (WeaponStatus[BRProp_MagLeft + side] >= 0)
			{
				vector2 CylinderPos = (0, 0);
				for (int i = 0; i < 6; ++i)
				{
					double DrawAngle = i * (360.0 / 6.0) + (side == 0 ? 90 : -30);
					vector2 DrawPos = CylinderPos + (sin(drawangle), cos(DrawAngle)) * 7;
					Color ShellCol = WeaponStatus[BRProp_MagType] & (1 << side) ? Color(255, 0, 165, 215) : Color(255, 167, 0, 0);

					int Mag = WeaponStatus[BRProp_MagLeft + side];
					sb.Fill((side == 0 ? Mag > i : Mag >= 6 - i) ? ShellCol : Color(200, 30, 26, 24), DrawPos.x - (48 - 20 * side), DrawPos.y - 35, 4,4, sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_RIGHT);
				}
			}
		}
		
		if (WeaponStatus[BRProp_Flags] & BRF_Double)
		{
			sb.DrawImage("STBURAUT", (-36, -37), sb.DI_SCREEN_CENTER_BOTTOM);
		}
	}
	override void DrawSightPicture(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl, bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot)
	{
		int cx, cy, cw, ch;
		[cx, cy, cw, ch] = Screen.GetClipRect();
		sb.SetClipRect(-16 + bob.x, -8 + bob.y, 32, 16, sb.DI_SCREEN_CENTER);
		vector2 bob2 = bob * 2;
		bob2.y = clamp(bob2.y, -8, 8);
		sb.DrawImage("FRNTSITE", bob2, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, alpha: 0.9, scale: (1.0, 0.6));
		sb.SetClipRect(cx, cy, cw, ch);
		sb.DrawImage("STLVBACK", bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, scale: (0.7, 0.7));
	}

	protected action void A_BarracudaFire(int barrel)
	{
		invoker.HasFired = true;
		A_AlertMonsters();
		A_Light1();
		A_ZoomRecoil(0.995);	
		DistantNoise.Make(self, "world/shotgunfar");
		let psp = player.GetPSprite(PSP_WEAPON);
		if (barrel & 1)
		{
			psp.frame = 0;
			A_MuzzleClimb(-frandom(1.15, 1.4), -frandom(1.7, 2.2), -frandom(1.15, 1.4), -frandom(1.7, 2.2));
			if (invoker.WeaponStatus[BRProp_MagType] & 1)
			{
				HDBulletActor.FireBullet(self, "HDB_SLUG", speedfactor: 1.15);
				A_StartSound("Six12/Fire", CHAN_WEAPON, CHANF_OVERLAP);
			}
			else
			{
				Hunter.Fire(self, 7);
				A_StartSound("Six12/Fire", CHAN_WEAPON, CHANF_OVERLAP, pitch: 0.9);
			}
			invoker.WeaponStatus[BRProp_MagLeft]--;
			invoker.WeaponStatus[BRProp_SpentShellsLeft]++;
			
		}
		if (barrel & 2)
		{
			psp.frame = 1;
			A_MuzzleClimb(frandom(1.15, 1.4), -frandom(1.7, 2.2), frandom(1.15, 1.4), -frandom(1.7, 2.2));
			if (invoker.WeaponStatus[BRProp_MagType] & 2)
			{
				HDBulletActor.FireBullet(self, "HDB_SLUG", speedfactor: 1.15);
				A_StartSound("Six12/Fire", CHAN_WEAPON, CHANF_OVERLAP);
			}
			else
			{
				Hunter.Fire(self, 7);
				A_StartSound("Six12/Fire", CHAN_WEAPON, CHANF_OVERLAP, pitch: 0.9);
			}
			invoker.WeaponStatus[BRProp_MagRight]--;
			invoker.WeaponStatus[BRProp_SpentShellsRight]++;
		}
		if (barrel & 1 && barrel & 2)
		{
			psp.frame = 2;
		}
	}
	
	private transient CVar SwapBarrels;
	private transient bool HasFired;

	Default
	{
		Weapon.SelectionOrder 300;
		Weapon.SlotNumber 3;
		Weapon.SlotPriority 3;
		HDWeapon.BarrelSize 24, 1, 2;
		Scale 0.5;
		Tag "Barracuda";
		HDWeapon.Refid "ace";
		Inventory.PickupMessage "You picked up the Barracuda. Watch out. It's got a bite!";
		HDWeapon.Loadoutcodes "
			\culslugs - Left Magzine loaded with Slugs
			\curslugs - Right Magazine loaded with Slugs";
	}

	States
	{
		RegisterSprites:
			BSAA A 0; BSBA A 0; BSSA A 0; BSAB A 0; BSAS A 0;

		Spawn:
			BSAB A 0 NoDelay
			{
				string LeftMag = "A";
				string RightMag = "A";
				if (invoker.WeaponStatus[BRProp_MagRight] == -1)
				{
					if (invoker.WeaponStatus[BRProp_MagLeft] > -1)
					{
						LeftMag = invoker.WeaponStatus[BRProp_MagType] & 1 ? "S" : "B";
					}
				}
				else
				{
					RightMag = invoker.WeaponStatus[BRProp_MagType] & 2 ? "S" : "B";
				}
				sprite = GetSpriteIndex("BS"..LeftMag..RightMag);
			}
		RealSpawn:
			#### A -1;
			Stop;
		Ready:
			BRCG A 1 A_WeaponReady(WRF_ALLOWRELOAD | WRF_ALLOWUSER3 | WRF_ALLOWUSER1 | WRF_ALLOWUSER4);
			Goto ReadyEnd;
		Select0:
			BRCG A 0;
			Goto Select0Big;
		Deselect0:
			BRCG A 0;
			Goto Deselect0Big;
		User3:
			BRCG A 0 A_MagManager(PressingUse() ? "HDSix12MagSlugs" : "HDSix12MagShells");
			Goto Ready;

		Fire:
		AltFire:
			BRCG # 0 A_ClearRefire();
		Ready:
			BRCG # 1
			{
				if (PressingFiremode())
				{
					invoker.WeaponStatus[BRProp_Flags] |= BRF_Double;
				}
				else 
				{
					invoker.WeaponStatus[BRProp_Flags] &= ~BRF_Double;
				}

				if (!invoker.HasFired)
				{
					// [Ace] Copy pasted from the Sledge.
					if (invoker.WeaponStatus[BRProp_Flags] & BRF_Double && (PressingFire() || PressingAltfire()))
					{
						if (invoker.WeaponStatus[BRProp_MagLeft] > 0 && invoker.WeaponStatus[BRProp_MagRight] > 0)
						{
							SetWeaponState('ShootBoth');
							return;
						}
						else if (invoker.WeaponStatus[BRProp_MagLeft] > 0)
						{
							SetWeaponState('ShootLeft');
							return;
						}
						else if (invoker.WeaponStatus[BRProp_MagRight] > 0)
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
					if ((!Swap && PressingFire() || Swap && PressingAltfire()) && invoker.WeaponStatus[BRProp_MagLeft] > 0)
					{
						SetWeaponState('ShootLeft');
						return;
					}
					if ((!Swap && PressingAltFire() || Swap && PressingFire()) && invoker.WeaponStatus[BRProp_MagRight] > 0)
					{
						SetWeaponState('ShootRight');
						return;
					}
				}
				else if (!PressingFire() && !PressingAltfire())
				{
					invoker.HasFired = false;
				}

				A_WeaponReady((WRF_ALL | WRF_NOFIRE) & ~WRF_ALLOWUSER2);
			}
			Goto ReadyEnd;
		ShootLeft:
			BRCF # 2 Bright A_BarracudaFire(1);
			BRCG A 2 Offset(0, 40);
			Goto Ready;
		ShootRight:
			BRCF # 2 Bright A_BarracudaFire(2);
			BRCG A 2 Offset(0, 40);
			Goto Ready;
		ShootBoth:
			BRCF # 2 Bright A_BarracudaFire(3);
			BRCG A 2 Offset(0, 48);
			Goto Ready;

		Unload:
			BRCG A 0
			{
				invoker.WeaponStatus[BRProp_Flags] |= BRF_JustUnload;
				if (!PressingUse() && invoker.WeaponStatus[BRProp_MagLeft] >= 0)
				{
					invoker.WeaponStatus[BRProp_OpSide] = 0;
					SetWeaponState("UnMag");
					return;
				}
				else if (PressingUse() && invoker.WeaponStatus[BRProp_MagRight] >= 0)
				{
					invoker.WeaponStatus[BRProp_OpSide] = 1;
					SetWeaponState("UnMag");
					return;
				}
			}
			Goto Nope;

		Reload:
		AltReload:
			BRCG A 0
			{
				invoker.WeaponStatus[BRProp_Flags] &= ~BRF_JustUnload;
				
				int Side = invoker.WeaponStatus[BRProp_OpSide] = PressingUse() ? 1 : 0;

				bool LoadSlugs = invoker.WeaponStatus[BRProp_LoadType] = PressingAltReload() ? 1 : 0;
				bool MagSlugs = invoker.WeaponStatus[BRProp_MagType] & (1 << Side);
				int Mag = invoker.WeaponStatus[BRProp_MagLeft + Side];
				bool NoMags = HDMagAmmo.NothingLoaded(self, LoadSlugs ? 'HDSix12MagSlugs' : 'HDSix12MagShells');

				if (NoMags || LoadSlugs == MagSlugs && Mag == (MagSlugs ? HDSix12MagSlugs.MagCapacity : HDSix12MagShells.MagCapacity))
				{
					SetWeaponState("Nope");
				}
			}
			Goto UnMag;

		UnMag:
			BRCG A 2 Offset(0, 34);
			#### A 2 Offset(5, 38);
			#### A 2 Offset(10, 42);
			#### A 4 Offset(20, 46)
			{
				A_StartSound("Six12/MagOut", 8);
				A_MuzzleClimb(0.3, 0.4);
			}
			#### A 2 Offset(26, 52) A_MuzzleClimb(0.3, 0.4);
			#### A 2 Offset(26, 54) A_MuzzleClimb(0.3, 0.4);
			#### A 0
			{
				int Side = invoker.WeaponStatus[BRProp_OpSide];
				int MagAmount = invoker.WeaponStatus[BRProp_MagLeft + Side];
				if (MagAmount == -1)
				{
					SetWeaponState("MagOut");
					return;
				}

				bool MagSlugs = invoker.WeaponStatus[BRProp_MagType] & (1 << Side);
				invoker.WeaponStatus[BRProp_MagLeft + Side] = -1;

				// [Ace] Dump out all the spent shells.
				while (invoker.WeaponStatus[BRProp_SpentShellsLeft + Side] > 0)
				{
					A_SpawnItemEx(MagSlugs ? 'HDSpentSlug' : 'HDSpentShell', 6 * cos(pitch), 0, height / 2 + 6, vel.x + frandom(-0.5, 0.5), 0.5 + vel.y + frandom(-0.5, 0.5), vel.z, 0, SXF_ABSOLUTEVELOCITY | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH);
					invoker.WeaponStatus[BRProp_SpentShellsLeft + Side]--;
				}

				class<HDMagAmmo> WhichMag = MagSlugs ? 'HDSix12MagSlugs' : 'HDSix12MagShells';
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
			BRCG AAAAAA 5 Offset(30, 54) A_MuzzleClimb(frandom(0.2, -0.8),frandom(-0.2, 0.4));
		MagOut:
			BRCG A 0
			{
				if (invoker.WeaponStatus[BRProp_Flags] & BRF_JustUnload)
				{
					SetWeaponState("ReloadEnd");
				}
			}
		LoadMag:
			BRCG A 0 A_StartSound("weapons/pocket", 9);
			#### A 6 Offset(32, 55) A_MuzzleClimb(frandom(0.2, -0.8), frandom(-0.2, 0.4));
			#### A 7 Offset(32, 52) A_MuzzleClimb(frandom(0.2, -0.8), frandom(-0.2, 0.4));
			#### A 10 Offset(30, 50);
			#### A 3 Offset(30, 49)
			{
				int Side = invoker.WeaponStatus[BRProp_OpSide];
				bool LoadSlugs = invoker.WeaponStatus[BRProp_LoadType];

				class<HDMagAmmo> WhichMag = (LoadSlugs ? 'HDSix12MagSlugs' : 'HDSix12MagShells');
				let Mag = HDMagAmmo(FindInventory(WhichMag));
				if (Mag)
				{
					invoker.WeaponStatus[BRProp_MagLeft + Side] = Mag.TakeMag(true);
					A_SetMagType(Side, LoadSlugs);
					A_StartSound("Six12/MagIn", 8, CHANF_OVERLAP);
				}
			}
			Goto ReloadEnd;

		ReloadEnd:
			BRCG A 4 Offset(30, 52);
			#### A 3 Offset(20, 46);
			#### A 2 Offset(10, 42);
			#### A 2 Offset(5, 38);
			#### A 1 Offset(0, 34);
			Goto Ready;
	}
}

class BarracudaRandom : IdleDummy
{
	States
	{
		Spawn:
			TNT1 A 0 NoDelay
			{
				A_SpawnItemEx("HDSix12MagShells", -3,flags: SXF_NOCHECKPOSITION);
				A_SpawnItemEx("HDSix12MagSlugs", 6,flags: SXF_NOCHECKPOSITION);
				let wpn = HDBarracuda(Spawn("HDBarracuda", pos, ALLOW_REPLACE));
				if (!wpn)
				{
					return;
				}
				
				HDF.TransferSpecials(self, wpn);
				
				wpn.WeaponStatus[wpn.BRProp_MagType] = randompick[sxtwlvrand](0, 0, 0, 1);
				
				wpn.InitializeWepStats(false);
			}
			Stop;
	}
}