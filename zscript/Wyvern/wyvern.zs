class HDWyvern : HDWeapon {

	const MaxSideRounds = 12;

	private transient CVar SwapBarrels;

	default {
		-HDWeapon.FITSINBACKPACK
		weapon.selectionOrder 300;
		weapon.slotNumber 8;
		weapon.slotPriority 4;
		HDWeapon.barrelSize 30, 1, 1;
		Scale 0.55;
		weapon.BobRangeX 0.18;
		weapon.BobRangeY 0.7;
		tag "Wyvern";
		HDWeapon.Refid "wyv";
	}

	override string, double GetPickupSprite() {
		string Frame = "";
		switch (weaponStatus[SHOTS_SIDESADDLE] / 2) {
			case 6:  Frame = "A"; break;
			case 5:  Frame = "B"; break;
			case 4:  Frame = "C"; break;
			case 3:  Frame = "D"; break;
			case 2:  Frame = "E"; break;
			case 1:  Frame = "F"; break;
			default: Frame = "G"; break;
		}

		return "WYVZ"..Frame.."0", 0.9;
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		if (sb.hudlevel == 1) {
			sb.DrawImage("OG10A0", (-47, -10), sb.DI_SCREEN_CENTER_BOTTOM);
			sb.DrawNum(hpl.CountInv("HD50OMGAmmo"), -46, -8, sb.DI_SCREEN_CENTER_BOTTOM);
		}
		vector2 ShellOff = (-31, -18);
		
		if (hdw.weaponStatus[WYVS_FLAGS] & WYVF_DOUBLE) {
			ShellOff = (-27, -22);
			sb.DrawImage("STBURAUT", (-23, -17), sb.DI_SCREEN_CENTER_BOTTOM);
		}

		if (hdw.weaponStatus[WYVS_CHAMBER1] > 1) {
			sb.DrawRect(ShellOff.x, -16, 2, 7);
		} else if (hdw.weaponStatus[WYVS_CHAMBER1] > 0) {
			sb.DrawRect(ShellOff.x, -12, 2, 3);
		}

		if (hdw.weaponStatus[WYVS_CHAMBER2] > 1) {
			sb.DrawRect(ShellOff.y, -16, 2, 7);
		} else if (hdw.weaponStatus[WYVS_CHAMBER2] > 0) {
			sb.DrawRect(ShellOff.y, -12, 2, 3);
		}
		
		for (int i = hdw.weaponStatus[SHOTS_SIDESADDLE]; i > 0; i--) {
			sb.DrawRect(-11 - i * 2, -7, 1, 5);
		}
	}

	override string GetHelpText() {
		return WEPHELP_FIRE.."  Shoot Left\n"
		..WEPHELP_ALTFIRE.."  Shoot Right\n"
		..WEPHELP_RELOAD.."  Reload (side saddles first)\n"
		..WEPHELP_ALTRELOAD.."  Reload (pockets only)\n"
		..WEPHELP_FIREMODE.."  Hold to force double shot\n"
		..WEPHELP_FIREMODE.."+"..WEPHELP_RELOAD.."  Load side saddles\n"
		..WEPHELP_UNLOADUNLOAD;
	}

	override void DrawSightPicture(
		HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl,
		bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot
	) {
		int cx, cy, cw, ch;
		// int ScaledYOffset = 48;
		// int ScaledWidth = 89;

		[cx, cy, cw, ch] = Screen.GetClipRect();
		sb.SetClipRect(
			-16 + bob.x, -4 + bob.y, 32, 12,
			sb.DI_SCREEN_CENTER
		);
		vector2 bob2 = bob * 3;
		bob2.y = clamp(bob2.y, -8, 8);
		sb.DrawImage(
			"FRNTSITE", bob2, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP,
			scale: (0.7, 1.0)
		);
		sb.SetClipRect(cx, cy, cw, ch);
		sb.DrawImage(
			"DBBAKSIT", bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP,
			alpha: 0.9
		);
	}

	override void PostBeginPlay() {
		weaponspecial = 1337; // [Ace] UaS sling compatibility.

		Super.PostBeginPlay();
	}
	
	override double GunMass() {
		double BaseMass = 6;
		if (weaponStatus[WYVS_CHAMBER1] > 0) {
			BaseMass += 0.2;
		}
		if (weaponStatus[WYVS_CHAMBER2] > 0) {
			BaseMass += 0.2;
		}
		BaseMass += 0.2 * weaponStatus[SHOTS_SIDESADDLE];
		return BaseMass;
	}

	override double WeaponBulk() {
		double BaseBulk = 110;
		if (weaponStatus[WYVS_CHAMBER1]  > 0)
		{
			BaseBulk += ENC_50OMG_LOADED * 0.75;
		}
		if (weaponStatus[WYVS_CHAMBER2] > 0)
		{
			BaseBulk += ENC_50OMG_LOADED * 0.75;
		}
		return BaseBulk + (ENC_50OMG_LOADED * weaponStatus[SHOTS_SIDESADDLE] * 0.75);
	}

	override bool AddSpareWeapon(actor newowner) {
		return AddSpareWeaponRegular(newowner);
	}

	override HDWeapon GetSpareWeapon(actor newowner , bool reverse, bool doselect) {
		return GetSpareWeaponRegular(newowner, reverse, doselect);
	}

	override void DropOneAmmo(int amt) {
		if (owner)
		{
			amt = clamp(amt, 1, 10);
			owner.A_DropInventory("HD50OMGAmmo", amt * 10);
		}
	}

	override string PickupMessage() {
		string autoStr = weaponStatus[WYVS_FLAGS] & WYVF_AUTOLOADER ? "autoloading " : "";
		return String.Format("You picked up the %s'Wyvern' .50 cal. double barreled rifle.", autoStr);
	}

	protected action void A_WyvernFire(int barrel) {
		A_Light2();
		A_ZoomRecoil(0.9);
		DistantNoise.Make(self, "world/shotgunfar");
		A_AlertMonsters();
		let psp = player.GetPSprite(PSP_WEAPON);

		if (barrel & 1) {
			psp.frame = invoker.weaponStatus[WYVS_CHAMBER2] > 1 ? 0 : 1;
			A_MuzzleClimb(0, 0, -0.2, -0.8, -frandom(0.5, 0.9), -frandom(3.2, 4.0), -frandom(0.5, 0.9), -frandom(3.2, 4.0));
			HDBulletActor.FireBullet(self, "HDB_50OMG");
			invoker.weaponStatus[WYVS_CHAMBER1] = 1;
			A_StartSound("Wyvern/Fire", CHAN_WEAPON, CHANF_OVERLAP);
		}

		if (barrel & 2) {
			psp.frame = invoker.weaponStatus[WYVS_CHAMBER1] > 1 ? 2 : 3;
			A_MuzzleClimb(0, 0, 0.2, -0.8, frandom(0.5, 0.9), -frandom(3.2, 4.0), frandom(0.5, 0.9), -frandom(3.2, 4.0));
			HDBulletActor.FireBullet(self, "HDB_50OMG");
			invoker.weaponStatus[WYVS_CHAMBER2] = 1;
			A_StartSound("Wyvern/Fire", CHAN_WEAPON, CHANF_OVERLAP);
		}

		if (barrel & 1 && barrel & 2) {
			psp.frame = 4;
		}
	}

	protected action void A_CheckIdleHammer() {
		let psp = player.GetPSprite(PSP_WEAPON);

		if (invoker.weaponStatus[WYVS_CHAMBER1] > 1 && invoker.weaponStatus[WYVS_CHAMBER2] > 1) {
			psp.frame = 0;
		} else if (invoker.weaponStatus[WYVS_CHAMBER1] > 1) {
			psp.frame = 1;
		} else if (invoker.weaponStatus[WYVS_CHAMBER2] > 1) {
			psp.frame = 2;
		} else {
			psp.frame = 3;
		}
	}

	States
	{
		Spawn:
			WYVZ ABCDEFG -1 NoDelay
			{
				frame = 6 - invoker.weaponStatus[SHOTS_SIDESADDLE] / 2;
			}
		Select0:
			WYVG D 0;
			Goto Select0Small;
		Deselect0:
			WYVG D 0;
			Goto Deselect0Small;
		Fire:
		AltFire:
			WYVG # 0 A_ClearRefire();
		Ready:
			WYVG # 1
			{
				A_CheckIdleHammer();

				if (PressingFiremode()) {
					invoker.weaponStatus[WYVS_FLAGS] |= WYVF_DOUBLE;
					if (PressingReload() && invoker.weaponStatus[SHOTS_SIDESADDLE] < MaxSideRounds) {
						invoker.weaponStatus[WYVS_FLAGS] &= ~WYVF_DOUBLE;
						SetWeaponState('ReloadSS');
						return;
					}
				} else {
					invoker.weaponStatus[WYVS_FLAGS] &= ~WYVF_DOUBLE;
				}

				// [Ace] I know there's a better way to do all this. I just don't care enough to do it.
				// It's going to take too much time to figure it out for exactly no benefit at all whatsoever.
				if (invoker.weaponStatus[WYVS_FLAGS] & WYVF_DOUBLE && (PressingFire() || PressingAltfire())) {
					if (invoker.weaponStatus[WYVS_CHAMBER1] == 2 && invoker.weaponStatus[WYVS_CHAMBER2] == 2) {
						SetWeaponState('ShootBoth');
						return;
					} else if (invoker.weaponStatus[WYVS_CHAMBER1] == 2) {
						SetWeaponState('ShootLeft');
						return;
					} else if (invoker.weaponStatus[WYVS_CHAMBER2] == 2) {
						SetWeaponState('ShootRight');
						return;
					} else {
						SetWeaponState('Nope');
						return;
					}
				}

				if (!invoker.SwapBarrels)
				{
					invoker.SwapBarrels = CVar.GetCVar("hd_swapbarrels", player);
				}
				bool Swap = invoker.SwapBarrels && invoker.SwapBarrels.GetBool();
				if ((!Swap && PressingFire() || Swap && PressingAltfire()) && invoker.weaponStatus[WYVS_CHAMBER1] == 2)
				{
					SetWeaponState('ShootLeft');
					return;
				}
				if ((!Swap && PressingAltFire() || Swap && PressingFire()) && invoker.weaponStatus[WYVS_CHAMBER2] == 2)
				{
					SetWeaponState('ShootRight');
					return;
				}

				A_WeaponReady((WRF_ALL | WRF_NOFIRE) & ~WRF_ALLOWUSER2);
			}
			WYVG # 0 A_WeaponReady();
			Goto ReadyEnd;

		ShootLeft:
			WYVF # 1 Bright A_WyvernFire(1);
			WYVG # 1 Offset(0, 44) A_CheckIdleHammer();
			WYVG # 1 Offset(0, 38);
			Goto Ready;
		ShootRight:
			WYVF # 1 Bright A_WyvernFire(2);
			WYVG # 1 Offset(0, 44) A_CheckIdleHammer();
			WYVG # 1 Offset(0, 38);
			Goto Ready;
		ShootBoth:
			WYVF # 1 Bright A_WyvernFire(3);
			WYVG # 1 Offset(0, 52) A_CheckIdleHammer();
			WYVG # 1 Offset(0, 42);
			WYVG # 1 Offset(0, 36);
			Goto Ready;

		AltReload:
			WYVG # 0
			{
				if (
					CountInv("HD50OMGAmmo") > 0
					&& (
						invoker.weaponStatus[WYVS_CHAMBER1] < 2
						|| invoker.weaponStatus[WYVS_CHAMBER2] < 2
					)
				) {
					invoker.weaponStatus[0] |= WYVF_FROMPOCKETS;
					invoker.weaponStatus[0] &= ~WYVF_JUSTUNLOAD;
				} else {
					SetWeaponState('Nope');
				}
			}
			Goto ReloadStart;
		Reload:
			WYVG # 0
			{
				if(
					invoker.weaponStatus[WYVS_CHAMBER1] > 1
					&& invoker.weaponStatus[WYVS_CHAMBER2] > 1
				) {
					SetWeaponState('ReloadSS');
				}

				invoker.weaponStatus[WYVS_FLAGS] &= ~WYVF_JUSTUNLOAD;

				if (invoker.weaponStatus[SHOTS_SIDESADDLE] > 0) {
					invoker.weaponStatus[WYVS_FLAGS] &= ~WYVF_FROMPOCKETS;
				} else if (CountInv("HD50OMGAmmo")) {
					invoker.weaponStatus[WYVS_FLAGS] |= WYVF_FROMPOCKETS;
				} else {
					SetWeaponState('Nope');
				}
			}
			Goto ReloadStart;
		Unload:
			WYVG # 2 Offset(0, 34)
			{
				if (invoker.weaponStatus[SHOTS_SIDESADDLE] > 0) {
					SetWeaponState('UnloadSS');
				} else {
					invoker.weaponStatus[WYVS_FLAGS] |= WYVF_JUSTUNLOAD;
				}
			}
			Goto UnloadStart;

		ReloadStart:
		UnloadStart:
			WYVG # 2 Offset(0, 34);
			WYVG # 1 Offset(0, 40);
			WYVG # 3 Offset(0, 46);
			WYVR A 5 Offset(0, 47) A_StartSound("Wyvern/Open", 8);
			WYVR B 4 Offset(0, 46) A_MuzzleClimb(
				frandom(0.6, 1.2), frandom(0.6, 1.2),
				frandom(0.6, 1.2), frandom(0.6, 1.2),
				frandom(1.2, 2.4), frandom(1.2, 2.4)
			);
			WYVR C 3 Offset(0, 36) {
				// Eject whatever is already loaded
				for (int i = 0; i < 2; ++i) {
					int chamber = invoker.weaponStatus[WYVS_CHAMBER1 + i];
					invoker.weaponStatus[WYVS_CHAMBER1 + i] = 0;
					
					actor sss = null;

					if (chamber > 1) {
						sss = Spawn("HDUnSpent50OMG", pos + HDMath.GetGunPos(self),ALLOW_REPLACE);
					} else if (chamber == 1) {
						sss = Spawn("HDSpent50OMG", pos + HDMath.GetGunPos(self),ALLOW_REPLACE);
					}

					if (!!sss) {
						double aaa = angle + frandom(-20,20);
						sss.pitch = pitch;
						sss.angle = angle;
						sss.vel = (cos(aaa),sin(aaa),2);
						
						if(chamber > 1) sss.vel*=frandom(0.5,2);
						
						sss.vel += vel;
						sss.target = self;
					}
				}
			}
			WYVR C 2 Offset(1, 34);
			WYVR C 2 Offset(2, 34);
			WYVR C 2 Offset(4, 34);
			WYVR C 8 Offset(0, 36)
			{
				if (invoker.weaponStatus[WYVS_FLAGS] & WYVF_JUSTUNLOAD) {
					SetWeaponState('UnloadEnd');
					return;
				}

				if (invoker.weaponStatus[WYVS_FLAGS] & WYVF_FROMPOCKETS) {
					A_StartSound("weapons/pocket", 9);
				} else {
					if (invoker.weaponStatus[WYVS_FLAGS] & WYVF_AUTOLOADER && invoker.weaponStatus[SHOTS_SIDESADDLE] > 0) {
						invoker.weaponStatus[SHOTS_SIDESADDLE]--;
						invoker.weaponStatus[WYVS_CHAMBER1] = 2;
						if (invoker.weaponStatus[SHOTS_SIDESADDLE] > 0) {
							invoker.weaponStatus[SHOTS_SIDESADDLE]--;
							invoker.weaponStatus[WYVS_CHAMBER2] = 2;
						}
						SetWeaponState('UnloadEndQuick');
						return;
					}
					SetWeaponState('ReloadContinue');
				}
			}
			WYVR C 4 Offset(2, 35);
			WYVR C 4 Offset(0, 35);
			WYVR C 4 Offset(0, 34);
		ReloadContinue:
			WYVR C 5 Offset(1, 35);
			WYVR C 2 Offset(0, 36);
			WYVR D 2 Offset(0, 40);
			WYVR D 1 Offset(0, 46);
			WYVR E 2 Offset(0, 54);
			TNT1 A 4
			{
				// Take up to 2 rounds in hand
				int handRounds = 0;
				if (invoker.weaponStatus[WYVS_FLAGS] & WYVF_FROMPOCKETS) {
					handRounds = min(2, CountInv("HD50OMGAmmo"));

					if (handRounds > 0) A_TakeInventory("HD50OMGAmmo", handRounds);
				} else {
					handRounds = min(2, invoker.weaponStatus[SHOTS_SIDESADDLE]);
					invoker.weaponStatus[SHOTS_SIDESADDLE] -= handRounds;
				}

				// If the above leaves you with nothing, abort
				if (handRounds == 0) {
					A_SetTics(0);
					return;
				}

				// Transfer from hand to chambers
				handRounds--;
				while (handRounds >= 0) {
					invoker.weaponStatus[WYVS_CHAMBER2 - handRounds] = 2;
					handRounds--;
				}
			}
			TNT1 A 4 A_StartSound("Wyvern/Insert", 8);
			WYVR F 2 Offset(0, 46) A_StartSound("Wyvern/Close", 9);
			WYVR F 1 Offset(0, 42);
			WYVG D 2 Offset(0, 42);
			WYVG D 2;
			Goto Ready;

		ReloadSS:
			WYVG # 0 A_JumpIf(invoker.weaponStatus[SHOTS_SIDESADDLE] >= MaxSideRounds,"Nope");
			WYVG # 1 Offset(1, 34);
			WYVG # 2 Offset(2, 34);
			WYVG # 3 Offset(3, 36);
		ReloadSSRestart:
			WYVG # 6 Offset(3, 35);
			WYVG # 9 Offset(4, 34) A_StartSound("weapons/pocket", 9);
		ReloadSSLoop:
			WYVG # 0
			{
				if (invoker.weaponStatus[SHOTS_SIDESADDLE] == 6) {
					SetWeaponState('ReloadSSEnd');
				}

				int handRounds = min(2, CountInv("HD50OMGAmmo"));
				if (handRounds < 1) {
					SetWeaponState("ReloadSSEnd");
					return;
				}
				handRounds = min(handRounds, max(1, health / 20), MaxSideRounds - invoker.weaponStatus[SHOTS_SIDESADDLE]);
				invoker.weaponStatus[SHOTS_SIDESADDLE] += handRounds;
				A_TakeInventory("HD50OMGAmmo", handRounds, TIF_NOTAKEINFINITE);
			}
		ReloadSSEnd:
			WYVG # 4 Offset(3, 34);
			WYVG # 0
			{
				if (
					invoker.weaponStatus[SHOTS_SIDESADDLE] < MaxSideRounds
				 	&& (PressingReload() || PressingAltReload())
					&& CountInv("HD50OMGAmmo") > 0
				) {
					SetWeaponState("ReloadSSRestart");
				}
			}
			WYVG # 3 Offset(2, 34);
			WYVG # 1 Offset(1, 34);
			Goto Nope;

		UnloadSS:
			WYVG # 2 Offset(2, 34) A_JumpIf(invoker.weaponStatus[SHOTS_SIDESADDLE] < 1, "Nope");
			WYVG # 1 Offset(3, 36);
		UnloadSSLoop:
			WYVG # 4 Offset(4, 36);
			WYVG # 4 Offset(5, 37)
			{
				int handRounds = clamp(invoker.weaponStatus[SHOTS_SIDESADDLE], 0, 2);
				if (handRounds == 0)
				{
					return;
				}
				A_StartSound("weapons/pocket", 9);

				invoker.weaponStatus[SHOTS_SIDESADDLE] -= handRounds;
				int MaxPocket = min(handRounds, HDPickup.MaxGive(self, "HD50OMGAmmo", ENC_50OMG));
				if (MaxPocket > 0 && PressingUnload())
				{
					A_SetTics(16);
					handRounds -= MaxPocket;
					A_GiveInventory("HD50OMGAmmo", MaxPocket);
				}
				else
				{
					while (handRounds > 0)
					{
						if (PressingUnload() && A_JumpIfInventory("HD50OMGAmmo", 0, "Null"))
						{
							handRounds--;
							HDF.Give(self, "HD50OMGAmmo", 1);
							A_SetTics(16);
						}
						else
						{
							handRounds--;
							A_SpawnItemEx("HDLoose50OMG", cos(pitch) * 0.5, 1, height - 7 - sin(pitch) * 1, cos(pitch) * cos(angle) * frandom(1, 2) + vel.x, cos(pitch) * sin(angle) * frandom(1, 2) + vel.y, -sin(pitch) + vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH);
						}
					}
				}
			}
			WYVG # 3 Offset(4, 36)
			{
				if (
					invoker.weaponStatus[SHOTS_SIDESADDLE] > 0
					&& !PressingFire()
					&& !PressingAltfire()
					&& !PressingReload()
				) {
					SetWeaponState("UnloadSSLoop");
				}
			}
			WYVG # 3 Offset(4, 35);
			WYVG # 2 Offset(3, 35);
			WYVG # 1 Offset(2, 34);
			Goto Nope;
		UnloadEnd:
			WYVR B 5;
		UnloadEndQuick:
			WYVR B 2 Offset(0, 46) A_StartSound("Wyvern/Close", 9);
			WYVR B 1 Offset(0, 42);
			WYVG B 2 Offset(0, 42);
			WYVG D 1;
			Goto Nope;
	}
	override void InitializeWepStats(bool idfa)
	{
		weaponStatus[WYVS_CHAMBER1] = 2;
		weaponStatus[WYVS_CHAMBER2] = 2;
		weaponStatus[SHOTS_SIDESADDLE] = MaxSideRounds;
	}
	override void LoadoutConfigure(string input)
	{
		InitializeWepStats();
		if (GetLoadoutVar(input, "auto", 1) > 0) {
			weaponStatus[WYVS_FLAGS] |= WYVF_AUTOLOADER;
		}
	}
}

enum WyvernStatus {
	WYVF_DOUBLE = 1,
	WYVF_FROMPOCKETS = 2,
	WYVF_JUSTUNLOAD = 4,
	WYVF_AUTOLOADER = 8,

	WYVS_CHAMBER1 = 1,
	WYVS_CHAMBER2 = 2,
	// 3 is for SHOTS_SIDESADDLE
	WYVS_FLAGS = 4
};

class WyvernRandom : IdleDummy
{
	States
	{
		Spawn:
			TNT1 A 0 NoDelay
			{
				A_SpawnItemEx("HD50OMGBoxPickup", -3, flags: SXF_NOCHECKPOSITION);
				let wpn = HDWyvern(Spawn("HDWyvern", pos, ALLOW_REPLACE));
				
				if (!wpn) return;

				if (!random(0, 3)) {
					wpn.weaponStatus[WYVS_FLAGS] |= WYVF_AUTOLOADER;
				}
				
				HDF.TransferSpecials(self, wpn);
				wpn.InitializeWepStats(false);
			}Stop;
	}
}