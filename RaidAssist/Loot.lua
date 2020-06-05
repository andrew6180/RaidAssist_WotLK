local RA = RaidAssist
local _

if (_G.RaidAssistLoadDeny) then
	return
end

RA.LootList = {
InstanceIds = {536},

		[1] = { -- HEAD

		}, -- [1]

		[2] = { -- NECK

		}, -- [2]

		[3] = { -- SHOULDERS

		}, -- [3]

		[5] = { -- CHEST

		},

		[6] = { -- WAIST
			{
				40271, -- Sash of Solitude
				16028,
			},
			{
				40260, -- Belt of the Tortured
				16028,
			},
			{
				40272, -- Girdle of the Gambit
				16028, 
			}
		}, -- [6]

		[7] = { -- LEGS

		},

		[8] = { -- FEET
			{	
				40269, -- Boots of Persuasion 
				16028,
			},
			{
				40270, -- Boots of Septic Wounds
				16028,
			},
		},

		[9] = { -- WRIST

		},

		[10] = { -- HANDS
			{
				40262, -- Gloves of Calculated Risk
				16028,
			},
			{
				40261, -- Crude Discolored Battlegrips
				16028,
			},
		},

		[11] = { -- FINGER

		},

		[13] = { -- TRINKET

		},

		[15] = { -- BACK

		},

		[16] = { -- WEAPON

		},

		[18] = { -- RANGED

		},

}
