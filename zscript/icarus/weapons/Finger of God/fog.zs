class HDFoG : HDCellWeapon
{
    enum FoGFlags
    {
        FoG_Efficiency = 1,
    }

    enum FoGProperties
    {
        FGProp_Flags,
        FGProp_Battery,
        FGProp_LoadType
    }

    override bool AddSpareWeapon(actor newowner) { return AddSpareWeaponRegular(newowner); }
    override HDWeapon GetSpareWeapon(actor newowner, bool reverse, bool doselect) { return GetSpareWeaponRegular(newowner, reverse, doselect); }
    
    override double GunMass()
    {
        return WeaponStatus[FGProp_Battery] >= 0 ? 14 : 12
        + (WeaponStatus[FGProp_Flags] & FoG_Efficiency ? +2 : 0);
    }
    
    override double WeaponBulk()
    {
        double BaseBulk = 140;
        if (WeaponStatus[FGProp_Flags] & FoG_Efficiency)
        {
            BaseBulk *= 1.25;
        }
        return BaseBulk + (WeaponStatus[FGProp_Battery] >= 0 ? ENC_BATTERY_LOADED : 0);
    }
    
    override string, double GetPickupSprite() { return "FOGPA0", 0.8; }
    override void InitializeWepStats(bool idfa)
    {
        WeaponStatus[FGProp_Battery] = 20;
    }
    
    override void LoadoutConfigure(string input)
    {
        if (GetLoadoutVar(input, "efficiency", 1) > 0)
        {
            WeaponStatus[FGProp_Flags] |= FoG_Efficiency;
        }		
        InitializeWepStats(false);
    }

    override string GetHelpText()
    {
        return WEPHELP_FIRE.."  Shoot\n"
        ..WEPHELP_ALTFIRE.." Abort charge\n"
        ..WEPHELP_RELOAD.."  Reload battery\n"
        ..WEPHELP_UNLOADUNLOAD;
    }

    override string PickupMessage()
    {
        string EffStr = WeaponStatus[FGProp_Flags] & FoG_Efficiency ? "High-Efficiency " : "";
        return String.Format("You got the %sFinger of God. Now go forth and touch some viles!", EffStr);
    }

    override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
    {
        if (sb.HudLevel == 1)
        {
            sb.DrawBattery(-54, -4, sb.DI_SCREEN_CENTER_BOTTOM, reloadorder: true);
            sb.DrawNum(hpl.CountInv("HDBattery"), -46, -8, sb.DI_SCREEN_CENTER_BOTTOM);
        }

        int BatteryCharge = hdw.WeaponStatus[FGProp_Battery];
        if (BatteryCharge > 0)
        {
            sb.DrawWepNum(BatteryCharge, 20, posy: -10);
        }
        else if (BatteryCharge == 0)
        {
            sb.DrawString(sb.mAmountFont, "00000", (-16, -9), sb.DI_TEXT_ALIGN_RIGHT | sb.DI_TRANSLATABLE | sb.DI_SCREEN_CENTER_BOTTOM, Font.CR_DARKGRAY);
        }
    }

    override void DrawSightPicture(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl, bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot)
    {
        int cx, cy, cw, ch;
        [cx, cy, cw, ch] = Screen.GetClipRect();
        sb.SetClipRect(-16 + bob.x, -4 + bob.y, 32, 16, sb.DI_SCREEN_CENTER);
        vector2 bobb = bob * 2;
        bobb.y = clamp(bobb.y, -8, 8);
        sb.DrawImage("FOGFRNT", bobb, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, alpha: 0.9);
        sb.SetClipRect(cx, cy, cw, ch);
        sb.DrawImage("FOGBACK", (0, 4) + bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_CENTER, scale: (0.8, 0.7));
    }

    Default
    {
        -HDWEAPON.FITSINBACKPACK
        Weapon.SelectionOrder 300;
        Weapon.SlotNumber 7;
        Weapon.SlotPriority 1.5;
        HDWeapon.BarrelSize 36, 1.5, 2.5;
        Scale 0.5;
        Tag "Finger of God";
        HDWeapon.Refid "fog";
        
        hdweapon.loadoutcodes "
            \cuefficiency - 0/1, uses only a quarter of battery per shot";
    }

    States
    {
        Spawn:
            FOGP A -1;
            Stop;
        Ready:
            FOGG A 1 A_WeaponReady(WRF_ALL);
            Goto ReadyEnd;
        Select0:
            FOGG A 0;
            Goto Select0Big;
        Deselect0:
            FOGG A 0;
            Goto Deselect0Big;
        User3:
            #### A 0 A_MagManager("HDBattery");
            Goto Ready;
        Fire:
            FOGG A 0
            {
                if (invoker.WeaponStatus[FGProp_Flags] & FoG_Efficiency && invoker.WeaponStatus[FGProp_Battery] >= 5 || invoker.WeaponStatus[FGProp_Battery] >= 10)
                {
                    return ResolveState("Charge");
                }
                
                return ResolveState("Nope");
            }
            Stop;		
        Charge:
            FOGC ############### 3
            {
                if (PressingAltFire())
                {
                    SetWeaponState("Nope");
                    Return;
                }
                A_Light0();
                A_SpawnItemEx("FoGLight");
                player.GetPSprite(PSP_WEAPON).frame = random[godrand](0, 3);
                A_StartSound ("FOG/Charge", CHAN_WEAPON, CHANF_NOSTOP);
                A_WeaponBusy(false);
            }
            Goto Shoot;
        Shoot:
            FOGF A 3 Bright Offset(0, 36);
            FOGF B 3 Bright Offset(0, 44)
            {
                A_Light0();
                A_SpawnItemEx("FoGLight");
                A_StartSound("FOG/Fire", CHAN_WEAPON);
                A_RailAttack(random(0, 0), 0, false, "", "", RGF_NORANDOMPUFFZ | RGF_SILENT, 0, "FoGRayImpact", 0, 0, 12600, 0, 2.0, 0, "FoGRaySmoke", limit: 1.0);
                A_AlertMonsters();
                A_MuzzleClimb(0, 0, -0.2, -0.8, -frandom(0.5, 0.9), -frandom(3.2, 4.0), -frandom(0.5, 0.9), -frandom(3.2, 4.0));
                if (invoker.WeaponStatus[FGProp_Flags] & FoG_Efficiency)
                {
                    invoker.WeaponStatus[FGProp_Battery] -= 5;
                }
                else
                {
                    invoker.WeaponStatus[FGProp_Battery] -= 10;
                }
            }
            FOGF B 3 Offset(0, 38);
            FOGG A 1 Offset(0, 32);
            Goto Nope;
        Reload:
            FOGG A 0
            {
                if (invoker.weaponstatus[FGProp_Battery] > 20 || !CheckInventory("HDBattery", 1))
                {
                    SetWeaponState("Nope");
                    return;
                }
                invoker.WeaponStatus[FGProp_LoadType] = 1;
            }
            Goto Reload1;
        Unload:
            #### A 0
            {
                if (invoker.WeaponStatus[FGProp_Battery] == -1)
                {
                    SetWeaponState("Nope");
                    return;
                }
                invoker.WeaponStatus[FGProp_LoadType] = 0;
            }
            Goto Reload1;
        Reload1:
            #### A 4;
            #### A 2 Offset(0, 36) A_MuzzleClimb(-frandom(1.2, 2.4), frandom(1.2, 2.4));
            #### A 2 Offset(0, 38) A_MuzzleClimb(-frandom(1.2, 2.4), frandom(1.2, 2.4));
            #### A 4 Offset(0, 40)
            {
                A_MuzzleClimb(-frandom(1.2, 2.4), frandom(1.2, 2.4));
            }
            #### A 2 Offset(0, 42)
            {
                A_MuzzleClimb(-frandom(1.2, 2.4), frandom(1.2, 2.4));
                A_StartSound("FOG/BattIn", 8);
                if(invoker.WeaponStatus[FGProp_Battery] >= 0)
                {
                    if (PressingReload() || PressingUnload())
                    {
                        HDMagAmmo.GiveMag(self, "HDBattery", invoker.WeaponStatus[FGProp_Battery]);
                        A_SetTics(10);
                    }
                    else
                    {
                        HDMagAmmo.SpawnMag(self, "HDBattery", invoker.WeaponStatus[FGProp_Battery]);
                        A_SetTics(4);
                    }
                }
                invoker.WeaponStatus[FGProp_Battery] = -1;
            }
            Goto BatteryOut;
        BatteryOut:
            #### A 4 Offset(0, 42)
            {
                if (invoker.WeaponStatus[FGProp_LoadType] == 0)
                {
                    SetWeaponState("Reload3");
                }
                else
                {
                    A_StartSound("weapons/pocket", 9);
                }
            }
            #### A 12;
            #### A 12 Offset(0, 42) A_StartSound("FOG/BattOut", 8);
            #### A 10 Offset(0, 36);
            #### A 0
            {
                let Battery = HDMagAmmo(FindInventory("HDBattery"));
                if (Battery && Battery.Amount > 0)
                {
                    invoker.WeaponStatus[FGProp_Battery] = Battery.TakeMag(true);
                }
                else
                {
                    SetWeaponState("Reload3");
                    return;
                }
            }
        Reload3:
            #### A 6 Offset(0, 38);
            #### A 8 Offset(0, 37);
            #### A 2 Offset(0, 38);
            #### A 2 Offset(0, 36);
            #### A 2 Offset(0, 34);
            #### A 12;
            Goto Ready;
        Reload4:
            #### A 6;
            Goto Nope;
    }
}

class FoGRandom : IdleDummy
{
    States
    {
        Spawn:
            TNT1 A 0 nodelay
            {
                let wpn = HDFoG(Spawn("HDFoG", pos, ALLOW_REPLACE));
                if (!wpn)
                {
                    return;
                }

                HDF.TransferSpecials(self, wpn);
                
                if (!random(0, 3))
                {
                    wpn.WeaponStatus[wpn.FGProp_Flags] |= wpn.FoG_Efficiency;
                }
                wpn.InitializeWepStats(false);
            }
            Stop;
    }
}

class FoGRayImpact : Actor
{
    Default
    {
        +FORCEDECAL
        +PUFFGETSOWNER
        +ALWAYSPUFF
        +HITTRACER
        +PUFFONACTORS
        +PUFFGETSOWNER
        +NOINTERACTION
        +BLOODLESSIMPACT
        +FORCERADIUSDMG
        +NOBLOOD
        Decal "BigScorch";
    }
    
    override void PostBeginPlay()
    {
        let Necro = Necromancer(tracer);
        if (Necro && !Necro.bFRIENDLY)
        {
            Necro.DamageMobj(self, target, 6000, 'Holy', DMG_FORCED);
        }

        Super.PostBeginPlay();
    }

    States
    {
        Spawn:
            TNT1 A 16 NoDelay
            {
                A_StartSound("FOG/Hit", attenuation: 0.5);
                DistantQuaker.Quake(self, 2, 50, 16384, 10, 256, 512, 128);

                // Horizontal ring.
                for (int i = -180; i < 180; i += 4)
                {
                    A_SpawnParticle(0xBB44FF, SPF_FULLBRIGHT | SPF_RELATIVE, 10, 32, i, 0, 0, 0, 12, 0, 0);
                }
                
                // Ball.
                for (int i = -180; i < 180; i += 10)
                {
                    for (int j = -90 + 9; j < 90 - 9; j += 10)
                    {
                        A_SpawnParticle(0x8666FF, SPF_FULLBRIGHT | SPF_RELATIVE, 15, 24, i, 0, 0, 0, 4 * cos(j) * 1.2, 0, 4 * sin(j));
                    }
                }

                // Spears.
                for (int i = 0; i < 10; ++i)
                {
                    double pitch = frandom(-85.0, 85.0);
                    A_SpawnItemEx("FoGRayImpactSpear", 0, 0, 0, random(25, 25) * cos(pitch), 0, random(20, 25) * sin(pitch), random(0, 360));
                }
            }
            Stop;
    }
}

class FoGRaySmoke : Actor
{
    override void PostBeginPlay()
    {
        if (!random(0, 2))
        {
            A_SpawnItemEx("FoGRaySmokeParticle");
        }

        A_SetRoll(random(0, 360));

        Super.PostBeginPlay();
    }

    Default
    {
        StencilColor "BB44FF";
        RenderStyle "Stencil";
        +NOINTERACTION
        +ROLLSPRITE
        Alpha 2.0;
        Scale 0.005;
    }

    States
    {
        Spawn:
            FGSM K 1 Bright
            {
                A_FadeOut(0.035);
                A_SetScale(Scale.X + 0.0001);
                A_ChangeVelocity(frandom(-0.005, 0.005), frandom(-0.005, 0.005), frandom(-0.005, 0.005), CVF_RELATIVE);
            }
            Loop;
    }
}

class FoGRaySmokeParticle : Actor
{
    override void PostBeginPlay()
    {
        Lifetime = DefaultLifeTime = random(50, 80);
        ParticleSize = frandom(2.0, 4.0);

        Super.PostBeginPlay();
    }

    Default
    {
        +NOINTERACTION
    }

    double Lifetime;
    double DefaultLifeTime;
    double ParticleSize;

    States
    {
        Spawn:
            TNT1 A 1
            {
                A_SpawnParticle("BB44FF", SPF_RELATIVE | SPF_FULLBRIGHT, 1, ParticleSize, startalphaf: Lifetime / DefaultLifeTime);
                A_ChangeVelocity(frandom(-0.15, 0.15), frandom(-0.15, 0.15), frandom(-0.15, 0.15), CVF_RELATIVE);
                if (Lifetime-- < 0) Destroy();
            }
            Loop;
    }
}

class FoGRayImpactSpear : Actor
{
    override void PostBeginPlay()
    {
        ReactionTime = int(ReactionTime * frandom(0.10, 0.5));

        Super.PostBeginPlay();
    }

    Default
    {
        +NOINTERACTION
        Gravity 0.6;
        ReactionTime 35;
    }

    States
    {
        Spawn:
            TNT1 A 1
            {
                if (!level.IsPointInLevel(pos)) Destroy();

                vel *= 0.95;
                vel.z -= 1.0 * Gravity;

                A_SpawnItemEx("FoGRaySpearSmoke");
                A_CountDown();
            }
            Loop;
    }
}

class FoGRaySpearSmoke : Actor
{
    override void PostBeginPlay()
    {
        A_SetRoll(random(0, 360));

        Super.PostBeginPlay();
    }

    override void Tick()
    {
        vel *= 0.88;

        Super.Tick();
    }

    Default
    {
        Scale 0.02;
        RenderStyle "Shaded";
        StencilColor "BB44FF";
        +BRIGHT
        +NOINTERACTION
        +ROLLSPRITE
        +FORCEXYBILLBOARD
    }

    States
    {
        Spawn:
            FGSM K 1
            {
                A_FadeOut(0.03);
                A_SetScale(Scale.X + 0.003);
            }
            Loop;
    }
}

class FoGLight : PointLight
{
    override void PostBeginPlay()
    {
        Super.PostBeginPlay();
        args[0] = 187;
        args[1] = 68;
        args[2] = 255;
        args[3] = 64;
    }

    override void Tick()
    {
        if (--ReactionTime <= 0)
        {
            Destroy();
            return;
        }

        Args[3] = random(50, 72);
    }

    Default
    {
        ReactionTime 20;
    }
}