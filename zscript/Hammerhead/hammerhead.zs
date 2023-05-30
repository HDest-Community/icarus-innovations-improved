class HDHammerhead : HDCellWeapon
{
	enum HammerheadProperties
	{
		HHProp_Flags,

		HHProp_BatteryFirst,
		HHProp_BatteryLast = HHProp_BatteryFirst + 3,

		HHProp_Mode, // [Ace] 0-2, 25%, 50%, and 100%.
		HHProp_ActiveBatteries, // [Ace] This is a bitfield.
		HHProp_LoadType,
		HHProp_Rpm,
		HHProp_Heat,
		HHProp_Dot
	}

	override void PostBeginPlay()
	{
		weaponspecial = 1337; // [Ace] UaS sling compatibility.
		Super.PostBeginPlay();
	}

	override void Tick()
	{
		if (WeaponStatus[HHProp_Heat] > 0)
		{
			DrainHeat(HHProp_Heat, 10, 0.5, 1.5, 0.6);
		}

		WeaponStatus[HHProp_Rpm] = clamp(WeaponStatus[HHProp_Rpm] - 4, 0, MaxRpm);
		double heatFac = WeaponStatus[HHProp_Heat] / double(A_GetMaxHeat());
		if (heatFac > 1.0 && owner && random(1, 100) <= 100 * (heatFac - 1))
		{
			owner.A_GiveInventory('Heat', 5);
		}

		/*int active = A_GetActiveBatteryCount(true);
		Console.Printf("\c[Green]RPM:\c- %i \c[Green]Heat:\c- %i \c[Green]Batteries:\c- %i %i %i %i - %i, %i, %i, %i - %i",
	 		WeaponStatus[HHProp_Rpm],
			WeaponStatus[HHProp_Heat],
	 		WeaponStatus[HHProp_BatteryFirst], WeaponStatus[HHProp_BatteryFirst + 1], WeaponStatus[HHProp_BatteryFirst + 2], WeaponStatus[HHProp_BatteryLast],
	 		WeaponStatus[HHProp_ActiveBatteries] & 1 > 0, WeaponStatus[HHProp_ActiveBatteries] & 2 > 0, WeaponStatus[HHProp_ActiveBatteries] & 4 > 0, WeaponStatus[HHProp_ActiveBatteries] & 8 > 0,
	 		active);*/

		Super.Tick();
	}

	override void DetachFromOwner()
	{
		owner.A_StopSound(6);
		Super.DetachFromOwner();
	}

	override void PreTravelled()
	{
		WeaponStatus[HHProp_Heat] = 0;
		Super.PreTravelled();
	}

	override bool AddSpareWeapon(actor newowner) { return AddSpareWeaponRegular(newowner); }
	override HDWeapon GetSpareWeapon(actor newowner , bool reverse, bool doselect) { return GetSpareWeaponRegular(newowner, reverse, doselect); }
	override double GunMass()
	{
		double baseMass = 10;
		for (int i = HHProp_BatteryFirst; i <= HHProp_BatteryLast; ++i)
		{
			if (WeaponStatus[i] > -1)
			{
				baseMass += ENC_BATTERY_LOADED * 0.03;
			}
		}
		return baseMass;
	}
	override double WeaponBulk()
	{
		double baseBulk = 150;
		for (int i = HHProp_BatteryFirst; i <= HHProp_BatteryLast; ++i)
		{
			if (WeaponStatus[i] > -1)
			{
				baseBulk += ENC_BATTERY_LOADED;
			}
		}
		return baseBulk;
	}
	override string, double GetPickupSprite() { return "BLNGZ0", 0.60; }
	override void InitializeWepStats(bool idfa)
	{
		for (int i = HHProp_BatteryFirst; i <= HHProp_BatteryLast; ++i)
		{
			WeaponStatus[i] = GetDefaultByType('HDBattery').MaxPerUnit * ShotsPerUnit;
		}
		WeaponStatus[HHProp_Mode] = 1;
		WeaponStatus[HHProp_ActiveBatteries] = (1 | 2);
	}

	override string GetHelpText()
	{
		return String.Format(WEPHELP_FIRE.."  Shoot\n"
		..WEPHELP_ALTFIRE.." (hold)  Vent heat\n"
		..WEPHELP_FIREMODE.."  Switch mode\n"
		..WEPHELP_RELOADRELOAD
		..WEPHELP_UNLOADUNLOAD);
	}

	override string PickupMessage()
	{
		return String.Format("You got the CIR-37 'Hammerhead' plasma minigun.");
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		if (sb.HudLevel == 1)
		{
			sb.DrawBattery(-60, -4, sb.DI_SCREEN_CENTER_BOTTOM, reloadorder: true);
			sb.DrawNum(hpl.CountInv("HDBattery"), -52, -8, sb.DI_SCREEN_CENTER_BOTTOM);
		}

		for (int i = 0; i < HHProp_BatteryLast; ++i)
		{
			int bat = WeaponStatus[HHProp_BatteryFirst + i];
			if (bat == 0)
			{
				sb.DrawString(sb.mAmountFont, "0", (-37 + 6 * i, -15), sb.DI_TEXT_ALIGN_RIGHT | sb.DI_SCREEN_CENTER_BOTTOM, Font.CR_DARKGRAY);
			}
			else if (bat > 0)
			{
				double batFac = min(1.0, bat / double(20 * ShotsPerUnit));
				sb.DrawRect(-36 + 6 * i, -9, -4, -int(max(1, 24 * batFac)));
			}

			if (WeaponStatus[HHProp_ActiveBatteries] & (1 << i))
			{
				sb.DrawRect(-36 + 6 * i, -6, -4, -2);
			}
		}

		double heatFac = WeaponStatus[HHProp_Heat] / double(A_GetMaxHeat());
		if (heatFac > 0)
		{
			sb.Fill(heatFac >= 1.0 ? 0xFFFF8811 : (sb.sbcolour | 0xFF000000), -16, -6, 2, -int(24 * heatFac), sb.DI_SCREEN_CENTER_BOTTOM);
		}
	}

	override void SetReflexReticle(int which) { WeaponStatus[HHProp_Dot] = which; }
	override void DrawSightPicture(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl, bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot)
	{
		double dotoff = max(abs(bob.x), abs(bob.y));
		if (dotoff < 6)
		{
			string whichdot = sb.ChooseReflexReticle(WeaponStatus[HHProp_Dot]);
			sb.DrawImage(whichdot, (0, 0) + bob * 3, sb.DI_SCREEN_CENTER | sb.DI_ITEM_CENTER, alpha: 0.8 - dotoff * 0.04, col: 0xFF000000 | sb.crosshaircolor.GetInt());
		}

		sb.DrawImage("HAMRSITE", (0, 0) + bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_CENTER);
	}

	private action bool A_InsertBattery(HDBattery bat)
	{
		if (!bat || invoker.WeaponStatus[HHProp_BatteryLast] > -1)
		{
			return false;
		}

		// [Ace] Shift the other batteries to the right.
		for (int i = HHProp_BatteryLast; i > HHProp_BatteryFirst; --i)
		{
			invoker.WeaponStatus[i] = invoker.WeaponStatus[i - 1];
			invoker.WeaponStatus[i - 1] = -1;
		}

		invoker.WeaponStatus[HHProp_BatteryFirst] = bat.TakeMag(true) * ShotsPerUnit;
		return true;
	}

	private action bool A_RemoveBattery(bool toPockets)
	{
		if (invoker.WeaponStatus[HHProp_BatteryFirst] == -1)
		{
			return false;
		}

		int remAmt = AceCore.GetRealBatteryCharge(invoker.WeaponStatus[HHProp_BatteryFirst], ShotsPerUnit, false);
		invoker.WeaponStatus[HHProp_BatteryFirst] = -1;

		if (!invoker.owner.A_JumpIfInventory('HDBattery', 0, "Null") && toPockets)
		{
			HDMagAmmo.GiveMag(invoker.owner, 'HDBattery', remAmt);
		}
		else
		{
			HDMagAmmo.SpawnMag(invoker.owner, 'HDBattery', remAmt);
		}

		for (int i = HHProp_BatteryFirst; i < HHProp_BatteryLast; ++i)
		{
			invoker.WeaponStatus[i] = invoker.WeaponStatus[i + 1];
			invoker.WeaponStatus[i + 1] = -1;
		}
		return true;
	}

	private clearscope action int A_GetBatteryCount(int minCharge = 1)
	{
		int count = 0;
		for (int i = HHProp_BatteryFirst; i <= HHProp_BatteryLast; ++i)
		{
			if (invoker.WeaponStatus[i] >= minCharge)
			{
				count++;
			}
		}
		return count;
	}

	// [Ace] This gets how many batteries are currently activated. If the "real" argument is true, returns the number of batteries currently affecting something.
	// If batteries 1 and 2 and active, but only 1 has a charge in it, return 1.
	private clearscope action int A_GetActiveBatteryCount(int real)
	{
		int count = 0;
		for (int i = 0; i < HHProp_BatteryLast; ++i)
		{
			if (invoker.WeaponStatus[HHProp_ActiveBatteries] & (1 << i) && (!real || invoker.WeaponStatus[HHProp_BatteryFirst + i] > 0))
			{
				count++;
			}
		}
		return count;
	}

	private action void A_CycleActiveBatteries()
	{
		int active = A_GetActiveBatteryCount(false);
		if (active == 4)
		{
			return;
		}
		
		// [Ace] We select only the first 4 bits and discard the rest because the bits will eventually wrap around and cause issues.
		int actBits = invoker.WeaponStatus[HHProp_ActiveBatteries] & 0x0F;
		int shift = active > 1 ? 2 : 1;
		actBits = (actBits << shift) | (actBits >> (4 - shift));
		invoker.WeaponStatus[HHProp_ActiveBatteries] = actBits;
	}

	private action int A_CycleModes(bool same = false)
	{
		if (!same)
		{
			++invoker.WeaponStatus[HHProp_Mode] %= 3;
		}

		int maxBatteries = 0;
		switch (invoker.WeaponStatus[HHProp_Mode])
		{
			case 0: maxBatteries = 1; break;
			case 1: maxBatteries = 2; break;
			case 2: maxBatteries = 4; break;
		}

		int newActive = 0;
		for (int i = 0, count = 0; i < HHProp_BatteryLast; ++i)
		{
			newActive |= 1 << i;
			if (++count == maxBatteries)
			{
				break;
			}
		}
		invoker.WeaponStatus[HHProp_ActiveBatteries] = newActive;
		return invoker.WeaponStatus[HHProp_Mode];
	}

	private action void A_DrainActiveBatteries()
	{
		for (int i = 0; i < HHProp_BatteryLast; ++i)
		{
			if (invoker.WeaponStatus[HHProp_BatteryFirst + i] > 0 && invoker.WeaponStatus[HHProp_ActiveBatteries] & (1 << i))
			{
				invoker.WeaponStatus[HHProp_BatteryFirst + i]--;
			}
		}
	}

	private clearscope action int A_GetMaxHeat(bool raw = false)
	{
		double mult = 1.0;
		return int(1000 * mult);
	}

	const MaxRpm = 700;
	const ShotsPerUnit = 5;

	Default
	{
		-HDWEAPON.FITSINBACKPACK
		Weapon.SelectionOrder 300;
		Weapon.SlotNumber 4;
		Weapon.SlotPriority 0.5;
		HDWeapon.BarrelSize 30, 3, 3;
		Scale 0.45;
		Tag "CIR-37 'Hammerhead' Plasma Minigun";
		HDWeapon.Refid "hhd";
	}

	States
	{
		Spawn:
			BLNG Z -1;
			Stop;
		Ready:
			BLNG A 1 A_WeaponReady(WRF_ALL);
			Goto ReadyEnd;
		Select0:
			BLNG A 0;
			Goto Select0Big;
		Deselect0:
			BLNG A 0;
			Goto Deselect0Big;
		User3:
			#### A 0 A_MagManager("HDBattery");
			Goto Ready;
		Fire:
			#### A 0
			{
				if (A_GetBatteryCount(1) == 0)
				{
					SetWeaponState('Nope');
					return;
				}
			}
			BLNF A 1 Bright
			{
				int active = A_GetActiveBatteryCount(true);
				if (active == 0)
				{
					SetWeaponState('FireWait');
					return;
				}

				let psp = player.GetPSprite(PSP_WEAPON);
				psp.frame = random(0, 3);
				
				double rpmFac = invoker.WeaponStatus[HHProp_Rpm] / double(MaxRpm);
				A_StartSound("Hammerhead/Fire", 8, pitch: 1.2 + 0.10 * rpmFac);
				
				invoker.WeaponStatus[HHProp_Heat] += 8 * active;
				double heatFac = invoker.WeaponStatus[HHProp_Heat] / double(A_GetMaxHeat());

				vector2 spread = (1.0, 0.5) * 3 * heatFac;
				vector2 shake = (0.5, 0.5) * rpmFac;

				A_MuzzleClimb(frandom(-shake.x, shake.x), frandom(-shake.y, shake.y), frandom(-shake.x, shake.x) * 0.5, frandom(-shake.y, shake.y) * 0.5);

				let proj = HammerheadPlasmaProjectile(Spawn('HammerheadPlasmaProjectile', pos + GunPos((0, 0, -4))));
				proj.angle = angle + frandom(-spread.x, spread.x);
				proj.pitch = pitch + frandom(-spread.y, spread.y);
				proj.target = self;
				proj.master = self;
				proj.Charge = active;

				A_DrainActiveBatteries();
			}
			BLNG B 1;
		FireWait:
			BLNG A 0
			{
				int active = A_GetActiveBatteryCount(true);
				if (active > 0)
				{
					invoker.WeaponStatus[HHProp_Rpm] += 40 + 15 * active;
				}
				double rpmFac = invoker.WeaponStatus[HHProp_Rpm] / double(MaxRpm);
				A_SetTics(int(ceil(1 + 4 * (1.0 - rpmFac))));
				A_CycleActiveBatteries();
			}
			BLNG A 0 A_Refire('Fire');
			Goto Ready;

		Altfire:
			BLNP A 3;
			BLNP B 3 A_StartSound("Hammerhead/HandlePull", CHAN_WEAPON);
			BLNP C 3
			{
				if (invoker.WeaponStatus[HHProp_Heat] > 300)
				{
					A_StartSound("Hammerhead/PressureRelease", 5);
				}
			}
			BLNP D 2
			{
				if (!PressingAltfire())
				{
					A_StopSound(6);
					SetWeaponState('EndVent');
					return;
				}

				if (invoker.WeaponStatus[HHProp_Heat] > 0)
				{
					A_StartSound("Hammerhead/Pressure", 6, CHANF_LOOPING);
					invoker.WeaponStatus[HHProp_Heat] = max(0, invoker.WeaponStatus[HHProp_Heat] - random(20, 40));

					vector3 gpos = GunPos((0, 0, -4));
					Actor a = null;
					a = Spawn('HammerheadSteam', pos + gpos); a.angle = angle - 90; a.A_ChangeVelocity(3, 0, 0, CVF_RELATIVE);
					a = Spawn('HammerheadSteam', pos + gpos); a.angle = angle + 90; a.A_ChangeVelocity(3, 0, 0, CVF_RELATIVE);
				}
				else
				{
					A_StopSound(6);
				}
			}
			Wait;
		EndVent:
			BLNP D 2;
			BLNP C 3 A_StartSound("Hammerhead/HandlePush", CHAN_WEAPON);
			BLNP B 3;
			BLNP A 3;
			Goto Ready;

		Firemode:
			BLNG A 5 Offset(0, 35)
			{
				double sndPitch = 0.8;
				switch (A_CycleModes())
				{
					case 1: sndPitch = 0.95; break;
					case 2: sndPitch = 1.10; break;
				}
				A_StartSound("Hammerhead/SwitchMode", 5, CHANF_OVERLAP, attenuation: 1.5, pitch: sndPitch);
			}
			Goto Nope;

		Reload:
			BLNG A 0
			{
				if (invoker.WeaponStatus[HHProp_BatteryLast] > -1 || !CheckInventory("HDBattery", 1) || HDMagAmmo.NothingLoaded(self, 'HDBattery') || invoker.WeaponStatus[HHProp_Heat] > 0)
				{
					SetWeaponState("Nope");
					return;
				}
				invoker.WeaponStatus[HHProp_LoadType] = 1;
			}
			Goto BeginReload;
		Unload:
			BLNG A 0
			{
				if (invoker.WeaponStatus[HHProp_BatteryFirst] == -1 || invoker.WeaponStatus[HHProp_Heat] > 0)
				{
					SetWeaponState("Nope");
					return;
				}
				invoker.WeaponStatus[HHProp_LoadType] = 0;
			}
			Goto BeginReload;

		BeginReload:
			#### # 3 Offset(-2, 35);
			#### # 3 Offset(-3, 42);
			#### # 3 Offset(-4, 48);
			#### # 3 Offset(-4, 52);
		DoReload:
			#### # 5 Offset(-4, 56)
			{
				A_MuzzleClimb(-frandom(1.2, 2.4), frandom(1.2, 2.4));
				A_StartSound("weapons/vulcopen1", CHAN_WEAPON, CHANF_OVERLAP);
			}
			#### # 8 Offset(-4, 55)
			{
				A_MuzzleClimb(-frandom(1.2, 2.4), frandom(1.2, 2.4));
				A_StartSound("weapons/vulcopen2", CHAN_WEAPON, CHANF_OVERLAP);
			}
			#### # 10 Offset(-4, 52)
			{
				switch (invoker.WeaponStatus[HHProp_LoadType])
				{
					case 0:
					{
						A_MuzzleClimb(-frandom(1.2, 2.4), frandom(1.2, 2.4));
						A_StartSound("Hammerhead/BatteryOut", CHAN_WEAPON, CHANF_OVERLAP);

						bool toPockets = PressingUnload() || PressingReload();
						A_RemoveBattery(toPockets);
						if (toPockets)
						{
							A_StartSound("weapons/pocket", CHAN_WEAPON, CHANF_OVERLAP);
							A_SetTics(25);
						}
						break;
					}
					case 1:
					{
						let bat = HDBattery(FindInventory('HDBattery'));
						if (bat)
						{
							A_MuzzleClimb(-frandom(1.2, 2.4), frandom(1.2, 2.4));
							A_StartSound("Hammerhead/BatteryIn", CHAN_WEAPON, CHANF_OVERLAP);
							A_InsertBattery(bat);
							A_SetTics(15);
						}
						break;
					}
				}
			}
			#### # 6 Offset(-4, 56);
			#### # 2
			{
				switch (invoker.WeaponStatus[HHProp_LoadType])
				{
					case 0:
					{
						if (A_GetBatteryCount(0) == 0)
						{
							SetWeaponState('ReloadEnd');
							return;
						}
						break;
					}
					case 1:
					{
						let bat = HDBattery(FindInventory('HDBattery'));
						if (!bat || invoker.WeaponStatus[HHProp_BatteryLast] > -1 || PressingReload() || PressingUnload())
						{
							SetWeaponState('ReloadEnd');
							return;
						}
						else
						{
							A_StartSound("weapons/pocket", CHAN_WEAPON, CHANF_OVERLAP);
							A_SetTics(15);
						}
						break;
					}
				}
			}
			Goto DoReload + 2;
		ReloadEnd:
			#### # 3 Offset(-3, 42);
			#### # 3 Offset(-2, 38);
			#### # 3 Offset(-1, 36);
			#### # 3 Offset(0, 34);
			Goto Nope;
	}
}

class HammerheadRandom : IdleDummy
{
	States
	{
		Spawn:
			TNT1 A 0 NoDelay
			{
				for (double i = 0; i < 360; i += 360 / 2.0)
				{
					A_SpawnItemEx("HDBattery", 8, angle: i + 45, flags: SXF_NOCHECKPOSITION);	
				}
				let wpn = HDHammerhead(Spawn("HDHammerhead", pos));
				if (!wpn)
				{
					return;
				}
			}
			Stop;
	}
}

class HammerheadPlasmaProjectile : SlowProjectile
{
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		A_ChangeVelocity(speed * cos(pitch), 0, speed * sin(-pitch), CVF_RELATIVE);
		Scale += (Charge, Charge) * 0.02;
	}
	override void GunSmoke() { }
	override void ExplodeSlowMissile(Line hitLine, Actor hitActor)
	{
		if (max(abs(pos.x), abs(pos.y)) >= 32768)
		{
			Destroy();
			return;
		}

		A_AlertMonsters(HDCONST_ONEMETRE * 10);
		if (hitActor)
		{
			hitActor.DamageMobj(self, target, random(40, 50) * Charge, 'Plasma');
			hitActor.A_GiveInventory('Heat', 25 * Charge);
		}
		ExplodeMissile(hitLine, null);
	}
	override void Tick()
	{
		Super.Tick();

		vector3 diff = Level.Vec3Diff(pos, Prev);
		double dist = diff.length();
		vector3 unit = diff.unit();

		for (int i = 0; i < dist; ++i)
		{
			double chargeFac = 1.0 + Charge * 0.025;
			A_SpawnParticle(0x55FF33, SPF_FULLBRIGHT, random(3, 6), frandom(2.0, 3.5), angle,
				i * unit.x + frandom(-0.25, 0.25) * chargeFac,
				i * unit.y + frandom(-0.25, 0.25) * chargeFac,
				i * unit.z + frandom(-0.25, 0.25) * chargeFac,
				frandom(-0.35, 0.35) * chargeFac,
				frandom(-0.35, 0.35) * chargeFac,
				frandom(-0.35, 0.35) * chargeFac);
		}
	}

	int Charge;

	Default
	{
		Speed HDCONST_MPSTODUPT * 50;
		Gravity 0.035;
		Renderstyle "Add";
		Scale 0.12;
		Mass 0;
		Decal "HammerheadScorch";
	}

	States
	{
		Spawn:
			HMPL A -1 Bright;
			Stop;
		Death:
			HMPL B 2
			{
				bNOINTERACTION = true;
				bMISSILE = false;
				scale *= 4;
				A_StartSound("Hammerhead/PlasmaHit");
			}
			HMPL CD 2;
			TNT1 A 10;
			Stop;
	}
}

class HammerheadSteam : ACESmokeBase
{
	Default
	{
		ACESmokeBase.GrowSpeed 0.0025, 0.003;
		ACESmokeBase.FadeSpeed 0.008, 0.009;
		Gravity -0.04;
		Scale 0.015;
	}
}