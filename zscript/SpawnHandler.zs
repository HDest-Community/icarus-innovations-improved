// Struct for itemspawn information.
class IcarusSpawnItem play {
	// ID by string for spawner
	string spawnname;
	
	// ID by string for spawnees
	Array<IcarusSpawnItemEntry> spawnreplaces;
	
	// Cached size of the above array
	int spawnreplacessize;
	
	// Whether or not to persistently spawn.
	bool isPersistent;
	
	bool replaceitem;
}

class IcarusSpawnItemEntry play {
	string name;
	int    chance;
}

// Struct for passing useinformation to ammunition.
class IcarusSpawnAmmo play
{
	// ID by string for the header ammo.
	string ammoname;
	
	// ID by string for weapons using that ammo.
	Array<string> weaponnames;
	
	// Cached size of the above array
	int weaponnamessize;
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
	array<IcarusSpawnAmmo> ammospawnlist;
	int ammospawnlistsize;

	// List of item-spawn associations.
	// used for item-replacement on mapload.
	array<IcarusSpawnItem> itemspawnlist;
	int itemspawnlistsize;


	// appends an entry to itemspawnlist;
	void additem(string name, Array<IcarusSpawnItemEntry> replacees, bool persists, bool rep=true)
	{
		// Creates a new struct;
		IcarusSpawnItem spawnee = IcarusSpawnItem(new('IcarusSpawnItem'));

		// Populates the struct with relevant information,
		spawnee.spawnname = name;
		spawnee.isPersistent = persists;
		spawnee.replaceitem = rep;

		for(int i = 0; i < replacees.size(); i++) {
			spawnee.spawnreplaces.push(replacees[i]);
			spawnee.spawnreplacessize++;
		}

		// Pushes the finished struct to the array.
		itemspawnlist.push(spawnee);
		itemspawnlistsize++;
	}

	IcarusSpawnItemEntry additementry(string name, int chance)
	{
		// Creates a new struct;
		IcarusSpawnItemEntry spawnee = IcarusSpawnItemEntry(new('IcarusSpawnItemEntry'));
		spawnee.name = name.makelower();
		spawnee.chance = chance;
		return spawnee;
	}


	// appends an entry to ammospawnlist;
	void addammo(string name, Array<string> weapons)
	{

		// Creates a new struct;
		IcarusSpawnAmmo spawnee = IcarusSpawnAmmo(new('IcarusSpawnAmmo'));
		spawnee.ammoname = name.makelower();

		// Populates the struct with relevant information,
		for(int i = 0; i < weapons.size(); i++) {
			spawnee.weaponnames.push(weapons[i].makelower());
			spawnee.weaponnamessize++;
		}

		// Pushes the finished struct to the array.
		ammospawnlist.push(spawnee);
		ammospawnlistsize++;
	}

	bool cvarsAvailable;

	// Populates the replacement and association arrays.
	void init()
	{
		cvarsAvailable = true;

		//------------
		// Ammunition
		//------------

		// .355
		Array<string> wep_355;
		wep_355.push("HDNyx");
		addammo("HDRevolverAmmo", wep_355);

		// .45 ACP
		Array<string> wep_45acp;
		wep_45acp.push("HDUMP");
		wep_45acp.push("HDUSP");
		addammo("HD45ACPAmmo", wep_45acp);

		// .50 AE
		Array<string> wep_50ae;
		wep_50ae.push("HDViper");
		addammo("HD50AEAmmo", wep_50ae);

		// 12 gauge Buckshot Ammo.
		Array<string> wep_12gaShell;
		wep_12gaShell.push("HDBarracuda");
		wep_12gaShell.push("HDSix12");
		addammo("HDShellAmmo", wep_12gaShell);

		// 12 gauge Slug Ammo.
		Array<string> wep_12gaSlug;
		wep_12gaSlug.push("HDBarracuda");
		wep_12gaSlug.push("HDPDFour");
		wep_12gaSlug.push("HDSix12");
		addammo("HDSlugAmmo", wep_12gaSlug);

		// 4mm
		Array<string> wep_4mm;
		wep_4mm.push("HDBitch");
		wep_4mm.push("HDPDFour");
		addammo("FourMilAmmo", wep_4mm);
			
		// Rocket (Gyro) Grenades.
		Array<string> wep_rocket;
		wep_rocket.push("HDBitch");
		addammo('HDRocketAmmo', wep_rocket);

		// Gas Tank
		Array<string> wep_gastank;
		wep_gastank.push("HDFlamethrower");
		addammo("HDGasTank", wep_gastank);
			
		// HDBattery. 
		Array<string> wep_battery;  
		wep_battery.push("HDFenris");
		wep_battery.push("HDHammerhead");
		wep_battery.push("HDNCT");
		addammo('HDBattery', wep_battery);

		// 7mm
		Array<string> wep_7mm;
		wep_7mm.push("HDFrontier");
		addammo("SevenMilAmmo", wep_7mm);

		// 35mm
		Array<string> wep_35mm;
		wep_35mm.push("HDScorpion");
		addammo("BrontornisRound", wep_35mm);

		// .50 OMG
		Array<string> wep_OMG;
		wep_OMG.push("HDWyvern");
		addammo("HD50OMGAmmo", wep_OMG);


		//------------
		// Weaponry
		//------------

		// Barracuda
		Array<IcarusSpawnItemEntry> spawns_barracuda;
		spawns_barracuda.push(additementry("Hunter", barracuda_hunter_spawn_bias));
		spawns_barracuda.push(additementry("Slayer", barracuda_slayer_spawn_bias));
		additem("BarracudaRandom", spawns_barracuda, barracuda_persistent_spawning);

		// Bitch LMG
		Array<IcarusSpawnItemEntry> spawns_bitch;
		spawns_bitch.push(additementry("Vulcanette", bitch_chaingun_spawn_bias));
		additem("BitchRandom", spawns_bitch, bitch_persistent_spawning);

		// Fenris
		Array<IcarusSpawnItemEntry> spawns_fenris;
		spawns_fenris.push(additementry("Thunderbuster", fenris_thunderbuster_spawn_bias));
		additem("FenrisRandom", spawns_fenris, fenris_persistent_spawning);

		// Flamenwerfer77
		Array<IcarusSpawnItemEntry> spawns_flamenwerfer;
		spawns_flamenwerfer.push(additementry("RLReplaces", flamenwerfer_launcher_spawn_bias));
		spawns_flamenwerfer.push(additementry("BFG9K", flamenwerfer_bfg_spawn_bias));
		additem("FlamethrowerSpawner", spawns_flamenwerfer, flamenwerfer_persistent_spawning);

		// Frontiersman
		Array<IcarusSpawnItemEntry> spawns_frontiersman;
		spawns_frontiersman.push(additementry("Hunter", frontiersman_hunter_spawn_bias));
		spawns_frontiersman.push(additementry("Slayer", frontiersman_slayer_spawn_bias));
		// spawns_frontiersman.push(additementry("ClipBoxPickup", frontiersman_clipbox_spawn_bias));
		additem("FrontierSpawner", spawns_frontiersman, frontiersman_persistent_spawning);

		// GFBlaster
		Array<IcarusSpawnItemEntry> spawns_gfb9;
		spawns_gfb9.push(additementry("HDPistol", gfb9_pistol_spawn_bias));
		additem("GFBlasterRandom", spawns_gfb9, gfb9_persistent_spawning);

		// Hammerhead
		Array<IcarusSpawnItemEntry> spawns_hammerhead;
		spawns_hammerhead.push(additementry("Vulcanette", hammerhead_chaingun_spawn_bias));
		additem("HammerheadRandom", spawns_hammerhead, hammerhead_persistent_spawning);

		// NCT
		Array<IcarusSpawnItemEntry> spawns_nct;
		spawns_nct.push(additementry("BFG9K", nct_bfg_spawn_bias));
		additem("NCTRandom", spawns_nct, nct_persistent_spawning);

		// Nyx
		Array<IcarusSpawnItemEntry> spawns_nyx;
		spawns_nyx.push(additementry("HDPistol", nyx_pistol_spawn_bias));
		spawns_nyx.push(additementry("Hunter", nyx_hunter_spawn_bias));
		additem("NyxRandom", spawns_nyx, nyx_persistent_spawning);

		// PD-42
		Array<IcarusSpawnItemEntry> spawns_pd42;
		spawns_pd42.push(additementry("ClipBoxPickup1", pd42_clipbox_spawn_bias));
		additem("PDFourRandom", spawns_pd42, pd42_persistent_spawning);

		// Scorpion
		Array<IcarusSpawnItemEntry> spawns_scorpion;
		spawns_scorpion.push(additementry("BrontornisSpawner", scorpion_bronto_spawn_bias));
		additem("ScorpionSpawner", spawns_scorpion, scorpion_persistent_spawning);

		// Six-12
		Array<IcarusSpawnItemEntry> spawns_six12;
		spawns_six12.push(additementry("Hunter", six12_hunter_spawn_bias));
		spawns_six12.push(additementry("Slayer", six12_slayer_spawn_bias));
		additem("Six12Random", spawns_six12, six12_persistent_spawning);

		// UMP
		Array<IcarusSpawnItemEntry> spawns_ump;
		spawns_ump.push(additementry("ClipBoxPickup1", ump45_clipbox_spawn_bias));
		additem("UMPrandom", spawns_ump, ump45_persistent_spawning);

		// USP
		Array<IcarusSpawnItemEntry> spawns_usp;
		spawns_usp.push(additementry("HDPistol", usp45_pistol_spawn_bias));
		additem("USPRandom", spawns_usp, usp45_persistent_spawning);

		// Viper
		Array<IcarusSpawnItemEntry> spawns_viper;
		spawns_viper.push(additementry("HDPistol", viper_pistol_spawn_bias));
		spawns_viper.push(additementry("Hunter", viper_hunter_spawn_bias));
		additem("ViperRandom", spawns_viper, viper_persistent_spawning);

		// Wyvern
		Array<IcarusSpawnItemEntry> spawns_wyvern;
		spawns_wyvern.push(additementry("Hunter", wyvern_hunter_spawn_bias));
		spawns_wyvern.push(additementry("Slayer", wyvern_slayer_spawn_bias));
		additem("WyvernRandom", spawns_wyvern, wyvern_persistent_spawning);


		//------------
		// Ammunition
		//------------

		// Flamenwerfer Gas Tank
		Array<IcarusSpawnItemEntry> spawns_gastank;
		spawns_gastank.push(additementry("RocketAmmo", gastank_rocket_spawn_bias));
		spawns_gastank.push(additementry("RocketBigPickup", gastank_rocketbox_spawn_bias));
		spawns_gastank.push(additementry("HDBattery", gastank_battery_spawn_bias));
		additem("HDGasTank", spawns_gastank, gastank_persistent_spawning);

		// Nyx Magazine
		Array<IcarusSpawnItemEntry> spawns_nyxmag;
		spawns_nyx.push(additementry("ShellBoxPickup", nyxmag_shellbox_spawn_bias));
		spawns_nyx.push(additementry("HD9mMag15", nyxmag_clipmag_spawn_bias));
		additem("HDNyxMag", spawns_nyxmag, nyxmag_persistent_spawning);

		// PD-42 Magazine
		Array<IcarusSpawnItemEntry> spawns_pd42mag;
		spawns_nyx.push(additementry("HD4mMag", pd42mag_clipmag_spawn_bias));
		additem("HDPDFourMag", spawns_pd42mag, pd42mag_persistent_spawning);

		// Six-12 Shell Magazine
		Array<IcarusSpawnItemEntry> spawns_six12shellmag;
		spawns_nyx.push(additementry("ShellPickup", six12shellmag_shell_spawn_bias));
		additem("HDSix12MagShells", spawns_six12shellmag, six12shellmag_persistent_spawning);

		// Six-12 Slug Magazine
		Array<IcarusSpawnItemEntry> spawns_six12slugmag;
		spawns_nyx.push(additementry("SlugPickup", six12slugmag_slug_spawn_bias));
		additem("HDSix12MagSlugs", spawns_six12slugmag, six12slugmag_persistent_spawning);

		// UMP Magazine
		Array<IcarusSpawnItemEntry> spawns_umpmag;
		spawns_nyx.push(additementry("HD4mMag", ump45mag_clipmag_spawn_bias));
		additem("HDUMPMag", spawns_umpmag, ump45mag_persistent_spawning);

		// USP Magazine
		Array<IcarusSpawnItemEntry> spawns_uspmag;
		spawns_nyx.push(additementry("HD9mMag15", usp45mag_clipmag_spawn_bias));
		additem("HDUSPMag", spawns_uspmag, usp45mag_persistent_spawning);

		// Viper Magazine
		Array<IcarusSpawnItemEntry> spawns_vipermag;
		spawns_nyx.push(additementry("HD9mMag15", vipermag_clipmag_spawn_bias));
		additem("HDViperMag", spawns_vipermag, vipermag_persistent_spawning);
        

		// --------------------
		// Item Spawns
		// --------------------

		// HEV Armor
		Array<IcarusSpawnItemEntry> spawns_hevarmour;
		spawns_hevarmour.push(additementry('HDArmour', hevarmour_spawn_bias));
		additem('HEVArmour', spawns_hevarmour, hevarmour_persistent_spawning);
	}

	// Random stuff, stores it and forces negative values just to be 0.
	bool giverandom(int chance)
	{
		bool result = false;
		int iii = random(0, chance);
		if(iii < 0)
			iii = 0;
		if (iii == 0)
		{
			if(chance > -1)
				result = true;
		}

		return result;
	}

	// Tries to create the item via random spawning.
	bool trycreateitem(worldevent e, IcarusSpawnItem f, int g, bool rep)
	{
		bool result = false;
		if(giverandom(f.spawnreplaces[g].chance))
		{
			if (hd_debug) { console.printf(e.thing.GetClassName().." -> "..f.spawnname); }
			let spawnitem = Actor.Spawn(f.spawnname, e.thing.pos);
			if(spawnitem)
			{
				if(rep)
				{
					e.thing.destroy();
					result = true;
				}
			}

		}
		return result;
	}

	override void worldthingspawned(worldevent e)
	{
		string candidatename;

		// loop controls.
		int i, j;
		bool isAmmo = false;

		// Populates the main arrays if they haven't been already.
		if(!cvarsAvailable)
			init();

		for(i = 0; i < blacklist.size(); i++)
		{
			if (e.thing is blacklist[i])
				return;
		}

		// Checks for null events.
		if(!e.Thing)
		{
			return;
		}

		candidatename  = e.Thing.GetClassName();
		candidatename = candidatename.makelower();

		// Pointers for specific classes.
		let ammo_ptr   = HDAmmo(e.Thing);

		// Whether or not an item can use this.
		if(ammo_ptr)
		{
			// Goes through the entire ammospawn array.
			for(i = 0; i < ammospawnlistsize; i++)
			{
				if(candidatename == ammospawnlist[i].ammoname)
				{
					// Appends each entry in that ammo's subarray.
					for(j = 0; j < ammospawnlist[i].weaponnamessize; j++)
					{
						// Actual pushing to itemsthatusethis().
						if(ammo_ptr)
							ammo_ptr.ItemsThatUseThis.Push(ammospawnlist[i].weaponnames[j]);
					}
				}
			}
		}

		// Return if range before replacing things.
		if(level.MapName ~== "RANGE")
		{
			return;
		}

		// Iterates through the list of item candidates for e.thing.
		for(i = 0; i < itemspawnlistsize; i++)
		{
			// Tries to cast the item as an inventory.
			let thing_inv_ptr = Inventory(e.thing);

			// Checks if the item in question is owned.
			bool owned    = thing_inv_ptr && (thing_inv_ptr.owner);

			// Checks if the level has been loaded more than 1 tic.
			bool prespawn = !(level.maptime > 1);

			// Checks if persistent spawning is on.
			bool persist  = (itemspawnlist[i].isPersistent);

			// if an item is owned or is an ammo (doesn't retain owner ptr),
			// do not replace it.
			if ((prespawn || persist) && (!owned && (!ammo_ptr || prespawn)))
			{
				int original_i = i;
				for(j = 0; j < itemspawnlist[original_i].spawnreplacessize; j++)
				{
					if(itemspawnlist[i].spawnreplaces[j].name == candidatename)
					{
						if(trycreateitem(e, itemspawnlist[i], j, itemspawnlist[i].replaceitem))
						{
							j = itemspawnlist[i].spawnreplacessize;
							i = itemspawnlistsize;
						}
					}
				}
			}
		}
	}
}