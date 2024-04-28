class HDFenris : HDCellWeapon
{
	enum FenrisFlags
	{
		FNF_JustUnload = 1,
		FNF_PolyFrame = 2,
		FNF_Platinum = 4
	}

	enum FenrisProperties
	{
		FNProp_Flags,
		FNProp_Battery,
		FNProp_Charge,
		FNProp_Mode
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
		return WeaponStatus[FNProp_Battery] >= 0 ? 12 : 11
		+ (WeaponStatus[FNProp_Flags] & FNF_PolyFrame ? -2 : 0);
	}
	override double WeaponBulk()
	{
		return 175
		+ (WeaponStatus[FNProp_Battery] >= 0 ? ENC_BATTERY_LOADED : 0)
		+ (WeaponStatus[FNProp_Flags] & FNF_PolyFrame ? -30 : 0);
	}

	override string PickupMessage()
	{
		string FraStr = WeaponStatus[FNProp_Flags] & FNF_PolyFrame ? Stringtable.localize("$PICKUP_FENRIS_POLYFRAME") : "";
		string PlaStr = WeaponStatus[FNProp_Flags] & FNF_Platinum ? Stringtable.localize("$PICKUP_FENRIS_PLATINUM") : "";

		return Stringtable.localize("$PICKUP_FENRIS_PREFIX")..FraStr..Stringtable.localize("$TAG_FENRIS")..PlaStr..Stringtable.localize("$PICKUP_FENRIS_SUFFIX");
	}

	override string, double GetPickupSprite()
	{
		return WeaponStatus[FNProp_Battery] >= 0 ? "FNRSY0" : "FNRSZ0", 1.0;
	}

	override void InitializeWepStats(bool idfa)
	{
		WeaponStatus[FNProp_Battery] = WeaponStatus[FNProp_Flags] & FNF_Platinum ? 80 : 60;
	}

	override void LoadoutConfigure(string input)
	{
		if (GetLoadoutVar(input, "frame", 1) > 0)
		{
			WeaponStatus[FNProp_Flags] |= FNF_PolyFrame;
		}
		
		if (GetLoadoutVar(input, "plat", 1) > 0)
		{
			WeaponStatus[FNProp_Flags] |= FNF_Platinum;
		}
		
		InitializeWepStats(false);
	}

	override string GetHelpText()
	{
		return WEPHELP_FIRE.."  Shoot\n"
		..WEPHELP_ALTFIRE.." Launch Snowball\n"
		..WEPHELP_FIREMODE.."  Change Firemode\n"
		..WEPHELP_RELOAD.."  Load battery\n"
		..WEPHELP_UNLOAD.."  Unload battery";
	}

	protected clearscope int GetRealBatteryCharge(bool useUpper)
	{
		if (WeaponStatus[FNProp_Battery] == -1)
		{
			return -1;
		}
		double FracCharge = WeaponStatus[FNProp_Battery] / double(WeaponStatus[FNProp_Flags] & FNF_Platinum ? 4.0 : 3.0);
		return int(useUpper ? ceil(FracCharge) : floor(FracCharge));
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		if (sb.HudLevel == 1)
		{
			sb.DrawBattery(-54, -4, sb.DI_SCREEN_CENTER_BOTTOM, reloadorder: true);
			sb.DrawNum(hpl.CountInv("HDBattery"), -46, -8, sb.DI_SCREEN_CENTER_BOTTOM);
		}
		
		sb.DrawWepCounter(hdw.WeaponStatus[FNProp_Mode], -15, -15, "STFULAUT", "RBRSA3A7");
		
		int BatteryCharge = GetRealBatteryCharge(true);
		if (BatteryCharge > 0)
		{
			int BatPercent = int((WeaponStatus[FNProp_Battery] / (WeaponStatus[FNProp_Flags] & FNF_Platinum ? 80.0 : 60.0)) * 100);
			string Col = "\c[Green]";
			if (BatPercent < 25)
			{
				Col = "\c[Red]";
			}
			else if (BatPercent < 50)
			{
				Col = "\c[Orange]";
			}
			else if (BatPercent < 75)
			{
				Col = "\c[Yellow]";
			}
			sb.DrawString(sb.pSmallFont, Col..BatPercent.."%\c-", (-14, -12), sb.DI_TEXT_ALIGN_RIGHT | sb.DI_SCREEN_CENTER_BOTTOM, Font.CR_DARKGRAY);
		}

		else if (BatteryCharge <= 0)
		{
			sb.DrawString(sb.mAmountFont, "00000", (-14, -10), sb.DI_TEXT_ALIGN_RIGHT | sb.DI_TRANSLATABLE | sb.DI_SCREEN_CENTER_BOTTOM, Font.CR_DARKGRAY);
		}
	}

	override void DrawSightPicture(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl, bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot)
	{
		int cx, cy, cw, ch;
		int ScaledYOffset = 48;
		int ScaledWidth = 89;

		[cx, cy, cw, ch] = Screen.GetClipRect();
		sb.SetClipRect(-16 + bob.x, -4 + bob.y, 32, 16, sb.DI_SCREEN_CENTER);
		vector2 bob2 = bob * 1.18;
		//bob2.y = clamp(bob2.y, -8, 8);
		sb.DrawImage("FENFRNT", (0,-4) + bob2, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, alpha: 0.9, scale: (0.6, 0.6));
		sb.SetClipRect(cx, cy, cw, ch);
		sb.DrawImage("FENBACK", (0,-4) + bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, scale: (0.6, 0.6));

	}

	Default
	{
		-HDWEAPON.FITSINBACKPACK
		Weapon.SelectionOrder 300;
		Weapon.SlotNumber 6;
		Weapon.SlotPriority 1.5;
		HDWeapon.BarrelSize 35, 1.5, 2;
		Scale 0.6;
		Tag "$TAG_FENRIS";
		HDWeapon.Refid HDLD_FENRIS;
		HDWeapon.Loadoutcodes "
			\cuframe - Lighter Weapon Frame (less bulk)
			\cuplat - Platinum Wiring (more efficient batteries)";
	}

	States
	{
		Spawn:
			FNRS Y 0 NoDelay A_JumpIf(invoker.WeaponStatus[FNProp_Battery] >= 0, 2);
			FNRS Z 0;
			FNRS # -1;
			Stop;
		Ready:
			FNRS A 0;
			#### A 1 A_WeaponReady(WRF_ALL);
			Goto ReadyEnd;
		Select0:
			FNRS A 0;
			#### A 0;
			Goto Select0Big;
		Deselect0:
			FNRS A 0;
			#### A 0;
			Goto Deselect0Big;
		User3:
			FNRS A 0 A_MagManager("HDBattery");
			Goto Ready;
		Fire:
			FNRS A 0
			{
				if (invoker.WeaponStatus[FNProp_Mode] == 0 && invoker.WeaponStatus[FNProp_Battery] > 0)
				{
					SetWeaponState("Full");
				}
				else if (invoker.WeaponStatus[FNProp_Mode] == 1 && invoker.WeaponStatus[FNProp_Battery] >= 2)
				{
					SetWeaponState("Semi");
				}
			}
			Goto Nope;
		Full:
			#### B 2 Offset(0, 36)
			{
				A_Overlay(PSP_FLASH, 'Flash');

				A_Light0();
				A_StartSound("Fenris/Fire", CHAN_WEAPON);
				int Charges = invoker.WeaponStatus[FNProp_Charge];
				int DamageDealt = random(40, 50);
				A_FireBullets(0, 0, 0, DamageDealt, "FenrisRayImpact", FBF_NORANDOM | FBF_NORANDOMPUFFZ, HDCONST_ONEMETRE * 300);
				A_AlertMonsters();
				A_MuzzleClimb(-frandom(-0.15, 0.15), -frandom(0.4, 0.5), -frandom(-0.2, 0.2), -frandom(0.5, 0.6));
				invoker.WeaponStatus[FNProp_Battery]--;
			}
			#### A 1 Offset(0, 34);
			#### A 1 Offset(0, 32);
			Goto Ready;
		Semi:
			#### B 2 Offset(0, 38)
			{
				A_Overlay(PSP_FLASH, 'Flash');

				A_Light0();
				A_StartSound("Fenris/Fire", CHAN_WEAPON);
				int Charges = invoker.WeaponStatus[FNProp_Charge];
				int DamageDealt = random(100, 120);
				A_FireBullets(0, 0, 0, DamageDealt, "FenrisRayImpact", FBF_NORANDOM | FBF_NORANDOMPUFFZ, HDCONST_ONEMETRE * 300);
				A_AlertMonsters();
				A_MuzzleClimb(-frandom(-0.15, 0.15), -frandom(0.6, 0.8), -frandom(-0.2, 0.2), -frandom(0.8, 1.0));
				invoker.WeaponStatus[FNProp_Battery] -= 2;
			}
			#### B 1 Offset(0, 35);
			#### A 1 Offset(0, 32);
			Goto Nope;

		AltFire:
			FNRS A 0
			{
				if (invoker.WeaponStatus[FNProp_Battery] >= 10)
				{
					SetWeaponState("Charge");
				}
			}
			Goto Nope;
		Charge:
			FNRS A 0 A_StartSound ("Fenris/SBCharge", CHAN_WEAPON | CHANF_OVERLAP);
			FNRS AAAAAAA 3
			{
				A_Light0();
				A_SpawnItemEx("ColdLight");

				switch(random[fenrand](0,3)) {
					case 0: A_Overlay(PSP_FLASH, 'ChargeFlashA'); break;
					case 1: A_Overlay(PSP_FLASH, 'ChargeFlashB'); break;
					case 2: A_Overlay(PSP_FLASH, 'ChargeFlashC'); break;
					case 3: A_Overlay(PSP_FLASH, 'ChargeFlashD'); break;
					default: break;
				}

				A_WeaponBusy(False);
			}
			Goto Snow;
		Snow:
			FNRS B 1 Offset(0, 36)
			{
				A_Overlay(PSP_FLASH, 'SnowFlash');
			}
			#### B 1 Offset(0, 42);
			#### B 1 Offset(0, 46)
			{
				A_Light0();
				A_StartSound("Fenris/SBFire", CHAN_WEAPON);
				int Charges = invoker.WeaponStatus[FNProp_Charge];
				A_FireProjectile("Snowball", spawnheight: (-10.0 * cos(-pitch)) * player.crouchfactor);
				A_AlertMonsters();
				A_MuzzleClimb(-frandom(-0.4, 0.4), -frandom(1.5, 1.8), -frandom(-0.6, 0.6), -frandom(1.8, 2.0));
				if (BackupSynergy.CheckForItem(self, "HDGFBlaster"))
				{
					invoker.WeaponStatus[FNProp_Battery] -= 12;
				}
				else invoker.WeaponStatus[FNProp_Battery] -= 20;
			}
			#### A 1 Offset(0, 42);
			#### A 1 Offset(0, 36);
			#### A 1 Offset(0, 32);
			Goto Nope;

		Flash:
			FNRF A 1 Bright
			{
				HDFlashAlpha(128);
			}
			goto lightdone;
		SnowFlash:
			FNRF A 3 Bright
			{
				HDFlashAlpha(128);
			}
			goto lightdone;
		ChargeFlashA:
			FNRC A 3 Bright
			{
				HDFlashAlpha(128);
			}
			goto lightdone;
		ChargeFlashB:
			FNRC B 3 Bright
			{
				HDFlashAlpha(128);
			}
			goto lightdone;
		ChargeFlashC:
			FNRC C 3 Bright
			{
				HDFlashAlpha(128);
			}
			goto lightdone;
		ChargeFlashD:
			FNRC D 3 Bright
			{
				HDFlashAlpha(128);
			}
			goto lightdone;

		FireMode:
			FNRS A 1 offset(1,32) A_WeaponBusy();
			#### A 1 offset(2,32);
			#### A 1 offset(1,33);
			#### A 1 offset(0,34)
			{
				++invoker.WeaponStatus[FNProp_Mode] %= 2;
				if (invoker.WeaponStatus[FNProp_Mode] == 0)
				{
					A_StartSound("Fenris/Charge",8, pitch: 0.85);
				}
				else A_StartSound("Fenris/Charge",8);
			}
			#### A 1 offset(-1,35);
			#### A 1 offset(-1,36);
			#### A 1 offset(-1,35);
			#### A 1 offset(0,34);
			#### A 1 offset(0,34);
			#### A 1 offset(1,33);
			Goto Nope;

		Unload:
			FNRS A 0
			{
				invoker.WeaponStatus[FNProp_Flags] |= FNF_JustUnload;
				if(invoker.WeaponStatus[FNProp_Battery] >= 0) return ResolveState("BatteryOut");
				return ResolveState("Nope");
			}
		BatteryOut:
			FNRS A 2 offset(0,36)
			{
				A_SetCrosshair(21);
				A_MuzzleClimb(frandom(-1.2,-2.4),frandom(1.2,2.4));
			}
			#### A 2 offset(1,37) A_StartSound("Fenris/Empty",8);
			#### A 2 offset(2,38);
			#### A 2 offset(3,42);
			#### A 2 offset(5,44);
			#### A 2 offset(6,42);
			#### A 2 offset(7,43) A_StartSound("Fenris/BattOut",8);
			#### A 2 offset(8,42);
			#### A 0
			{
				int BatteryCharge = invoker.GetRealBatteryCharge(false); // [Ace] Lose fractions if you take out a non-empty battery.
				invoker.WeaponStatus[FNProp_Battery] = -1;
				if(BatteryCharge < 0)SetWeaponState("MagOut");
				else if((!PressingUnload() && !PressingReload()) || A_JumpIfInventory("HDBattery", 0, "null"))
					{
						HDMagAmmo.SpawnMag(self,"HDBattery",BatteryCharge);
						SetWeaponState("MagOut");
					}
				else
					{
						HDMagAmmo.GiveMag(self,"HDBattery",BatteryCharge);
						A_StartSound("weapons/pocket",9);
						SetWeaponState("PocketMag");
					}
			}
		DropMag:
			FNRS A 0
			{
				int bat = invoker.WeaponStatus[FNProp_Battery];
				invoker.WeaponStatus[FNProp_Battery] = -1;
				if(bat >= 0)
				{
					HDMagAmmo.SpawnMag(self, "HDBattery", bat);
				}
			}
			Goto MagOut;

		PocketMag:
			FNRS A 0
			{
				int bat = invoker.WeaponStatus[FNProp_Battery];
				invoker.WeaponStatus[FNProp_Battery] = -1;
				if(bat >= 0)
				{
					HDMagAmmo.GiveMag(self,"HDBattery", bat);
				}
			}
			#### A 8 offset(9,43) A_StartSound("weapons/pocket",9);
			Goto MagOut;

		MagOut:
			FNRS A 0 A_JumpIf(invoker.WeaponStatus[FNProp_Flags] & FNF_JustUnload, "Reload3");
			Goto LoadMag;

		Reload:
			FNRS A 0
			{
				invoker.WeaponStatus[FNProp_Flags] &= ~FNF_JustUnload;
				int MaxBattery = invoker.WeaponStatus[FNProp_Flags] & FNF_Platinum ? 80 : 60;
				if (invoker.WeaponStatus[FNProp_Battery] < MaxBattery && CountInv("HDBattery"))
				{
					SetWeaponState("BatteryOut");
				}
			}
			Goto Nope;

		LoadMag:
			FNRS A 4 offset(8,42);
			#### A 4 offset(7,43) A_StartSound("Fenris/BattIn",8);
			#### A 4 offset(6,42);
			#### A 4 offset(5,44);
			#### A 4 offset(3,42);
			#### A 4 offset(2,38);
			#### A 4 offset(1,37) A_StartSound("Fenris/Charge",8);
			#### A 4 offset(0,36);

			#### A 0
			{
				let mmm = HDMagAmmo(findinventory("HDBattery"));
				double mult = invoker.WeaponStatus[FNProp_Flags] & FNF_Platinum ? 4 : 3;
				if(mmm)invoker.WeaponStatus[FNProp_Battery] = int(ceil(mmm.TakeMag(true) * mult));
			}
			Goto Reload3;

		Reload3:
			FNRS A 6 offset(0,40);
			#### A 2 offset(0,36);
			#### A 4 offset(0,33);
			Goto Nope;
	}
}

class FenrisRandom : IdleDummy
{
	States
	{
		Spawn:
			TNT1 A 0 NoDelay
			{
				A_SpawnItemEx("HDBattery", -3,flags: SXF_NOCHECKPOSITION);
				let wpn = HDFenris(Spawn("HDFenris", pos, ALLOW_REPLACE));
				if (!wpn)
				{
					return;
				}

				HDF.TransferSpecials(self, wpn);
				
				if (!random(0, 3))
				{
					wpn.WeaponStatus[wpn.FNProp_Flags] |= wpn.FNF_PolyFrame;
				}
				if (!random(0, 3))
				{
					wpn.WeaponStatus[wpn.FNProp_Flags] |= wpn.FNF_Platinum;
				}
				
				wpn.InitializeWepStats(false);
			}
			Stop;
	}
}

class FenrisRayImpact : Actor
{
	Default
	{
		+FORCEDECAL
		+PUFFGETSOWNER
		+HITTRACER
		+PUFFONACTORS
		+PUFFGETSOWNER
		+NOINTERACTION
		+BLOODLESSIMPACT
		+FORCERADIUSDMG
		+NOBLOOD
		Decal "FenrisScorch";
		DamageType "Cold";
	}

	States
	{
		Spawn:
			TNT1 A 5 NoDelay
			{
				A_StartSound("Fenris/Impact");

				for (int i = 0; i < 30; ++i)
				{
					double pitch = frandom(-85.0, 85.0);
					A_SpawnParticle(0x93D3FF, SPF_RELATIVE | SPF_FULLBRIGHT, random(10, 20), random(5, 8), random(0, 359), random(0, 4), 0, 0, random(1, 5) * cos(pitch), 0, random(1, 5) * sin(pitch), 0, 0, -0.5);
				}
			}
			Stop;
	}
}

class Snowball : HDActor
{
	Default
	{
		Projectile;
		Radius 9;
		Height 18;
		Speed 40;
		Gravity 0.05;
		DamageFunction (random (300, 350));
		DamageType "Cold";
		DeathSound "Fenris/SBExplode";
		Alpha 0.9;
		Scale 1.0;
		RenderStyle "Add";
		+BRIGHT
		+RIPPER
		+FORCEXYBILLBOARD
		+NODAMAGETHRUST
	}
	
	States
	{
		Spawn:
			TNT1 A 0 nodelay
			{
				actor mjl = spawn("SnowballLight", pos + (0, 0, 16), ALLOW_REPLACE);
				mjl.target = self;
			}
		Spawn2:
			SNBL ABC 1;
			loop;
		death:
			TNT1 A 0
			{
				A_HDBlast(HDCONST_ONEMETRE * 4, random(100,120), HDCONST_ONEMETRE * 2, "Cold");
				A_SpawnChunks("HDB_frag", 42, 100, 700);
				A_SpawnChunks("BigWallChunk", 14, 4, 12);
			}
			BXPL ABCDEFGHIJKL 2 { Alpha -= 0.05; }
			stop;
	}
}

class ColdLight : PointLight
{
    override void PostBeginPlay()
    {
        Super.PostBeginPlay();
        args[0] = 22;
        args[1] = 168;
        args[2] = 215;
        args[3] = 64;
    }

    override void Tick()
    {
        if (--ReactionTime <= 0)
        {
            Destroy();
            return;
        }

        Args[3] = random(50, 72);
    }

    Default
    {
        ReactionTime 20;
    }
}

class SnowballLight : PointLight
{
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		args[0]=189;
		args[1]=227;
		args[2]=254;
		args[3]=0;
	}
	
	override void tick()
	{
		if(!target)
		{
			args[3]+=random(-20,4);
			if(args[3]<1)destroy();
		}
		else
		{
			SetOrigin(target.pos, true);
			if(target.bmissile)args[3] = random(28,44);
			else args[3] = random(32,64);
		}
	}
}

class BackupSynergy play
{
	static clearscope bool CheckForItem(Actor other, Name item, int amt = 1)
	{
		class<HDWeapon> cls = item;
		return cls && other && other.CountInv(cls) >= amt;
	}
}
