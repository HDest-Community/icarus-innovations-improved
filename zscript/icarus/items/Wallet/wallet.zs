class HDWallet : HDBackpack
{
    default
    {
        HDBackpack.MaxCapacity 1000000;
        tag "$TAG_WALLET";
        Inventory.Icon "WLLTA0";
        Inventory.PickupMessage "$PICKUP_WALLET";
        scale 0.6;
        hdweapon.wornlayer 0;
        hdweapon.refid HDLD_WLT;
        -hdweapon.FITSINBACKPACK;
    }

    override string, double GetPickupSprite() { return "WLLTA0", 1.0; }

    override void BeginPlay()
    {
        super.BeginPlay();
        Storage = new('Wallet_ItemStorage');
        UpdateCapacity();
    }
    
    override double WeaponBulk() { return max((Storage ? Storage.TotalBulk * 0.1 : 0), 30); }

    override bool IsBeingWorn() { return false; }

    override inventory CreateTossable(int amt)
    {
        Storage.UpdateStorage(self, null);
        if(!player || player.ReadyWeapon != self)
        {
            return Super.CreateTossable(amt);
        }
        if(!HDPlayerPawn.CheckStrip(owner,self))
        {
            return null;
        }
        return Super.CreateTossable(amt);
    }
    
    override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
    {
        int BaseOffset = -80;

        sb.DrawString(sb.pSmallFont, Stringtable.Localize("$WALLET_TEXT1"), (0, BaseOffset), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER);
        string BulkString = Stringtable.Localize("$WALLET_TEXT2")..int(Storage.TotalBulk).."\c-";
        sb.DrawString(sb.pSmallFont, BulkString, (0, BaseOffset + 10), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER);

        int ItemCount = Storage.Items.Size();

        if (ItemCount == 0)
        {
            sb.DrawString(sb.pSmallFont, Stringtable.Localize("$WALLET_TEXT3"), (0, BaseOffset + 30), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER, Font.CR_DARKGRAY);
            return;
        }

        StorageItem SelItem = Storage.GetSelectedItem();
        if (!SelItem)
        {
            return;
        }

        for (int i = 0; i < (ItemCount > 1 ? 5 : 1); ++i)
        {
            int RealIndex = (Storage.SelItemIndex + (i - 2)) % ItemCount;
            if (RealIndex < 0)
            {
                RealIndex = ItemCount - abs(RealIndex);
            }

            vector2 Offset = ItemCount > 1 ? (-100, 8) : (0, 0);
            switch (i)
            {
                case 1: Offset = (-50, 4);  break;
                case 2: Offset = (0, 0); break;
                case 3: Offset = (50, 4); break;
                case 4: Offset = (100, 8); break;
            }

            StorageItem CurItem = Storage.Items[RealIndex];
            bool CenterItem = Offset ~== (0, 0);
            sb.DrawImage(CurItem.Icons[0], (Offset.x, BaseOffset + 40 + Offset.y), sb.DI_SCREEN_CENTER | sb.DI_ITEM_CENTER, CenterItem && !CurItem.HaveNone() ? 1.0 : 0.6, CenterItem ? (50, 30) : (30, 20), CenterItem ? (4.0, 4.0) : (3.0, 3.0));
        }

        sb.DrawString(sb.pSmallFont, SelItem.NiceName, (0, BaseOffset + 60), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER, Font.CR_FIRE);

        int AmountInBackpack = SelItem.ItemClass is 'HDMagAmmo' ? SelItem.Amounts.Size() : (SelItem.Amounts.Size() > 0 ? SelItem.Amounts[0] : 0);
        sb.DrawString(sb.pSmallFont, Stringtable.Localize("$WALLET_TEXT4")..sb.FormatNumber(AmountInBackpack, 1, 6), (0, BaseOffset + 70), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER, AmountInBackpack > 0 ? Font.CR_BROWN : Font.CR_DARKBROWN);

        int AmountOnPerson = GetAmountOnPerson(hpl.FindInventory(SelItem.ItemClass));
        sb.DrawString(sb.pSmallFont, Stringtable.Localize("$WALLET_TEXT5")..sb.FormatNumber(AmountOnPerson, 1, 6), (0, BaseOffset + 78), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER, AmountOnPerson > 0 ?  Font.CR_WHITE : Font.CR_DARKGRAY);

    }
    
    override int GetSbarNum()
    {
        name bux = "MercenaryBucks";
        return Storage.GetAmount(bux);
    }

    States
    {
        Spawn:
            WLLT ABC -1 NoDelay
            {
                if (invoker.Storage.TotalBulk ~== 0)
                {
                    frame = 1;
                }
                else if (target)
                {
                    translation = target.translation;
                    frame = 2;
                }
                invoker.bNO_AUTO_SWITCH = false;
            }
            Stop;
        User3:
            #### # 0 A_MagManager("");
            goto Ready;
    }
}

class Wallet_ItemStorage : ItemStorage
{	
    override int CheckConditions(Inventory item, class<Inventory> cls) {
        name bux = "MercenaryBucks";
        bool valid = (
            (item && (item is bux)) ||
            (cls  && (cls  is bux))
        );

        if (!valid) { return IType_Invalid; }
        return super.CheckConditions(item,cls);
    }

    override int GetOperationSpeed(class<Inventory> item, int operation) {
        switch (clamp(operation, 0, 2))
        {
            case 0: return 1; break;	//extract
            case 1: return 1; break;	//pocket
            case 2: return 1; break;	//insert
        }
        return 10;
    }
}


class RandomWallet : IdleDummy
{
    override void postbeginplay()
    {
        super.postbeginplay();
        let SpawnedPouch=HDWallet(spawn("HDWallet",pos,ALLOW_REPLACE));
        SpawnedPouch.vel = vel;
        SpawnedPouch.RandomContents();
        self.destroy();
    }
}