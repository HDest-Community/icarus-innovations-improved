// Struct for itemspawn information.
class IcarusSpawnItem play {
    // ID by string for spawner
    string spawnName;

    // ID by string for spawnees
    Array<IcarusSpawnItemEntry> spawnReplaces;

    // Whether or not to persistently spawn.
    bool isPersistent;

    // Whether or not to replace the original item.
    bool replaceItem;

    string toString() {

        let replacements = "[";

        foreach (spawnReplace : spawnReplaces) replacements = replacements..", "..spawnReplace.toString();

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

        foreach (weaponName : weaponNames) weapons = weapons..", "..weaponName;

        weapons = weapons.."]";

        return String.format("{ ammoName=%s, weaponNames=%s }", ammoName, weapons);
    }
}



// One handler to rule them all.
class IcarusWepsHandler : EventHandler {

    // List of persistent classes to completely ignore.
    // This -should- mean this mod has no performance impact.
    static const string blacklist[] = {
        'HDSmoke',
        'BloodTrail',
        'CheckPuff',
        'WallChunk',
        'HDBulletPuff',
        'HDFireballTail',
        'ReverseImpBallTail',
        'HDSmokeChunk',
        'ShieldSpark',
        'HDFlameRed',
        'HDMasterBlood',
        'PlantBit',
        'HDBulletActor',
        'HDLadderSection'
    };

    // List of CVARs for Backpack Spawns
    array<Class <Inventory> > backpackBlacklist;

    // Cache of Ammo Box Loot Table
    private HDAmBoxList ammoBoxList;

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

            let msg = "Adding "..(persists ? "Persistent" : "Non-Persistent").." Replacement Entry for "..name..": [";

            foreach (replacee : replacees) msg = msg..", "..replacee.toString();

            console.printf(msg.."]");
        }

        // Creates a new struct;
        IcarusSpawnItem spawnee = IcarusSpawnItem(new('IcarusSpawnItem'));

        // Populates the struct with relevant information,
        spawnee.spawnName = name;
        spawnee.isPersistent = persists;
        spawnee.replaceItem = rep;
        spawnee.spawnReplaces.copy(replacees);

        // Pushes the finished struct to the array.
        itemSpawnList.push(spawnee);
    }

    IcarusSpawnItemEntry addItemEntry(string name, int chance) {
        // Creates a new struct;
        IcarusSpawnItemEntry spawnee = IcarusSpawnItemEntry(new('IcarusSpawnItemEntry'));
        spawnee.name = name;
        spawnee.chance = chance;
        return spawnee;
    }

    // appends an entry to ammoSpawnList;
    void addAmmo(string name, Array<string> weapons) {

        if (hd_debug) {
            let msg = "Adding Ammo Association Entry for "..name..": [";

            foreach (weapon : weapons) msg = msg..", "..weapon;

            console.printf(msg.."]");
        }

        // Creates a new struct;
        IcarusSpawnAmmo spawnee = IcarusSpawnAmmo(new('IcarusSpawnAmmo'));
        spawnee.ammoName = name;
        spawnee.weaponNames.copy(weapons);

        // Pushes the finished struct to the array.
        ammoSpawnList.push(spawnee);
    }


    // Populates the replacement and association arrays.
    void init() {

        cvarsAvailable = true;

        //-----------------
        // Backpack Spawns
        //-----------------

        if (!barracuda_allowBackpacks)     backpackBlacklist.push((Class<Inventory>)('HDBarracuda'));
        if (!bitch_allowBackpacks)         backpackBlacklist.push((Class<Inventory>)('HDBitch'));
        if (!fenris_allowBackpacks)        backpackBlacklist.push((Class<Inventory>)('HDFenris'));
        if (!flamenwerfer_allowBackpacks)  backpackBlacklist.push((Class<Inventory>)('HDFlamethrower'));
        if (!frontiersman_allowBackpacks)  backpackBlacklist.push((Class<Inventory>)('HDFrontier'));
        if (!gfb9_allowBackpacks)          backpackBlacklist.push((Class<Inventory>)('HDGFBlaster'));
        if (!mbr_allowBackpacks)           backpackBlacklist.push((Class<Inventory>)('HDMBR'));
        if (!nct_allowBackpacks)           backpackBlacklist.push((Class<Inventory>)('HDNCT'));
        if (!nyx_allowBackpacks)           backpackBlacklist.push((Class<Inventory>)('HDNyx'));
        if (!pd42_allowBackpacks)          backpackBlacklist.push((Class<Inventory>)('HDPDFour'));
        if (!six12_allowBackpacks)         backpackBlacklist.push((Class<Inventory>)('HDSix12'));
        if (!ump45_allowBackpacks)         backpackBlacklist.push((Class<Inventory>)('HDUMP'));
        if (!usp45_allowBackpacks)         backpackBlacklist.push((Class<Inventory>)('HDUSP'));

        if (!gastank_allowBackpacks)       backpackBlacklist.push((Class<Inventory>)('HDGasTank'));
        if (!mbrmagheavy_allowBackpacks)   backpackBlacklist.push((Class<Inventory>)('HDMBRMagHeavy'));
        if (!mbrmaglight_allowBackpacks)   backpackBlacklist.push((Class<Inventory>)('HDMBRMagLight'));
        if (!nyxmag_allowBackpacks)        backpackBlacklist.push((Class<Inventory>)('HDNyxMag'));
        if (!pd42mag_allowBackpacks)       backpackBlacklist.push((Class<Inventory>)('HDPDFourMag'));
        if (!six12shellmag_allowBackpacks) backpackBlacklist.push((Class<Inventory>)('HDSix12MagShells'));
        if (!six12slugmag_allowBackpacks)  backpackBlacklist.push((Class<Inventory>)('HDSix12MagSlugs'));
        if (!ump45mag_allowBackpacks)      backpackBlacklist.push((Class<Inventory>)('HDUMPMag'));
        if (!usp45mag_allowBackpacks)      backpackBlacklist.push((Class<Inventory>)('HDUSPMag'));


        //------------
        // Ammunition
        //------------

        // .355
        Array<string> wep_355;
        wep_355.push('HDNyx');
        addAmmo('HDRevolverAmmo', wep_355);

        // .45 ACP
        Array<string> wep_45acp;
        wep_45acp.push('HDUMP');
        wep_45acp.push('HDUSP');
        addAmmo('HD45ACPAmmo', wep_45acp);

        // .500 S&W Heavy
        Array<string> wep_swheavy;
        wep_swheavy.push('HDMBR');
        addAmmo('HD500SWHeavyAmmo', wep_swheavy);

        // .500 S&W Light
        Array<string> wep_swlight;
        wep_swlight.push('HDMBR');
        addAmmo('HD500SWLightAmmo', wep_swlight);

        // 12 gauge Buckshot Ammo.
        Array<string> wep_12gaShell;
        wep_12gaShell.push('HDBarracuda');
        wep_12gaShell.push('HDSix12');
        addAmmo('HDShellAmmo', wep_12gaShell);

        // 12 gauge Slug Ammo.
        Array<string> wep_12gaSlug;
        wep_12gaSlug.push('HDBarracuda');
        wep_12gaSlug.push('HDPDFour');
        wep_12gaSlug.push('HDSix12');
        addAmmo('HDSlugAmmo', wep_12gaSlug);

        // 4mm
        Array<string> wep_4mm;
        wep_4mm.push('HDBitch');
        wep_4mm.push('HDPDFour');
        addAmmo('FourMilAmmo', wep_4mm);

        // Rocket (Gyro) Grenades.
        Array<string> wep_rocket;
        wep_rocket.push('HDBitch');
        wep_rocket.push('HDMBR');
        addAmmo('HDRocketAmmo', wep_rocket);

        // Gas Tank
        Array<string> wep_gastank;
        wep_gastank.push('HDFlamethrower');
        addAmmo('HDGasTank', wep_gastank);

        // HDBattery.
        Array<string> wep_battery;
        wep_battery.push('HDFenris');
        wep_battery.push('HDNCT');
        addAmmo('HDBattery', wep_battery);

        // 7mm
        Array<string> wep_7mm;
        wep_7mm.push('HDFrontier');
        addAmmo('SevenMilAmmo', wep_7mm);


        //------------
        // Weaponry
        //------------

        // Barracuda
        Array<IcarusSpawnItemEntry> spawns_barracuda;
        spawns_barracuda.push(addItemEntry('HunterRandom', barracuda_hunter_spawn_bias));
        spawns_barracuda.push(addItemEntry('SlayerRandom', barracuda_slayer_spawn_bias));
        addItem('BarracudaRandom', spawns_barracuda, barracuda_persistent_spawning);

        // Bitch LMG
        Array<IcarusSpawnItemEntry> spawns_bitch;
        spawns_bitch.push(addItemEntry('ChaingunReplaces', bitch_chaingun_spawn_bias));
        addItem('BitchRandom', spawns_bitch, bitch_persistent_spawning);

        // Fenris
        Array<IcarusSpawnItemEntry> spawns_fenris;
        spawns_fenris.push(addItemEntry('PlasmaReplaces', fenris_plasma_spawn_bias));
        addItem('FenrisRandom', spawns_fenris, fenris_persistent_spawning);

        // Flamenwerfer77
        Array<IcarusSpawnItemEntry> spawns_flamenwerfer;
        spawns_flamenwerfer.push(addItemEntry('RLReplaces', flamenwerfer_launcher_spawn_bias));
        spawns_flamenwerfer.push(addItemEntry('BFGReplaces', flamenwerfer_bfg_spawn_bias));
        addItem('FlamethrowerSpawner', spawns_flamenwerfer, flamenwerfer_persistent_spawning);

        // Frontiersman
        Array<IcarusSpawnItemEntry> spawns_frontiersman;
        spawns_frontiersman.push(addItemEntry('HunterRandom', frontiersman_hunter_spawn_bias));
        spawns_frontiersman.push(addItemEntry('SlayerRandom', frontiersman_slayer_spawn_bias));
        addItem('FrontierSpawner', spawns_frontiersman, frontiersman_persistent_spawning);

        // GFBlaster
        Array<IcarusSpawnItemEntry> spawns_gfb9;
        spawns_gfb9.push(addItemEntry('PistolReplaces', gfb9_pistol_spawn_bias));
        spawns_gfb9.push(addItemEntry('ClipBoxPickup2', gfb9_clipbox_spawn_bias));
        addItem('GFBlasterRandom', spawns_gfb9, gfb9_persistent_spawning);

        // Modular Battle Rifle
        Array<IcarusSpawnItemEntry> spawns_mbr;
        spawns_mbr.push(addItemEntry('ChaingunReplaces', mbr_chaingun_spawn_bias));
        spawns_mbr.push(addItemEntry('ClipBoxPickup1', mbr_clipbox_spawn_bias));
        addItem('MBRRandom', spawns_mbr, mbr_persistent_spawning);

        // NCT
        Array<IcarusSpawnItemEntry> spawns_nct;
        spawns_nct.push(addItemEntry('ChainsawReplaces', nct_chainsaw_spawn_bias));
        spawns_nct.push(addItemEntry('BFGReplaces', nct_bfg_spawn_bias));
        addItem('NCTRandom', spawns_nct, nct_persistent_spawning);

        // Nyx
        Array<IcarusSpawnItemEntry> spawns_nyx;
        spawns_nyx.push(addItemEntry('PistolReplaces', nyx_pistol_spawn_bias));
        spawns_nyx.push(addItemEntry('HunterRandom', nyx_hunter_spawn_bias));
        spawns_nyx.push(addItemEntry('SlayerRandom', nyx_slayer_spawn_bias));
        spawns_nyx.push(addItemEntry('ClipBoxPickup2', nyx_clipbox_spawn_bias));
        addItem('NyxRandom', spawns_nyx, nyx_persistent_spawning);

        // PD-42
        Array<IcarusSpawnItemEntry> spawns_pd42;
        spawns_pd42.push(addItemEntry('ChaingunReplaces', pd42_chaingun_spawn_bias));
        spawns_pd42.push(addItemEntry('ClipBoxPickup1', pd42_clipbox_spawn_bias));
        addItem('PDFourRandom', spawns_pd42, pd42_persistent_spawning);

        // Six-12
        Array<IcarusSpawnItemEntry> spawns_six12;
        spawns_six12.push(addItemEntry('HunterRandom', six12_hunter_spawn_bias));
        spawns_six12.push(addItemEntry('SlayerRandom', six12_slayer_spawn_bias));
        addItem('Six12Random', spawns_six12, six12_persistent_spawning);

        // UMP
        Array<IcarusSpawnItemEntry> spawns_ump;
        spawns_ump.push(addItemEntry('ChaingunReplaces', ump45_chaingun_spawn_bias));
        spawns_ump.push(addItemEntry('ClipBoxPickup2', ump45_clipbox_spawn_bias));
        addItem('UMPrandom', spawns_ump, ump45_persistent_spawning);

        // USP
        Array<IcarusSpawnItemEntry> spawns_usp;
        spawns_usp.push(addItemEntry('PistolReplaces', usp45_pistol_spawn_bias));
        spawns_usp.push(addItemEntry('ClipBoxPickup2', usp45_clipbox_spawn_bias));
        addItem('USPRandom', spawns_usp, usp45_persistent_spawning);


        //------------
        // Ammunition
        //------------

        // Flamenwerfer Gas Tank
        Array<IcarusSpawnItemEntry> spawns_gastank;
        spawns_gastank.push(addItemEntry('RocketAmmo', gastank_rocket_spawn_bias));
        spawns_gastank.push(addItemEntry('RocketBoxRandom', gastank_rocketbox_spawn_bias));
        spawns_gastank.push(addItemEntry('CellRandom', gastank_battery_spawn_bias));
        addItem('HDGasTank', spawns_gastank, gastank_persistent_spawning);

        // Modular Battle Rifle Heavy Magazine
        Array<IcarusSpawnItemEntry> spawns_mbrmagheavy;
        spawns_mbrmagheavy.push(addItemEntry('ClipMagPickup', mbrmagheavy_clipmag_spawn_bias));
        spawns_mbrmagheavy.push(addItemEntry('RocketAmmo', mbrmagheavy_rocket_spawn_bias));
        addItem('HDMBRMagHeavy', spawns_mbrmagheavy, mbrmagheavy_persistent_spawning);

        // Modular Battle Rifle Light Magazine
        Array<IcarusSpawnItemEntry> spawns_mbrmaglight;
        spawns_mbrmaglight.push(addItemEntry('ClipMagPickup', mbrmaglight_clipmag_spawn_bias));
        spawns_mbrmaglight.push(addItemEntry('ShellRandom', mbrmaglight_shell_spawn_bias));
        addItem('HDMBRMagLight', spawns_mbrmaglight, mbrmaglight_persistent_spawning);

        // Nyx Magazine
        Array<IcarusSpawnItemEntry> spawns_nyxmag;
        spawns_nyxmag.push(addItemEntry('ClipMagPickup', nyxmag_clipmag_spawn_bias));
        addItem('HDNyxMag', spawns_nyxmag, nyxmag_persistent_spawning);

        // PD-42 Magazine
        Array<IcarusSpawnItemEntry> spawns_pd42mag;
        spawns_pd42mag.push(addItemEntry('ClipMagPickup', pd42mag_clipmag_spawn_bias));
        addItem('HDPDFourMag', spawns_pd42mag, pd42mag_persistent_spawning);

        // Six-12 Shell Magazine
        Array<IcarusSpawnItemEntry> spawns_six12shellmag;
        spawns_six12shellmag.push(addItemEntry('ShellRandom', six12shellmag_shell_spawn_bias));
        addItem('HDSix12MagShells', spawns_six12shellmag, six12shellmag_persistent_spawning);

        // Six-12 Slug Magazine
        Array<IcarusSpawnItemEntry> spawns_six12slugmag;
        spawns_six12slugmag.push(addItemEntry('ShellRandom', six12slugmag_shell_spawn_bias));
        addItem('HDSix12MagSlugs', spawns_six12slugmag, six12slugmag_persistent_spawning);

        // UMP Magazine
        Array<IcarusSpawnItemEntry> spawns_umpmag;
        spawns_umpmag.push(addItemEntry('ClipMagPickup', ump45mag_clipmag_spawn_bias));
        addItem('HDUMPMag', spawns_umpmag, ump45mag_persistent_spawning);

        // USP Magazine
        Array<IcarusSpawnItemEntry> spawns_uspmag;
        spawns_uspmag.push(addItemEntry('ClipMagPickup', usp45mag_clipmag_spawn_bias));
        addItem('HDUSPMag', spawns_uspmag, usp45mag_persistent_spawning);


        // --------------------
        // Item Spawns
        // --------------------

        // HEV Armor
        Array<IcarusSpawnItemEntry> spawns_hevarmour;
        spawns_hevarmour.push(addItemEntry('GarrisonArmour', hevarmour_greenarmour_spawn_bias));
        spawns_hevarmour.push(addItemEntry('BattleArmour', hevarmour_bluearmour_spawn_bias));
        addItem('HEVArmour', spawns_hevarmour, hevarmour_persistent_spawning);
    }

    // Random stuff, stores it and forces negative values just to be 0.
    bool giveRandom(int chance) {
        if (chance > -1) {
            let result = random(0, chance);

            if (hd_debug) console.printf("Rolled a "..(result + 1).." out of "..(chance + 1));

            return result == 0;
        }

        return false;
    }

    // Tries to replace the item during spawning.
    bool tryReplaceItem(ReplaceEvent e, string spawnName, int chance) {
        if (giveRandom(chance)) {
            if (hd_debug) console.printf(e.replacee.getClassName().." -> "..spawnName);

            e.replacement = spawnName;

            return true;
        }

        return false;
    }

    // Tries to create the item via random spawning.
    bool tryCreateItem(Actor thing, string spawnName, int chance) {
        if (giveRandom(chance)) {
            if (hd_debug) console.printf(thing.getClassName().." + "..spawnName);

            Actor.Spawn(spawnName, thing.pos);

            return true;
        }

        return false;
    }

    override void worldLoaded(WorldEvent e) {

        // Populates the main arrays if they haven't been already.
        if (!cvarsAvailable) init();

        foreach (bl : backpackBlacklist) {
            if (hd_debug) console.printf("Removing "..bl.getClassName().." from Backpack Spawn Pool");

            BPSpawnPool.removeItem(bl);
        }
    }

    override void checkReplacement(ReplaceEvent e) {

        // Populates the main arrays if they haven't been already.
        if (!cvarsAvailable) init();

        // If there's nothing to replace or if the replacement is final, quit.
        if (!e.replacee || e.isFinal) return;

        // If thing being replaced is blacklisted, quit.
        foreach (bl : blacklist) if (e.replacee is bl) return;

        string candidateName = e.replacee.getClassName();

        // If current map is Range, quit.
        if (level.MapName == 'RANGE') return;

        handleWeaponReplacements(e, candidateName);
    }

    override void worldThingSpawned(WorldEvent e) {

        // Populates the main arrays if they haven't been already.
        if (!cvarsAvailable) init();

        // If thing spawned doesn't exist, quit.
        if (!e.thing) return;

        // If thing spawned is blacklisted, quit.
        foreach (bl : blacklist) if (e.thing is bl) return;

        // Handle Ammo Box Loot Table Filtering
        if (e.thing is 'HDAmBox' && !ammoBoxList) handleAmmoBoxLootTable();

        string candidateName = e.thing.getClassName();

        // Pointers for specific classes.
        let ammo = HDAmmo(e.thing);

        // If the thing spawned is an ammunition, add any and all items that can use this.
        if (ammo) handleAmmoUses(ammo, candidateName);

        // If current map is Range, quit.
        if (level.MapName == 'RANGE') return;

        handleWeaponSpawns(e.thing, ammo, candidateName);
    }

    private void handleAmmoBoxLootTable() {
        ammoBoxList = HDAmBoxList.Get();

        foreach (bl : backpackBlacklist) {
            let index = ammoBoxList.invClasses.find(bl.getClassName());

            if (index != ammoBoxList.invClasses.Size()) {
                if (hd_debug) console.printf("Removing "..bl.getClassName().." from Ammo Box Loot Table");

                ammoBoxList.invClasses.Delete(index);
            }
        }
    }

    private void handleAmmoUses(HDAmmo ammo, string candidateName) {
        foreach (ammoSpawn : ammoSpawnList) if (candidateName ~== ammoSpawn.ammoName) {
            if (hd_debug) {
                console.printf("Adding the following to the list of items that use "..ammo.getClassName().."");
                foreach (weapon : ammoSpawn.weaponNames) console.printf("* "..weapon);
            }

            ammo.itemsThatUseThis.append(ammoSpawn.weaponNames);
        }
    }

    private void handleWeaponReplacements(ReplaceEvent e, string candidateName) {

        // Checks if the level has been loaded more than 1 tic.
        bool prespawn = !(level.maptime > 1);

        // Iterates through the list of item candidates for e.thing.
        foreach (itemSpawn : itemSpawnList) {

            if ((prespawn || itemSpawn.isPersistent) && itemSpawn.replaceItem) {
                foreach (spawnReplace : itemSpawn.spawnReplaces) {
                    if (spawnReplace.name ~== candidateName) {
                        if (hd_debug) console.printf("Attempting to replace "..candidateName.." with "..itemSpawn.spawnName.."...");

                        if (tryReplaceItem(e, itemSpawn.spawnName, spawnReplace.chance)) return;
                    }
                }
            }
        }
    }

    private void handleWeaponSpawns(Actor thing, HDAmmo ammo, string candidateName) {

        // Checks if the level has been loaded more than 1 tic.
        bool prespawn = !(level.maptime > 1);

        // Iterates through the list of item candidates for e.thing.
        foreach (itemSpawn : itemSpawnList) {

            // if an item is owned or is an ammo (doesn't retain owner ptr),
            // do not replace it.
            let item = Inventory(thing);
            if (
                (prespawn || itemSpawn.isPersistent)
             && (!(item && item.owner) && (!ammo || prespawn))
             && !itemSpawn.replaceItem
            ) {
                foreach (spawnReplace : itemSpawn.spawnReplaces) {
                    if (spawnReplace.name ~== candidateName) {
                        if (hd_debug) console.printf("Attempting to spawn "..itemSpawn.spawnName.." with "..candidateName.."...");

                        if (tryCreateItem(thing, itemSpawn.spawnName, spawnReplace.chance)) return;
                    }
                }
            }
        }
    }
}
