Class HEVArmorHandler : EventHandler
{
	Override Void CheckReplacement(ReplaceEvent e)
	{
		if (!e.Replacement)
		{
			return;
		}

		switch (e.Replacement.GetClassName())
		{
			case 'BattleArmour':
				if (random[hevrand]() <= 48)
				{
					e.Replacement = "HEVArmour";
				}
				break;

			case 'GarrisonArmour':
				if (random[hevrand]() <= 48)
				{
					e.Replacement = "HEVArmour";
				}
				break;
		}
	}
}

CONST HDCONST_HEVARMOUR = 107;
CONST ENC_HEVARMOUR = 530;

Class HDHEVArmour : HDArmour
{
	Default
	{
		HDMagAmmo.MaxPerUnit HDCONST_HEVARMOUR;
		HDMagAmmo.MagBulk ENC_HEVARMOUR;
		Tag "HEV Armor";
		Inventory.Icon "HEVAA0";
		Inventory.PickupMessage "Picked up the Hazardous Environment Armor.";
	}

	Override Void AddAMag(int AddAmt)
	{
		if (AddAmt < 0)
		{
			AddAmt = HDCONST_HEVARMOUR;
		}
		Mags.Push(AddAmt);
		Amount = Mags.Size();
	}

	Override Void MaxCheat()
	{
		SyncAmount();
		for (int i = 0; i < Amount; i++)
		{
			Mags[i] = HDCONST_HEVARMOUR;
		}
	}

	action Void A_WearArmour()
	{
		bool HelpText = (!!Player && CVar.GetCvar("hd_HelpText", Player).GetBool());
		Invoker.SyncAmount();
		int dbl = Invoker.Mags[Invoker.Mags.Size() - 1];
		if (!!Player && Player.CMD.Buttons & BT_USE)
		{
			Invoker.Mags.Insert(0, dbl);
			Invoker.Mags.Pop();
			Invoker.SyncAmount();
			return;
		}
		Invoker.WornLayer = STRIP_ARMOUR;
		bool Intervening = !HDPlayerPawn.CheckStrip(Self, Invoker, false);
		Invoker.WornLayer = 0;
		if(Intervening)
		{
			Invoker.WornLayer = STRIP_ARMOUR + 1;
			bool notarmour = !HDPlayerPawn.CheckStrip(Self,Invoker,false);
			Invoker.WornLayer = 0;

			if(notarmour || Invoker.cooldown > 0)
			{
				HDPlayerPawn.CheckStrip(Self, Self);
			}
			else Invoker.cooldown = 10;
			return;
		}

		HDArmour.ArmourChangeEffect(Self, 100);
		A_GiveInventory("HDHEVArmourWorn");
		let worn = HDHEVArmourWorn(FindInventory("HDHEVArmourWorn"));
		if(dbl >= 1000) { dbl -= 1000; }
		worn.Durability = dbl;
		Invoker.Amount--;
		Invoker.Mags.pop();
		if (HelpText)
		{
			string blah = string.Format("You put on the Hazardous Environment Armor. ");
			double qual = double(worn.Durability) / HDCONST_HEVARMOUR;
			if (qual < 0.2) A_Log(blah.."Just don't get hit.", true);
			else if (qual < 0.3) A_Log(blah.."You cover your shameful nakedness with your filthy rags.", true);
			else if (qual < 0.5) A_Log(blah.."It's better than nothing.", true);
			else if (qual < 0.7) A_Log(blah.."This armour has definitely seen better days.", true);
			else if (qual < 0.9) A_Log(blah.."This armour does not pass certification.", true);
			else A_Log(blah, true);
		}

		Invoker.SyncAmount();
	}

	Override Void SyncAmount()
	{
		if (Amount < 1)
		{
			Destroy();
			return;
		}
		Super.SyncAmount();
		Icon = TexMan.CheckForTexture("HEVAA0", TexMan.Type_MiscPatch);
		for (int i = 0; i < Amount; i++)
		{
			Mags[i] = Min(Mags[i], HDCONST_HEVARMOUR);
		}
	}

	Override Void BeginPlay()
	{
		cooldown = 0;
		Mags.push(HDCONST_HEVARMOUR);
		HDMagAmmo.BeginPlay();
	}

	Override double GetBulk()
	{
		SyncAmount();
		double blk = 0;
		for (int i = 0; i < Amount; i++)
		{
			blk += ENC_HEVARMOUR;
		}
		return blk;
	}

	Override bool BeforePockets(actor other)
	{
		if(other.Player && other.Player.CMD.Buttons & BT_USE && !other.findinventory("HDHEVArmourWorn"))
		{
			WornLayer = STRIP_ARMOUR;
			bool Intervening = !HDPlayerPawn.CheckStrip(other, Self, false);
			WornLayer = 0;
			if(Intervening)return false;
			HDArmour.ArmourChangeEffect(other, 110);
			let worn = HDHEVArmourWorn(other.GiveInventoryType("HDHEVArmourWorn"));
			int Durability = Mags[Mags.size() - 1];
			worn.Durability = Durability;
			destroy();
			return true;
		}
		return false;
	}

	Override Void ActualPickup(actor other, bool silent)
	{
		cooldown = 0;
		if(!other)return;
		int Durability = Mags[Mags.size() - 1];
		HDHEVArmour aaa = HDHEVArmour(other.findinventory("HDHEVArmour"));
		if(aaa)
		{
			double totalbulk = (Durability >= 1000) ? 2. : 1.;
			for(int i = 0; i < aaa.Mags.size(); i++)
			{
				totalbulk += (aaa.Mags[i] >= 1000) ? 2. : 1.;
			}
			if(totalbulk * hdmath.getencumbrancemult() > 3.)return;
		}
		if(!trypickup(other))return;
		aaa = HDHEVArmour(other.findinventory("HDHEVArmour"));
		aaa.SyncAmount();
		aaa.Mags.insert(0, Durability);
		aaa.Mags.pop();
		other.A_StartSound(pickupsound ,CHAN_AUTO);
		HDPickup.LogPickupMessage(other, PickupMessage());
	}

	States
	{
		Spawn:
			HEVA A -1;
			stop;
		Use:
			TNT1 A 0 A_WearArmour();
			fail;
	}
}

Class HDHEVArmourWorn : HDArmourWorn
{
	
	Default
	{
		+inventory.isarmor
		inventory.maxAmount 1;
		Tag "HEV Armor";
		HDDamageHandler.priority 0;
		HDPickup.WornLayer STRIP_ARMOUR;
	}
	
	Override Void BeginPlay()
	{
		Super.BeginPlay();
		Durability = HDCONST_HEVARMOUR;
	}
	
	Override Void tick()
	{
		Owner.A_GiveInventory("HDFireDouse", 13);
		Owner.A_TakeInventory("Heat");
		Super.Tick();
	}
	
	Override Void DetachFromOwner()
	{
		Owner.A_TakeInventory("HDFireDouse", 13);
		Super.DetachFromOwner();
	}

	Override double RestrictSpeed(double speedcap)
	{
		return min(speedcap, 2.5);
	}

	Override double GetBulk()
	{
		return ENC_HEVARMOUR * 0.13;
	}

	Override Void DrawHudStuff(hdstatusbar sb, hdPlayerpawn hpl, int hdflags, int gzflags)
	{
		vector2 coords = (hdflags&HDSB_AUTOMAP) ? (4, 86) : (hdflags&HDSB_MUGSHOT) ? ((sb.hudlevel == 1 ? -85 : -55), -4) : (0, -sb.mIndexFont.mFont.GetHeight() * 2);
		sb.drawbar("HEVAA0", "HEVAB0", Durability, HDCONST_HEVARMOUR, coords, -1, sb.SHADER_VERT, gzflags);
		sb.drawstring(sb.pnewsmallfont, sb.FormatNumber(Durability), coords + (10, -7), gzflags | sb.DI_ITEM_CENTER | sb.DI_TEXT_ALIGN_RIGHT, Font.CR_DARKGRAY, scale:(0.5, 0.5));
	}
	
	Override inventory CreateTossable(int amt)
	{
		if(!HDPlayerPawn.CheckStrip(Owner,Self))return null;
		if(Durability < random(1, 3))
		{
			for(int i = 0; i < 10; i++)
			{
				actor aaa = spawn("WallChunk", Owner.pos + (0, 0, Owner.Height - 24),ALLOW_REPLACE);
				vector3 offspos=(frandom(-12, 12), frandom(-12, 12), frandom(-16, 4));
				aaa.SetOrigin(aaa.pos + offspos,false);
				aaa.vel = Owner.vel + offspos * frandom(0.3,0.6);
				aaa.scale *= frandom(0.8, 2.);
			}
			destroy();
			return null;
		}

		let tossed = HDHEVArmour(Owner.spawn("HDHEVArmour", (Owner.pos.x, Owner.pos.y, Owner.pos.z + Owner.Height - 20), ALLOW_REPLACE));
		tossed.Mags.clear();
		tossed.Mags.push(Durability);
		tossed.Amount = 1;
		HDArmour.ArmourChangeEffect(owner,90);
		destroy();
		return tossed;
	}
	
	states
	{
		spawn:
			TNT1 A 0;
			stop;
	}

	Override int, name, int, double, int, int, int HandleDamage(int damage, name mod, int flags, actor Inflictor, actor source, double towound, int toburn, int tostun, int tobreak)
	{
		let Victim=Owner;
		int alv = 2;
		if((flags & DMG_NO_ARMOR) || mod == "staples" || mod == "maxhpdrain" || mod == "internal" || mod == "jointlock" || mod == "falling" || mod == "bleedout" || mod == "invisiblebleedout" || mod == "drowning" || mod == "poison" || !Victim)
		return damage, mod, flags, towound, toburn, tostun, tobreak;
		if(Inflictor && Inflictor.Default.bmissile)
		{
			double ImpactHeight = Inflictor.pos.z + Inflictor.Height * 0.5;
			double ShoulderHeight = Victim.pos.z + Victim.Height - 16;
			double WaistHeight = Victim.pos.z + Victim.Height * 0.4;
			double ImpactAngle = AbsAngle(Victim.Angle, Victim.AngleTo(Inflictor));
			if(ImpactAngle > 90)ImpactAngle = 180 - ImpactAngle;
			bool ShouldHitFlesh = (ImpactHeight > ShoulderHeight || ImpactHeight < WaistHeight || ImpactAngle > 80) ? !random(0, 5) : !random(0, 31);
			if(ShouldHitFlesh)alv = 0;
			else if(ImpactAngle > 80)alv = random(1, alv);
		}

		if(alv < 1)
		return damage, mod, flags, towound, toburn, tostun, tobreak;

		int tobash = 0;
		int armourdamage = 0;
		int resist = 0;
		int originaldamage = damage;
		if(mod == "slime")
		{
			resist += 10 * (alv + 1);
			if(resist > 0)
			{
				damage -= resist;
				toburn = min(originaldamage, resist) >> 1;
			}
			armourdamage = 0;
		}

		else if(mod == "hot" || mod == "cold" || mod =="balefire")
		{
			resist += 10 * (alv + 1);
			if(resist > 0)
			{
				toburn = min(originaldamage, resist) >> 3;
				if(damage > 21)
				{
					int olddamage = damage >> 2;
					damage = olddamage >> 3;
					if(!damage && random(0, olddamage))damage = 1;
					armourdamage = random(0, originaldamage >> 2);
				}
				else damage = 0;
			}
		}
		
		else if(mod =="electrical")
		{
			resist += 10 * (alv + 1);
			if(resist > 0)
			{
				toburn = min(originaldamage, resist) >> 3;
				if(damage > 60)
				{
					int olddamage = damage >> 2;
					damage = olddamage >> 3;
					if(!damage && random(0, olddamage))damage = 1;
					armourdamage = random(0, originaldamage >> 3);
				}
				else damage = 0;
			}
		}
		
		else if(mod =="piercing")
		{
			resist += 25 * (alv + 1);
			if(resist > 0)
			{
				damage -= resist;
				tobash = min(originaldamage, resist) >> 3;
			}
			armourdamage = random(0, originaldamage >> 2);
		
		}
		
		else if(mod =="slashing")
		{
			resist += 100 + 25 * alv;
			if(resist > 0)
			{
				damage -= resist;
				tobash = min(originaldamage, resist) >> 2;
			}
			armourdamage = random(0, originaldamage >> 2);
		}
		
		else if(mod =="teeth" || mod =="claws" || mod =="natural")
		{
			resist += random((alv << 4), 100 + 50 * alv);
			if(resist > 0)
			{
				damage -= resist;
				tobash = min(originaldamage, resist) >> 3;
			}
			armourdamage = random(0, originaldamage >> 3);
		}
		
		else if(mod =="bashing" || mod =="melee")
		{
			armourdamage = clamp((originaldamage >> 3), 0, random(0 ,alv));
			bool headshot = Inflictor && ((Inflictor.Player && Inflictor.pitch < -3.2) || (HDHumanoid(Inflictor) && damage > 50));
			if(!headshot)
			{
				damage = int(damage * (1. - (alv * 0.1)));
			}
		}
		
		else
		{
			resist += 50 * alv;
			if(resist > 0)
			{
				damage -= resist;
				tobash = min(originaldamage, resist) >> random(0, 2);
			}
			armourdamage = random(0, originaldamage >> random(1, 3));
		}

		if(hd_debug)console.printf(Owner.gettag().."  took "..originaldamage.." "..mod.." from "..(source ? source.gettag():"the world")..((Inflictor && Inflictor != source) ? ("'s "..Inflictor.gettag()) : "").."  converted "..tobash.."  final "..damage.."   lost "..armourdamage);
		vector3 puffpos = Victim.pos;
		if(Inflictor && Inflictor != source)puffpos = Inflictor.pos;
		else if(source && source.pos.xy != Victim.pos.xy)puffpos = (Victim.pos.xy + Victim.radius * (source.pos.xy - Victim.pos.xy).unit(), Victim.pos.z + min(Victim.Height, source.Height * 0.6));
		else puffpos = (Victim.pos.xy, Victim.pos.z + Victim.Height * 0.6);
		if(damage < 1 && tobash < 1 && Victim.health > 0 && Victim.Height > Victim.radius * 1.6 && Victim.pos != puffpos)
		{
			Victim.vel += (Victim.pos - puffpos).unit() * 0.01 * originaldamage;
			let hdp = hdPlayerpawn(Victim);
			if(hdp && !hdp.incapacitated)
			{
				hdp.wepbobrecoil2 += (frandom(-5. ,5.), frandom(2.5, 4.)) * 0.01 * originaldamage;
				hdp.playrunning();
			}
			else if(random(0, 255) < Victim.painchance)hdmobbase.forcepain(Victim);
		}

		if(armourdamage > 3)
		{
			actor ppp = spawn("FragPuff", puffpos);
			ppp.vel += Victim.vel;
		}
		
		if(armourdamage > random(0, 2))
		{
			vector3 prnd = (frandom(-1, 1), frandom(-1, 1), frandom(-1, 1));
			actor ppp = spawn("WallChunk", puffpos + prnd);
			ppp.vel += Victim.vel + (puffpos - Owner.pos).unit() * 3 + prnd;
		}

		if(tobash > 0)Victim.damagemobj(Inflictor, source, min(tobash, Victim.health - 1), "bashing", DMG_NO_ARMOR | DMG_THRUSTLESS);
		if(armourdamage > 0)Durability -= armourdamage;
		if(Durability < 1)destroy();
		return damage, mod, flags, towound, toburn ,tostun, tobreak;
	}

	Override double, double OnBulletImpact (HDBulletActor bullet, double pen, double penshell, double hitAngle, double deemedwidth, vector3 hitpos, vector3 vu, bool hitactoristall)
	{
		let hitactor = Owner;
		if(!Owner)return 0, 0;
		let hdp = HDPlayerPawn(hitactor);
		let hdmb = HDMobBase(hitactor);
		if(bullet.pitch > 80 && ((hdp && hdp.incapacitated) || (hdmb && hdmb.frame >= hdmb.downedframe && hdmb.instatesequence(hdmb.curstate, hdmb.resolvestate("falldown")))) && !!bullet.target && abs(bullet.target.pos.z - bullet.pos.z) < bullet.target.Height)
		return pen, penshell;
		double hitHeight = hitactoristall ? ((hitpos.z - hitactor.pos.z) / hitactor.Height) : 0.5;
		double addpenshell = 21;
		int crackseed = int(level.time + Angle) & (1 | 2 | 4 | 8 | 16 | 32);
		if(hitHeight>0.8)
		{
			if((hdmb && !hdmb.bhashelmet))addpenshell = -1;
			else
			{
				if(crackseed > clamp(Durability, 1, 3) && AbsAngle(bullet.Angle, hitactor.Angle) > (180. -5.) && bullet.pitch > -20 && bullet.pitch < 7) addpenshell *= frandom(0.1, 0.9);
				else addpenshell = min(addpenshell, frandom(10, 20));
			}
		}
		
		else if(hitHeight < 0.4)
		{
			if(crackseed > clamp(Durability, 1, 8))
			addpenshell *= frandom(frandom(0, 0.9), 1.);
		}
		
		else if(crackseed > max(Durability, 8))
		{
			addpenshell *= frandom(0.8,1.1);
		}

		int armourdamage = 0;
		if(addpenshell > 0)
		{
			double bad = min(pen, addpenshell) * bullet.stamina * 0.0005;
			armourdamage = random(-1, int(bad));

			if(!armourdamage &&bad &&frandom(0,6) < bad)armourdamage = 1;

			if(armourdamage>0)
			{
				actor p = spawn(armourdamage > 2 ? "FragPuff" : "WallChunk", bullet.pos, ALLOW_REPLACE);
				if(p)p.vel = hitactor.vel - vu * 2 + (frandom(-1,1), frandom(-1,1), frandom(-1,3));
			}
			else if(pen > addpenshell)armourdamage = 1;
		}
		
		else if(addpenshell > -0.5)
		{
			armourdamage += max(random(0,1), (bullet.stamina >> 7));
		}
		
		else if(hd_debug)console.printf("missed the armour!");

		if(hd_debug)console.printf(hitactor.getClassname().."  armour resistance:  "..addpenshell);
		penshell += addpenshell;

		if(pen > 2 && penshell > pen && hitactor.health > 0 && hitactoristall)
		{
			hitactor.vel += vu * 0.001 * hitHeight * mass;
			if(hdp && !hdp.incapacitated)
			{
				hdp.wepbobrecoil2 += (frandom(-5.,5.), frandom(2.5,4.)) * 0.01 * hitHeight * mass;
				hdp.playrunning();
			}
			else if(random(0,255) < hitactor.painchance) hdmobbase.forcepain(hitactor);
		}

		if(armourdamage > 0)Durability -= armourdamage;
		if(Durability < 1)destroy();

		return pen,penshell;
	}
}

Class HEVArmour : HDPickupGiver
{

	Default
	{
		+missilemore
		+hdpickup.fitsinbackpack
		+inventory.isarmor
		inventory.Icon "HEVAA0";
		hdpickupgiver.pickuptogive "HDHEVArmour";
		hdpickup.bulk ENC_HEVARMOUR;
		hdpickup.refid "hva";
		tag "HEV Armor (spare)";
		inventory.PickupMessage "Picked up the Hazardous Environment Armor.";
	}
	
	Override Void configureactualpickup()
	{
		let aaa=HDHEVArmour(actualitem);
		aaa.Mags.clear();
		aaa.Mags.push(HDCONST_HEVARMOUR);
		aaa.SyncAmount();
	}
}

Class HEVArmourWorn : HDPickup
{

	Default
	{
		+missilemore
		-hdpickup.fitsinbackpack
		+inventory.isarmor
		hdpickup.refid "hve";
		tag "HEV Armor";
		inventory.maxAmount 1;
	}

	Override Void postbeginplay()
	{
		Super.postbeginplay();
		if(Owner)
		{
			for(inventory iii=Owner.inv;iii!=null;iii=iii.inv)
			{
				let hdp=hdpickup(iii);
				if(hdp&&hdp.WornLayer==STRIP_ARMOUR)hdp.destroy();
			}
			Owner.A_GiveInventory("HDHEVArmourWorn");
		}
		destroy();
	}
}
