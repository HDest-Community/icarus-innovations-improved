class PDFourHandler : EventHandler
{
	override void CheckReplacement(ReplaceEvent e)
	{
		if (!e.Replacement)
		{
			return;
		}

		switch (e.Replacement.GetClassName())
		{
			case 'ClipBoxPickup':
				if (random[pdfrand]() <= AceCore.GetScaledChance(16, 64, acl_spawnscale_min, acl_spawnscale_max))
				{
					e.Replacement = randompick[pdfrand](0,0,0,0,1) ? "PDFourRandom" : "HDPDFourMag";
				}
				break;
		}
	}

	override void WorldThingSpawned(WorldEvent e)
	{
		let PDFourAmmo = HDAmmo(e.Thing);
		if (!PDFourAmmo)
		{
			return;
		}

		switch (PDFourAmmo.GetClassName())
		{
			case 'FourMilAmmo':
			case 'HDSlugAmmo':
				PDFourAmmo.ItemsThatUseThis.Push("HDPDFour");
				break;
		}
	}
}

class HDPDFour : HDWeapon
{
	enum PDFourFlags
	{
		PDF_JustUnload = 1,
		PDF_SlugLoaded = 2,
		PDF_SlugLauncher = 4
	}

	enum PDFourProperties
	{
		PDProp_Flags,
		PDProp_Chamber,
		PDProp_Mag,
		PDProp_Mode,
		PDProp_Dot
	}

	override void PostBeginPlay()
	{
		weaponspecial = 1337; // [Ace] UaS sling compatibility.
		Super.PostBeginPlay();
	}
	override void Tick()
	{
		Super.Tick();
		if (!(WeaponStatus[PDProp_Flags] & PDF_SlugLauncher) && WeaponStatus[PDProp_Flags] & PDF_SlugLoaded)
		{
			WeaponStatus[PDProp_Flags] &= ~PDF_SlugLoaded;
			Actor ptr = owner ? owner : Actor(self);
			ptr.A_SpawnItemEx('HDSlugAmmo', cos(ptr.pitch) * 10, 0, ptr.height - 10 - 10 * sin(ptr.pitch), ptr.vel.x, ptr.vel.y, ptr.vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH);
			ptr.A_StartSound("weapons/huntrackdown", CHAN_WEAPON, CHANF_OVERLAP);
		}
	}

	override bool AddSpareWeapon(actor newowner) { return AddSpareWeaponRegular(newowner); }
	override HDWeapon GetSpareWeapon(actor newowner, bool reverse, bool doselect) { return GetSpareWeaponRegular(newowner, reverse, doselect); }
	override double GunMass()
	{
		double BaseMass = 6;
		if (WeaponStatus[PDProp_Flags] & PDF_SlugLauncher)
		{
			BaseMass += 1;
		}
		return BaseMass + 0.03 * WeaponStatus[PDProp_Mag];
	}
	
	override double WeaponBulk()
	{
		double BaseBulk = 80;
		int Mag = WeaponStatus[PDProp_Mag];
		if (Mag >= 0)
		{
			BaseBulk += HDPDFourMag.EncMagLoaded + Mag * ENC_426_LOADED;
		}
		if (WeaponStatus[PDProp_Flags] & PDF_SlugLauncher)
		{
			BaseBulk += 5;
		}
		if (WeaponStatus[PDProp_Flags] & PDF_SlugLoaded)
		{
			BaseBulk += ENC_SHELLLOADED;
		}
		return BaseBulk;
	}
	
	override string, double GetPickupSprite()
	{
		string IconString = "";
		if (WeaponStatus[PDProp_Mag] > 0)
		{
			IconString = WeaponStatus[PDProp_Flags] & PDF_SlugLauncher ? "PDWSY0" : "PDWGY0";
		}
		else
		{
			IconString = WeaponStatus[PDProp_Flags] & PDF_SlugLauncher ? "PDWSZ0" : "PDWGZ0";
		}
		return IconString, 1.0;
	}
	
	override void InitializeWepStats(bool idfa)
	{
		WeaponStatus[PDProp_Chamber] = 1;
		WeaponStatus[PDProp_Mag] = HDPDFourMag.MagCapacity;
		if (WeaponStatus[PDProp_Flags] & PDF_SlugLauncher)
		{
			WeaponStatus[PDProp_Flags] |= PDF_SlugLoaded;
		}
	}

	override void LoadoutConfigure(string input)
	{
		if (GetLoadoutVar(input, "slugger", 1) > 0)
		{
			WeaponStatus[PDProp_Flags] |= PDF_SlugLauncher;
		}

		InitializeWepStats();
	}
	
	override string GetHelpText()
	{
		return WEPHELP_FIRESHOOT
		..(WeaponStatus[PDProp_Flags] & PDF_SlugLauncher ? WEPHELP_ALTFIRE.. "  Fire Slug Thrower\n" : "")
		..(WeaponStatus[PDProp_Flags] & PDF_SlugLauncher ? WEPHELP_ALTRELOAD.. "  Load Slug Thrower\n" : "")
		..(WeaponStatus[PDProp_Flags] & PDF_SlugLauncher ? WEPHELP_FIREMODE.."+"..WEPHELP_UNLOAD.. "  Unload Slug Thrower\n" : "")
		..WEPHELP_RELOAD.."  Reload mag\n"
		..WEPHELP_UNLOADUNLOAD
		..WEPHELP_FIREMODE.."  Semi Auto/Double Tap/Full Auto\n"
		..WEPHELP_MAGMANAGER;
	}

	override string PickupMessage()
	{
		string SlugString = WeaponStatus[PDProp_Flags] & PDF_SlugLauncher ? " with an Under-Barrel Slug Thrower" : "";
		return String.Format("You picked up the PD-42 4mm PDW%s.", SlugString);
	}
	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		if (sb.HudLevel == 1)
		{
			int NextMagLoaded = sb.GetNextLoadMag(HDMagAmmo(hpl.findinventory("HDPDFourMag")));
			if (NextMagLoaded >= HDPDFourMag.MagCapacity)
			{
				sb.DrawImage("PDMGA0", (-46, -3),sb. DI_SCREEN_CENTER_BOTTOM, scale: (1.0, 1.0));
			}
			else if (NextMagLoaded <= 0)
			{
				sb.DrawImage("PDMGB0", (-46, -3), sb.DI_SCREEN_CENTER_BOTTOM, alpha: NextMagLoaded ? 0.6 : 1.0, scale: (1.0, 1.0));
			}
			else
			{
				sb.DrawBar("PDMGNORM", "PDMGGREY", NextMagLoaded, HDPDFourMag.MagCapacity, (-46, -3), -1, sb.SHADER_VERT, sb.DI_SCREEN_CENTER_BOTTOM);
			}
			sb.DrawNum(hpl.CountInv('HDPDFourMag'), -43, -8, sb.DI_SCREEN_CENTER_BOTTOM);

			if (hdw.WeaponStatus[PDProp_Flags] & PDF_SlugLauncher)
			{
				sb.DrawImage("SLG1A0",(-59, -8), sb.DI_SCREEN_CENTER_BOTTOM, scale: (0.6, 0.6));
				sb.DrawNum(hpl.CountInv('HDSlugAmmo'), -58, -8, sb.DI_SCREEN_CENTER_BOTTOM);
			}
		}
		sb.DrawWepNum(hdw.WeaponStatus[PDProp_Mag], HDPDFourMag.MagCapacity);

		if (hdw.WeaponStatus[PDProp_Chamber] == 1)
		{
			sb.DrawRect(-19, -11, 3, 1);
		}
		if (hdw.WeaponStatus[PDProp_Flags] & PDF_SlugLoaded)
		{
			sb.DrawRect(-20, -15, 4, 2.6);
		}
		
		sb.DrawWepCounter(hdw.WeaponStatus[PDProp_Mode], -22, -10, "RBRSA3A7", "STBURAUT", "STFULAUT");
	}

	override void SetReflexReticle(int which) { weaponstatus[PDProp_Dot] = which; }
	override void DrawSightPicture(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl, bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot)
	{
		double dotoff = max(abs(bob.x), abs(bob.y));
		if (dotoff < 6)
		{
			string whichdot = sb.ChooseReflexReticle(hdw.WeaponStatus[PDProp_Dot]);
			sb.DrawImage(whichdot, (0, 0) + bob * 3, sb.DI_SCREEN_CENTER | sb.DI_ITEM_CENTER, alpha : 0.8 - dotoff * 0.04, col:0xFF000000 | sb.crosshaircolor.GetInt());
		}
		sb.DrawImage("PDWBACK", (0, -18) + bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, scale: (0.8, 0.8));
	}

	override void DropOneAmmo(int amt)
	{
		if (owner)
		{
			double OldAngle = owner.angle;
			
			amt = clamp(amt, 1, 10);
			if (owner.CheckInventory('FourMilAmmo', 1))
			{
				owner.A_DropInventory('FourMilAmmo', amt * 30);
			}
			else
			{
				owner.A_DropInventory('HDPDFourMag', amt);
			}

			owner.angle += 15;
			if (owner.CheckInventory('HDSlugAmmo', 1))
			{
				owner.A_DropInventory('HDSlugAmmo', amt * 4);
			}

			owner.angle = OldAngle;
		}
	}

	private int BurstIndex;

	Default
	{
		+HDWEAPON.FITSINBACKPACK
		Weapon.SelectionOrder 300;
		Weapon.SlotNumber 4;
		Weapon.SlotPriority 3;
		HDWeapon.BarrelSize 20,0.5,1;
		Scale 0.45;
		Tag "PD-42 4mm PDW";
		HDWeapon.Refid "pd4";
		HDWeapon.Loadoutcodes "
			\cuslugger - Under-Barrel Slug Thrower";
	}

	States
	{
		Spawn:
			PDWS Y 0 NoDelay A_JumpIf(invoker.WeaponStatus[PDProp_Flags] & PDF_SlugLauncher, 2);
			PDWG Y 0;
			#### # -1
			{
				frame = (invoker.WeaponStatus[PDProp_Mag] == -1 ? 25 : 24);
			}
			Stop;
		Ready:
			PDFG A 1 
			{
				if (JustPressed(BT_FIREMODE))
				{
					++invoker.WeaponStatus[PDProp_Mode] %= 3;
				}
				invoker.BurstIndex = 0;
				A_WeaponReady(WRF_ALL & ~WRF_ALLOWUSER2);
			}
			Goto ReadyEnd;
		Select0:
			PDFG A 0;
			Goto Select0Small;
		Deselect0:
			PDFG A 0;
			Goto Deselect0Small;
		User3:
			PDFG A 0 A_MagManager("HDPDFourMag");
			Goto Ready;
		
		Fire:
			PDFF A 0
			{
				if (invoker.WeaponStatus[PDProp_Chamber] == 0)
				{
					SetWeaponState('ChamberManual');
					return;
				}
			}
			PDFF A 1
			{
				HDBulletActor.FireBullet(self, "HDB_426", speedfactor: 0.9);
				A_AlertMonsters(HDCONST_ONEMETRE * 15);
				A_ZoomRecoil(0.95);
				A_StartSound("PD42/Fire", CHAN_WEAPON);
				invoker.WeaponStatus[PDProp_Chamber] = 0;
				HDFlashAlpha(-200);
				A_Light1();
			}
			PDFF A 0
			{
				if (invoker.WeaponStatus[PDProp_Mode] == 1)
				{
					A_MuzzleClimb(-frandom(-0.7, 0.7), -frandom(0.8, 1.2));
				}
				else
				{
					A_MuzzleClimb(-frandom(-0.5, 0.5), -frandom(0.6, 0.8), -frandom(-0.5, 0.5), -frandom(0.6, 0.8));
				}
			}
			PDFG A 0
			{
				A_WeaponOffset(0, 35);
				if (invoker.WeaponStatus[PDProp_Mag] > 0)
				{
					invoker.WeaponStatus[PDProp_Chamber] = 1;
					invoker.WeaponStatus[PDProp_Mag]--;
				}
				if (invoker.WeaponStatus[PDProp_Mode] == 2)
				{
					A_SetTics(2);
				}
				A_WeaponReady(WRF_NOFIRE);
			}
			PDFG A 0
			{
				switch (invoker.WeaponStatus[PDProp_Mode])
				{
					case 1:
					{
						if (invoker.BurstIndex < 2)
						{
							invoker.BurstIndex++;
							A_Refire('Fire');
						}
						break;
					}
					case 2:
					{
						A_Refire('Fire');
						break;
					}
				}
			}
			Goto Nope;

		AltFire:
			PDFG A 0 A_JumpIf(!(invoker.WeaponStatus[PDProp_Flags] & PDF_SlugLoaded), 'Nope');
			PDFF B 2
			{
				A_WeaponOffset(0, 36);
				HDBulletActor.FireBullet(self, "HDB_SLUG", speedfactor: 0.65);
				invoker.WeaponStatus[PDProp_Flags] &= ~PDF_SlugLoaded;
				A_AlertMonsters();
				A_StartSound("weapons/hunter", CHAN_WEAPON);
				A_ZoomRecoil(0.95);
			}
			PDFG A 2 A_MuzzleClimb(-frandom(-0.5, 0.5), -frandom(1.5, 2.0), -frandom(-0.6, 0.6), -frandom(1.5, 2.0));
			Goto Nope;

		Unload:
			PDFG A 0
			{
				invoker.WeaponStatus[PDProp_Flags] |= PDF_JustUnload;
				if (PressingFiremode() && invoker.WeaponStatus[PDProp_Flags] & PDF_SlugLoaded)
				{
					SetWeaponState('UnloadST');
					Return;
				}
				if (invoker.WeaponStatus[PDProp_Mag] >= 0)
				{
					SetWeaponState('UnMag');
				}
				else if (invoker.WeaponStatus[PDProp_Chamber] > 0)
				{
					SetWeaponState('UnloadChamber');
				}
			}
			Goto Nope;
		UnloadChamber:
			PDFG A 1 A_JumpIf(invoker.WeaponStatus[PDProp_Chamber] == 0, "Nope");
			PDFG A 4 Offset(2, 34)
			{
				A_StartSound("PD42/BoltPull", 8);
			}
			PDFG A 6 Offset(1, 36)
			{
				class<Actor> Which = invoker.WeaponStatus[PDProp_Chamber] > 1 ? "FourMilAmmo" : "ZM66DroppedRound";
				invoker.WeaponStatus[PDProp_Chamber] = 0;
				A_SpawnItemEx(which, cos(pitch) * 10, 0, height - 8 - sin(pitch) * 10, vel.x, vel.y, vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH);
			}
			PDFG A 2 Offset(0, 34);
			Goto ReadyEnd;

		AltReload:
			PDFG A 0
			{
				invoker.WeaponStatus[PDProp_Flags] &= ~PDF_JustUnload;
				if (invoker.WeaponStatus[PDProp_Flags] & PDF_SlugLauncher && !(invoker.WeaponStatus[PDProp_Flags] & PDF_SlugLoaded) && CheckInventory('HDSlugAmmo', 1))
				{
					SetWeaponState('UnloadST');
				}
			}
			Goto Nope;
		UnloadST:
			PDFG A 0
			{
				A_SetCrosshair(21);
				A_MuzzleClimb(-0.3, -0.3);
			}
			#### A 2 Offset(0, 34);
			#### A 1 Offset(4, 38) A_MuzzleClimb(-0.3,-0.3);
			#### A 2 Offset(8, 48)
			{
				A_StartSound("weapons/huntrackdown", CHAN_WEAPON, CHANF_OVERLAP);
				A_MuzzleClimb(-0.3, -0.3);

				if (invoker.WeaponStatus[PDProp_Flags] & PDF_SlugLoaded)
				{
					A_StartSound("weapons/huntreload", CHAN_WEAPON);
				}
			}
			#### A 4 Offset(10, 49)
			{
				if (!(invoker.WeaponStatus[PDProp_Flags] & PDF_SlugLoaded))
				{
					if (invoker.WeaponStatus[PDProp_Flags] & PDF_JustUnload)
					{
						A_SetTics(3);
					}
					return;
				}
				invoker.WeaponStatus[PDProp_Flags] &= ~PDF_SlugLoaded;
				if(!PressingUnload() || A_JumpIfInventory('HDSlugAmmo', 0, 'Null'))
				{
					A_SpawnItemEx('HDSlugAmmo', cos(pitch) * 10, 0, height - 10 - 10 * sin(pitch), vel.x, vel.y, vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH);
				}
				else
				{
					A_SetTics(20);
					A_StartSound("weapons/pocket", CHAN_WEAPON, CHANF_OVERLAP);
					A_GiveInventory('HDSlugAmmo', 1);
					A_MuzzleClimb(frandom(0.8, -0.2), frandom(0.4, -0.2));
				}
			}
			#### A 0 A_JumpIf(invoker.WeaponStatus[PDProp_Flags] & PDF_JustUnload, 'ReloadEndST');
		LoadST:
			PDFG A 2 Offset(10, 50) A_StartSound("weapons/pocket", CHAN_WEAPON,  CHANF_OVERLAP);
			#### A 5 Offset(10, 50) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			#### A 10 Offset(8, 50)
			{
				A_TakeInventory('HDSlugAmmo', 1, TIF_NOTAKEINFINITE);
				invoker.WeaponStatus[PDProp_Flags] |= PDF_SlugLoaded;
				A_StartSound("weapons/huntreload", CHAN_WEAPON);
			}
		ReloadEndST:
			PDFG A 4 Offset(4, 44) A_StartSound("weapons/huntrackdown", CHAN_WEAPON);
			#### A 1 Offset(0, 40);
			#### A 1 Offset(0, 34) A_MuzzleClimb(frandom(-2.4, 0.2), frandom(-1.4, 0.2));
			Goto Nope;

		Reload:
			PDFG A 0
			{
				invoker.WeaponStatus[PDProp_Flags] &=~ PDF_JustUnload;
				bool NoMags = HDMagAmmo.NothingLoaded(self, "HDPDFourMag");
				int Mag = invoker.WeaponStatus[PDProp_Mag];
				if (Mag >= HDPDFourMag.MagCapacity || Mag < HDPDFourMag.MagCapacity && NoMags)
				{
					SetWeaponState("Nope");
				}
			}
			Goto UnMag;

		ChamberManual:
			PDFG A 0 A_JumpIf(invoker.WeaponStatus[PDProp_Mag] <= 0 || invoker.WeaponStatus[PDProp_Chamber] == 1, "Nope");
			PDFG A 2 Offset(2, 34);
			PDFG A 2 Offset(3, 38) A_StartSound("PD42/BoltPull", 8, CHANF_OVERLAP);
			PDFG A 3 Offset(4, 44)
			{
				if (invoker.WeaponStatus[PDProp_Chamber] == 1)
				{
					A_SpawnItemEx("ZM66DroppedRound", cos(pitch) * 10, 0, height - 10 - sin(pitch) * 10, vel.x, vel.y, vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH);
					invoker.WeaponStatus[PDProp_Chamber] = 0;
				}

				A_WeaponBusy();
				invoker.WeaponStatus[PDProp_Mag]--;
				invoker.WeaponStatus[PDProp_Chamber] = 1;
			}
			PDFG A 1 Offset(3, 38);
			PDFG A 1 Offset(2, 34);
			PDFG A 1 Offset(0, 32);
			Goto Nope;

		UnMag:
			#### A 1 Offset(0,34) A_SetCrosshair(21);
			#### A 1 Offset(5,38);
			#### A 1 Offset(10,42);
			#### A 2 Offset(20,46) A_StartSound("weapons/smgmagclick",8);
			#### A 4 Offset(30,52)
			{
				A_MuzzleClimb(0.3,0.4);
				A_StartSound("PD42/MagOut",8,CHANF_OVERLAP);
			}
			#### A 0
			{
				int magamt=invoker.WeaponStatus[PDProp_Mag];
				if(magamt<0)
				{
					SetWeaponState("magout");
					return;
				}
				invoker.WeaponStatus[PDProp_Mag]=-1;
				if ((!PressingUnload()&&!PressingReload())||A_JumpIfInventory("HDPDFourMag",0,"null"))
				{
					HDMagAmmo.SpawnMag(self,"HDPDFourMag",magamt);
					SetWeaponState("magout");
				}
				else
				{
					HDMagAmmo.GiveMag(self,"HDPDFourMag",magamt);
					A_StartSound("weapons/pocket",9);
					SetWeaponState("pocketmag");
				}
			}
		PocketMag:
			#### AA 7 Offset(34,54)
			{
				A_MuzzleClimb(frandom(0.2, -0.8), frandom(-0.2, 0.4));
			}
		MagOut:
			#### A 0
			{
				if(invoker.WeaponStatus[PDProp_Flags] & PDF_JustUnload)
				{
					SetWeaponState("reloadend");
				}
				else
				{
					SetWeaponState("loadmag");
				}
			}
		LoadMag:
			PDFG A 0 A_StartSound("weapons/pocket", 9);
			PDFG A 6 Offset(26, 54) A_MuzzleClimb(frandom(0.2, -0.8), frandom(-0.2, 0.4));
			PDFG A 7 Offset(26, 52) A_MuzzleClimb(frandom(0.2, -0.8), frandom(-0.2, 0.4));
			PDFG A 10 Offset(24, 50);
			PDFG A 3 Offset(24, 48)
			{
				let Mag = HDMagAmmo(FindInventory("HDPDFourMag"));
				if (Mag)
				{
					invoker.WeaponStatus[PDProp_Mag] = Mag.TakeMag(true);
					A_StartSound("PD42/MagIn", 8, CHANF_OVERLAP);
				}
			}
			Goto ReloadEnd;

		ReloadEnd:
			PDFG A 3 Offset(30, 52);
			PDFG A 2 Offset(20, 46);
			PDFG A 1 Offset(10, 42);
			PDFG A 1 Offset(5, 38);
			PDFG A 1 Offset(0, 34);
			Goto ChamberManual;
	}
}

class PDFourRandom : IdleDummy
{
	States
	{
		Spawn:
			TNT1 A 0 NoDelay
			{
				A_SpawnItemEx('HDPDFourMag', -3,flags: SXF_NOCHECKPOSITION);
				A_SpawnItemEx('HDPDFourMag', 3,flags: SXF_NOCHECKPOSITION);
				let wpn = HDPDFour(Spawn('HDPDFour', pos, ALLOW_REPLACE));
				if (!wpn)
				{
					return;
				}

				HDF.TransferSpecials(self, wpn);
				
				if (!random(0, 2))
				{
					wpn.WeaponStatus[wpn.PDProp_Flags] |= wpn.PDF_SlugLauncher;
					A_SpawnItemEx('SlugPickup', -6,flags: SXF_NOCHECKPOSITION);
				}
				wpn.InitializeWepStats(false);
			}
			Stop;
	}
}

class HDPDFourMag : HDMagAmmo
{
	override string, string, name, double GetMagSprite(int thismagamt)
	{
		return (thismagamt > 0) ? "PDMGA0" : "PDMGB0", "RBRSBRN", "FourMilAmmo", 1.0;
	}

	override void GetItemsThatUseThis()
	{
		ItemsThatUseThis.Push("HDPDFour");
	}

	const MagCapacity = 36;
	const EncMagEmpty = 6;
	const EncMagLoaded = EncMagEmpty * 0.8;

	Default
	{
		HDMagAmmo.MaxPerUnit MagCapacity;
		HDMagAmmo.InsertTime 8;
		HDMagAmmo.ExtractTime 6;
		HDMagAmmo.RoundType "FourMilAmmo";
		HDMagAmmo.RoundBulk ENC_426_LOADED;
		HDMagAmmo.MagBulk EncMagEmpty;
		Tag "PD-42 magazine";
		Inventory.PickupMessage "Picked up a PD-42 magazine.";
		HDPickup.RefId "436";
		Scale 0.35;
	}
	
	override bool Extract()
	{
		SyncAmount();
		int mindex = Mags.Size() - 1;
		if (mindex == -1 || Mags[mindex] < 1 || owner.A_JumpIfInventory(roundtype, 0, "null"))
		{
			return false;
		}
		ExtractTime = GetDefaultByType(GetClass()).extracttime;
		int toTake = min(random(1, 24), mags[mindex]);
		if (toTake < HDPickup.MaxGive(owner, roundtype, roundbulk))
		{
			HDF.Give(owner, roundtype, totake);
		}
		else
		{
			HDPickup.DropItem(owner, roundtype, totake);
		}
		owner.A_StartSound("weapons/rifleclick2", CHAN_WEAPON);
		owner.A_StartSound("weapons/rockreload", CHAN_WEAPON, CHANF_OVERLAP, 0.4);
		Mags[mindex] -= totake;
		return true;
	}
	
	override bool Insert()
	{
		SyncAmount();
		int mindex = Mags.Size() - 1;
		if (mindex == -1 || Mags[Mags.Size() - 1] >= MaxPerUnit || owner.CountInv(roundtype) == 0)
		{
			return false;
		}
		owner.A_TakeInventory(roundtype, 1, TIF_NOTAKEINFINITE);
		owner.A_StartSound("weapons/rifleclick2", 7);
		if (random(0,100) <= 10)
		{
			owner.A_StartSound("weapons/bigcrack", 8, CHANF_OVERLAP);
			owner.A_SpawnItemEx("WallChunk", 12, 0, owner.height - 12, 4, frandom(-2, 2), frandom(2, 4));
			return false;
		}
		owner.A_StartSound("weapons/pocket", 9, volume: frandom(0.1, 0.6));
		Mags[mindex]++;
		return true;
	}
	
	States
	{
		Spawn:
			PDMG A -1;
			Stop;
		SpawnEmpty:
			PDMG B -1
			{
				bROLLSPRITE = true;
				bROLLCENTER = true;
				roll = randompick(0, 0, 0, 0, 2, 2, 2, 2, 1, 3) * 90;
			}
			Stop;
	}
}
