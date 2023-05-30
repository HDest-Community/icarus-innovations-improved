class ScorpionSpawner : IdleDummy
{
	states
	{
		Spawn:
			TNT1 A 0 NoDelay
			{
				A_SpawnItemEx("BrontornisRound", 1, flags: SXF_NOCHECKPOSITION);
				A_SpawnItemEx("BrontornisRound", -3,flags: SXF_NOCHECKPOSITION);
				let wpn = HDWeapon(Spawn('HDScorpion', pos, ALLOW_REPLACE));
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

class HDScorpion : HDWeapon
{
	enum ScorpionProperties
	{
		SCRProp_Chamber,
		SCRProp_Mag,
		SCRProp_Heat,
		SCRProp_LoadType,
		SCRProp_Hand,
		SCRProp_Dot
	}

	override bool AddSpareWeapon(actor newowner) {return AddSpareWeaponRegular(newowner);}
	override HDWeapon GetSpareWeapon(actor newowner, bool reverse, bool doselect) { return GetSpareWeaponRegular(newowner, reverse, doselect); }
	override double GunMass()
	{
		double Extra = 1.5 * WeaponStatus[SCRProp_Mag] + (WeaponStatus[SCRProp_Chamber] == 2 ? 1.5 : 0);
		return 18 + Extra;
	}
	override double WeaponBulk()
	{
		return 200 + (WeaponStatus[SCRProp_Chamber] > 1 ? ENC_BRONTOSHELLLOADED : 0) + WeaponStatus[SCRProp_Mag] * ENC_BRONTOSHELLLOADED;
	}
	override string, double GetPickupSprite() { return "SCRPZ0", 0.5; }
	override void InitializeWepStats(bool idfa)
	{
		WeaponStatus[SCRProp_Chamber] = 2;
		WeaponStatus[SCRProp_Mag] = MaxMag;
		WeaponStatus[SCRProp_Heat] = 0;
	}
	override void LoadoutConfigure(string input)
	{
		WeaponStatus[SCRProp_Chamber] = 2;
		WeaponStatus[SCRProp_Mag] = MaxMag;
	}
	override void Tick()
	{
		Super.Tick();
		DrainHeat(SCRProp_Heat, 12);
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		if (sb.HudLevel == 1)
		{
			sb.DrawImage("BROCA0", (-48, -10), sb.DI_SCREEN_CENTER_BOTTOM, scale: (0.7, 0.7));
			sb.DrawNum(hpl.CountInv("BrontornisRound"), -45, -8, sb.DI_SCREEN_CENTER_BOTTOM);
		}

		sb.DrawWepNum(hpl.CountInv("BrontornisRound"), (HDCONST_MAXPOCKETSPACE / ENC_BRONTOSHELL), posy: -2);

		int Chamber = hdw.WeaponStatus[SCRProp_Chamber];
		if (Chamber > 0)
		{
			sb.DrawRect(-16, -13, Chamber == 2 ? -5 : -2, 3);
		}

		for (int i = hdw.WeaponStatus[SCRProp_Mag]; i > 0; --i)
		{
			sb.drawrect(-15 - i * 5, -8, 4, 3);
		}
	}

	override string GetHelpText()
	{
		return WEPHELP_FIRESHOOT
		..WEPHELP_ALTFIRE.."  Work bolt\n"
		..WEPHELP_RELOAD.."  Reload rounds\n"
		..WEPHELP_UNLOADUNLOAD;
	}

	override void SetReflexReticle(int which) { weaponstatus[SCRProp_Dot] = which; }

	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
	){
			int cx,cy,cw,ch;
		[cx,cy,cw,ch]=Screen.GetClipRect();
		sb.SetClipRect(
			-16+bob.x,-64+bob.y,32,76,
			sb.DI_SCREEN_CENTER
		);
		sb.drawimage(
			"bsfrntsit",bob*1.14,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP
		);
		sb.SetClipRect(cx,cy,cw,ch);

		sb.drawimage(
			"bsbaksit",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			alpha:0.9
		);

		if(scopeview){
			int scaledwidth=89;
			int scaledyoffset=60;
			double degree=0.1*hdw.weaponstatus[BOSSS_ZOOM];
			double deg=1/degree;
			int cx,cy,cw,ch;
			[cx,cy,cw,ch]=screen.GetClipRect();
			sb.SetClipRect(-44+bob.x,16+bob.y,scaledwidth,scaledwidth,
				sb.DI_SCREEN_CENTER
			);

			sb.fill(color(255,0,0,0),
				bob.x-44,scaledyoffset+bob.y-44,
				88,88,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
			);

			texman.setcameratotexture(hpc,"HDXCAM_BOSS",4);
			let cam     = texman.CheckForTexture("HDXCAM_BOSS",TexMan.Type_Any);
			let reticle = texman.CheckForTexture("bossret1",TexMan.Type_Any);

			vector2 frontoffs=(0,scaledyoffset)+bob*3;

			double camSize  = texman.GetSize(cam);
			sb.DrawCircle(cam, frontoffs, 0.125,usePixelRatio:true);

			//[2022-09-17] there's a glitch in GZDoom where if the reticle would be drawn completely off screen,
			//the cliprect is ignored. The figure is a product of trial and error.
			if((bob.y/fov)<0.4){
				let reticleScale = camSize / texman.GetSize(reticle);
				if(hdw.weaponstatus[0]&BOSSF_FRONTRETICLE){
					sb.DrawCircle(reticle, frontoffs, .5*reticleScale, bob*deg*5-bob, 1.6*deg);
				}else{
					sb.DrawCircle(reticle, (0,scaledyoffset)+bob, .5*reticleScale,uvScale:.5);
				}
			}

			//let holeScale    = camSize / texman.GetSize(hole);
			//let hole    = texman.CheckForTexture("scophole",TexMan.Type_Any);
			//sb.DrawCircle(hole, (0, scaledyoffset) + bob, .5 * holeScale, bob * 5, 1.5);


			screen.SetClipRect(cx,cy,cw,ch);

			sb.drawimage(
				"bossscope",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
				scale:(1.24,1.24)
			);

		}
		// the scope display is in 10ths of an arcminute.
		// one dot = 6 arcminutes.
	}

	
	override void DropOneAmmo(int amt)
	{
		if (owner)
		{
			owner.A_DropInventory("BrontornisRound", 1);
		}
	}

	const MaxMag = 5;

	Default
	{
		Weapon.SelectionOrder 60;
		Weapon.SlotNumber 7;
		Weapon.SlotPriority 2;
		Weapon.Kickback 100;
		Weapon.BobRangeX 0.21;
		Weapon.BobRangeY 0.86;
		Scale 0.3;
		Inventory.PickupMessage "You got the 'Scorpion' 35mm sniper cannon.";
		HDWeapon.BarrelSize 45, 1.4, 2;
		Tag "Scorpion";
		HDWeapon.Refid "scr";
	}

	States
	{
		Spawn:
			SCRP Z -1;
			Stop;
		Ready:
			SCRP A 1 A_WeaponReady(WRF_ALL);
			Goto ReadyEnd;
		Select0:
			SCRP A 0;
			Goto Select0BFG;
		Deselect0:
			SCRP A 0;
			Goto Deselect0BFG;
		User3:
			#### A 0 A_MagManager("PickupManager");
			Goto Ready;
		Fire:
			#### A 0
			{
				if (invoker.WeaponStatus[SCRProp_Chamber] < 2)
				{
					SetWeaponState("Nope");
					return;
				}
			}
			#### B 1 Bright Offset(0, 34)
			{
				A_GiveInventory("IsMoving", GunBraced() ? 2 : 7);

				if (!bINVULNERABLE && (CountInv("IsMoving") > 6 || floorz < pos.z))
				{
					GiveBody(max(0, 11 - health));
					DamageMobj(invoker, self, 10, "bashing");
					A_GiveInventory("IsMoving", 5);
					A_ChangeVelocity(cos(pitch) * -frandom(2, 4), 0, sin(pitch) * frandom(2, 4), CVF_RELATIVE);
				}

				HDFlashAlpha(0, true);
				A_Light1();
				A_StartSound("Scorpion/Fire", CHAN_WEAPON);

				HDBulletActor.FireBullet(self, "HDB_bronto", speedfactor: 1.15);
				invoker.WeaponStatus[SCRProp_Chamber] = 1;
				invoker.WeaponStatus[SCRProp_Heat] += 32;
			}
			#### A 1
			{
				A_ZoomRecoil(0.5);
				A_Light0();
			}
			#### A 0
			{
				double RecoilSide = frandompick(-0.5, 0.5);
				double RecoilMult = 1.0;
				if (GunBraced())
				{
					HDPlayerPawn(self).gunbraced = false;
					A_ChangeVelocity(-frandom(0.4, 0.8)  * cos(pitch), 0, frandom(0.4, 0.8) * sin(pitch), CVF_RELATIVE);
					A_MuzzleClimb(RecoilSide * 0.5 * RecoilMult, -frandom(1.0, 1.2) * RecoilMult, RecoilSide * 0.5 * RecoilMult, -frandom(1.0, 1.2) * RecoilMult);
				}
				else
				{
					A_ChangeVelocity(-frandom(1.0, 1.6)  * cos(pitch), 0, frandom(1.0, 1.6) * sin(pitch), CVF_RELATIVE);
					A_MuzzleClimb(RecoilSide * RecoilMult, -frandom(1.0, 1.2) * RecoilMult, RecoilSide * RecoilMult, -frandom(1.0, 1.2) * RecoilMult);
					A_MuzzleClimb(RecoilSide * RecoilMult, -frandom(1.0, 1.2) * RecoilMult, RecoilSide * RecoilMult, -frandom(1.0, 1.2) * RecoilMult, wepdot: true);
				}
 			}
			Goto Nope;
		AltFire:
			#### A 1 Offset(0, 34) A_WeaponBusy();
			#### C 1 Offset(1, 35);
			#### D 1 Offset(2, 36);
			#### E 1 Offset(3, 37);
			#### F 1 Offset(4, 38);
			#### G 0 A_Refire("Chamber");
			Goto Ready;
		Chamber:
			#### G 4 Offset(4, 38);
			#### G 3 Offset(6, 42)
			{
				A_StartSound("Scorpion/BoltBack", 8);
				if (GunBraced())
				{
					A_MuzzleClimb(frandom(-0.1, 0.3), frandom(-0.1, 0.3));
				}
				else
				{
					A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.4, 0.8));
				}
			}
			#### G 2 Offset(6, 42)
			{
				switch (invoker.WeaponStatus[SCRProp_Chamber])
				{
					case 2: A_SpawnItemEx("BrontornisRound", cos(pitch) * 2, 0, height - 10 - sin(pitch) * 2, vel.x, vel.y, vel.z - frandom(-1, 1), random(-3, 3), SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH | SXF_TRANSFERTRANSLATION); break;
					case 1: A_SpawnItemEx("TerrorCasing", cos(pitch) * 8, 1, height - 15 - sin(pitch) * 8, cos(pitch) * cos(angle - 80) * 6 + vel.x, cos(pitch) * sin(angle - 80) * 6 + vel.y, -sin(pitch) * 4 + vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH | SXF_TRANSFERTRANSLATION); break;
				}
				
				if (invoker.WeaponStatus[SCRProp_Mag] > 0)
				{  
					invoker.WeaponStatus[SCRProp_Chamber] = 2;
					invoker.WeaponStatus[SCRProp_Mag]--;
				}
				else
				{
					invoker.WeaponStatus[SCRProp_Chamber] = 0;
				}
			}
			#### H 2 Offset(7, 44);
			#### I 2 Offset(6, 46);
			#### I 1 Offset(5, 42);
			#### I 1 Offset(3, 38);
			#### I 1 Offset(1, 34);
			#### I 1 A_WeaponReady(WRF_NOFIRE);
			#### I 0 A_Refire("AltHold");
			Goto AltHoldEnd;
		AltHold:
			#### # 1 A_WeaponReady(WRF_NOFIRE);
			#### # 1
			{
				A_ClearRefire();
				bool ChamberEmpty = invoker.WeaponStatus[SCRProp_Chamber] < 1;
				if (PressingReload())
				{
					if (!ChamberEmpty)
					{
						invoker.WeaponStatus[SCRProp_LoadType] = 0;
						return ResolveState("LoadChamber");
					}
					else if (CheckInventory("BrontornisRound", 1))
					{
						invoker.WeaponStatus[SCRProp_LoadType] = 1;
						return ResolveState("LoadChamber");
					}
				}

				if (PressingAltFire())
				{
					return ResolveState("AltHold");
				}

				return ResolveState("AltHoldEnd");
			}
			Stop;
		LoadChamber:
			#### # 1 Offset(2, 36) A_ClearRefire();
			#### # 1 Offset(3, 38);
			#### # 1 Offset(5, 42);
			#### # 1 Offset(8, 48) A_StartSound("weapons/pocket", 9);
			#### # 1 Offset(9, 52) A_MuzzleClimb(frandom(-0.2, 0.2), 0.2, frandom(-0.2, 0.2),0.2, frandom(-0.2, 0.2), 0.2);
			#### # 1 Offset(8, 60);
			#### # 1 Offset(7, 72);
			#### # 1 Offset(6, 80);
			#### # 1 Offset(6, 88);
			TNT1 # 25;
			TNT1 # 4
			{
				A_StartSound("Scorpion/BossLoad", 8, volume: 0.7);
				switch (invoker.WeaponStatus[SCRProp_LoadType])
				{
					case 0:
						int Chamber = invoker.WeaponStatus[SCRProp_Chamber];
						invoker.WeaponStatus[SCRProp_Chamber] = 0;
						if (Chamber < 2 || A_JumpIfInventory("BrontornisRound", 0, "null"))
						{
							Class<actor> EjectClass = Chamber == 2 ? "BrontornisRound" : "TerrorCasing";
							actor rrr = Spawn(EjectClass, pos + (cos(angle) * 10, sin(angle) * 10,  height - 12), ALLOW_REPLACE);
							rrr.angle = angle;
							rrr.A_ChangeVelocity(1, 2, 1, CVF_RELATIVE);
						}
						else
						{
							HDF.Give(self, "BrontornisRound", 1);
						}
						break;
					case 1:
						A_TakeInventory("BrontornisRound", 1, TIF_NOTAKEINFINITE);
						invoker.WeaponStatus[SCRProp_Chamber] = 2;
						break;
				}
			}
			SCRP # 2 Offset(6, 80);
			#### # 2 Offset(7, 72);
			#### # 2 Offset(8, 60);
			#### # 1 Offset(7, 52);
			#### # 1 Offset(5, 42);
			#### # 1 Offset(3, 38);
			#### # 1 Offset(3, 35);
			Goto AltHold;
		AltHoldEnd:
			#### H 2 A_StartSound("Scorpion/BoltFwd", 8);
			#### HGEDC 2;
			Goto Ready;
		Reload:
			#### A 0
			{
				if (invoker.WeaponStatus[SCRProp_Mag] == MaxMag)
				{
					SetWeaponState("ReloadDone");
				}
			}
			#### A 2 Offset(0, 34);
			#### A 2 Offset(2, 36);
			#### A 2 Offset(4, 40);
			#### A 4 Offset(8, 42)
			{
				A_StartSound("Scorpion/RifleClick2", 8, CHANF_OVERLAP, 0.9, pitch: 0.95);
				A_MuzzleClimb(-frandom(0.4, 0.8), frandom(0.4,  1.4));
			}
			#### A 8 Offset(14, 46)
			{
				A_StartSound("Scorpion/RifleLoad", 8, CHANF_OVERLAP);
				A_MuzzleClimb(-frandom(0.4, 0.8), frandom(0.4, 1.4));
			}
		LoadHand:
			#### A 0 A_JumpIfInventory("BrontornisRound", 1, "LoadHandLoop");
			Goto ReloadDone;
		LoadHandLoop:
			#### A 4
			{
				if (!CheckInventory("BrontornisRound", 1) || invoker.WeaponStatus[SCRProp_Mag] == MaxMag)
				{
					SetWeaponState("ReloadDone");
					return;
				}
				A_TakeInventory("BrontornisRound", 1, TIF_NOTAKEINFINITE);
				invoker.WeaponStatus[SCRProp_Hand] = 1;
				A_StartSound("weapons/pocket", 9);
			}
		LoadOne:
			#### A 5 Offset(16, 50) A_JumpIf(invoker.WeaponStatus[SCRProp_Hand] < 1, "LoadHandNext");
			#### A 7 Offset(14, 46)
			{
				invoker.WeaponStatus[SCRProp_Hand]--;
				invoker.WeaponStatus[SCRProp_Mag]++;
				A_StartSound("Scorpion/RifleClick2", 8);
			}
			Loop;
		LoadHandNext:
			#### A 16 Offset(16, 48)
			{
				if (PressingReload() || PressingFire() || PressingAltFire() || PressingZoom() || !CheckInventory("BrontornisRound", 1))
				{
					SetWeaponState("ReloadDone");
					return;
				}
			}
			Goto LoadHandLoop;
		ReloadDone:
			#### A 1 Offset(4, 40);
			#### A 1 Offset(2, 36);
			#### A 1 Offset(0, 34);
			Goto nope;
		Unload:
			#### A 0
			{
				if (invoker.WeaponStatus[SCRProp_Mag] < 1)
				{
					SetWeaponState("Nope");
				}
			}
			#### A 1 Offset(0, 34);
			#### A 1 Offset(2, 36);
			#### A 1 Offset(4, 40);
			#### A 2 Offset(8, 42)
			{
				A_MuzzleClimb(-frandom(0.4, 0.8),frandom(0.4, 1.4));
				A_StartSound("Scorpion/RifleClick2", 8);
			}
			#### A 4 Offset (14, 46){

				A_MuzzleClimb(-frandom(0.4, 0.8), frandom(0.4,  1.4));
				A_StartSound("Scorpion/RifleLoad", 8);
			}
		UnloadLoop:
			#### A 12 Offset(3, 41)
			{
				if (invoker.WeaponStatus[SCRProp_Mag] < 1)
				{
					SetWeaponState("UnloadDone");
					return;
				}
				A_StartSound("Scorpion/RifleClick2", 8);
				invoker.WeaponStatus[SCRProp_Mag]--;

				if (A_JumpIfInventory("BrontornisRound", 0, "null"))
				{
					A_SpawnItemEx("BrontornisRound", cos(pitch) * 2, 0, height - 10 - sin(pitch) * 2, vel.x, vel.y, vel.z - frandom(-1, 1), random(-3, 3), SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH | SXF_TRANSFERTRANSLATION);
				}
				else
				{
					A_GiveInventory("BrontornisRound", 1);
				}
			}
			#### A 4 Offset(2, 42);
			#### A 0
			{
				if (PressingReload() || PressingFire() || PressingAltFire() || PressingZoom() || !CheckInventory("BrontornisRound", 1))
				{
					SetWeaponState("UnloadDone");
				}
			}
			Loop;
		UnloadDone:
			#### A 2 Offset(2, 42);
			#### A 3 Offset(3, 41);
			#### A 1 Offset(4, 40) A_StartSound("Scorpion/RifleClick", 8);
			#### A 1 Offset(2, 36);
			#### A 1 Offset(0, 34);
			Goto ready;
	}
}
