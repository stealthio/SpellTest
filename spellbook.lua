-- API Documentation --

--[[
Every Player has the "recipes" attribute where a recipe table is stored as a string. You can
convert it back to a table by using the recipe_to_str function and convert it back into a
string using the str_to_recipe function

The following Commands are added by this mod:
- /add_recipe <player> <item_created> <amount> <item_cost>
- /reset_recipes <player>

These are the main functions:
- add_recipe_to_player(player, item_created, amount, item_cost)
- recipe_to_str(recipe)
- str_to_recipe(str)

The following items are added by this mod:
- spelltest:spellbook
--]]

-- Configuration parameters --

--[[Defines the recipes a player starts with, the first
element declares which item is being created and
the second + third define which item and how many of it are required--]]
default_recipes = {
	{"spelltest:spell_light",5,"default:torch"},
	{"spelltest:spell_heal_weak",3,"default:apple"}
}



local item_mapping = {}
for key, val in pairs(minetest.registered_items) do
    table.insert(item_mapping, key)
end

-- for name,node in pairs(minetest.registered_nodes) do
  -- if type(node.drop)=='string' then
    -- add(node.drop,item_mapping)
  -- end
-- end
-- item_mapping=makeunique(item_mapping)

function add_recipe_to_player(player, item_created, amount, item_cost)
	if not player then
		return false
	end
	local recipes = str_to_recipe(player:get_attribute("recipes"))
	if not recipes then
		recipes = {}
	end
	table.insert(recipes, {item_created, amount, item_cost})
	player:set_attribute("recipes", recipe_to_str(recipes))
	return true
end

minetest.register_chatcommand("add_recipe", {
	params = "<player> <item_created> <amount> <item_cost>",
	description = "Inserts a recipe into the player's spellbook. Which declares which item to create, amount declares how many <cost> items are required",
	func = function(name, param)
		local playername, which, amount, cost = string.match(param, "([^ ]+) ([^ ]+) (-?%d+) ([^ ]+)")
		if not playername or not which or not amount or not cost then
			return false, ("* Insufficient or wrong parameters")
		end
		amount = tonumber(amount)
		local player = minetest.get_player_by_name(playername)
		if not player then
			return false, ("* Player" .. playername .. "not found")
		end
		if (not minetest.registered_items[which]) or (not minetest.registered_items[cost]) then
			return false, ("* One of the Items given as parameters does not exist")
		end
		
		
		add_recipe_to_player(player, which, amount, cost)
		return true, "* Recipe'" .. which .. ("' was added to") .. playername
		end
})

minetest.register_chatcommand("reset_recipes", {
	params = "<player>",
	description = "Clears recipe list",
	func = function(name, param)
		if not param then
			return false, ("* Insufficient or wrong parameters")
		end
		local player = minetest.get_player_by_name(param)
		if not player then
			return false, ("* Player" .. param .. "not found")
		end
		player:set_attribute("recipes", "")
		return true, "* Recipe list was cleared"
		end
})

function str_to_recipe(s)
	if not (s) or s == "nil" then
		return
	end
	return (loadstring)("return "..s)()
end

minetest.register_craftitem("spelltest:spellbook", {
	description = "Spellbook",
	inventory_image = "spelltest_spellbook.png",
	wield_image = "spelltest_spellbook_open.png",
	on_use = function(itemstack, user, pointed_thing)
		local recipes = user:get_attribute("recipes")
		recipes = str_to_recipe(recipes)--(loadstring)("return "..recipes)()
		if not (recipes) then
			return
		end
		local txl = "textlist[2,3;5,3;spells;" -- minetest.registered_items[item1].description
		for i = 1, table.getn(recipes) do
			txl = txl .. "#000000" .. minetest.registered_items[recipes[i][1]].description .. " - Costs: " .. recipes[i][2] .. "x " .. minetest.registered_items[recipes[i][3]].description .. ","
		end
		txl = txl:sub(1, -2)
		txl = txl .. ";;true]"
		

		
		minetest.show_formspec(user:get_player_name(), "spelltest:spellbook",
			"size[10,10]" ..
			"background[0,0;10,10;spelltest_spellbook_empty.png]" ..
			"label[2,2;".. minetest.get_color_escape_sequence("#000") .. user:get_player_name() .. "'s Spellbook]" ..
			txl ..
			"button_exit[6.5,6.5;2,1;exit;Close]")
	end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "spelltest:spellbook" then
		return false
	end
	if fields.spells then
		local event = minetest.explode_textlist_event(fields.spells)
		local recipes = player:get_attribute("recipes")
		recipes = str_to_recipe(recipes)
		local recipe = recipes[event.index]
		
		if event.type == "DCL" then
			local inv = player:get_inventory()
			local items = inv:get_list("main")
			for i = 1, table.getn(items) do
				if (items[i]:get_name() == recipe[3]) and (items[i]:get_count() >= recipe[2]) then
					local item_to_remove = items[i]
					item_to_remove:set_count(recipe[2])
					inv:remove_item("main", item_to_remove)
					inv:add_item("main", recipe[1])					
				end
			end
		end
	end
	
	return true
end)

minetest.register_on_newplayer(function(player)
	if not player then
		return
	end
	local r = player:get_attribute("recipes")
	if not r then
		
		player:set_attribute("recipes", recipe_to_str(default_recipes))
	end
end)

minetest.register_on_joinplayer(function(player)
	if not player then
		return
	end
	local r = player:get_attribute("recipes")
	if not r then
		local recipes = default_recipes
		if recipes then
			player:set_attribute("recipes", recipe_to_str(recipes))
		end
	end
end)

-- http://lua-users.org/wiki/TableUtils
function recipe_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table_to_str( v ) or
      tostring( v )
  end
end

function table_to_str( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, recipe_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. recipe_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end