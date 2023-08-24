class FlamethrowerSpawner : IdleDummy
{
	states
	{
		Spawn:
			TNT1 A 0 NoDelay
			{
				A_SpawnItemEx("HDGasTank", -3,flags: SXF_NOCHECKPOSITION);
				let wpn = HDFlamethrower(Spawn("HDFlamethrower", pos, ALLOW_REPLACE));
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

const TankFuel = 0.1;

class HDFlamethrower : HDWeapon
{
	

	enum FlamerFlags
	{
		FTF_JustUnload = 1,
	}
	
	enum FlamerProperties
	{
		FTProp_Flags,
		FTProp_Gasoline
	}

	Override Void DrawSightPicture(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl, bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot)
	{
		int cx, cy, cw, ch;
		int ScaledYOffset = 48;
		int ScaledWidth = 89;

		[cx, cy, cw, ch] = Screen.GetClipRect();
		sb.SetClipRect(-16 + bob.x, -12 + bob.y, 32, 24, sb.DI_SCREEN_CENTER);
		sb.DrawImage("FLMRSITE", (0, 0) + bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, alpha: 0.9, scale: (0.6, 0.6));
		sb.SetClipRect(cx, cy, cw, ch);
	}
	
	private transient CVar PrettyLights;
	
	default
	{
		-HDWeapon.fitsinbackpack
		weapon.selectionorder 300;
		weapon.slotnumber 7;
		Weapon.SlotPriority 1.5;
		scale 0.5;
		obituary "$OB_FLAMENWERFER77";
		HDWeapon.BarrelSize 35, 1.2, 1.2;
		HDWeapon.refid HDLD_FLAMENWERFER77;
		tag "$TAG_FLAMENWERFER77";
	}
	
	Override bool AddSpareWeapon(actor newowner)
	{
		return AddSpareWeaponRegular(newowner);
	}
	
	Override hdweapon GetSpareWeapon(actor newowner,bool reverse)
	{
		return GetSpareWeaponRegular(newowner,reverse);
	}

	override string PickupMessage()
	{
		return Stringtable.localize("$PICKUP_FLAMENWERFER77_PREFIX")..Stringtable.localize("$TAG_FLAMENWERFER77")..Stringtable.localize("$PICKUP_FLAMENWERFER77_SUFFIX");
	}

	Override string, double GetPickupSprite()
	{
		return WeaponStatus[FTProp_Gasoline] >= 0 ? "WFLMA0" : "WFLMB0", 0.8;
	}
	
	Override Void initializewepstats(bool idfa)
	{
		WeaponStatus[FTProp_Gasoline]=100;
	}
	
	Override Void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl)
	{
		if(sb.hudlevel == 1)
		{
			int NextMagLoaded = sb.GetNextLoadMag(HDMagAmmo(hpl.findinventory("HDGasTank")));
			if (NextMagLoaded >= HDGasTank.TankCapacity)
			{
				sb.DrawImage("AGASA0",(-54,-4),sb.DI_SCREEN_CENTER_BOTTOM);
			}
			else if (NextMagLoaded <= 0)
			{
				sb.DrawImage("AGASB0",(-54,-4),sb.DI_SCREEN_CENTER_BOTTOM);
			}
			else
			{
				sb.DrawBar("AGASA0", "AGASB0", NextMagLoaded, HDGasTank.TankCapacity, (-46, -3), -1, sb.SHADER_VERT, sb.DI_SCREEN_CENTER_BOTTOM);
			}
			sb.DrawNum(hpl.countinv("HDGasTank"),-46,-8,sb.DI_SCREEN_CENTER_BOTTOM,font.CR_BLACK);
		}
		
		int Gas = hdw.WeaponStatus[FTProp_Gasoline];
		if(Gas > 0)
		{
			sb.DrawWepNum(Gas, HDGasTank.TankCapacity);
		}
		else if(Gas == 0)
		{
			sb.drawstring(sb.mamountfont, "00000", (-16, -9), sb.DI_TEXT_ALIGN_RIGHT | sb.DI_TRANSLATABLE | sb.DI_SCREEN_CENTER_BOTTOM, Font.CR_DARKGRAY);
		}

	}
	
	Override string gethelptext()
	{
		return
		WEPHELP_FIRE.."  Throw Flames\n"
		..WEPHELP_ALTFIRE.."  Airblast\n"
		..WEPHELP_RELOAD.."  Reload Canister\n"
		..WEPHELP_UNLOAD.."  Unload Canister\n";
	}
	
	Override double gunmass()
	{
		return 10 + WeaponStatus[FTProp_Gasoline] < 0 ? 0 : 1;
	}
	
	Override double weaponbulk()
	{
		double BaseBulk = 90;
		int Gas = WeaponStatus[FTProp_Gasoline];
		if (Gas >= 0)
		{
			BaseBulk += HDGasTank.EncTankLoaded + Gas * TankFuel;
		}
		return BaseBulk;
	}
	
	Override Void consolidate()
	{
		CheckBFGCharge(FTProp_Gasoline);
	}
	
	Override Void DropOneAmmo(int amt)
	{
		if(owner)
		{
			amt = clamp(amt, 1, 10);
			owner.A_DropInventory("HDGasTank", 1);
		}
	}

	states
	{
		Spawn:
			WFLM A 0 NoDelay A_JumpIf(invoker.WeaponStatus[FTProp_Gasoline] >= 0, 2);
			WFLM B 0;
			WFLM # -1;
			Stop;
		Ready:
			FLAM A 0;
			#### A 1 A_WeaponReady(WRF_ALL);
			Goto ReadyEnd;			
		Select0:
			FLAM A 0;
			#### A 0;
			Goto Select0Big;			
		Deselect0:
			FLAM A 0;
			#### A 0;
			Goto Deselect0Big;
		User3:
			#### A 0 A_MagManager("HDGasTank");
			Goto Ready;

		Fire:
			FLAM B 3 Bright
			{
				if (invoker.WeaponStatus[FTProp_Gasoline] > 0)
				{
					A_StartSound ("Flamer/Start", CHAN_WEAPON);
					return ResolveState("Burn");
				}
				else
				{
					A_StartSound ("Weapons/FlamerEmpty", CHAN_WEAPON);
					return ResolveState("Nope");
				}
			}
			Stop;
		Hold:
			FLAM B 1 bright A_JumpIf(invoker.WeaponStatus[FTProp_Gasoline] > 0,"Burn");
			Goto Nope;
		Burn:
			FLAF A 1 Bright
			{				
				if (!invoker.PrettyLights)
				{
					invoker.PrettyLights = CVar.GetCVar('Flamer_PrettyLights');
				}
				if (invoker.PrettyLights.GetBool())
				{
					A_SpawnItemEx("FlamerLight");
				}
				A_AlertMonsters();
				invoker.WeaponStatus[FTProp_Gasoline]--;
				A_MuzzleClimb(randompick(-1, 1) * frandom(0.1, 0.1), randompick(-1, 1) * frandom(0.2, 0.2));
			}
			FLAF ABCD 1 bright
			{
				player.GetPSprite(PSP_WEAPON).frame;
				A_FireProjectile("HDFireCone", frandom(-3, 3), spawnheight: (3.5 * cos(-pitch)) * player.crouchfactor);
			}
			FLAF D 1 A_Refire();
			Goto Sad;
		Sad:
			FLAM B 1 A_StartSound ("Flamer/Stop", CHAN_WEAPON);
			Goto ReadyEnd;
		
		AltFire:
			FLAB A 3
			{
				if (invoker.WeaponStatus[FTProp_Gasoline] > 10)
				{
					A_StartSound ("Flamer/Blast", CHAN_WEAPON);
					return ResolveState("BackBlast");
				}
				else
				{
					A_StartSound ("Weapons/FlamerEmpty", CHAN_WEAPON);
					return ResolveState("Nope");
				}
			}
			Stop;
		BackBlast:
			FLAB A 1
			{
				A_AlertMonsters();
				A_FireProjectile("HDBackBlast", frandom(-3,3), spawnheight: (3.5 * cos(-pitch)) * player.crouchfactor);
				invoker.WeaponStatus[FTProp_Gasoline] -= 5;
				A_MuzzleClimb(0, 0, -0.2, -0.8, -frandom(0.5, 0.9), -frandom(3.2, 4.0), -frandom(0.5, 0.9), -frandom(3.2, 4.0));
			}
			Goto Nope;

		Unload:
			FLAB A 0
			{
				invoker.WeaponStatus[FTProp_Flags] |= FTF_JustUnload;
				if(invoker.WeaponStatus[FTProp_Gasoline] >= 0)setweaponstate("Unmag");
			}
			Goto Nope;
		Unmag:
			FLAM A 4 offset(0,36)
			{
				A_SetCrosshair(21);
				A_MuzzleClimb(frandom(-1.2, -2.4),frandom(1.2, 2.4));
			}
			#### A 2 offset(1,37) A_StartSound("Flamer/CanOut");
			#### A 2 offset(2,38);
			#### A 2 offset(3,42);
			#### A 2 offset(5,44);
			#### A 2 offset(6,42);
			#### A 2 offset(7,43);
			#### A 2 offset(8,42);
			#### A 0
			{
				int magamt = invoker.WeaponStatus[FTProp_Gasoline];
				invoker.WeaponStatus[FTProp_Gasoline] = -1;
				if(magamt < 0)setweaponstate("MagOut");
				else if((!PressingUnload() && !PressingReload()) || A_JumpIfInventory("HDGasTank", 0, "null"))
					{
						HDMagAmmo.SpawnMag(self, "HDGasTank", magamt);
						SetWeaponState("MagOut");
					}
				else
					{
						HDMagAmmo.GiveMag(self,"HDGasTank",magamt);
						A_StartSound("weapons/pocket",9);
						setweaponstate("pocketmag");
					}
			}

		DropMag:
			FLAM A 0
			{
				int mag = invoker.WeaponStatus[FTProp_Gasoline];
				invoker.WeaponStatus[FTProp_Gasoline]=-1;
				if(mag>=0)
				{
					HDMagAmmo.SpawnMag(self,"HDGasTank",mag);
				}
			}
			Goto MagOut;

		PocketMag:
			FLAM A 0
			{
				int mag = invoker.WeaponStatus[FTProp_Gasoline];
				invoker.WeaponStatus[FTProp_Gasoline] =- 1;
				if(mag >= 0)
				{
					HDMagAmmo.GiveMag(self,"HDGasTank",mag);
				}
			}
			FLAM A 8 offset(9,43) A_StartSound("weapons/pocket",9);
			Goto MagOut;

		MagOut:
			FLAM A 0 A_JumpIf(invoker.WeaponStatus[FTProp_Flags] & FTF_JustUnload, "Reload3");
			Goto loadmag;

		Reload:
			FLAM A 0
			{
				if(invoker.WeaponStatus[FTProp_Gasoline] >= 500||!countinv("HDGasTank"))
				{
					return resolvestate("Nope");
				}
				invoker.WeaponStatus[FTProp_Flags]&=~FTF_JustUnload;
				return resolvestate("Unmag");
			}
			Goto Nope;

		Loadmag:
			FLAM A 4 offset(8,42);
			#### A 4 offset(7,43);
			#### A 4 offset(6,42);
			#### A 4 offset(5,44);
			#### A 4 offset(3,42);
			#### A 4 offset(2,38);
			#### A 4 offset(1,37) A_StartSound("Flamer/CanIn");
			#### A 4 offset(0,36);

			#### A 0
			{
				let mmm=HDMagAmmo(findinventory("HDGasTank"));
				if(mmm)invoker.WeaponStatus[FTProp_Gasoline]=mmm.TakeMag(true);
			}
			Goto Reload3;

		Reload3:
			FLAM A 6 offset(0,40);
			#### A 2 offset(0,36);
			#### A 4 offset(0,33);
			Goto Nope;
	}
}

// ------------------------------------------------------------
// Fuel Canister
// ------------------------------------------------------------

class HDGasTank : HDMagAmmo
{
	override string PickupMessage()
	{
		return Stringtable.localize("$PICKUP_GASTANK_PREFIX")..Stringtable.localize("$TAG_GASTANK")..Stringtable.localize("$PICKUP_GASTANK_SUFFIX");
	}

	Override string,string,name,double getmagsprite(int thismagamt)
	{
		String magsprite=(thismagamt > 0) ? "AGASA0" : "AGASB0";
		Return magsprite, "TNT1A0", "HDGasTank", 0.4;
	}

	Override Void GetItemsThatUseThis()
	{
		ItemsThatUseThis.Push("HDFlamethrower");
	}
	
	Override Bool Extract()
	{
		Return False;
	}
	
	Override Bool Insert()
	{
		SyncAmount();
		if(amount < 2)
		{
			return mags[0];
		}
		if (mags[mags.size()-1] >= maxperunit)
		{
			return false;
		}
		int lowestindex =- 1;
		int lowest = maxperunit;
		for (int i=0; i<amount-1; i++)
		{
			if(lowest > mags[i] && mags[i] > 0)
			{
				lowest = mags[i];
				lowestindex = i;
			}
		}
		if (lowestindex < 0) 
		{
			return false;
		}
		if (mags[lowestindex] < 1)
		{
			return false;
		}
		mags[lowestindex]--;
		mags[mags.size()-1]++;
		owner.A_StartSound("potion/swish",CHAN_WEAPON);
		return true;
	}
	
	const TankCapacity = 100;
	const EncTankEmpty = 25;
	const EncTankLoaded = EncTankEmpty * 0.8;
	
	default
	{
		Health 10;
		+SHOOTABLE
		+DONTTHRUST
		+NOBLOOD
		HDMagAmmo.MaxPerUnit TankCapacity;
		HDMagAmmo.RoundType "";
		HDMagAmmo.RoundBulk TankFuel;
		HDMagAmmo.MagBulk EncTankEmpty;
		Tag "$TAG_GASTANK";
		Inventory.PickupMessage "$PICKUP_GASTANK";
		HDPickup.RefID HDLD_GASTANK;
		Scale 0.4;
	}
	
	States
	{
		Spawn:
			AGAS A -1;
			Stop;
		SpawnEmpty:
			AGAS B -1
			{
				brollsprite=true;brollcenter=true;
				roll=randompick(0,0,0,0,2,2,2,2,1,3)*90;
			}
			Stop;
		Death:
			#### A 0
			{
				let bomb = HDGasBomb(Spawn('HDGasBomb', pos));
				bomb.GasLeft = invoker.Mags[0];
			}
			Stop;
	}
}

class HDGasBomb : HDActor
{
	int GasLeft;

	States
	{
		Spawn:
			TNT1 A 1 NoDelay
			{
				if (GasLeft > 0)
				{
					A_SpawnItemEx("HDSmokeChunk", frandom(-10, 10), frandom(-10, 10), frandom(1, 10), frandom(-4, 4), frandom(-4, 4), frandom(0, 2), 0, SXF_NOCHECKPOSITION, 24);
					A_SpawnItemEx("HDExplosion", frandom(-1, 1), frandom(-1, 1), frandom(3, 4), 0, 0, frandom(0, 2), 0, SXF_NOCHECKPOSITION);
					A_Immolate(self, self.target, random(0.5 * GasLeft, 1 * GasLeft));
					A_HDBlast(immolateradius:HDCONST_ONEMETRE * (GasLeft / 20), random(2 * GasLeft, 5 * GasLeft), 1 * GasLeft, true);
				}
				A_SpawnItemEx("HugeWallChunk", frandom(-3, 3), frandom(-3, 3), frandom(1, 8), frandom(-10, 10), frandom(-10, 10), frandom(-3, 8), 0, SXF_NOCHECKPOSITION);
			}
			Stop;
	}
}

class HDFireCone : HDActor
{
	
	Private Transient CVar PrettyLights;
	
	default
	{
		Projectile;
		Height 10;
		Speed 40;
		Gravity 0;
		SeeSound "Flamer/Loop";
		DamageFunction (0);
		Alpha 0.5;
		Scale 0.05;
		Radius 0.6;
		RenderStyle "Add";
		Decal "Scorch";
		+RIPPER
		+BLOODLESSIMPACT
		+FORCEXYBILLBOARD
		+ROLLSPRITE
		+ROLLCENTER
		+BRIGHT
	}

	States
	{
		Spawn:
			FLMP ABCDEFGHIJKLMNOP 2 bright
			{
				scale+=(0.1, 0.1);
				A_FadeOut(0.05);

				if (!invoker.PrettyLights) invoker.PrettyLights = CVar.GetCVar('Flamer_PrettyLights');

				if (invoker.PrettyLights.GetBool()) A_SpawnItemEx("FireballLight");

				let burnRange = HDCONST_ONEMETRE * clamp(max(scale.x, 0.65) * 1.5, 1.0, 3.5);

				BlockThingsIterator it = BlockThingsIterator.Create(self, burnRange);
				while (it.Next())
				{
					if (
						Distance3D(it.thing) <= burnRange
						&& it.thing.bshootable
					) A_Immolate(it.thing, target, 20);
				}
			}
			stop;
		Death:
			FLMP ABCDEFGHIJKLMNOP 1 bright
			{
				scale.x+=0.05;
				scale.y+=0.05;
			}
			TNT1 A 1
			{
				A_SpawnItemEx("HDSmoke", random(-2,2), random(-2,2), random(-2,2), frandom(2,-4), frandom(-2,2), frandom(1,4), 0, SXF_NOCHECKPOSITION);
			}
			Stop;
	}
}

class HDBackBlast : HDActor
{
	default
	{
		Projectile;
		Height 9;
		Speed 8;
		Gravity 0;
		Alpha 0.8;
		Scale 0.1;
		RenderStyle "Add";
		+FORCEXYBILLBOARD
		+ROLLSPRITE
		+ROLLCENTER
		+BRIGHT
	}

	const EffectRange = HDCONST_ONEMETRE * 3;

	States
	{
		Spawn:
			SMOK ABCDEFGHIJKLMNOP 1
			{
				scale.x+=0.1;
				scale.y+=0.1;
				BlockThingsIterator it = BlockThingsIterator.Create(self, EffectRange);
				while (it.Next())
				{
					string Follower = "HDFollower";
					class<Actor> FollowerCls = Follower;
					if (!it.thing.bISMONSTER || it.thing.bNODAMAGE || !CheckSight(it.thing, SF_IGNOREVISIBILITY) || it.thing is 'HDPlayerCorpse' || it.thing is FollowerCls)
					{
						continue;
					}

					if (it.thing)
					{
						it.thing.bSLIDESONWALLS = true;
						it.thing.A_Face(self, 0, 0);
						it.thing.A_ChangeVelocity(-1 * cos(it.thing.pitch), 0, -2 * -sin(it.thing.pitch), CVF_RELATIVE);
						it.thing.vel.x = clamp(it.thing.vel.x, -4, 4);
						it.thing.vel.y = clamp(it.thing.vel.y, -4, 4);
						it.thing.vel.z = clamp(it.thing.vel.z, -4, 4);
					}
				}
			}
			Stop;
		Death:
			TNT1 A 0;
			Stop;
	}
}

class FlamerLight : PointLight
{
	Override Void PostBeginPlay()
    {
        Super.PostBeginPlay();
        args[0] = 200;
        args[1] = 160;
        args[2] = 70;
        args[3] = 64;
    }

	Override Void Tick()
    {
        if (--ReactionTime <= 0)
        {
            Destroy();
            return;
        }

        Args[3] = random(50, 72);
    }

	default
    {
        ReactionTime 20;
    }
}

class FireballLight : PointLight
{
    Override Void PostBeginPlay()
    {
        Super.PostBeginPlay();
        args[0] = 200;
        args[1] = 160;
        args[2] = 70;
        args[3] = 64;
    }

    Override Void Tick()
    {
        if (--ReactionTime <= 0)
        {
            Destroy();
            return;
        }

        Args[3] = random(21, 42);
    }

    default
    {
        ReactionTime 20;
    }
}
