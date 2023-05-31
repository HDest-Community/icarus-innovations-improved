class HDNCT : HDCellWeapon
{
	enum NCTProperties
	{
		NCProp_Flags,
		NCProp_Battery,
		NCProp_LoadType
	}

	override bool AddSpareWeapon(actor newowner) { return AddSpareWeaponRegular(newowner); }
	override HDWeapon GetSpareWeapon(actor newowner, bool reverse, bool doselect) { return GetSpareWeaponRegular(newowner, reverse, doselect); }
	override double GunMass() { return WeaponStatus[NCProp_Battery] >= 0 ? 10 : 8; }
	override double WeaponBulk() { return 20 + (WeaponStatus[NCProp_Battery] >= 0 ? ENC_BATTERY_LOADED : 0); }
	override string, double GetPickupSprite() { return "NCTPA0", 0.8; }
	override void InitializeWepStats(bool idfa)
	{
		WeaponStatus[NCProp_Battery] = 20;
	}

	override string GetHelpText()
	{
		return WEPHELP_FIRE.."  Shoot\n"
		..WEPHELP_RELOAD.."  Reload battery\n"
		..WEPHELP_UNLOADUNLOAD;
	}

	override string PickupMessage()
	{
		return "You found a weird tiny ... gun? thing?";
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		if (sb.HudLevel == 1)
		{
			sb.DrawBattery(-54, -4, sb.DI_SCREEN_CENTER_BOTTOM, reloadorder: true);
			sb.DrawNum(hpl.CountInv("HDBattery"), -46, -8, sb.DI_SCREEN_CENTER_BOTTOM);
		}

		int BatteryCharge = hdw.WeaponStatus[NCProp_Battery];
		if (BatteryCharge > 0)
		{
			string Col = "\c[Green]";
			if (BatteryCharge <= 19)
			{
				Col = "\c[Red]NOT ";
			}
			sb.DrawString(sb.pSmallFont, Col.."READY\c-", (-14, -12), sb.DI_TEXT_ALIGN_RIGHT | sb.DI_SCREEN_CENTER_BOTTOM, Font.CR_DARKGRAY);
		}
		else if (BatteryCharge == 0)
		{
			sb.DrawString(sb.mAmountFont, "00000", (-16, -9), sb.DI_TEXT_ALIGN_RIGHT | sb.DI_TRANSLATABLE | sb.DI_SCREEN_CENTER_BOTTOM, Font.CR_DARKGRAY);
		}
	}
	
	private action void A_Chirpchirp()
	{
		invoker.WeaponStatus[NCProp_Battery] -= 20;
		HDBulletActor.FireBullet(self, "HDB_Chirp");
		A_MuzzleClimb(-frandom(20.0, 25.0), -frandom(25.0, 30.0));		
		A_Light1();
		A_StartSound("weapons/plascrack", CHAN_WEAPON);
		A_AlertMonsters();
		A_ChangeVelocity(-5, 0, 2.5, CVF_RELATIVE);
		Actor plr = self;
		double oldAngle = (2 * angle);
		DropInventory(invoker);
		plr.angle = oldAngle;
		damagemobj(invoker,self,30,"bashing");
		HDPlayerPawn(self).A_Incapacitated( HDPlayerPawn.HDINCAP_SCREAM, 175 );
	}

	Default
	{
		+HDWEAPON.FITSINBACKPACK
		Weapon.SelectionOrder 50;
		Weapon.SlotNumber 2;
		Weapon.SlotPriority 0.5;
		HDWeapon.BarrelSize 6, 0.15, 0.25;
		Scale 0.5;
		Tag "NS3-Cr.KT";
		HDWeapon.Refid "tny";
	}

	States
	{
		Spawn:
			NCTP A -1;
			Stop;
		Ready:
			NCTG A 1 A_WeaponReady(WRF_ALL);
			Goto ReadyEnd;
		Select0:
			NCTG A 0;
			Goto Select0Big;
		Deselect0:
			NCTG A 0;
			Goto Deselect0Big;
		User3:
			#### A 0 A_MagManager("HDBattery");
			Goto Ready;
		Fire:
			NCTG A 0 A_JumpIf(invoker.WeaponStatus[NCProp_Battery] < 20, 'Nope');
			NCTF A 2 Bright Offset(0, 36);
			NCTF B 2 Bright Offset(0, 44);
			NCTF A 2 Offset(0, 38)
			{
				if (invoker.WeaponStatus[NCProp_Battery] >= 20)
				{
					A_Chirpchirp();
				}
				A_StartSound("NCT/Fail", CHAN_WEAPON);
				return ResolveState("Nope");
			}
			Goto Nope;
		Reload:
			NCTG A 0
			{
				if (invoker.weaponstatus[NCProp_Battery] >= 20 || !CheckInventory("HDBattery", 1))
				{
					SetWeaponState("Nope");
					return;
				}
				invoker.WeaponStatus[NCProp_LoadType] = 1;
			}
			Goto Reload1;
		Unload:
			#### A 0
			{
				if (invoker.WeaponStatus[NCProp_Battery] == -1)
				{
					SetWeaponState("Nope");
					return;
				}
				invoker.WeaponStatus[NCProp_LoadType] = 0;
			}
			Goto Reload1;
		Reload1:
			#### A 4;
			#### A 2 Offset(0, 36) A_MuzzleClimb(-frandom(1.2, 2.4), frandom(1.2, 2.4));
			#### A 2 Offset(0, 38) A_MuzzleClimb(-frandom(1.2, 2.4), frandom(1.2, 2.4));
			#### A 4 Offset(0, 40)
			{
				A_MuzzleClimb(-frandom(1.2, 2.4), frandom(1.2, 2.4));
				A_StartSound("weapons/plasopen", 8);
			}
			#### A 2 Offset(0, 42)
			{
				A_MuzzleClimb(-frandom(1.2, 2.4), frandom(1.2, 2.4));
				if(invoker.WeaponStatus[NCProp_Battery] >= 0)
				{
					if (PressingReload() || PressingUnload())
					{
						HDMagAmmo.GiveMag(self, "HDBattery", invoker.WeaponStatus[NCProp_Battery]);
						A_SetTics(10);
					}
					else
					{
						HDMagAmmo.SpawnMag(self, "HDBattery", invoker.WeaponStatus[NCProp_Battery]);
						A_SetTics(4);
					}
				}
				invoker.WeaponStatus[NCProp_Battery] = -1;
			}
			Goto BatteryOut;
		BatteryOut:
			#### A 4 Offset(0, 42)
			{
				if (invoker.WeaponStatus[NCProp_LoadType] == 0)
				{
					SetWeaponState("Reload3");
				}
				else
				{
					A_StartSound("weapons/pocket", 9);
				}
			}
			#### A 12;
			#### A 12 Offset(0, 42) A_StartSound("weapons/bfgbattout", 8);
			#### A 10 Offset(0, 36) A_StartSound("weapons/plasclose2", 8);
			#### A 0
			{
				let Battery = HDMagAmmo(FindInventory("HDBattery"));
				if (Battery && Battery.Amount > 0)
				{
					invoker.WeaponStatus[NCProp_Battery] = Battery.TakeMag(true);
				}
				else
				{
					SetWeaponState("Reload3");
					return;
				}
			}
		Reload3:
			#### A 6 Offset(0, 38) A_StartSound("weapons/plasload", 8);
			#### A 8 Offset(0, 37) A_StartSound("weapons/plasclose", 8);
			#### A 2 Offset(0, 38);
			#### A 2 Offset(0, 36);
			#### A 2 Offset(0, 34);
			#### A 12;
			Goto Ready;
		Reload4:
			#### A 6;
			Goto Nope;
	}
}

class NCTRandom : IdleDummy
{
	States
	{
		Spawn:
			TNT1 A 0 nodelay
			{
				let wpn = HDNCT(Spawn("HDNCT", pos, ALLOW_REPLACE));
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

class HDB_Chirp : HDBulletActor
{
	default
	{
		Pushfactor 0.05;
		Mass 5000;
		Speed HDCONST_MPSTODUPT*420;
		Accuracy 600;
		Stamina 3700;
		HDBulletActor.DistantSound "world/shotgunfar";
		HDBulletActor.DistantSoundVol 2.;
		MissileType "HDGunsmoke";
		Scale 0.08;
		Translation "128:151=%[1,1,1]:[0.2,0.2,0.2]";
		SeeSound "weapons/riflecrack";
		Obituary "%o got chirp chirp'd by %k's tny gun.";
	}

	Override Actor Puff()
	{
		if(max(abs(pos.x), abs(pos.y)) >= 32768) return null;
		setorigin(pos - (2 * (cos(angle), sin(angle)), 0), false);
		A_SprayDecal("BrontoScorch", 16);
		if(vel == (0, 0, 0))A_ChangeVelocity(cos(pitch), 0, -sin(pitch), CVF_RELATIVE | CVF_REPLACE);
		else vel *= 0.01;
		if(tracer)
		{
			int dmg = random(1000, 1200);
			vector3 hitpoint = pos + vel.unit() * tracer.radius;
			vector3 tracmid = (tracer.pos.xy, tracer.pos.z + tracer.height * 0.618);
			dmg=int((1. - ((hitpoint - tracmid).length() / tracer.radius)) * dmg);
			tracer.damagemobj(self, target, dmg, "Piercing", DMG_THRUSTLESS);
		}
		doordestroyer.destroydoor(self, 128, frandom(24, 36), 6, dedicated:true);
		A_HDBlast(fragradius:256, fragtype:"HDB_fragBronto", immolateradius:64, immolateamount:random(4,20), immolatechance:32, source:target);
		DistantQuaker.Quake(self, 3, 35, 256, 12);
		actor aaa = Spawn("WallChunker", pos,ALLOW_REPLACE);
		A_SpawnChunks("BigWallChunk", 20, 4, 20);
		A_SpawnChunks("HDSmoke", 4, 1, 7);
		aaa = spawn("HDExplosion", pos, ALLOW_REPLACE);
		aaa.vel.z = 2;
		distantnoise.make(aaa, "world/rocketfar");
		A_SpawnChunks("HDSmokeChunk", random(3, 4), 6, 12);
		A_AlertMonsters();
		bmissile=false;
		bnointeraction=true;
		vel = (0, 0, 0);
		if(!instatesequence(curstate, findstate("death")))setstatelabel("death");
		return null;
	}

	Override void OnHitActor(actor hitactor, vector3 hitpos, vector3 vu, int flags)
	{
		double spbak = speed;
		super.onhitactor(hitactor, hitpos, vu, flags);
		if(spbak - speed > 10)puff();
	}

	Override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		for(int i=2; i; i--)
		{
			A_SpawnItemEx("TerrorSabotPiece", 0, 0, 0, speed * cos(pitch) * 0.01, (i == 2 ? 3 : -3), speed * sin(pitch) * 0.01, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS);
		}
	}

	States
	{
	Death:
		TNT1 A 0{if(tracer)puff();}
		goto super::death;
	}
}