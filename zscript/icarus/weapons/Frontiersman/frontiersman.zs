class FrontierSpawner : IdleDummy
{
	states
	{
		Spawn:
			TNT1 A 0 NoDelay
			{
				let wpn = HDWeapon(Spawn('HDFrontier', pos, ALLOW_REPLACE));
				if (!wpn) return;

				HDF.TransferSpecials(self, wpn);
				wpn.InitializeWepStats(false);

				spawn("HD7mBoxPickup",pos,ALLOW_REPLACE);
			}
			Stop;
	}
}

class HDFrontier : HDWeapon
{
	enum FrontierFlags
	{
		FMFJustUnload = 1,
		FMFFromPockets = 2,
		FMFHold = 4,
		FMFAltHold = 8

	}
	enum FrontierProperties
	{
		FMProp_Flags,
		FMProp_Chamber,
		FMProp_Tube,
		FMProp_SideSaddles,
		FMProp_Mode

	}

	override void PostBeginPlay()
	{
		weaponspecial = 1337; // [Ace] UaS sling compatibility.
		Super.PostBeginPlay();
	}

	override bool AddSpareWeapon(actor newowner) {return AddSpareWeaponRegular(newowner);}
	override HDWeapon GetSpareWeapon(actor newowner, bool reverse, bool doselect) { return GetSpareWeaponRegular(newowner, reverse, doselect); }
	override double GunMass() { return 12; }
	override double WeaponBulk()
	{
		return 144 + (WeaponStatus[FMProp_SideSaddles] + WeaponStatus[FMProp_Tube]) * ENC_776_LOADED;
	}

	override string PickupMessage()
	{
		return Stringtable.localize("$PICKUP_FRONTIERSMAN_PREFIX")..Stringtable.localize("$TAG_FRONTIERSMAN")..Stringtable.localize("$PICKUP_NYX_SUFFIX");
	}

	override string, double GetPickupSprite()
	{
		string BaseSprite = "FRMZ";
		int Rounds = WeaponStatus[FMProp_SideSaddles];
		string Frame = "G";
		switch (WeaponStatus[FMProp_SideSaddles] / 3)
		{
			case 6: Frame = "A"; break;
			case 5: Frame = "B"; break;
			case 4: Frame = "C"; break;
			case 3: Frame = "D"; break;
			case 2: Frame = "E"; break;
			case 1: Frame = "F"; break;
		}
		return BaseSprite..Frame.."0", 0.6;
	}

	override void InitializeWepStats(bool idfa)
	{
		WeaponStatus[FMProp_Chamber] = 2;
		WeaponStatus[FMProp_Tube] = MaxTube;
		WeaponStatus[FMProp_SideSaddles] = MaxSideRounds;
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		if (sb.hudlevel == 1)
		{
			int sevenrounds=hpl.CountInv("SevenMilAmmo");
			sb.drawimage("TEN7A0", (-54, -4), sb.DI_SCREEN_CENTER_BOTTOM, alpha: sevenrounds ? 1 : 0.6, scale: (1.2, 1.2));
			sb.drawnum(hpl.CountInv("SevenMilAmmo"), -50, -8, sb.DI_SCREEN_CENTER_BOTTOM);
		}
		if(hdw.WeaponStatus[FMProp_Chamber] > 1)
		{
			sb.drawrect(-25, -12, 1, 1);
			sb.drawrect(-24, -13, 2, 3);
			sb.drawrect(-22, -13, 5, 3);
		}
		else if(hdw.WeaponStatus[FMProp_Chamber] > 0)
		{
			sb.drawrect(-22, -13, 5, 3);
		}
		for (int i = hdw.WeaponStatus[FMProp_Tube]; i > 0; --i)
		{
			sb.drawrect(-16 - i * 6, -9, 5, 3);
		}
		for(int i = hdw.WeaponStatus[FMProp_SideSaddles]; i > 0; i--)
		{
			sb.drawrect(-16 - i * 2, -5, 1, 3);
		}
		sb.DrawWepCounter(hdw.WeaponStatus[FMProp_Mode], -16, -16, "blank", "HOLYBLT");
	}

	override string GetHelpText()
	{
		return WEPHELP_FIRESHOOT
		..WEPHELP_ALTFIRE.."  Cycle Action\n"
		..WEPHELP_RELOAD.."  Reload (Side Saddles First)\n"
		..WEPHELP_ALTRELOAD.."  Reload (Pockets Only)\n"
		..WEPHELP_FIREMODE.."  Use Holy Rounds (requires blues)\n"
		..WEPHELP_FIREMODE.."+"..WEPHELP_RELOAD.."  Load side saddles\n"
		..WEPHELP_UNLOADUNLOAD;
	}

	override void DrawSightPicture(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl, bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot)
	{
		int cx, cy, cw, ch;
		[cx, cy, cw, ch] = Screen.GetClipRect();
		sb.SetClipRect(-16 + bob.x, -32 + bob.y, 32, 40, sb.DI_SCREEN_CENTER);
		vector2 bobb = bob * 2;
		sb.DrawImage("FRNTSITE", (0, 0) + bobb, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP);
		sb.SetClipRect(cx, cy, cw, ch);
		sb.DrawImage("SGBAKSIT", (0, 0) + bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP);
	}

	override void DropOneAmmo(int amt)
	{
		if (owner)
		{
			amt = clamp(amt, 1, 10);
			if (owner.CheckInventory("SevenMilAmmo", 1))
			{
				owner.A_DropInventory("SevenMilAmmo", amt * 10);
			}
		}
	}

	action void EmptyHand(int amt =- 1,bool careful = false)
	{
		if(!amt)return;
		if(amt > 0)invoker.HandRounds = amt;
		while(invoker.HandRounds > 0)
		{
			if(careful && !A_JumpIfInventory("SevenMilAmmo", 0, "null"))
			{
				invoker.HandRounds--;
				HDF.Give(self, "SevenMilAmmo", 1);
 			}
			else
			{
				invoker.HandRounds--;
				A_SpawnItemEx("HDLoose7mm", cos(pitch) * 5, 1, height - 7 - sin(pitch) * 5, cos(pitch) * cos(angle) * frandom(1, 4) + vel.x, cos(pitch) * sin(angle) * frandom(1, 4) + vel.y, -sin(pitch) * random(1, 4) + vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH);
			}
		}
	}

	action void A_UnloadSideSaddle()
	{
		int uamt = clamp(invoker.WeaponStatus[FMProp_SideSaddles], 0, 4);
		if(!uamt)return;
		invoker.WeaponStatus[FMProp_SideSaddles] -= uamt;
		int maxpocket = min(uamt, HDPickup.MaxGive(self, "SevenMilAmmo", ENC_776));
		if(maxpocket > 0 && PressingUnload())
		{
			A_SetTics(16);
			uamt -= maxpocket;
			A_GiveInventory("SevenMilAmmo", maxpocket);
		}
		A_StartSound("Weapons/Pocket", 9);
		EmptyHand(uamt);
	}

	action void A_SetAltHold(bool which)
	{
		if(which)invoker.WeaponStatus[FMProp_Flags] |= FMFAltHold;
		else invoker.WeaponStatus[FMProp_Flags] &=~ FMFAltHold;
	}

	action void A_Chamber(bool careful = false)
	{
		A_UpdateHammerFrame();
		int chm = invoker.WeaponStatus[FMProp_Chamber];
		invoker.WeaponStatus[FMProp_Chamber] = 0;
		if(invoker.WeaponStatus[FMProp_Tube] > 0)
		{
			invoker.WeaponStatus[FMProp_Chamber] = 2;
			invoker.WeaponStatus[FMProp_Tube]--;
		}
		vector3 cockdir;
		double cp = cos(pitch);
		if(careful)cockdir = (-cp, cp, -5);
		else cockdir = (0, -cp * 5, sin(pitch) * frandom(4, 6));
		cockdir.xy = rotatevector(cockdir.xy, angle);
		bool pocketed = false;
		if(chm > 1)
		{
			if(careful && !A_JumpIfInventory("SevenMilAmmo", 0, "null"))
			{
				HDF.Give(self, "SevenMilAmmo", 1);
				pocketed = true;
			}
		}
		else if(chm > 0)
		{
			cockdir *= frandom(1, 1.3);
		}
		if(!pocketed && chm >= 1)
		{
			vector3 gunofs = HDMath.RotateVec3D((9, -1, -2), angle, pitch);
			actor rrr = null;

			if(chm > 1)rrr = spawn("HDLoose7mm", (pos.xy, pos.z + height * 0.85) + gunofs);
			else rrr = spawn("HDSpent7mm", (pos.xy, pos.z + height * 0.85) + gunofs);

			rrr.target = self;
			rrr.angle = angle;
			rrr.vel = HDMath.RotateVec3D((1, -5, 0.2), angle, pitch);
			if(chm == 1)rrr.vel *= 1.3;
			rrr.vel += vel;
		}
	}

	action void A_CheckPocketSaddles()
	{
		if(invoker.WeaponStatus[FMProp_SideSaddles] < 1)invoker.WeaponStatus[FMProp_Flags] |= FMFFromPockets;
		if(!CountInv("SevenMilAmmo"))invoker.WeaponStatus[FMProp_Flags] &=~ FMFFromPockets;
	}

	action bool A_LoadTubeFromHand()
	{
		int hand = invoker.HandRounds;
		if(!hand || (invoker.WeaponStatus[FMProp_Chamber] > 0 && invoker.WeaponStatus[FMProp_Tube] >= MaxTube))
		{
			EmptyHand();
			return false;
		}
		invoker.WeaponStatus[FMProp_Tube]++;
		invoker.HandRounds--;
		A_StartSound("Weapons/BossLoad", 8, CHANF_OVERLAP);
		return true;
	}

	action bool A_GrabRounds(int maxhand = 3,bool settics = false,bool alwaysone = false)
	{
		if(maxhand > 0)EmptyHand();
		else maxhand = abs(maxhand);
		bool fromsidesaddles =! (invoker.WeaponStatus[FMProp_Flags] & FMFFromPockets);
		int toload = min(fromsidesaddles ? invoker.WeaponStatus[FMProp_SideSaddles] : CountInv("SevenMilAmmo"), alwaysone ? 1 : (MaxTube - invoker.WeaponStatus[FMProp_Tube]), maxhand);
		if(toload < 1)return false;
		invoker.HandRounds = toload;
		if(fromsidesaddles)
		{
			invoker.WeaponStatus[FMProp_SideSaddles] -= toload;
			if(settics)A_SetTics(2);
			A_StartSound("Weapons/Pocket", 8, CHANF_OVERLAP, 0.4);
			A_MuzzleClimb(frandom(0.1, 0.15), frandom(0.05, 0.08), frandom(0.1, 0.15), frandom(0.05, 0.08));
		}
		else
		{
			A_TakeInventory("SevenMilAmmo", toload, TIF_NOTAKEINFINITE);
			if(settics)A_SetTics(7);
			A_StartSound("Weapons/Pocket", 9);
			A_MuzzleClimb(frandom(0.1, 0.15), frandom(0.2, 0.4), frandom(0.2, 0.25), frandom(0.3, 0.4), frandom(0.1, 0.35), frandom(0.3, 0.4), frandom(0.1, 0.15), frandom(0.2, 0.4));
		}
		return true;
	}

	private action void A_UpdateHammerFrame()
	{
		let psp = player.GetPSprite(PSP_WEAPON);
		psp.frame = invoker.WeaponStatus[FMProp_Chamber] < 2 ? 1 : 0;
	}

	const MaxTube = 5;
	const MaxSideRounds = 15;
	int HandRounds;

	default
	{
		Weapon.SelectionOrder 300;
		Weapon.SlotNumber 3;
		Weapon.SlotPriority 3;
		Weapon.BobRangeX 0.18;
		Weapon.BobRangeY 0.7;
		Scale 0.6;
		HDWeapon.BarrelSize 30, 1, 1;
		Tag "$TAG_FRONTIERSMAN";
		HDWeapon.Refid HDLD_FRONTIERSMAN;
	}

	States
	{
		Spawn:
			FRMZ ABCDEFG -1 NoDelay
			{
				frame = 6 - invoker.WeaponStatus[FMProp_SideSaddles] / 3;
			}
				Stop;
		Select0:
			FRMG A 0 A_UpdateHammerFrame();
			goto Select0Big;
		Deselect0:
			FRMG A 0 A_UpdateHammerFrame();
			goto Deselect0Big;
		Ready:
			FRMG A 0 A_JumpIf(PressingAltFire(),2);
			#### A 0
			{
				if(!PressingAltFire())
				{
					if(!PressingFire())A_ClearRefire();
					A_SetAltHold(false);
				}
				A_UpdateHammerFrame();
			}
			#### # 1 A_WeaponReady(WRF_ALL);
			goto ReadyEnd;
		Firemode:
			FRMG # 0 { ++invoker.WeaponStatus[FMProp_Mode] %= 2; }
		FiremodeHold:
			FRMG # 1
			{
				if(PressingReload())
				{
					SetWeaponState("ReloadSS");
				}
				else A_WeaponReady(WRF_NONE);
			}
			#### # 0 A_JumpIf(PressingFiremode() && invoker.WeaponStatus[FMProp_SideSaddles] < MaxSideRounds,"FiremodeHold");
			goto Nope;
		User3:
			#### A 0 A_MagManager("HD7mClip");
			goto Ready;

		Fire:
			FRMG # 0 A_JumpIf(invoker.WeaponStatus[FMProp_Chamber] == 2,"Shoot");
			#### # 1 A_WeaponReady(WRF_NONE);
			#### # 0 A_Refire();
			goto Ready;
		Shoot:
			FRMG A 2;
			FRMG B 1 Offset (0, 36)
			{
				A_Overlay(PSP_FLASH, 'Flash');

				A_ZoomRecoil(1.05);
				A_Light1();
				if(invoker.WeaponStatus[FMProp_Mode] == 1 && CountInv("HealingMagic") > 0)
				{
					HDBulletActor.FireBullet(self, "HDB_776_Holy");
					A_TakeInventory("HealingMagic", 7);
					A_StartSound("Weapons/BigRifle2", CHAN_WEAPON, pitch: 0.85);
				}
				else
				{
					HDBulletActor.FireBullet(self, "HDB_776");
					A_StartSound("Weapons/BigRifle2", CHAN_WEAPON, pitch: 1.1);
				}
				invoker.WeaponStatus[FMProp_Chamber] = 1;
				A_MuzzleClimb(-frandom(-0.6, 0.6), -frandom(1.2, 2.1));
			}
			FRMG A 1 A_UpdateHammerFrame();
			goto Ready;
		Flash:
			FRMF A 1 Bright
			{
				HDFlashAlpha(72);
			}
			goto lightdone;

		AltFire:
		Chamber:
			FRMG # 0
			{
				A_UpdateHammerFrame();
				A_JumpIf(invoker.WeaponStatus[FMProp_Flags] & FMFAltHold,"nope");
			}
			#### # 0 A_SetAltHold(true);
			#### # 1 A_Overlay(120, "PlaySGCO");
			#### # 1;
			#### C 1 A_MuzzleClimb(0, frandom(0.6, 1));
			#### C 1 A_JumpIf(PressingAltFire(), "LongStroke");
			#### C 2 A_MuzzleClimb(0, -frandom(0.6, 1));
			#### C 0 A_Refire("Ready");
			goto Ready;
		LongStroke:
			FRMG D 2 A_MuzzleClimb(frandom(1, 2));
			#### D 0
			{
				A_Chamber();
				A_UpdateHammerFrame();
				A_MuzzleClimb(-frandom(1, 2));
			}
		Racked:
			FRMG D 1 A_WeaponReady(WRF_NOFIRE);
			#### D 0 A_JumpIf(!PressingAltFire(),"Unrack");
			#### D 0 A_JumpIf(PressingUnload(),"RackUnload");
			#### D 0 A_JumpIf(invoker.WeaponStatus[FMProp_Chamber],"Racked");
			#### D 0
			{
				int rld = 0;
				if(pressingReload())
				{
					rld = 1;
					if(invoker.WeaponStatus[FMProp_SideSaddles] > 0)invoker.WeaponStatus[FMProp_Flags] &=~ FMFFromPockets;
					else
					{
						invoker.WeaponStatus[FMProp_Flags] |= FMFFromPockets;
						rld = 2;
					}
				}
				else if(PressingAltReload())
				{
					rld = 2;
					invoker.WeaponStatus[FMProp_Flags] |= FMFFromPockets;
				}
				if((rld == 2 && CountInv("SevenMilAmmo")) || (rld == 1 && invoker.WeaponStatus[FMProp_SideSaddles] > 0))SetWeaponState("RackReload");
			}
			Loop;
		RackReload:
			FRMG D 1 Offset (-1, 35) A_WeaponBusy(true);
			#### D 2 Offset (-2, 37);
			#### D 4 Offset (-3, 40);
			#### D 1 Offset (-4, 42) A_GrabRounds(1, true, true);
			#### D 0 A_JumpIf(!(invoker.WeaponStatus[FMProp_Flags] & FMFFromPockets),"RackLoadOne");
			#### D 6 Offset (-5, 43);
			#### D 6 Offset (-4, 41) A_StartSound("Weapons/Pocket", 9);
		RackLoadOne:
			FRMG D 1 Offset (-4, 42);
			#### D 2 Offset (-4, 41);
			#### D 3 Offset (-4, 40)
			{
				A_StartSound("Weapons/BossLoad", 8, CHANF_OVERLAP);
				invoker.WeaponStatus[FMProp_Chamber] = 2;
				invoker.HandRounds--;
				EmptyHand(careful: true);
			}
			#### D 5 Offset (-4, 41);
			#### D 4 Offset (-4, 40) A_JumpIf(invoker.HandRounds > 0,"RackLoadOne");
			goto RackReloadEnd;
		RackReloadEnd:
			FRMG D 1 Offset (-3, 39);
			#### D 1 Offset (-2, 37);
			#### D 1 Offset (-1, 34);
			#### D 0 A_WeaponBusy(false);
			goto Racked;

		RackUnload:
			FRMG D 1 Offset (-1, 35) A_WeaponBusy(true);
			#### D 2 Offset (-2, 37);
			#### D 4 Offset (-3, 40);
			#### D 1 Offset (-4, 42);
			#### D 2 Offset (-4, 41);
			#### D 3 Offset (-4, 40)
			{
				int chm = invoker.WeaponStatus[FMProp_Chamber];
				invoker.WeaponStatus[FMProp_Chamber] = 0;
				if(chm == 2)
				{
					invoker.HandRounds++;
					EmptyHand(careful:true);
				}
				else if(chm == 1)A_SpawnItemEx("HDSpent7mm", cos(pitch) * 8, 0, height - 7 - sin(pitch) * 8, cos(pitch) * cos(angle - 40) * 1 + vel.x, cos(pitch) * sin(angle - 40) * 1 + vel.y, -sin(pitch) * 1 + vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH);
				if(chm)A_StartSound("Weapons/BossLoad", 8, CHANF_OVERLAP);
			}
			#### D 5 Offset (-4, 41);
			#### D 4 Offset (-4, 40) A_JumpIf(invoker.HandRounds > 0,"RackLoadOne");
			goto RackReloadEnd;

		Unrack:
			FRMG D 0 A_Overlay(120, "PlaySGCO2");
			#### C 1 A_JumpIf(!PressingFire(), 1);
			#### C 2;
			#### A 2
			{
				A_UpdateHammerFrame();
				if(PressingFire())A_SetTics(1);
				A_MuzzleClimb(0, -frandom(0.6, 1));
			}
			#### # 0 A_ClearRefire();
			goto Ready;
		PlaySGCO:
			TNT1 A 8 A_StartSound("Weapons/BoltBack", 8);
			TNT1 A 0 A_StopSound(8);
			stop;
		PlaySGCO2:
			TNT1 A 8 A_StartSound("Weapons/BoltFwd", 8);
			TNT1 A 0 A_StopSound(8);
			stop;

		Reload:
		Reloadfromsidesaddles:
			FRMG # 0
			{
				A_UpdateHammerFrame();
				int sss = invoker.WeaponStatus[FMProp_SideSaddles];
				int ppp = CountInv("SevenMilAmmo");
				if(ppp < 1 && sss < 1)SetWeaponState("nope");
				else if(sss < 1)invoker.WeaponStatus[FMProp_Flags] |= FMFFromPockets;
				else invoker.WeaponStatus[FMProp_Flags] &=~ FMFFromPockets;
			}
			goto StartReload;
		StartReload:
			FRMG # 1
			{
				A_UpdateHammerFrame();
				if(invoker.WeaponStatus[FMProp_Tube] >= MaxTube)
				{
					if(invoker.WeaponStatus[FMProp_SideSaddles] < MaxSideRounds && CountInv("SevenMilAmmo"))SetWeaponState("ReloadSS");
					else SetWeaponState("nope");
				}
			}
			#### # 6 A_MuzzleClimb(frandom(.6, .7),-frandom(.6, .7));
		ReloadStartHand:
			FRMG # 1 Offset (0, 36) A_UpdateHammerFrame();
			#### # 1 Offset (0, 38);
			#### # 2 Offset (0, 36);
			#### # 2 Offset (0, 34);
			#### # 2 Offset (0, 36);
			#### # 2 Offset (0, 40) A_CheckPocketSaddles();
			#### # 0 A_JumpIf(invoker.WeaponStatus[FMProp_Flags] & FMFFromPockets, "ReloadPocket");
		ReloadFast:
			FRMG # 3 Offset (0, 40)
			{
				A_UpdateHammerFrame();
				A_GrabRounds(3, false);
			}
			#### # 2 Offset (0, 42) A_StartSound("Weapons/Pocket", 9, volume: 0.4);
			#### # 2 Offset (0, 41);
			goto ReloadARound;
		ReloadPocket:
			FRMG # 3 Offset (0, 39)
			{
				A_UpdateHammerFrame();
				A_GrabRounds(3, false);
			}
			#### # 3 Offset (0, 40) A_StartSound("Weapons/Pocket", 9);
			#### # 6 Offset (0, 42) A_StartSound("Weapons/Pocket", 9);
			#### # 5 Offset (0, 41) A_StartSound("Weapons/Pocket", 9);
			goto ReloadARound;
		ReloadARound:
			FRMG # 2 Offset (0, 36) A_UpdateHammerFrame();
			#### # 3 Offset (0, 34) A_LoadTubeFromHand();
			#### # 5 Offset (0, 33)
			{
				if(PressingReload() || PressingAltReload() || PressingUnload() || PressingFire() || PressingAltfire() || PressingZoom() || PressingFiremode())invoker.WeaponStatus[FMProp_Flags] |= FMFHold;
				else invoker.WeaponStatus[FMProp_Flags] &=~ FMFHold;

				if(invoker.WeaponStatus[FMProp_Tube] == MaxTube || (invoker.HandRounds < 1 && (invoker.WeaponStatus[FMProp_Flags] & FMFFromPockets || invoker.WeaponStatus[FMProp_SideSaddles] < 1) && !CountInv("SevenMilAmmo")))SetWeaponState("ReloadEnd");
				else if(!PressingAltReload() && !pressingReload())SetWeaponState("ReloadEnd");
				else if(invoker.HandRounds < 1)SetWeaponState("ReloadStartHand");
			}
			goto ReloadARound;
		ReloadEnd:
			FRMG # 3 Offset (0, 34);
			#### # 1 Offset (0, 36) EmptyHand(careful: true);
			#### # 1 Offset (0, 34);
			#### # 6 A_UpdateHammerFrame();
			#### # 0 A_JumpIf(invoker.WeaponStatus[FMProp_Flags] & FMFHold, "nope");
			goto Ready;

		AltReload:
		ReloadFromPockets:
			FRMG # 0
			{
				A_UpdateHammerFrame();
				if(!CountInv("SevenMilAmmo"))SetWeaponState("nope");
				else invoker.WeaponStatus[FMProp_Flags] |= FMFFromPockets;
			}
			goto StartReload;

		ReloadSS:
			FRMG # 1 Offset (1, 34);
			#### # 2 Offset (2, 34);
			#### # 3 Offset (3, 36);
		ReloadSSRestart:
			FRMG # 6 Offset (3, 35);
			#### # 9 Offset (4, 34);
			#### # 4 Offset (3, 34)
			{
				int hnd = min(CountInv("SevenMilAmmo"), MaxSideRounds - invoker.WeaponStatus[FMProp_SideSaddles], 3);
				if(hnd < 1)SetWeaponState("ReloadSSEnd");
				else
				{
					A_TakeInventory("SevenMilAmmo",hnd);
					invoker.WeaponStatus[FMProp_SideSaddles] += hnd;
					A_StartSound("Weapons/Pocket",8);
				}
			}
			#### # 0
			{
				if(!PressingReload() && !PressingAltReload())SetWeaponState("ReloadSSEnd");
				else if(invoker.WeaponStatus[FMProp_SideSaddles] < MaxSideRounds && CountInv("SevenMilAmmo"))SetWeaponState("ReloadSSrestart");
			}
		ReloadSSEnd:
			FRMG # 3 Offset (2, 34);
			#### # 1 Offset (1, 34) EmptyHand(careful:true);
			goto nope;
		Hold:
			FRMG # 0
			{
				bool paf = PressingAltFire();
				if(paf && !(invoker.WeaponStatus[FMProp_Flags] & FMFAltHold))SetWeaponState("Chamber");
				else if(!paf)invoker.WeaponStatus[FMProp_Flags] &=~ FMFAltHold;
			}
			#### # 1 A_WeaponReady(WRF_NONE);
			#### # 0 A_Refire();
			goto Ready;

		UnloadSS:
			FRMG # 2 Offset (1, 34)
			{
				A_UpdateHammerFrame();
				A_JumpIf(invoker.WeaponStatus[FMProp_SideSaddles] < 1, "nope");
			}
			#### # 1 Offset (2, 34);
			#### # 1 Offset (3, 36);
		UnloadSSLoop1:
			FRMG # 4 Offset (4, 36) A_UpdateHammerFrame();
			#### # 2 Offset (5, 37) A_UnloadSideSaddle();
			#### # 3 Offset (4, 36)
			{
				if(PressingReload() || PressingFire() || PressingAltfire() || invoker.WeaponStatus[FMProp_SideSaddles] < 1)SetWeaponState("UnloadSSEnd");
			}
			goto UnloadSSLoop1;
		UnloadSSEnd:
			FRMG # 3 Offset (4, 35) A_UpdateHammerFrame();
			#### # 2 Offset (3, 35);
			#### # 1 Offset (2, 34);
			#### # 1 Offset (1, 34);
			goto nope;
		Unload:
			FRMG # 1
			{
				A_UpdateHammerFrame();
				if(invoker.WeaponStatus[FMProp_SideSaddles] > 0 && !(player.cmd.buttons & BT_USE))SetWeaponState("UnloadSS");
				else if(invoker.WeaponStatus[FMProp_Chamber] < 1 && invoker.WeaponStatus[FMProp_Tube] < 1)SetWeaponState("nope");
			}
			#### # 8 A_MuzzleClimb(frandom(1.2, 2.4), -frandom(1.2, 2.4));
			#### # 1 Offset (0, 34);
			#### # 1 Offset (0, 36);
			#### # 1 Offset (0, 38);
			#### # 4 Offset (0, 36)
			{
				A_MuzzleClimb(-frandom(1.2, 2.4), frandom(1.2, 2.4));
				if(invoker.WeaponStatus[FMProp_Chamber] < 1)
				{
					SetWeaponState("Unloadtube");
				}
			}
			#### # 8 Offset (0, 34)
			{
				A_MuzzleClimb(-frandom(1.2, 2.4), frandom(1.2, 2.4));
				int chm = invoker.WeaponStatus[FMProp_Chamber];
				invoker.WeaponStatus[FMProp_Chamber] = 0;
				if(chm > 1)
				{
					A_StartSound("Weapons/BossLoad", 8);
					if(A_JumpIfInventory("SevenMilAmmo", 0, "null"))A_SpawnItemEx("HDLoose7mm", cos(pitch) * 8, 0, height - 7 - sin(pitch) * 8, cos(pitch) * cos(angle - 40) * 1 + vel.x, cos(pitch) * sin(angle - 40) * 1 + vel.y, -sin(pitch) * 1 + vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH);
					else
					{
						HDF.Give(self,"SevenMilAmmo", 1);
						A_StartSound("Weapons/Pocket", 9);
						A_SetTics(5);
					}
				}
				else if(chm > 0)A_SpawnItemEx("HDSpent7mm", cos(pitch) * 8, 0, height - 7 - sin(pitch) * 8, cos(pitch) * cos(angle - 40) * 1 + vel.x, cos(pitch) * sin(angle - 40) * 1 + vel.y, -sin(pitch) * 1 + vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH);
			}
			#### # 0 A_JumpIf(!PressingUnload(),"ReloadEnd");
			#### # 4 Offset (0, 40) A_UpdateHammerFrame();
		Unloadtube:
			FRMG # 6 Offset (0, 40)
			{
				A_UpdateHammerFrame();
				EmptyHand(careful: true);
			}
		UnloadLoop:
			FRMG # 8 Offset (1, 41)
			{
				A_UpdateHammerFrame();
				if(invoker.WeaponStatus[FMProp_Tube] < 1)SetWeaponState("ReloadEnd");
				else if(invoker.HandRounds >= 3)SetWeaponState("UnloadLoopEnd");
				else
				{
					invoker.HandRounds++;
					invoker.WeaponStatus[FMProp_Tube]--;
				}
			}
			#### # 4 Offset (0, 40)
			{
				A_UpdateHammerFrame();
				A_StartSound("Weapons/BossLoad", 8);
			}
			Loop;
		UnloadLoopEnd:
			FRMG # 6 Offset (1, 41) A_UpdateHammerFrame();
			#### # 3 Offset (1, 42)
			{
				int rmm = HDPickup.MaxGive(self, "SevenMilAmmo", ENC_776);
				if(rmm > 0)
				{
					A_StartSound("Weapons/Pocket", 9);
					A_SetTics(8);
					HDF.Give(self, "SevenMilAmmo", min(rmm, invoker.HandRounds));
					invoker.HandRounds = max(invoker.HandRounds - rmm, 0);
				}
			}
			#### # 0 EmptyHand(careful: true);
			#### # 6
			{
				A_UpdateHammerFrame();
				A_Jumpif(!PressingUnload(), "ReloadEnd");
			}
			goto UnloadLoop;
	}
}


class HDB_776_Holy : HDBulletActor
{
	default
	{
		pushfactor 0.1;
		mass 120;
		speed HDCONST_MPSTODUPT * 1100;
		accuracy 600;
		stamina 776;
		woundhealth 5;
		hdbulletactor.hardness 4;
		hdbulletactor.distantsound "world/riflefar";
		hdbulletactor.distantsoundvol 2.;
	}

	override void OnHitActor(actor hitactor, vector3 hitpos, vector3 vu, int flags)
	{
		double tinyspeedsquared = speed * speed * 0.000001;
		double impact = tinyspeedsquared * 0.2 * mass;
		if (hitactor.bSHOOTABLE)
		{
			hitactor.damagemobj(self ,target, int(impact) << 2, "holy", DMG_NO_ARMOR);
			hitactor.A_GiveInventory("Heat", 500);
		}
		Super.OnHitActor(hitactor, hitpos, vu, flags);
	}
}