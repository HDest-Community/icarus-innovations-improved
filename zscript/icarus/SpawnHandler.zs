// Struct for itemspawn information.
class IcarusSpawnItem play {
	// ID by string for spawner
	string spawnName;
	
	// ID by string for spawnees
	Array<IcarusSpawnItemEntry> spawnReplaces;
	
	// Whether or not to persistently spawn.
	bool isPersistent;
	
	bool replaceItem;

	string toString() {

		let replacements = "[";
		if (spawnReplaces.size()) {
			replacements = replacements..spawnReplaces[0].toString();

			for (let i = 1; i < spawnReplaces.size(); i++) {
				replacements = replacements..", "..spawnReplaces[i].toString();
			}
		}
		replacements = replacements.."]";


		return String.format("{ spawnName=%s, spawnReplaces=%s, isPersistent=%b, replaceItem=%b }", spawnName, replacements, isPersistent, replaceItem);
	}
}

class IcarusSpawnItemEntry play {
	string name;
	int    chance;

	string toString() {
		return String.format("{ name=%s, chance=%s }", name, chance >= 0 ? "1/"..(chance + 1) : "never");
	}
}

// Struct for passing useinformation to ammunition.
class IcarusSpawnAmmo play {
	// ID by string for the header ammo.
	string ammoName;
	
	// ID by string for weapons using that ammo.
	Array<string> weaponNames;
	
	string toString() {

		let weapons = "[";
		if (weaponNames.size()) {
			weapons = weapons..weaponNames[0];

			for (let i = 1; i < weaponNames.size(); i++) {
				weapons = weapons..", "..weaponNames[i];
			}
		}
		weapons = weapons.."]";

		return String.format("{ ammoName=%s, weaponNames=%s }", ammoName, weapons);
	}
}



// One handler to rule them all.
class IcarusWepsHandler : EventHandler {

	// List of persistent classes to completely ignore.
	// This -should- mean this mod has no performance impact.
	static const class<actor> blacklist[] = {
		"HDSmoke",
		"BloodTrail",
		"CheckPuff",
		"WallChunk",
		"HDBulletPuff",
		"HDFireballTail",
		"ReverseImpBallTail",
		"HDSmokeChunk",
		"ShieldSpark",
		"HDFlameRed",
		"HDMasterBlood",
		"PlantBit",
		"HDBulletActor",
		"HDLadderSection"
	};

	// List of weapon-ammo associations.
	// Used for ammo-use association on ammo spawn (happens very often).
	array<IcarusSpawnAmmo> ammoSpawnList;

	// List of item-spawn associations.
	// used for item-replacement on mapload.
	array<IcarusSpawnItem> itemSpawnList;

	bool cvarsAvailable;

	// appends an entry to itemSpawnList;
	void addItem(string name, Array<IcarusSpawnItemEntry> replacees, bool persists, bool rep=true) {

		if (hd_debug) {
			let msg = "Adding "..(persists ? "Persistent" : "Non-Persistent").." Replacement Entry for "..name..": ["..replacees[0].toString();

			if (replacees.size() > 1) {
				for (let i = 1; i < replacees.size(); i++) msg = msg..", "..replacees[i].toString();
			}

			console.printf(msg.."]");
		}

		// Creates a new struct;
		IcarusSpawnItem spawnee = IcarusSpawnItem(new('IcarusSpawnItem'));

		// Populates the struct with relevant information,
		spawnee.spawnName = name;
		spawnee.isPersistent = persists;
		spawnee.replaceItem = rep;

		for (int i = 0; i < replacees.size(); i++) {
			spawnee.spawnReplaces.push(replacees[i]);
		}

		// Pushes the finished struct to the array.
		itemSpawnList.push(spawnee);
	}

	IcarusSpawnItemEntry addItemEntry(string name, int chance) {
		// Creates a new struct;
		IcarusSpawnItemEntry spawnee = IcarusSpawnItemEntry(new('IcarusSpawnItemEntry'));
		spawnee.name = name.makelower();
		spawnee.chance = chance;
		return spawnee;
	}

	// appends an entry to ammoSpawnList;
	void addAmmo(string name, Array<string> weapons) {

		// Creates a new struct;
		IcarusSpawnAmmo spawnee = IcarusSpawnAmmo(new('IcarusSpawnAmmo'));
		spawnee.ammoName = name.makelower();

		// Populates the struct with relevant information,
		for (int i = 0; i < weapons.size(); i++) {
			spawnee.weaponNames.push(weapons[i].makelower());
		}

		// Pushes the finished struct to the array.
		ammoSpawnList.push(spawnee);
	}


	// Populates the replacement and association arrays.
	void init() {
		
		cvarsAvailable = true;

		//------------
		// Ammunition
		//------------

		// .355
		Array<string> wep_355;
		wep_355.push("HDNyx");
		addAmmo("HDRevolverAmmo", wep_355);

		// .45 ACP
		Array<string> wep_45acp;
		wep_45acp.push("HDUMP");
		wep_45acp.push("HDUSP");
		addAmmo("HD45ACPAmmo", wep_45acp);

		// .50 AE
		Array<string> wep_50ae;
		wep_50ae.push("HDViper");
		addAmmo("HD50AEAmmo", wep_50ae);

		// 12 gauge Buckshot Ammo.
		Array<string> wep_12gaShell;
		wep_12gaShell.push("HDBarracuda");
		wep_12gaShell.push("HDSix12");
		addAmmo("HDShellAmmo", wep_12gaShell);

		// 12 gauge Slug Ammo.
		Array<string> wep_12gaSlug;
		wep_12gaSlug.push("HDBarracuda");
		wep_12gaSlug.push("HDPDFour");
		wep_12gaSlug.push("HDSix12");
		addAmmo("HDSlugAmmo", wep_12gaSlug);

		// 4mm
		Array<string> wep_4mm;
		wep_4mm.push("HDBitch");
		wep_4mm.push("HDPDFour");
		addAmmo("FourMilAmmo", wep_4mm);
			
		// Rocket (Gyro) Grenades.
		Array<string> wep_rocket;
		wep_rocket.push("HDBitch");
		addAmmo('HDRocketAmmo', wep_rocket);

		// Gas Tank
		Array<string> wep_gastank;
		wep_gastank.push("HDFlamethrower");
		addAmmo("HDGasTank", wep_gastank);
			
		// HDBattery. 
		Array<string> wep_battery;  
		wep_battery.push("HDFenris");
		wep_battery.push("HDHammerhead");
		wep_battery.push("HDNCT");
		addAmmo('HDBattery', wep_battery);

		// 7mm
		Array<string> wep_7mm;
		wep_7mm.push("HDFrontier");
		addAmmo("SevenMilAmmo", wep_7mm);

		// 35mm
		Array<string> wep_35mm;
		wep_35mm.push("HDScorpion");
		addAmmo("BrontornisRound", wep_35mm);

		// .50 OMG
		Array<string> wep_OMG;
		wep_OMG.push("HDWyvern");
		addAmmo("HD50OMGAmmo", wep_OMG);


		//------------
		// Weaponry
		//------------

		// Barracuda
		Array<IcarusSpawnItemEntry> spawns_barracuda;
		spawns_barracuda.push(addItemEntry("Hunter", barracuda_hunter_spawn_bias));
		spawns_barracuda.push(addItemEntry("Slayer", barracuda_slayer_spawn_bias));
		addItem("BarracudaRandom", spawns_barracuda, barracuda_persistent_spawning);

		// Bitch LMG
		Array<IcarusSpawnItemEntry> spawns_bitch;
		spawns_bitch.push(addItemEntry("Vulcanette", bitch_chaingun_spawn_bias));
		addItem("BitchRandom", spawns_bitch, bitch_persistent_spawning);

		// Fenris
		Array<IcarusSpawnItemEntry> spawns_fenris;
		spawns_fenris.push(addItemEntry("Thunderbuster", fenris_thunderbuster_spawn_bias));
		addItem("FenrisRandom", spawns_fenris, fenris_persistent_spawning);

		// Flamenwerfer77
		Array<IcarusSpawnItemEntry> spawns_flamenwerfer;
		spawns_flamenwerfer.push(addItemEntry("RLReplaces", flamenwerfer_launcher_spawn_bias));
		spawns_flamenwerfer.push(addItemEntry("BFG9K", flamenwerfer_bfg_spawn_bias));
		addItem("FlamethrowerSpawner", spawns_flamenwerfer, flamenwerfer_persistent_spawning);

		// Frontiersman
		Array<IcarusSpawnItemEntry> spawns_frontiersman;
		spawns_frontiersman.push(addItemEntry("Hunter", frontiersman_hunter_spawn_bias));
		spawns_frontiersman.push(addItemEntry("Slayer", frontiersman_slayer_spawn_bias));
		// spawns_frontiersman.push(addItemEntry("HdAmBoxUnarmed", frontiersman_clipbox_spawn_bias));
		// spawns_frontiersman.push(addItemEntry("HdAmBox", frontiersman_clipbox_spawn_bias));
		addItem("FrontierSpawner", spawns_frontiersman, frontiersman_persistent_spawning);

		// GFBlaster
		Array<IcarusSpawnItemEntry> spawns_gfb9;
		spawns_gfb9.push(addItemEntry("HDPistol", gfb9_pistol_spawn_bias));
		addItem("GFBlasterRandom", spawns_gfb9, gfb9_persistent_spawning);

		// Hammerhead
		Array<IcarusSpawnItemEntry> spawns_hammerhead;
		spawns_hammerhead.push(addItemEntry("Vulcanette", hammerhead_chaingun_spawn_bias));
		spawns_hammerhead.push(addItemEntry("Thunderbuster", hammerhead_thunderbuster_spawn_bias));
		addItem("HammerheadRandom", spawns_hammerhead, hammerhead_persistent_spawning);

		// NCT
		Array<IcarusSpawnItemEntry> spawns_nct;
		spawns_nct.push(addItemEntry("BFG9K", nct_bfg_spawn_bias));
		addItem("NCTRandom", spawns_nct, nct_persistent_spawning);

		// Nyx
		Array<IcarusSpawnItemEntry> spawns_nyx;
		spawns_nyx.push(addItemEntry("HDPistol", nyx_pistol_spawn_bias));
		spawns_nyx.push(addItemEntry("Hunter", nyx_hunter_spawn_bias));
		addItem("NyxRandom", spawns_nyx, nyx_persistent_spawning);

		// PD-42
		Array<IcarusSpawnItemEntry> spawns_pd42;
		spawns_pd42.push(addItemEntry("HDAmBoxUnarmed", pd42_clipbox_spawn_bias));
		spawns_pd42.push(addItemEntry("HdAmBox", pd42_clipbox_spawn_bias));
		addItem("PDFourRandom", spawns_pd42, pd42_persistent_spawning);

		// Scorpion
		Array<IcarusSpawnItemEntry> spawns_scorpion;
		spawns_scorpion.push(addItemEntry("Brontornis", scorpion_bronto_spawn_bias));
		addItem("ScorpionSpawner", spawns_scorpion, scorpion_persistent_spawning);

		// Six-12
		Array<IcarusSpawnItemEntry> spawns_six12;
		spawns_six12.push(addItemEntry("Hunter", six12_hunter_spawn_bias));
		spawns_six12.push(addItemEntry("Slayer", six12_slayer_spawn_bias));
		addItem("Six12Random", spawns_six12, six12_persistent_spawning);

		// UMP
		Array<IcarusSpawnItemEntry> spawns_ump;
		spawns_ump.push(addItemEntry("HDAmBoxUnarmed", ump45_clipbox_spawn_bias));
		spawns_ump.push(addItemEntry("HdAmBox", ump45_clipbox_spawn_bias));
		addItem("UMPrandom", spawns_ump, ump45_persistent_spawning);

		// USP
		Array<IcarusSpawnItemEntry> spawns_usp;
		spawns_usp.push(addItemEntry("HDPistol", usp45_pistol_spawn_bias));
		addItem("USPRandom", spawns_usp, usp45_persistent_spawning);

		// Viper
		Array<IcarusSpawnItemEntry> spawns_viper;
		spawns_viper.push(addItemEntry("HDPistol", viper_pistol_spawn_bias));
		spawns_viper.push(addItemEntry("Hunter", viper_hunter_spawn_bias));
		addItem("ViperRandom", spawns_viper, viper_persistent_spawning);

		// Wyvern
		Array<IcarusSpawnItemEntry> spawns_wyvern;
		spawns_wyvern.push(addItemEntry("Hunter", wyvern_hunter_spawn_bias));
		spawns_wyvern.push(addItemEntry("Slayer", wyvern_slayer_spawn_bias));
		addItem("WyvernRandom", spawns_wyvern, wyvern_persistent_spawning);


		//------------
		// Ammunition
		//------------

		// Flamenwerfer Gas Tank
		Array<IcarusSpawnItemEntry> spawns_gastank;
		spawns_gastank.push(addItemEntry("RocketAmmo", gastank_rocket_spawn_bias));
		spawns_gastank.push(addItemEntry("RocketBigPickup", gastank_rocketbox_spawn_bias));
		spawns_gastank.push(addItemEntry("HDBattery", gastank_battery_spawn_bias));
		addItem("HDGasTank", spawns_gastank, gastank_persistent_spawning);

		// Nyx Magazine
		Array<IcarusSpawnItemEntry> spawns_nyxmag;
		spawns_nyxmag.push(addItemEntry("ShellBoxPickup", nyxmag_shellbox_spawn_bias));
		spawns_nyxmag.push(addItemEntry("HD9mMag15", nyxmag_clipmag_spawn_bias));
		addItem("HDNyxMag", spawns_nyxmag, nyxmag_persistent_spawning);

		// PD-42 Magazine
		Array<IcarusSpawnItemEntry> spawns_pd42mag;
		spawns_pd42mag.push(addItemEntry("HD4mMag", pd42mag_clipmag_spawn_bias));
		addItem("HDPDFourMag", spawns_pd42mag, pd42mag_persistent_spawning);

		// Six-12 Shell Magazine
		Array<IcarusSpawnItemEntry> spawns_six12shellmag;
		spawns_six12shellmag.push(addItemEntry("ShellPickup", six12shellmag_shell_spawn_bias));
		addItem("HDSix12MagShells", spawns_six12shellmag, six12shellmag_persistent_spawning);

		// Six-12 Slug Magazine
		Array<IcarusSpawnItemEntry> spawns_six12slugmag;
		spawns_six12slugmag.push(addItemEntry("SlugPickup", six12slugmag_slug_spawn_bias));
		addItem("HDSix12MagSlugs", spawns_six12slugmag, six12slugmag_persistent_spawning);

		// UMP Magazine
		Array<IcarusSpawnItemEntry> spawns_umpmag;
		spawns_umpmag.push(addItemEntry("HD4mMag", ump45mag_clipmag_spawn_bias));
		addItem("HDUMPMag", spawns_umpmag, ump45mag_persistent_spawning);

		// USP Magazine
		Array<IcarusSpawnItemEntry> spawns_uspmag;
		spawns_uspmag.push(addItemEntry("HD9mMag15", usp45mag_clipmag_spawn_bias));
		addItem("HDUSPMag", spawns_uspmag, usp45mag_persistent_spawning);

		// Viper Magazine
		Array<IcarusSpawnItemEntry> spawns_vipermag;
		spawns_vipermag.push(addItemEntry("HD9mMag15", vipermag_clipmag_spawn_bias));
		addItem("HDViperMag", spawns_vipermag, vipermag_persistent_spawning);
        

		// --------------------
		// Item Spawns
		// --------------------

		// HEV Armor
		Array<IcarusSpawnItemEntry> spawns_hevarmour;
		spawns_hevarmour.push(addItemEntry('HDArmour', hevarmour_spawn_bias));
		addItem('HEVArmour', spawns_hevarmour, hevarmour_persistent_spawning);
	}

	// Random stuff, stores it and forces negative values just to be 0.
	bool giveRandom(int chance) {
		if (chance > -1) {
			let result = random(0, chance);

			if (hd_debug) console.printf("Rolled a "..result.." out of "..(chance + 1));

			return result == 0;
		}

		return false;
	}

	// Tries to create the item via random spawning.
	bool tryCreateItem(Actor thing, IcarusSpawnItem f, int g, bool rep) {
		if (giveRandom(f.spawnReplaces[g].chance)) {
            if (Actor.Spawn(f.spawnName, thing.pos) && rep) {
                if (hd_debug) console.printf(thing.GetClassName().." -> "..f.spawnName);

                thing.destroy();

				return true;
			}
		}

		return false;
	}

	override void worldthingspawned(worldevent e) {
		// Populates the main arrays if they haven't been already. 
		if (!cvarsAvailable) init();

		// If thing spawned doesn't exist, quit
		if (!e.Thing) return;

		// If thing spawned is blacklisted, quit
		for (let i = 0; i < blacklist.size(); i++) if (e.thing is blacklist[i]) return;

		string candidateName = e.Thing.GetClassName();
		candidateName = candidateName.makelower();

		// Pointers for specific classes.
		let ammo = HDAmmo(e.Thing);

		// If the thing spawned is an ammunition, add any and all items that can use this.
		if (ammo) handleAmmoUses(ammo, candidateName);

		// Return if range before replacing things.
		if (level.MapName ~== "RANGE") return;

        handleWeaponReplacements(e.Thing, ammo, candidateName);
	}

	private void handleAmmoUses(HDAmmo ammo, string candidateName) {
		// Goes through the entire ammospawn array.
		for (let i = 0; i < ammoSpawnList.size(); i++) {
			if (candidateName == ammoSpawnList[i].ammoName) {
				// Appends each entry in that ammo's subarray.
				for (let j = 0; j < ammoSpawnList[i].weaponNames.size(); j++) {
					// Actual pushing to itemsthatusethis().
					ammo.ItemsThatUseThis.Push(ammoSpawnList[i].weaponNames[j]);
				}
			}
		}
	}

    private void handleWeaponReplacements(Actor thing, HDAmmo ammo, string candidateName) {

		// Checks if the level has been loaded more than 1 tic.
		bool prespawn = !(level.maptime > 1);

		// Iterates through the list of item candidates for e.thing.
		for (let i = 0; i < itemSpawnList.size(); i++) {

			// if an item is owned or is an ammo (doesn't retain owner ptr),
			// do not replace it.
            let item = Inventory(thing);
            if ((prespawn || itemSpawnList[i].isPersistent) && (!(item && item.owner) && (!ammo || prespawn))) {
				for (let j = 0; j < itemSpawnList[i].spawnReplaces.size(); j++) {
					if (itemSpawnList[i].spawnReplaces[j].name == candidateName) {
						if (hd_debug) console.printf("Attempting to replace "..candidateName.." with "..itemSpawnList[i].spawnName.."...");

                        if (tryCreateItem(thing, itemSpawnList[i], j, itemSpawnList[i].replaceItem)) return;
					}
				}
			}
		}
	}
}