CONST HDCONST_HEVARMOUR = 107;
CONST ENC_HEVARMOUR = 530;

Class HDHEVArmour : HDArmour {
	default {
		Tag "$TAG_HEVARMOUR";

		Inventory.Icon "HEVAA0";
		Inventory.PickupMessage "$PICKUP_HEVARMOUR";
		
		HDPickup.refid HDLD_HEVARMOUR;

		HDMagAmmo.MaxPerUnit HDCONST_HEVARMOUR;
		HDMagAmmo.MagBulk ENC_HEVARMOUR;
	}

	States {
		Spawn:
			HEVA A -1;
			stop;
	}
}

Class HDHEVArmourWorn : HDArmourWorn {

	default {
		Tag "$TAG_HEVARMOURWORN";

		HDPickup.bulk ENC_HEVARMOUR * 0.13;
		HDPickup.refId HDLD_HEVARMOURWORN;

		HDArmourWorn.armoursprite "HEVAA0";
		HDArmourWorn.armourback "HEVAB0";

		HDArmourWorn.coverage ARMOUR_TORSO|ARMOUR_ARMS|ARMOUR_LEGS;
		HDArmourWorn.durability HDCONST_HEVARMOUR;
		HDArmourWorn.hindrance 2.5;
		HDArmourWorn.thickness 2;
	}

	override void DoEffect() {
		super.DoEffect();

		HDF.Give(owner, "HDFireDouse", 13);
		owner.A_TakeInventory("Heat");
	}

	override void DetachFromOwner() {
		super.DetachFromOwner();

		owner.A_TakeInventory("HDFireDouse", 13);
	}

	override bool isDamageIgnored(name mod, int flags, int durThresh) {
		return (flags&DMG_NO_ARMOR)
				|| mod == 'staples'
				|| mod == 'maxhpdrain'
				|| mod == 'internal'
				|| mod == 'jointlock'
				|| mod == 'falling'
				|| mod == 'bleedout'
				|| mod == 'invisiblebleedout'
				|| mod == 'drowning'
				|| mod == 'poison';
	}

// FIXME: made virtual to stop VM Aborts
	override int,int,double,int,int,int,int,int HandleDamageType(
		name mod,
		int alv,
		actor inflictor,
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
				if (resist > 0) {
					damage -= resist;
					toburn = min(damage, resist) >> 1;
				}
				armourdamage = 0;
				break;
			case 'hot':
			case 'cold':
			case 'balefire':
				resist += 10 * (alv + 1);
				if (resist > 0) {
					toburn = min(damage, resist) >> 3;
					if (damage > 21) {
						int olddamage = damage >> 2;
						damage = olddamage >> 3;
						if (!damage && random(0, olddamage)) damage = 1;
						armourdamage = random(0, damage >> 2);
					} else {
						damage = 0;
					}
				}
				break;
			case 'electrical':
				resist += 10 * (alv + 1);
				if (resist > 0) {
					toburn = min(damage, resist) >> 3;
					if (damage > 60) {
						int olddamage = damage >> 2;
						damage = olddamage >> 3;
						if (!damage && random(0, olddamage))damage = 1;
						armourdamage = random(0, damage >> 3);
					} else {
						damage = 0;
					}
				}
				break;
			case 'piercing':
				resist += 25 * (alv + 1);
				if(resist > 0) {
					damage -= resist;
					tobash = min(damage, resist) >> 3;
				}
				armourdamage = random(0, damage >> 2);
				break;
			default:
				return super.HandleDamageType(mod, alv, inflictor, damage, armourdamage, towound, tobash, toburn, tostun, tobreak, resist);
		}

		return damage, armourdamage, towound, tobash, toburn, tostun, tobreak, resist;
	}
}
