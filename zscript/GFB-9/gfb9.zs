class HDGFBlaster : HDHandgun
{
	enum GFBlasterFlags
	{
		GFB_Capacitor = 1,
	}

	enum GFBlasterProperties
	{
		GBProp_Flags,
		GBProp_Charge,
		GBProp_Timer,
		GBProp_Shards
	}

	override bool AddSpareWeapon(actor newowner)
	{
		return AddSpareWeaponRegular(newowner);
	}
	
	override HDWeapon GetSpareWeapon(actor newowner, bool reverse, bool doselect)
	{
		return GetSpareWeaponRegular(newowner, reverse, doselect);
	}
	
	override double GunMass()
	{
		double BaseMass = 12;
		if (WeaponStatus[GBProp_Flags] & GFB_Capacitor)
		{
			BaseMass *= 1.25;
		}
		return BaseMass;
	}
	
	override double WeaponBulk()
	{
		double BaseBulk = 60;
		if (WeaponStatus[GBProp_Flags] & GFB_Capacitor)
		{
			BaseBulk *= 1.25;
		}
		return BaseBulk;
	}
	
	override string, double GetPickupSprite()
	{
		return "GFBNZ0", 1.2;
	}
	
	override void InitializeWepStats(bool idfa)
	{
		WeaponStatus[GBProp_Charge] = GetMaxCharge();
		WeaponStatus[GBProp_Timer] = 0;
	}
	override void LoadoutConfigure(string input)
	{
		if (GetLoadoutVar(input, "cap", 1) > 0)
		{
			WeaponStatus[GBProp_Flags] |= GFB_Capacitor;
		}
		InitializeWepStats(false);
	}

	override string GetHelpText()
	{
		return WEPHELP_FIRE.."  Fire\n"
		..WEPHELP_ALTFIRE.."/"..WEPHELP_RELOAD.."  Charge Capacitor\n";
	}

	override string PickupMessage()
	{
		string CapStr = WeaponStatus[GBProp_Flags] & GFB_Capacitor ? "high-capacity " : "";
		return String.Format("You got the %sGretchenfrage Blaster Mk. 9.", CapStr);
	}

	protected clearscope int GetMaxCharge()
	{
		return WeaponStatus[GBProp_Flags] & GFB_Capacitor ? 20 : 15;
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		sb.DrawWepNum(hdw.WeaponStatus[GBProp_Charge], GetMaxCharge());
		int lod=clamp(hdw.weaponstatus[GBProp_Charge]%100,0,50);
		sb.drawnum(lod,-18,-18,sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,Font.CR_GREEN);
	}

	override void DrawSightPicture(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl, bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot)
	{
		int cx, cy, cw, ch;
		[cx, cy, cw, ch] = Screen.GetClipRect();
		sb.SetClipRect(-16 + bob.x, -4 + bob.y, 32, 16, sb.DI_SCREEN_CENTER);
		vector2 bobb = bob * 2;
		bobb.y = clamp(bobb.y, -8, 8);
		sb.drawimage("GFBFRNT", bobb, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, alpha: 0.9);
		sb.SetClipRect(cx, cy, cw, ch);
		sb.drawimage("GFBBACK", bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP);
	}

	Default
	{
		+HDWEAPON.FITSINBACKPACK
		Weapon.SelectionOrder 300;
		Weapon.SlotNumber 2;
		Weapon.SlotPriority 2.0;
		HDWeapon.BarrelSize 12, 0.3, 0.5;
		Scale 0.5;
		Tag "GFB-9";
		HDWeapon.Refid "gfb";
		HDWeapon.Loadoutcodes "
			\cucap - Extended Capacitor";
	}

	States
	{
		Spawn:
			GFBN Z -1;
			Stop;
		Select0:
			GFBN A 0;
			#### # 0;
			Goto Select0Small;
		Deselect0:
			GFBN A 0;
			#### # 0
			{
				invoker.WeaponStatus[GBProp_Timer] = 0;
			}
			Goto Deselect0Small;
		Ready:
			GFBN A 0;
			#### A 0 A_JumpIf(invoker.weaponstatus[GBProp_Charge]>0,2);
			#### C 0; 
			#### # 1 A_WeaponReady(WRF_ALL);
			Goto ReadyEnd;
		User3:
			---- A 0 A_MagManager("HDBattery");
			Goto Ready;
		Fire:
			#### # 0
			{
				invoker.WeaponStatus[GBProp_Timer] = 0;
				if (invoker.WeaponStatus[GBProp_Charge] > 0)
				{
					return ResolveState("Shoot");
				}
				
				return ResolveState("Nope");
			}
			Stop;
		Reload:
		AltReload:
		AltFire:
			#### # 0
			{
				if (invoker.WeaponStatus[GBProp_Charge] < invoker.GetMaxCharge())
				{ 
					return ResolveState("Charge");
				}

				return ResolveState("Nope");
			}
			Stop;
		Shoot:
			#### A 2 Offset(0, 36);
			#### B 2 Bright Offset(0, 44)
			{
				A_Light0();
				A_StartSound("GFBlaster/Fire", CHAN_WEAPON);
				A_FireBullets(0, 0, 0, 0, "GFBBlastImpact", FBF_NORANDOM | FBF_NORANDOMPUFFZ, HDCONST_ONEMETRE * 50);
				A_AlertMonsters();
				A_MuzzleClimb(-frandom(1.0, 1.25), -frandom(1.5, 2.0));
				invoker.WeaponStatus[GBProp_Charge] -= 1;
			}
			Goto Hold;
		Hold:
			#### A 0;
			Goto Nope;
		Charge:
			#### C 4;
			#### D 4;
			#### E 4;
		ActualCharge:
			#### F 4
			{
				if (PressingReload()||invoker.WeaponStatus[GBProp_Charge] >= invoker.GetMaxCharge())
				{
					invoker.WeaponStatus[GBProp_Timer] = 0;
					SetWeaponState("EndCharge");
					return;
				}
				
				if (PressingFire()||PressingAltFire()||PressingFireMode())
				{
					SetWeaponState("EndCharge");
				}

				if (++invoker.WeaponStatus[GBProp_Timer] > 3 - (Synergy.CheckForItem(self, "HDFenris") ? 1 : 0))
				{
					invoker.WeaponStatus[GBProp_Timer] = 0;
					invoker.WeaponStatus[GBProp_Charge]++;
				}

				A_WeaponBusy(false);
				A_StartSound("GFBlaster/Charge", 8);
				BFG9k.Spark(self, 1, height - 10);
				if(!random(0, 30) && invoker.WeaponStatus[GBProp_Shards] <= 4)
				{
					A_FireProjectile("BFGNecroShard",random(170,190),spawnofs_xy:random(-20,20));
					invoker.WeaponStatus[GBProp_Shards]++;
				}
				A_WeaponReady(WRF_NOFIRE);
			}
			Loop;
		EndCharge:
			#### E 4;
			#### D 4;
			#### C 4
			{
				invoker.weaponstatus[GBProp_Shards] = 0;
			}
			Goto Ready;
	}
}

class GFBlasterRandom : IdleDummy
{
	States
	{
		Spawn:
			TNT1 A 0 nodelay
			{
				let wpn = HDGFBlaster(Spawn("HDGFBlaster", pos, ALLOW_REPLACE));
				if (!wpn)
				{
					return;
				}

				HDF.TransferSpecials(self, wpn);
				
				if (!random(0, 3))
				{
					wpn.WeaponStatus[wpn.GBProp_Flags] |= wpn.GFB_Capacitor;
				}
				wpn.InitializeWepStats(false);
			}
			Stop;
	}
}

class GFBBlastImpact : HDActor
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
		Decal "GFBScorch";
		damagetype "Bashing";
	}

	States
	{
		Spawn:
			TNT1 A 1 NoDelay
			{
				//int BlastDamage = random(1,2);
				//A_HDBlast(42, BlastDamage, 21, "Electrical", 0, 0, 0, false, 0, "None", 0, 0, 0, true, null, false, 180);
				A_Explode(frandom(15,45),6,XF_HURTSOURCE,1,8);
					
					/*
					A_HDBlast(blastradius:8, blastdamage:random(1,4), fullblastradius:5, blastdamagetype:"Electrical", pushradius:0, pushamount:0, fragradius:HDCONST_ONEMETRE*1, fragtype:"HDB_frag", 
						fragments:(HDEXPL_FRAGS>>0), immolateradius:15,immolateamount:random(4,20), immolatechance:20, source:target);
					*/
					
				A_StartSound("GFBlaster/Impact");
				bool Freedoom = Wads.CheckNumForName("id", 0) == -1;

				for (int i = 0; i < 30; ++i)
				{
					double pitch = frandom(-85.0, 85.0);
					A_SpawnParticle(Freedoom ? 0x0084FF : 0x44D61D, SPF_RELATIVE | SPF_FULLBRIGHT, random(10, 20), random(5, 8), random(0, 359), random(0, 4), 0, 0, random(1, 5) * cos(pitch), 0, random(1, 5) * sin(pitch), 0, 0, -0.5);
				}
			}
			Stop;
	}
}

class Synergy play
{
	static clearscope bool CheckForItem(Actor other, Name item, int amt = 1)
	{
		class<HDWeapon> cls = item;
		return cls && other && other.CountInv(cls) >= amt;
	}
}