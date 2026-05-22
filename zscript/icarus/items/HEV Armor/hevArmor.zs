CONST HDCONST_HEVARMOUR = 107;
CONST ENC_HEVARMOUR = 530;

Class HDHEVArmour : HDArmour {
	default {
		Tag "$TAG_HEVARMOUR";

		Inventory.Icon "HEVAA0";
		Inventory.PickupMessage "$PICKUP_HEVARMOUR";
		
		HDPickup.refid HDLD_HEVARMOURSPARE;

		HDMagAmmo.MaxPerUnit HDCONST_HEVARMOUR;
		HDMagAmmo.MagBulk ENC_HEVARMOUR;
	}

	void WearArmourHelpText(Actor wearer, double durability) {
		if (!HDWeapon.CheckDoHelpText(wearer)) return;

		string opinion = "";
		double qual = durability / maxperunit;
		if (qual < 0.1)       opinion = "$HEVARMOUR_DURABILITY_1";
		else if (qual < 0.3)  opinion = "$HEVARMOUR_DURABILITY_3";
		else if (qual < 0.6)  opinion = "$HEVARMOUR_DURABILITY_6";
		else if (qual < 0.75) opinion = "$HEVARMOUR_DURABILITY_75";
		else if (qual < 0.95) opinion = "$HEVARMOUR_DURABILITY_95";
		wearer.A_Log(
			Stringtable.Localize("$ARMOUR_PUTON")
			..gettag()
			..Stringtable.Localize("$HD_SENTENCEBREAK")
			..Stringtable.Localize(opinion)
		,true);
	}

	States {
		Spawn:
			HEVA A -1;
			stop;
	}
}

Class HDHEVArmourWorn : HDArmourWorn {
	
	default {
		Tag "$TAG_HEVARMOUR";

		HDPickup.bulk ENC_HEVARMOUR * 0.13;
		hdpickup.refId HDLD_HEVARMOUR;
		HDPickup.wornLayer STRIP_ARMOUR;

		HDArmourWorn.armoursprite "HEVAA0";
		HDArmourWorn.armourback "HEVAB0";

		HDArmourWorn.durability HDCONST_HEVARMOUR;
		HDArmourWorn.hindrance 2.5;
		HDArmourWorn.thickness 2;
	}

	Override Void DoEffect() {
		super.DoEffect();

		HDF.Give(owner, "HDFireDouse", 13);
		owner.A_TakeInventory("Heat");
	}

	Override Void DetachFromOwner()
	{
		super.DetachFromOwner();
		owner.A_TakeInventory("HDFireDouse", 13);
	}

	Override int,name,int,double,int,int,int HandleDamage(
		int damage,
		name mod,
		int flags,
		actor inflictor,
		actor source,
		double towound,
		int toburn,
		int tostun,
		int tobreak
	) {
		// TODO: refactor check
		if (
			(flags & DMG_NO_ARMOR)
			|| mod == "staples"
			|| mod == "maxhpdrain"
			|| mod == "internal"
			|| mod == "jointlock"
			|| mod == "falling"
			|| mod == "bleedout"
			|| mod == "invisiblebleedout"
			|| mod == "drowning"
			|| mod == "poison"
		) return damage, mod, flags, towound, toburn, tostun, tobreak;

		return super.HandleDamage(damage, mod, flags, inflictor, source, towound, toburn, tostun, tobreak);
	}

	override int,int,double,int,int,int,int,int HandleDamageType(
		name mod,
		int alv,
		int damage,
		int armourdamage,
		double towound,
		int tobash,
		int toburn,
		int tostun,
		int tobreak,
		int resist
	) {
		switch (mod) {
			case 'slime':
				resist += 10 * (alv + 1);
				if(resist > 0)
				{
					damage -= resist;
					toburn = min(originaldamage, resist) >> 1;
				}
				armourdamage = 0;
				break;
			case 'hot':
			case 'cold':
			case 'balefire':
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
				break;
			case 'electrical':
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
				break;
			case 'piercing':
				resist += 25 * (alv + 1);
				if(resist > 0) {
					damage -= resist;
					tobash = min(originaldamage, resist) >> 3;
				}
				armourdamage = random(0, originaldamage >> 2);
				break;
			default:
				return super.HandleDamageType(mod, alv, damage, armourdamage, towound, tobash, toburn, tostun, tobreak, resist);
		}

		return damage, armourdamage, towound, tobash, toburn, tostun, tobreak, resist;
	}
}
