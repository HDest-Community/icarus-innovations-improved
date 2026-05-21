// FIXME: Just use a HDMagAmmo?
class HDWallet : HDStorageItem {

    private transient CVar _bulkCvar;
    private transient double _bulk;


    default {
        +Inventory.INVBAR
        +Weapon.WIMPY_WEAPON
        // -HDWeapon.DROPTRANSLATION
        +HDWeapon.FITSINBACKPACK
        // +HDWeapon.ALWAYSSHOWSTATUS
        +HDWeapon.IGNORELOADOUTAMOUNT

        tag "$TAG_WALLET";
        Inventory.Icon "WLLTA0";
        Inventory.PickupMessage "$PICKUP_WALLET";
		Inventory.PickupSound "weapons/pocket";
        scale 0.6;
        
        // Not worn at all.
        hdweapon.wornlayer 0;
        hdweapon.refid HDLD_WLT;

        HDStorageItem.MinBulk 30;
        HDStorageItem.MaxCapacity 50;
        HDStorageItem.MaxBunch 1000;
    }

    override void Tick() {
        super.Tick();

        // FIXME: this is gross a hell, please fix to not check for a CVAR from Merchant!
        if (!_bulkCvar) _bulkCvar = CVar.getCVar('hdm_moneybulk');

        if (_bulk != _bulkCvar.getFloat()) _bulk = _bulkCvar.getFloat();

        itemBulk = count('MercenaryBucks') * _bulk;
    }
    
    override double WeaponBulk() {
        return ContainerBulk(itemBulk);
    }

	override double ContainerBulk(double it) const {
		return max(minBulk, minBulk * 0.6 + it);
	}

    override bool CanFitInThisContainer(Class<Inventory> itemType) {
        return HDCore.isChildClass(itemType, 'MercenaryBucks');
    }

    override bool ThisCanFitInThisContainer(Inventory item) {
        return HDCore.isChildClass(item.getClass(), 'MercenaryBucks');
    }

    override bool IsBeingWorn() { return false; }

    override void DropOneAmmo(int amt) {
        int i = weaponStatus[SISTAT_SELINDEX];

        if (selectableitems.size() > i) Extract(IndexOf(selectableitems[i]), weaponStatus[SISTAT_HOWMANY]);

        SanitizeSelectionIndex();
    }
    
    // override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
    // {
    //     int BaseOffset = -80;

    //     sb.DrawString(sb.pSmallFont, Stringtable.Localize("$WALLET_TEXT1"), (0, BaseOffset), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER);
    //     string BulkString = Stringtable.Localize("$WALLET_TEXT2")..int(Storage.TotalBulk).."\c-";
    //     sb.DrawString(sb.pSmallFont, BulkString, (0, BaseOffset + 10), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER);

    //     int ItemCount = Storage.Items.Size();

    //     if (ItemCount == 0)
    //     {
    //         sb.DrawString(sb.pSmallFont, Stringtable.Localize("$WALLET_TEXT3"), (0, BaseOffset + 30), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER, Font.CR_DARKGRAY);
    //         return;
    //     }

    //     StorageItem SelItem = Storage.GetSelectedItem();
    //     if (!SelItem)
    //     {
    //         return;
    //     }

    //     for (int i = 0; i < (ItemCount > 1 ? 5 : 1); ++i)
    //     {
    //         int RealIndex = (Storage.SelItemIndex + (i - 2)) % ItemCount;
    //         if (RealIndex < 0)
    //         {
    //             RealIndex = ItemCount - abs(RealIndex);
    //         }

    //         vector2 Offset = ItemCount > 1 ? (-100, 8) : (0, 0);
    //         switch (i)
    //         {
    //             case 1: Offset = (-50, 4);  break;
    //             case 2: Offset = (0, 0); break;
    //             case 3: Offset = (50, 4); break;
    //             case 4: Offset = (100, 8); break;
    //         }

    //         StorageItem CurItem = Storage.Items[RealIndex];
    //         bool CenterItem = Offset ~== (0, 0);
    //         sb.DrawImage(CurItem.Icons[0], (Offset.x, BaseOffset + 40 + Offset.y), sb.DI_SCREEN_CENTER | sb.DI_ITEM_CENTER, CenterItem && !CurItem.HaveNone() ? 1.0 : 0.6, CenterItem ? (50, 30) : (30, 20), CenterItem ? (4.0, 4.0) : (3.0, 3.0));
    //     }

    //     sb.DrawString(sb.pSmallFont, SelItem.NiceName, (0, BaseOffset + 60), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER, Font.CR_FIRE);

    //     int AmountInBackpack = SelItem.ItemClass is 'HDMagAmmo' ? SelItem.Amounts.Size() : (SelItem.Amounts.Size() > 0 ? SelItem.Amounts[0] : 0);
    //     sb.DrawString(sb.pSmallFont, Stringtable.Localize("$WALLET_TEXT4")..sb.FormatNumber(AmountInBackpack, 1, 6), (0, BaseOffset + 70), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER, AmountInBackpack > 0 ? Font.CR_BROWN : Font.CR_DARKBROWN);

    //     int AmountOnPerson = GetAmountOnPerson(hpl.FindInventory(SelItem.ItemClass));
    //     sb.DrawString(sb.pSmallFont, Stringtable.Localize("$WALLET_TEXT5")..sb.FormatNumber(AmountOnPerson, 1, 6), (0, BaseOffset + 78), sb.DI_SCREEN_CENTER | sb.DI_TEXT_ALIGN_CENTER, AmountOnPerson > 0 ?  Font.CR_WHITE : Font.CR_DARKGRAY);

    // }

    states(actor) {
        Spawn:
            WLLT ABC -1 NoDelay {
                if (items.size() < 1) {
                    frame = 1;
                } else if (target) {
                    translation = target.translation;
                    frame = 2;
                }
                bNO_AUTO_SWITCH = false;
            }
            stop;
    }
}

class HDWalletStorageItemList : HDStorageItemList {
    override bool CanAdd(Class<Inventory> itemCls) {
        let valid = HDCore.isChildClass(itemCls, 'MercenaryBucks');
        HDCore.log('IcarusInnovations.Wallet', LOGGING_DEBUG, "Can '"..itemCls.getClassName().."' be added? "..valid);
        return valid;
    }
}

class RandomWallet : IdleDummy {
    override void postBeginPlay() {
        super.postBeginPlay();

        let aaa = HDWallet(spawn("HDWallet", pos, ALLOW_REPLACE));
        aaa.RandomContents('HDWalletStorageItemList', frandom(0.01, 0.5), false);

        HDF.TransferSpecials(self, aaa);

        destroy();
    }
}