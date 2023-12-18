class HDMBR : HDWeapon
{
	enum MBRFrames
	{
		BRFrame_Basic,
		BRFrame_Short,
		BRFrame_Bull
	}

	enum MBRChamber
	{
		BRChamber_Empty,
		BRChamber_SpentLight,
		BRChamber_Light,
		BRChamber_SpentHeavy,
		BRChamber_Heavy
	}

	enum MBRFlags
	{
		BRF_JustUnload = 1,
		BRF_GrenadeLoaded = 2,
		BRF_FireSelector = 4,
		BRF_Scope = 8,
		BRF_GL = 16
	}

	enum MBRProperties
	{
		BRProp_Flags,
		BRProp_Chamber,
		BRProp_Firemode,
		BRProp_Frame,
		BRProp_Mag,
		BRProp_MagType,
		BRProp_LoadType,
		BRProp_Zoom,
		BRProp_DropAdjust
	}

	override void PostBeginPlay()
	{
		weaponspecial = 1337; // [Ace] UaS sling compatibility.
		Super.PostBeginPlay();
	}

	override void Tick()
	{
		Super.Tick();
		
		switch (WeaponStatus[BRProp_Frame])
		{
			case BRFrame_Basic:
				BarrelLength = 32;
				bFITSINBACKPACK = false;
				break;
			case BRFrame_Short:
				BarrelLength = 24;
				bFITSINBACKPACK = True;
				break;
			case BRFrame_Bull:
				BarrelLength = 38;
				bFITSINBACKPACK = false;
				break;
		}

		if (!(WeaponStatus[BRProp_Flags] & BRF_GL) && WeaponStatus[BRProp_Flags] & BRF_GrenadeLoaded)
		{
			WeaponStatus[BRProp_Flags] &= ~BRF_GrenadeLoaded;
			Actor ptr = owner ? owner : Actor(self);
			ptr.A_SpawnItemEx('HDRocketAmmo', cos(ptr.pitch) * 10, 0, ptr.height - 10 - 10 * sin(ptr.pitch), ptr.vel.x, ptr.vel.y, ptr.vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH);
			ptr.A_StartSound("MBR/GrenadeOpen", CHAN_WEAPON);
		}
	}

	override bool AddSpareWeapon(actor newowner) { return AddSpareWeaponRegular(newowner); }
	override HDWeapon GetSpareWeapon(actor newowner, bool reverse, bool doselect) { return GetSpareWeaponRegular(newowner, reverse, doselect); }
	override double GunMass()
	{
		double BaseMass = 10;
		switch (WeaponStatus[BRProp_Frame])
		{
			case BRFrame_Short: BaseMass = 8; break;
			case BRFrame_Bull: BaseMass = 13; break;
		}
		if (WeaponStatus[BRProp_Flags] & BRF_Scope)
		{
			BaseMass += 0.3;
		}
		if (WeaponStatus[BRProp_Flags] & BRF_GL)
		{
			BaseMass += 0.8;
		}
		if (WeaponStatus[BRProp_Flags] & BRF_GrenadeLoaded)
		{
			BaseMass += 0.2;
		}

		double RndMass = WeaponStatus[BRProp_MagType] == 0 ? 0.04 : 0.05;
		double MagMass = WeaponStatus[BRProp_MagType] == 0 ? HDMBRMagLight.EncMagLoaded * 0.1 : HDMBRMagHeavy.EncMagLoaded * 0.1;
		return BaseMass + (WeaponStatus[BRProp_Mag] > -1 ? MagMass + RndMass * WeaponStatus[BRProp_Mag] : 0);
	}
	override double WeaponBulk()
	{
		double BaseBulk = 120;
		switch (WeaponStatus[BRProp_Frame])
		{
			case BRFrame_Short: BaseBulk = 100; break;
			case BRFrame_Bull: BaseBulk = 140; break;
		}
		if (WeaponStatus[BRProp_Flags] & BRF_Scope)
		{
			BaseBulk += 7;
		}
		if (WeaponStatus[BRProp_Flags] & BRF_GL)
		{
			BaseBulk += 10;
		}
		if (WeaponStatus[BRProp_Flags] & BRF_GrenadeLoaded)
		{
			BaseBulk += ENC_ROCKETLOADED;
		}

		int Mag = WeaponStatus[BRProp_Mag];
		if (Mag >= 0)
		{
			BaseBulk += (WeaponStatus[BRProp_MagType] == 0 ? HDMBRMagLight.EncMagLoaded : HDMBRMagHeavy.EncMagLoaded) + Mag * ENC_50SW_LOADED;
		}
		return BaseBulk;
	}
	
	override string, double GetPickupSprite()
	{
		string s; int f;
		[s, f] = GetFullSprite();
		return s..String.Format("%c", 65 + f).."0", 0.8;
	}
	override void LoadoutConfigure(string input)
	{
		if (GetLoadoutVar(input, "heavy", 1) > 0)
		{
			WeaponStatus[BRProp_MagType] = 1;
		}
		if (GetLoadoutVar(input, "cqc", 1) > 0)
		{
			WeaponStatus[BRProp_Frame] = BRFrame_Short;
		}
		if (GetLoadoutVar(input, "dmr", 1) > 0)
		{
			WeaponStatus[BRProp_Frame] = BRFrame_Bull;
		}
		if (GetLoadoutVar(input, "scope", 1) > 0)
		{
			WeaponStatus[BRProp_Flags] |= BRF_Scope;
		}
		if (GetLoadoutVar(input, "select", 1) > 0)
		{
			WeaponStatus[BRProp_Flags] |= BRF_FireSelector;
		}
		if (GetLoadoutVar(input, "gl", 1) > 0)
		{
			WeaponStatus[BRProp_Flags] |= BRF_GL;
		}

		InitializeWepStats(false);
	}
	override void InitializeWepStats(bool idfa)
	{
		WeaponStatus[BRProp_Mag] = WeaponStatus[BRProp_MagType] == 0 ? HDMBRMagLight.MagCapacity : HDMBRMagHeavy.MagCapacity;
		WeaponStatus[BRProp_Chamber] = WeaponStatus[BRProp_MagType] == 0 ? BRChamber_Light : BRChamber_Heavy;
		WeaponStatus[BRProp_Zoom] = 40;
		WeaponStatus[BRProp_DropAdjust] = 270;
		if (WeaponStatus[BRProp_Flags] & BRF_GL)
		{
			WeaponStatus[BRProp_Flags] |= BRF_GrenadeLoaded;
		}
	}

	override string GetHelpText()
	{
		return WEPHELP_FIRESHOOT
		..(WeaponStatus[BRProp_Flags] & BRF_GL ? WEPHELP_ALTFIRE.. "  Fire GL\n" : "")
		..(WeaponStatus[BRProp_Flags] & BRF_GL ? WEPHELP_ALTRELOAD.. "  Load GL\n" : "")
		..(WeaponStatus[BRProp_Flags] & BRF_GL ? WEPHELP_FIREMODE.."+"..WEPHELP_UNLOAD.. "  Unload GL\n" : "")
		..(WeaponStatus[BRProp_Flags] & BRF_Scope ? WEPHELP_ZOOM.."+"..WEPHELP_FIREMODE.."+"..WEPHELP_UPDOWN.."  Zoom\n" : "")
		..WEPHELP_RELOAD.."  Load factory mag\n"
		..WEPHELP_USE.."+"..WEPHELP_RELOAD.."  Load heavy mag\n"
		..WEPHELP_UNLOAD.. "  Unload loaded mag\n"
		.."("..WEPHELP_USE..")+"..WEPHELP_FIREMODE.."+"..WEPHELP_RELOAD.. "  Load chamber\n"
		.."("..WEPHELP_USE..")+"..WEPHELP_MAGMANAGER;
	}

	// [Ace] Returns sprite + frame.
	clearscope string, int GetFullSprite()
	{
		string SName = "MFC";
		switch (WeaponStatus[BRProp_Frame])
		{
			case BRFrame_Short: SName = "CQC"; break;
			case BRFrame_Bull: SName = "DMR"; break;
		}

		SName = SName..(WeaponStatus[BRProp_MagType] == 0 ? "L" : "H");

		int SFrame = 0;
		if (WeaponStatus[BRProp_Mag] >= 0)
		{
			SFrame |= 1;
		}
		if (WeaponStatus[BRProp_Flags] & BRF_Scope)
		{
			SFrame |= 2;
		}
		if (WeaponStatus[BRProp_Flags] & BRF_FireSelector)
		{
			SFrame |= 4;
		}
		if (WeaponStatus[BRProp_Flags] & BRF_GL)
		{
			SFrame |= 8;
		}

		/*
			A (0) - No mag, no attachments.
			B (1) - Mag, no attachments.
			C (2) - No mag + scope
			D (3) - Mag + scope
			E (4) - No mag + fire selector
			F (5) - Mag + fire selector
			G (6) - No mag + scope + fire selector
			H (7) - Mag + scope + fire selector
			I (8) - No mag + GL
			J (9) - Mag + GL
			K (10) - No mag + GL + scope
			L (11) - Mag + GL + scope
			M (12) - No mag + GL + fire selector
			N (13) - Mag + GL + fire selector
			O (14) - No mag + GL + scope + fire selector
			P (15) - Mag + GL + scope + fire selector
		*/

		return SName, SFrame;
	}

	override string PickupMessage()
	{
		string ConfigString = "";
		switch (WeaponStatus[BRProp_Frame])
		{
			case BRFrame_Basic: ConfigString = " in factory configuration"; break;
			case BRFrame_Short: ConfigString = " in CQC configuration"; break;
			case BRFrame_Bull: ConfigString = " in DMR configuration"; break;
		}
		string SelFireStr = WeaponStatus[BRProp_Flags] & BRF_FireSelector ? " select-fire" : "";
		string ScopedStr = WeaponStatus[BRProp_Flags] & BRF_Scope ? " scoped" : "";
		string GLString = WeaponStatus[BRProp_Flags] & BRF_GL ? " This one has a grenade launcher." : "";
		return String.Format("You picked up the%s%s Modular Battle Rifle%s.%s", ScopedStr, SelFireStr, ConfigString, GLString);
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		if (sb.hudlevel == 1)
		{
			int NextMagLight = sb.GetNextLoadMag(HDMagAmmo(hpl.FindInventory('HDMBRMagLight')));
			if (NextMagLight >= HDMBRMagLight.MagCapacity)
			{
				sb.DrawImage("5LMGA0", (-20, -5),sb. DI_SCREEN_CENTER_BOTTOM);
			}
			else if (NextMagLight <= 0)
			{
				sb.DrawImage("5LMGB0", (-20, -5), sb.DI_SCREEN_CENTER_BOTTOM, alpha: NextMagLight ? 0.6 : 1.0);
			}
			else
			{
				sb.DrawBar("5LMGNORM", "5MAGGREY", NextMagLight, HDMBRMagLight.MagCapacity, (-20, -5), -1, sb.SHADER_VERT, sb.DI_SCREEN_CENTER_BOTTOM);
			}
			sb.DrawNum(hpl.CountInv('HDMBRMagLight'), -18, -8, sb.DI_SCREEN_CENTER_BOTTOM);

			int NextMagHeavy = sb.GetNextLoadMag(HDMagAmmo(hpl.FindInventory('HDMBRMagHeavy')));
			if (NextMagHeavy >= HDMBRMagHeavy.MagCapacity)
			{
				sb.DrawImage("5HMGA0", (-35, -5),sb. DI_SCREEN_CENTER_BOTTOM);
			}
			else if (NextMagHeavy <= 0)
			{
				sb.DrawImage("5HMGB0", (-35, -5), sb.DI_SCREEN_CENTER_BOTTOM, alpha: NextMagHeavy ? 0.6 : 1.0);
			}
			else
			{
				sb.DrawBar("5HMGNORM", "5HMGGREY", NextMagHeavy, HDMBRMagHeavy.MagCapacity, (-35, -5), -1, sb.SHADER_VERT, sb.DI_SCREEN_CENTER_BOTTOM);
			}
			sb.DrawNum(hpl.CountInv('HDMBRMagHeavy'), -33, -8, sb.DI_SCREEN_CENTER_BOTTOM);

			if (hdw.WeaponStatus[BRProp_Flags] & BRF_GL)
			{
				sb.DrawImage("ROQPA0",(-50, -4), sb.DI_SCREEN_CENTER_BOTTOM, scale: (0.6, 0.6));
				sb.DrawNum(hpl.CountInv('HDRocketAmmo'), -48, -8, sb.DI_SCREEN_CENTER_BOTTOM);
			}
		}

		if (hdw.WeaponStatus[BRProp_Flags] & BRF_FireSelector)
		{
			sb.DrawWepCounter(hdw.WeaponStatus[BRProp_Firemode], -22, -21, "RBRSA3A7", "STFULAUT");
		}
		if (hdw.WeaponStatus[BRProp_Mag] > 0)
		{
			sb.DrawWepNum(hdw.WeaponStatus[BRProp_Mag], HDMBRMagLight.MagCapacity, posy: -16);
		}
		if (hdw.WeaponStatus[BRProp_Chamber] == BRChamber_Light || hdw.WeaponStatus[BRProp_Chamber] == BRChamber_Heavy)
		{
			sb.DrawRect(-19, -21, 3, 1);
		}
		if (hdw.WeaponStatus[BRProp_Flags] & BRF_GrenadeLoaded)
		{
			sb.DrawRect(-20, -24.6, 4, 2.6);
		}
	}
	
	override void DrawSightPicture(
		HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl,
		bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc
	) {
		int cx, cy, cw, ch;
		[cx, cy, cw, ch] = Screen.GetClipRect();
		sb.SetClipRect(
			-16 + bob.x,
			-64 + bob.y,
			32, 76,
			sb.DI_SCREEN_CENTER
		);
		
		vector2 bob2 = bob * 1.18;
		//bob2.y = clamp(bob2.y, -8, 8);
		sb.DrawImage("MBRGFRNT", bob2, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, alpha: 0.9, scale: (0.6, 0.6));

		sb.SetClipRect(cx, cy, cw, ch);
		sb.DrawImage("MBRGBACK", (0, 0) + bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP,
			alpha: 0.9,
			scale: (1.0, 0.9)
		);

		if (hdw.WeaponStatus[BRProp_Flags] & BRF_Scope && scopeview)
		{
			int ScaledWidth = 72;
			int ScaledYOffset = 60;
			double Degree = 0.1 * hdw.WeaponStatus[BRProp_Zoom];
			int cx, cy, cw, ch;
			[cx, cy, cw, ch] = Screen.GetClipRect();
			sb.SetClipRect(-36 + bob.x, 24 + bob.y, ScaledWidth, ScaledWidth,
				sb.DI_SCREEN_CENTER
			);

			sb.fill(color(255,0,0,0),
				bob.x-36, ScaledYOffset+bob.y-36,
				72, 72, sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
			);

			TexMan.SetCameraToTexture(hpc, "HDXCAM_LIB", Degree);
			let cam     = TexMan.CheckForTexture("HDXCAM_LIB", TexMan.Type_Any);
			let reticle = TexMan.CheckForTexture("reticle2", TexMan.Type_Any);

			vector2 frontoffs = (0, ScaledYOffset) + bob * 2;

			double camSize = texman.GetSize(cam);
			sb.DrawCircle(cam, frontoffs, .08825, usePixelRatio: true);
			
			if((bob.y / fov) < 0.4)
			{
				let reticleScale = camSize / texman.GetSize(reticle);
				sb.DrawCircle(reticle, (0, scaledyoffset) + bob, 0.403 * reticleScale, uvScale: 0.52);
			}

			Screen.SetClipRect(cx,cy,cw,ch);

			sb.DrawImage(
				"libscope", (0, ScaledYOffset) + bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_CENTER/* ,
				scale:(1.24, 1.24) */
			);
			sb.drawstring(
				sb.mAmountFont,string.format ("%.1f", degree),
				(6 + bob.x, 95 + bob.y), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_RIGHT,
				Font.CR_BLACK
			);
			sb.drawstring(
				sb.mAmountFont,string.format ("%i", hdw.WeaponStatus[BRProp_DropAdjust]),
				(6+bob.x,17+bob.y), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_RIGHT,
				Font.CR_BLACK
			);
		}
	}

	override void DropOneAmmo(int amt)
	{
		if (owner)
		{
			double OldAngle = owner.angle;

			amt = clamp(amt, 10, 20);
			if (owner.CheckInventory('HD500SWLightAmmo', 1))
			{
				owner.A_DropInventory('HD500SWLightAmmo', amt * 2);
				owner.angle += 15;
			}
			else
			{
				owner.A_DropInventory('HDMBRMagLight', 1);
				owner.angle += 15;
			}

			if (owner.CheckInventory('HD500SWHeavyAmmo', 1))
			{
				owner.A_DropInventory('HD500SWHeavyAmmo', amt);
				owner.angle += 15;
			}
			else
			{
				owner.A_DropInventory('HDMBRMagHeavy', 1);
				owner.angle += 15;
			}

			if (owner.CheckInventory('HDRocketAmmo', 1))
			{
				owner.A_DropInventory('HDRocketAmmo', 1);
			}

			owner.angle = OldAngle;
		}
	}

	transient int OldFireMode;

	Default
	{
		-HDWEAPON.FITSINBACKPACK
		Weapon.SelectionOrder 300;
		Weapon.SlotNumber 6;
		Weapon.SlotPriority 2;
		HDWeapon.BarrelSize 32, 1, 3;
		Inventory.Icon "MBR5A0";
		Scale 0.5;
		Tag "Modular Battle Rifle";
		HDWeapon.Refid "mbr";
		HDWeapon.Loadoutcodes "
			\cuheavy - Loaded with Heavy Mags
			\cucqc - CQC Barrel
			\cudmr - DMR Barrel
			\cuscope - Scope
			\cuselect - Select Fire Switch
			\cugl - Grenade Launcher";
	}

	States
	{
		RegisterSprites:
			DMRG A 0; DMRS A 0; // [Ace] First person. Normal and scoped, respectively. Stuff below is world sprites.
			MFCL A 0; MFCH A 0;
			CQCL A 0; CQCH A 0;
			DMRL A 0; DMRH A 0;

		Spawn:
			MBRL A 0 NoDelay
			{
				string s; int f;
				[s, f] = invoker.GetFullSprite();
				sprite = GetSpriteIndex(s);
				frame = f;
			}
		RealSpawn:
			#### # -1;
			Stop;
		Ready:
			DMRG A 1
			{
				player.GetPSprite(PSP_WEAPON).sprite = GetSpriteIndex(invoker.WeaponStatus[BRProp_Flags] & BRF_Scope ? "DMRS" : "DMRG");
				if (PressingZoom())
				{
					A_ZoomAdjust(BRProp_Zoom, 5, 60);
					if (player.cmd.buttons & BT_USE)
					{
						A_ZoomAdjust(BRProp_DropAdjust, 0, 1200, BT_USE);
					}
					A_WeaponReady(WRF_NONE);
				}
				else
				{
					if (JustPressed(BT_FIREMODE) && invoker.WeaponStatus[BRProp_Flags] & BRF_FireSelector)
					{
						// [Ace] Save the fire mode to restore it when trying to manually chamber the weapon.
						// It'ss because the chambering requires you to hold firemode. This is as "fixed" as it's gonna get.
						invoker.OldFireMode = invoker.WeaponStatus[BRProp_Firemode];
						++invoker.WeaponStatus[BRProp_Firemode] %= 2;
					}
					A_WeaponReady(WRF_ALL & ~WRF_ALLOWUSER2);
				}
			}
			Goto ReadyEnd;
		Select0:
			#### A 0 { player.GetPSprite(PSP_WEAPON).sprite = GetSpriteIndex(invoker.WeaponStatus[BRProp_Flags] & BRF_Scope ? "DMRS" : "DMRG"); }
			Goto Select0Big;
		Deselect0:
			#### A 0 { player.GetPSprite(PSP_WEAPON).sprite = GetSpriteIndex(invoker.WeaponStatus[BRProp_Flags] & BRF_Scope ? "DMRS" : "DMRG"); }
			Goto Deselect0Big;
		User3:
			#### A 0 A_MagManager(PressingUse() ? "HDMBRMagHeavy" : "HDMBRMagLight");
			Goto Ready;

		AltFire:
			#### A 0 A_JumpIf(!(invoker.WeaponStatus[BRProp_Flags] & BRF_GrenadeLoaded), 'Nope');
			#### A 2
			{
				A_FireHDGL();
				invoker.WeaponStatus[BRProp_Flags] &= ~BRF_GrenadeLoaded;
				A_StartSound("weapons/grenadeshot", CHAN_WEAPON);
				A_ZoomRecoil(0.95);
			}
			#### A 2 A_MuzzleClimb(0, 0, 0, 0, -1.2, -3.0, -1.0, -2.8);
			Goto Nope;

		Fire:
			#### A 0
			{
				int Mag = invoker.WeaponStatus[BRProp_Mag];
				int Chamber = invoker.WeaponStatus[BRProp_Chamber];
				if (Mag > 0 || Chamber > BRChamber_Empty)
				{
					if (Chamber != BRChamber_Light && Chamber != BRChamber_Heavy)
					{
						SetWeaponState('PostReloadChamber');
						return;
					}
					SetWeaponState('RealFire');
					return;
				}

			}
			Goto Nope;
		RealFire:
			#### B 1 Offset(0, 33)
			{
				if (invoker.WeaponStatus[BRProp_Flags] & BRF_Scope) {
					A_Overlay(PSP_FLASH, 'ScopeFlash');
				} else {
					A_Overlay(PSP_FLASH, 'Flash');
				}

				int MType = invoker.WeaponStatus[BRProp_MagType];
				int Chamber = invoker.WeaponStatus[BRProp_Chamber];

				// [Ace] Speed factor and recoil factor. Defaults are for BRFrame_Basic.
				double SFactor = 1.10;
				double RFactor = 1.00;

				switch (invoker.WeaponStatus[BRProp_Frame])
				{
					case BRFrame_Short:
						SFactor = 1.00;
						RFactor = 1.30;
						break;
					case BRFrame_Bull:
						SFactor = 1.25;
						RFactor = 0.80;
						break;
				}

				switch (Chamber)
				{
					case BRChamber_Light:
						HDBulletActor.FireBullet(self, 'HDB_500SW', aimoffy: (-HDCONST_GRAVITY / 1000.0) * invoker.WeaponStatus[BRProp_DropAdjust], speedfactor: SFactor);
						invoker.WeaponStatus[BRProp_Chamber] = BRChamber_SpentLight;
						A_StartSound("MBR/Fire", CHAN_WEAPON, pitch: 1.1);
						break;
					case BRChamber_Heavy:
						HDBulletActor.FireBullet(self, 'HDB_500LAD', aimoffy: (-HDCONST_GRAVITY / 1000.0) * invoker.WeaponStatus[BRProp_DropAdjust], speedfactor: SFactor);
						invoker.WeaponStatus[BRProp_Chamber] = BRChamber_SpentHeavy;
						A_StartSound("MBR/Fire", CHAN_WEAPON, pitch: 1.0);
						break;
				}
				
				A_AlertMonsters();
				A_ZoomRecoil(0.990);
				A_MuzzleClimb(
					-frandom(1, 1.2) * RFactor, -frandom(1.5, 2.0) * RFactor,
					-frandom(1, 1.2) * RFactor, -frandom(1.5, 2.0) * RFactor
				);
				A_Light1();
			}
			#### A 2 Offset(0, 35)
			{
				if (invoker.WeaponStatus[BRProp_Chamber] == BRChamber_SpentLight || invoker.WeaponStatus[BRProp_Chamber] == BRChamber_SpentHeavy)
				{
					A_EjectCasing('HDSpent500', frandom(-1,2),(frandom(0.2,0.3),-frandom(7,7.5),frandom(0,0.2)),(0,0,-2));
					// A_EjectCasing('HDSpent500', 10, -random(79, 81), frandom(6.0, 6.5), 0.78);
					invoker.WeaponStatus[BRProp_Chamber] = 0;
				}

				if (invoker.WeaponStatus[BRProp_Mag] <= 0)
				{
					SetWeaponState('Nope');
				}
				else
				{
					A_Light0();
					invoker.WeaponStatus[BRProp_Chamber] = invoker.WeaponStatus[BRProp_MagType] == 0 ? BRChamber_Light : BRChamber_Heavy;
					invoker.WeaponStatus[BRProp_Mag]--;
				}
			}
			#### A 0 A_Refire();
			Goto Ready;
		Hold:
			#### A 0 A_JumpIf(invoker.WeaponStatus[BRProp_Firemode] == 0, "Nope");
			Goto RealFire;

		Flash:
			DMRF A 1 Bright
			{
				HDFlashAlpha(72);
			}
			goto lightdone;
		ScopeFlash:
			DMRF B 1 Bright
			{
				HDFlashAlpha(72);
			}
			goto lightdone;
			
		Unload:
			#### A 0
			{
				invoker.WeaponStatus[BRProp_Flags] |= BRF_JustUnload;
				if (PressingFiremode() && invoker.WeaponStatus[BRProp_Flags] & BRF_GrenadeLoaded)
				{
					SetWeaponState('UnloadGL');
				}
				else if (invoker.WeaponStatus[BRProp_Mag] >= 0)
				{
					SetWeaponState('UnMag');
				}
				else if (invoker.WeaponStatus[BRProp_Chamber] > BRChamber_Empty)
				{
					SetWeaponState('UnloadChamber');
				}
			}
			Goto Nope;
		UnloadChamber:
			#### A 4 Offset(2, 34)
			{
				A_StartSound("MBR/BoltPull", 8);
			}
			#### A 8 Offset(1, 36)
			{
				class<Inventory> Which = null;
				switch (invoker.WeaponStatus[BRProp_Chamber])
				{
					case 2: Which = 'HD500SWLightAmmo'; break;
					case 4: Which = 'HD500SWHeavyAmmo'; break;
				}
				if (Which)
				{
					invoker.WeaponStatus[BRProp_Chamber] = BRChamber_Empty;
					A_SpawnItemEx(which, cos(pitch) * 10, 0, height - 8 - sin(pitch) * 10, vel.x, vel.y, vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH);
				}
			}
			#### A 2 Offset(0, 34);
			Goto ReadyEnd;

		AltReload:
			#### A 0
			{
				invoker.WeaponStatus[BRProp_Flags] &= ~BRF_JustUnload;
				if (invoker.WeaponStatus[BRProp_Flags] & BRF_GL && !(invoker.WeaponStatus[BRProp_Flags] & BRF_GrenadeLoaded) && CheckInventory("HDRocketAmmo", 1))
				{
					SetWeaponState('UnloadGL');
				}
			}
			Goto Nope;
		UnloadGL:
			#### A 0
			{
				A_SetCrosshair(21);
				A_MuzzleClimb(-0.3, -0.3);
			}
			#### A 2 Offset(0, 34);
			#### A 1 Offset(4, 38) A_MuzzleClimb(-0.3,-0.3);
			#### A 2 Offset(8, 48)
			{
				A_StartSound("MBR/GrenadeOpen", CHAN_WEAPON, CHANF_OVERLAP);
				A_MuzzleClimb(-0.3, -0.3);

				if (invoker.WeaponStatus[BRProp_Flags] & BRF_GrenadeLoaded)
				{
					A_StartSound("MBR/GrenadeUnload", CHAN_WEAPON);
				}
			}
			#### A 8 Offset(10, 49)
			{
				if (!(invoker.WeaponStatus[BRProp_Flags] & BRF_GrenadeLoaded))
				{
					if (invoker.WeaponStatus[BRProp_Flags] & BRF_JustUnload)
					{
						A_SetTics(3);
					}
					return;
				}
				invoker.WeaponStatus[BRProp_Flags] &= ~BRF_GrenadeLoaded;
				if(!PressingUnload() || A_JumpIfInventory('HDRocketAmmo', 0, 'Null'))
				{
					A_SpawnItemEx('HDRocketAmmo', cos(pitch) * 10, 0, height - 10 - 10 * sin(pitch), vel.x, vel.y, vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH);
				}
				else
				{
					A_SetTics(20);
					A_StartSound("weapons/pocket", CHAN_WEAPON, CHANF_OVERLAP);
					A_GiveInventory('HDRocketAmmo', 1);
					A_MuzzleClimb(frandom(0.8, -0.2), frandom(0.4, -0.2));
				}
			}
			#### A 0 A_JumpIf(invoker.WeaponStatus[BRProp_Flags] & BRF_JustUnload, 'ReloadEndGL');
		LoadGL:
			#### A 2 Offset(10, 50) A_StartSound("weapons/pocket", CHAN_WEAPON,  CHANF_OVERLAP);
			#### AAA 5 Offset(10, 50) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			#### A 15 Offset(8, 50)
			{
				A_TakeInventory('HDRocketAmmo', 1, TIF_NOTAKEINFINITE);
				invoker.WeaponStatus[BRProp_Flags] |= BRF_GrenadeLoaded;
				A_StartSound("MBR/GrenadeLoad", CHAN_WEAPON);
			}
		ReloadEndGL:
			#### A 4 Offset(4, 44) A_StartSound("MBFG/GrenadeClose", CHAN_WEAPON);
			#### A 1 Offset(0, 40);
			#### A 1 Offset(0, 34) A_MuzzleClimb(frandom(-2.4, 0.2), frandom(-1.4, 0.2));
			Goto Nope;

		Reload:
			#### A 0
			{
				bool UseHeavy = PressingUse() || CountInv('HD500SWLightAmmo') == 0;
				if (PressingFiremode() && invoker.WeaponStatus[BRProp_Chamber] == BRChamber_Empty && CheckInventory(UseHeavy ? 'HD500SWHeavyAmmo' : 'HD500SWLightAmmo', 1))
				{
					invoker.WeaponStatus[BRProp_LoadType] = UseHeavy;
					invoker.WeaponStatus[BRProp_Firemode] = invoker.OldFireMode;
					SetWeaponState('ChamberManual');
					return;
				}

				invoker.WeaponStatus[BRProp_Flags] &= ~BRF_JustUnload;
				
				bool NoLightMags = HDMagAmmo.NothingLoaded(self, 'HDMBRMagLight');
				bool NoHeavyMags = HDMagAmmo.NothingLoaded(self, 'HDMBRMagHeavy');

				int LType = !NoHeavyMags && (PressingUse() || NoLightMags) ? 1 : 0;
				invoker.WeaponStatus[BRProp_LoadType] = LType;

				int MType = invoker.WeaponStatus[BRProp_MagType];
				int Mag = invoker.WeaponStatus[BRProp_Mag];

				if (NoLightMags && NoHeavyMags || LType == MType && Mag == (MType == 0 ? HDMBRMagLight.MagCapacity : HDMBRMagHeavy.MagCapacity))
				{
					SetWeaponState('Nope');
					return;
				}
			}
			Goto UnMag;

		ChamberManual:
			#### A 1 Offset(0, 34) A_StartSound("weapons/pocket", 9);
			#### A 1 Offset(2, 36);
			#### A 1 Offset(2, 44);
			#### A 1 Offset(5, 54);
			#### A 2 Offset(7, 60);
			#### A 6 Offset(8, 70);
			#### A 5 Offset(8, 77)
			{
				int LType = invoker.WeaponStatus[BRProp_LoadType];
				class<Inventory> Which = LType == 0 ? 'HD500SWLightAmmo' : 'HD500SWHeavyAmmo';
				if (CheckInventory(Which, 1))
				{
					A_TakeInventory(Which, 1, TIF_NOTAKEINFINITE);
					invoker.WeaponStatus[BRProp_Chamber] = LType == 0 ? BRChamber_Light : BRChamber_Heavy;
					A_StartSound("MBR/ChamberRound", 8);
				}
				else
				{
					A_SetTics(4);
				}
			}
			#### A 3 Offset(9, 74);
			#### A 2 Offset(5, 70);
			#### A 1 Offset(5, 64);
			#### A 1 Offset(5, 52);
			#### A 1 Offset(5, 42);
			#### A 1 Offset(2, 36);
			#### A 1 Offset(0, 34);
			Goto Nope;

		UnMag:
			#### A 2 Offset(2, 34);
			#### A 2 Offset(3, 36);
			#### A 2 Offset(5, 40);
			#### A 2 Offset(6, 44);
			#### A 2 Offset(6, 46)
			{
				A_StartSound("MBR/MagOut", 8);
				A_MuzzleClimb(0.3, 0.4);
			}
			#### A 0
			{
				int MagAmount = invoker.WeaponStatus[BRProp_Mag];
				if (MagAmount == -1)
				{
					SetWeaponState('MagOut');
					return;
				}

				int MType = invoker.WeaponStatus[BRProp_MagType];
				invoker.WeaponStatus[BRProp_Mag] = -1;

				class<HDMagAmmo> WhichMag = MType == 0 ? 'HDMBRMagLight' : 'HDMBRMagHeavy';
				if ((!PressingUnload() && !PressingReload()) || A_JumpIfInventory(WhichMag, 0, "Null"))
				{
					HDMagAmmo.SpawnMag(self, WhichMag, MagAmount);
					SetWeaponState("MagOut");
				}
				else
				{
					HDMagAmmo.GiveMag(self, WhichMag, MagAmount);
					A_StartSound("weapons/pocket", 9);
					SetWeaponState('PocketMag');
				}
			}
		PocketMag:
			#### AAAAAA 3 Offset(6, 46) A_MuzzleClimb(frandom(0.2, -0.8),frandom(-0.2, 0.4));
		MagOut:
			#### A 0
			{
				if (invoker.WeaponStatus[BRProp_Flags] & BRF_JustUnload)
				{
					SetWeaponState('ReloadEnd');
				}
			}
		LoadMag:
			#### A 3 A_StartSound("weapons/pocket", 9);
			#### A 3 Offset(6, 46) A_MuzzleClimb(frandom(0.2, -0.8), frandom(-0.2, 0.4));
			#### A 3 Offset(6, 47) A_MuzzleClimb(frandom(0.2, -0.8), frandom(-0.2, 0.4));
			#### A 3 Offset(6, 48) A_MuzzleClimb(frandom(0.2, -0.8), frandom(-0.2, 0.4));
			#### A 8 Offset(6, 49) A_MuzzleClimb(frandom(0.2, -0.8), frandom(-0.2, 0.4));
			#### A 4 Offset(7, 44)
			{
				int LType = invoker.WeaponStatus[BRProp_LoadType];
				class<HDMagAmmo> WhichMag = (LType == 0 ? 'HDMBRMagLight' : 'HDMBRMagHeavy');
				let Mag = HDMagAmmo(FindInventory(WhichMag));
				if (Mag)
				{
					invoker.WeaponStatus[BRProp_Mag] = Mag.TakeMag(true);
					invoker.WeaponStatus[BRProp_MagType] = LType;
					A_StartSound("MBR/MagIn", 8, CHANF_OVERLAP);
				}
			}
			Goto ReloadEnd;

		ReloadEnd:
			#### A 3 A_WeaponOffset(7, 48);
			#### A 3 A_WeaponOffset(4, 44);
			#### A 3 A_WeaponOffset(2, 40);
			#### A 3 A_WeaponOffset(1, 36);
			#### A 3 A_WeaponOffset(0, 34);
			#### A 3 A_WeaponOffset(0, 32);
			#### A 0 A_JumpIf(invoker.WeaponStatus[BRProp_Flags] & BRF_JustUnload, 'Ready');
		PostReloadChamber:
			#### A 0 A_JumpIf(invoker.WeaponStatus[BRProp_Chamber] == BRChamber_Light || invoker.WeaponStatus[BRProp_Chamber] == BRChamber_Heavy, 'Ready');
			#### A 0 A_WeaponBusy();
			#### A 2 Offset(1, 36);
			#### A 4 Offset(2, 38) A_StartSound("MBR/ChamberRound", 8, CHANF_OVERLAP);
			#### A 5 Offset(2, 44)
			{
				if (invoker.WeaponStatus[BRProp_Chamber] == BRChamber_SpentLight || invoker.WeaponStatus[BRProp_Chamber] == BRChamber_SpentHeavy)
				{
					A_EjectCasing('HDSpent500', frandom(-1,2),(frandom(0.2,0.3),-frandom(7,7.5),frandom(0,0.2)),(0,0,-2));
					// A_EjectCasing('HDSpent500', 10, -random(79, 81), frandom(6.0, 6.5), 0.78);
					invoker.WeaponStatus[BRProp_Chamber] = BRChamber_Empty;
				}

				if (invoker.WeaponStatus[BRProp_Mag] > 0)
				{
					invoker.WeaponStatus[BRProp_Mag]--;
					invoker.WeaponStatus[BRProp_Chamber] = invoker.WeaponStatus[BRProp_MagType] == 0 ? BRChamber_Light : BRChamber_Heavy;
				}
			}
			#### A 2 Offset(2, 38);
			#### A 2 Offset(1, 34);
			#### A 2 Offset(0, 32);
			#### A 0 A_WeaponBusy(false);
			Goto Nope;
	}
}

class MBRRandom : IdleDummy
{
	States
	{
		Spawn:
			TNT1 A 0 NoDelay
			{
				A_SpawnItemEx('HDMBRMagLight', -3, flags: SXF_NOCHECKPOSITION);
				A_SpawnItemEx('HDMBRMagHeavy', 6, flags: SXF_NOCHECKPOSITION);
				let wpn = HDMBR(Spawn('HDMBR', pos, ALLOW_REPLACE));
				if (!wpn)
				{
					return;
				}

				HDF.TransferSpecials(self, wpn);

				wpn.WeaponStatus[wpn.BRProp_Frame] = random(wpn.BRFrame_Basic, wpn.BRFrame_Bull);

				if (!random(0, 2))
				{
					wpn.WeaponStatus[wpn.BRProp_Flags] |= wpn.BRF_FireSelector;
				}
				if (!random(0, 2))
				{
					wpn.WeaponStatus[wpn.BRProp_Flags] |= wpn.BRF_Scope;
				}
				if (!random(0, 2))
				{
					wpn.WeaponStatus[wpn.BRProp_Flags] |= wpn.BRF_GL;
				}
				
				wpn.WeaponStatus[wpn.BRProp_MagType] = randompick[mbrrand](0, 0, 0, 1);
				
				wpn.InitializeWepStats(false);
			}
			Stop;
	}
}


class HDMBRMagLight : HDMagAmmo
{
	override string, string, Name, double GetMagSprite(int thismagamt)
	{
		return (thismagamt > 0) ? "5LMGA0" : "5LMGB0", "SWRNA0", 'HD500SWLightAmmo', 0.8;
	}

	override void GetItemsThatUseThis()
	{
		ItemsThatUseThis.Push("HDMBR");
	}

	const MagCapacity = 20;
	const EncMagEmpty = 10;
	const EncMagLoaded = EncMagEmpty * 0.8;

	Default
	{
		HDMagAmmo.MaxPerUnit MagCapacity;
		HDMagAmmo.InsertTime 7;
		HDMagAmmo.ExtractTime 4;
		HDMagAmmo.RoundType 'HD500SWLightAmmo';
		HDMagAmmo.RoundBulk ENC_50SW_LOADED;
		HDMagAmmo.MagBulk EncMagEmpty;
		Tag "MBR Light Magazine";
		Inventory.PickupMessage "Picked up a MBR Light Magazine.";
		HDPickup.RefId "mbm";
		Scale 0.5;
	}

	States
	{
		Spawn:
			5LMG A -1;
			Stop;
		SpawnEmpty:
			5LMG B -1
			{
				bROLLSPRITE = true;
				bROLLCENTER = true;
				roll = randompick(0, 0, 0, 0, 2, 2, 2, 2, 1, 3) * 90;
			}
			Stop;
	}
}

class HDMBRMagHeavy : HDMBRMagLight
{
	override string, string, Name, double GetMagSprite(int thismagamt)
	{
		return (thismagamt > 0) ? "5HMGA0" : "5HMGB0", "SWRNB0", 'HD500SWHeavyAmmo', 0.8;
	}

	Default
	{
		HDMagAmmo.RoundType 'HD500SWHeavyAmmo';
		Tag "MBR Heavy Magazine";
		Inventory.PickupMessage "Picked up a MBR Heavy Magazine";
		HDPickup.RefId "mbh";
	}

	States
	{
		Spawn:
			5HMG A -1;
			Stop;
		SpawnEmpty:
			5HMG B -1
			{
				bROLLSPRITE = true;
				bROLLCENTER = true;
				roll = randompick(0, 0, 0, 0, 2, 2, 2, 2, 1, 3) * 90;
			}
			Stop;
	}
}
