/*==============================================================================


	Southclaws' Scavenge and Survive

		Copyright (C) 2017 Barnaby "Southclaws" Keene

		This program is free software: you can redistribute it and/or modify it
		under the terms of the GNU General Public License as published by the
		Free Software Foundation, either version 3 of the License, or (at your
		option) any later version.

		This program is distributed in the hope that it will be useful, but
		WITHOUT ANY WARRANTY; without even the implied warranty of
		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
		See the GNU General Public License for more details.

		You should have received a copy of the GNU General Public License along
		with this program.  If not, see <http://www.gnu.org/licenses/>.


==============================================================================*/


#include <YSI\y_hooks>


#define MAX_BBQ				(256)

#define COOKER_STATE_NONE	(0)
#define COOKER_STATE_COOK	(1)


// Struct for item data
enum //E_BBQ_DATA
{
			bbq_state,
			bbq_fuel,
			bbq_grillItem1,
			bbq_grillItem2, 
			bbq_grillPart1,
			bbq_grillPart2,
Timer:		bbq_cookTimer
}


static
			bbq_PlaceFoodTick[MAX_PLAYERS],
			bbq_ItemBBQ[ITM_MAX] = {-1, ...};


hook OnItemTypeDefined(uname[])
{
	if(!strcmp(uname, "Barbecue"))
		SetItemTypeMaxArrayData(GetItemTypeFromUniqueName("Barbecue"), 7);
}

hook OnItemCreate(itemid)
{
	dbg("global", CORE, "[OnItemCreate] in /gamemodes/sss/core/world/barbecue.pwn");

	dbg("gamemodes/sss/core/world/barbecue.pwn", 1, "[OnItemCreate] itemid: %d type: %d", itemid, _:GetItemType(itemid));
	if(GetItemType(itemid) == item_Barbecue)
	{
		dbg("gamemodes/sss/core/world/barbecue.pwn", 1, "[OnItemCreate] BBQ item %d created", itemid);

		new data[7];

		if(GetItemLootIndex(itemid) != -1)
		{
			data[bbq_fuel] = random(10);
		}

		data[bbq_state] = COOKER_STATE_NONE;
		data[bbq_grillItem1] = INVALID_ITEM_ID;
		data[bbq_grillItem2] = INVALID_ITEM_ID;
		data[bbq_grillPart1] = INVALID_ITEM_ID;
		data[bbq_grillPart2] = INVALID_ITEM_ID;
		data[bbq_cookTimer] = Timer:0;

		dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "SET %d data[bbq_state]: %d", itemid, data[bbq_state]);
		dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "SET %d data[bbq_fuel]: %d", itemid, data[bbq_fuel]);
		dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "SET %d data[bbq_grillItem1]: %d", itemid, data[bbq_grillItem1]);
		dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "SET %d data[bbq_grillItem2]: %d", itemid, data[bbq_grillItem2]);
		dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "SET %d data[bbq_grillPart1]: %d", itemid, data[bbq_grillPart1]);
		dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "SET %d data[bbq_grillPart2]: %d", itemid, data[bbq_grillPart2]);
		dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "SET %d data[bbq_cookTimer]: %d", itemid, data[bbq_cookTimer]);

		SetItemArrayData(itemid, data, 7);
	}
}

hook OnPlayerUseItemWithItem(playerid, itemid, withitemid)
{
	dbg("global", CORE, "[OnPlayerUseItemWithItem] in /gamemodes/sss/core/world/barbecue.pwn");

	dbg("gamemodes/sss/core/world/barbecue.pwn", 1, "[OnPlayerUseItemWithItem HOOK] %d %d %d", playerid, itemid, withitemid);

	if(GetItemType(withitemid) == item_Barbecue)
	{
		if(_UseBbqHandler(playerid, itemid, withitemid))
			return 1;
	}

	dbg("gamemodes/sss/core/world/barbecue.pwn", 2, "[OnPlayerUseItemWithItem END] %d %d %d", playerid, itemid, withitemid);

	return Y_HOOKS_CONTINUE_RETURN_0;
}

_UseBbqHandler(playerid, itemid, withitemid)
{
	dbg("gamemodes/sss/core/world/barbecue.pwn", 1, "[_UseBbqHandler] %d %d %d", playerid, itemid, withitemid);

	new data[7];

	GetItemArrayData(withitemid, data);

	dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "GET %d data[bbq_state]: %d", itemid, data[bbq_state]);
	dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "GET %d data[bbq_fuel]: %d", itemid, data[bbq_fuel]);
	dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "GET %d data[bbq_grillItem1]: %d", itemid, data[bbq_grillItem1]);
	dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "GET %d data[bbq_grillItem2]: %d", itemid, data[bbq_grillItem2]);
	dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "GET %d data[bbq_grillPart1]: %d", itemid, data[bbq_grillPart1]);
	dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "GET %d data[bbq_grillPart2]: %d", itemid, data[bbq_grillPart2]);
	dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "GET %d data[bbq_cookTimer]: %d", itemid, data[bbq_cookTimer]);

	new ItemType:itemtype = GetItemType(itemid);

	if(GetItemTypeLiquidContainerType(itemtype) != -1)
	{
		dbg("gamemodes/sss/core/world/barbecue.pwn", 2, "[_UseBbqHandler] Item type is gas can", playerid, itemid, withitemid);

		if(GetLiquidItemLiquidType(itemid) != liquid_Petrol)
		{
			ShowActionText(playerid, ls(playerid, "FUELNOTPETR", true), 3000);
			return 1;
		}

		new 
			Float:canfuel = GetLiquidItemLiquidAmount(itemid),
			Float:transfer;

		if(canfuel > 0.0)
		{
			transfer = (canfuel - 0.6 < 0.0) ? canfuel : 0.6;
			SetLiquidItemLiquidAmount(itemid, canfuel - transfer);
			SetItemArrayDataAtCell(withitemid, data[bbq_fuel] + 10, bbq_fuel);
			ShowActionText(playerid, ls(playerid, "BBQADDPETRO", true), 3000);
		}
		else
		{
			ShowActionText(playerid, ls(playerid, "PETROLEMPTY", true), 3000);
		}

		return 1;
	}

	if(IsItemTypeFood(itemtype))
	{
		dbg("gamemodes/sss/core/world/barbecue.pwn", 2, "[_UseBbqHandler] Item type %d is food", _:itemtype);

		if(GetItemExtraData(itemid) != 0)
		{
			ShowActionText(playerid, ls(playerid, "BBQALREADYC", true), 3000);
			return 1;
		}

		new
			Float:x,
			Float:y,
			Float:z,
			Float:r;

		GetItemPos(withitemid, x, y, z);
		GetItemRot(withitemid, r, r, r);

		if(data[bbq_grillItem1] <= 0)// == INVALID_ITEM_ID) temp fix
		{
			dbg("gamemodes/sss/core/world/barbecue.pwn", 2, "[_UseBbqHandler] Adding food to grill slot 1");

			CreateItemInWorld(itemid,
				x + (0.25 * floatsin(-r + 90.0, degrees)),
				y + (0.25 * floatcos(-r + 90.0, degrees)),
				z + 0.818,
				.rz = r);

			bbq_ItemBBQ[itemid] = withitemid;
			SetItemArrayDataAtCell(withitemid, itemid, bbq_grillItem1);
			bbq_PlaceFoodTick[playerid] = GetTickCount();
			ShowActionText(playerid, ls(playerid, "BBQFOODADDE", true), 3000);

			return 1;
		}
		else if(data[bbq_grillItem2] <= 0)// == INVALID_ITEM_ID) temp fix
		{
			dbg("gamemodes/sss/core/world/barbecue.pwn", 2, "[_UseBbqHandler] Adding food to grill slot 2");

			CreateItemInWorld(itemid,
				x + (0.25 * floatsin(-r - 90.0, degrees)),
				y + (0.25 * floatcos(-r - 90.0, degrees)),
				z + 0.818,
				.rz = r);

			bbq_ItemBBQ[itemid] = withitemid;
			SetItemArrayDataAtCell(withitemid, itemid, bbq_grillItem2);
			bbq_PlaceFoodTick[playerid] = GetTickCount();
			ShowActionText(playerid, ls(playerid, "BBQFOODADDE", true), 3000);

			return 1;
		}
	}

	if(itemtype == item_FireLighter)
	{
		dbg("gamemodes/sss/core/world/barbecue.pwn", 2, "[_UseBbqHandler] Item type is lighter");

		if(data[bbq_fuel] <= 0)
		{
			dbg("gamemodes/sss/core/world/barbecue.pwn", 2, "[_UseBbqHandler] Fuel empty");
			ShowActionText(playerid, ls(playerid, "BBQFUELEMPT", true), 3000);
			return 1;
		}

		new Timer:timerid = defer bbq_FinishCooking(withitemid);

		SetItemArrayDataAtCell(withitemid, _:timerid, bbq_cookTimer);
		SetItemArrayDataAtCell(withitemid, COOKER_STATE_COOK, bbq_state);

		_LightBBQ(withitemid);

		ShowActionText(playerid, ls(playerid, "BBQLITSTART", true), 3000);

		return 1;
	}

	return 0;
}

_LightBBQ(itemid)
{
	dbg("gamemodes/sss/core/world/barbecue.pwn", 1, "[_LightBBQ] Lighting BBQ item %d", itemid);

	new
		Float:x,
		Float:y,
		Float:z,
		Float:r;

	GetItemPos(itemid, x, y, z);
	GetItemRot(itemid, r, r, r);

	SetItemArrayDataAtCell(itemid, CreateDynamicObject(18701,
		x + (0.25 * floatsin(-r + 90.0, degrees)),
		y + (0.25 * floatcos(-r + 90.0, degrees)),
		z - 0.6,
		0.0, 0.0, r), bbq_grillPart1);

	SetItemArrayDataAtCell(itemid, CreateDynamicObject(18701,
		x + (0.25 * floatsin(-r + 270.0, degrees)),
		y + (0.25 * floatcos(-r + 270.0, degrees)),
		z - 0.6,
		0.0, 0.0, r), bbq_grillPart2);

	return 1;
}

timer bbq_FinishCooking[30000](itemid)
{
	dbg("gamemodes/sss/core/world/barbecue.pwn", 1, "[bbq_FinishCooking] itemid: %d", itemid);

	new data[7];

	GetItemArrayData(itemid, data);

	DestroyDynamicObject(data[bbq_grillPart1]);
	DestroyDynamicObject(data[bbq_grillPart2]);

	SetItemExtraData(data[bbq_grillItem1], 1);
	SetItemExtraData(data[bbq_grillItem2], 1);

	SetItemArrayDataAtCell(itemid, data[bbq_fuel] - 1, bbq_fuel);
	SetItemArrayDataAtCell(itemid, COOKER_STATE_NONE, bbq_state);
}


hook OnPlayerPickUpItem(playerid, itemid)
{
	dbg("global", CORE, "[OnPlayerPickUpItem] in /gamemodes/sss/core/world/barbecue.pwn");

	dbg("gamemodes/sss/core/world/barbecue.pwn", 1, "[OnPlayerPickUpItem] playerid: %d itemid: %d", playerid, itemid);
	if(GetItemType(itemid) == item_Barbecue)
	{
		dbg("gamemodes/sss/core/world/barbecue.pwn", 1, "[OnPlayerPickUpItem] Item type is BBQ", playerid, itemid);
		if(GetTickCountDifference(GetTickCount(), bbq_PlaceFoodTick[playerid]) < 1000)
			return Y_HOOKS_BREAK_RETURN_1;

		new data[7];

		GetItemArrayData(itemid, data);

		dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "GET %d data[bbq_state]: %d", itemid, data[bbq_state]);
		dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "GET %d data[bbq_fuel]: %d", itemid, data[bbq_fuel]);
		dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "GET %d data[bbq_grillItem1]: %d", itemid, data[bbq_grillItem1]);
		dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "GET %d data[bbq_grillItem2]: %d", itemid, data[bbq_grillItem2]);
		dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "GET %d data[bbq_grillPart1]: %d", itemid, data[bbq_grillPart1]);
		dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "GET %d data[bbq_grillPart2]: %d", itemid, data[bbq_grillPart2]);
		dbg("gamemodes/sss/core/world/barbecue.pwn", 3, "GET %d data[bbq_cookTimer]: %d", itemid, data[bbq_cookTimer]);

		if(data[bbq_state] != COOKER_STATE_NONE)
			return Y_HOOKS_BREAK_RETURN_1;

		if(IsValidItem(data[bbq_grillItem1]) && data[bbq_grillItem1] > 0) // temp fix
		{
			dbg("gamemodes/sss/core/world/barbecue.pwn", 2, "[OnPlayerPickUpItem] BBQ has valid item in slot 1 (%d)", data[bbq_grillItem1]);
			GiveWorldItemToPlayer(playerid, data[bbq_grillItem1], 1);
			SetItemArrayDataAtCell(itemid, INVALID_ITEM_ID, bbq_grillItem1);
			return Y_HOOKS_BREAK_RETURN_1;
		}

		if(IsValidItem(data[bbq_grillItem2]) && data[bbq_grillItem2] > 0) // temp fix
		{
			dbg("gamemodes/sss/core/world/barbecue.pwn", 2, "[OnPlayerPickUpItem] BBQ has valid item in slot 2 (%d)", data[bbq_grillItem2]);
			GiveWorldItemToPlayer(playerid, data[bbq_grillItem2], 1);
			SetItemArrayDataAtCell(itemid, INVALID_ITEM_ID, bbq_grillItem2);
			return Y_HOOKS_BREAK_RETURN_1;
		}
	}

	if(bbq_ItemBBQ[itemid] != -1)
	{
		dbg("gamemodes/sss/core/world/barbecue.pwn", 1, "[OnPlayerPickUpItem] Item %d is from BBQ item %d", itemid, bbq_ItemBBQ[itemid]);

		if(GetItemArrayDataAtCell(bbq_ItemBBQ[itemid], bbq_grillItem1) == itemid)
		{
			dbg("gamemodes/sss/core/world/barbecue.pwn", 2, "[OnPlayerPickUpItem] Item removed from bbq slot 1");
			SetItemArrayDataAtCell(bbq_ItemBBQ[itemid], INVALID_ITEM_ID, bbq_grillItem1);
		}

		else if(GetItemArrayDataAtCell(bbq_ItemBBQ[itemid], bbq_grillItem2) == itemid)
		{
			dbg("gamemodes/sss/core/world/barbecue.pwn", 2, "[OnPlayerPickUpItem] Item removed from bbq slot 2");
			SetItemArrayDataAtCell(bbq_ItemBBQ[itemid], INVALID_ITEM_ID, bbq_grillItem2);
		}
	}

	return Y_HOOKS_CONTINUE_RETURN_0;
}
