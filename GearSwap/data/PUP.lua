-------------------------------------------------------------------------------------------------------------------
-- Setup functions for this job.  Generally should not be modified.
-------------------------------------------------------------------------------------------------------------------

-- Initialization function for this job file.
function get_sets()
    mote_include_version = 2
	include('organizer-lib')

    -- Load and initialize the include file.
    include('Mote-Include.lua')
end


-- Setup vars that are user-independent.  state.Buff vars initialized here will automatically be tracked.
function job_setup()

    state.OffenseMode:options('Normal', 'Acc','Hybrid')
    state.HybridMode:options('Normal', 'Acc', 'DT')
    state.WeaponskillMode:options('Normal', 'Acc')
    state.PhysicalDefenseMode:options('PDT', 'Pet')

    -- Default maneuvers 1, 2, 3 and 4 for each pet mode.
    defaultManeuvers = {
        ['Melee'] = {'Fire Maneuver', 'Thunder Maneuver', 'Wind Maneuver', 'Light Maneuver'},
        ['Ranged'] = {'Wind Maneuver', 'Fire Maneuver', 'Thunder Maneuver', 'Light Maneuver'},
        ['Tank'] = {'Earth Maneuver', 'Dark Maneuver', 'Light Maneuver', 'Wind Maneuver'},
        ['Magic'] = {'Ice Maneuver', 'Light Maneuver', 'Dark Maneuver', 'Earth Maneuver'},
        ['Heal'] = {'Light Maneuver', 'Dark Maneuver', 'Water Maneuver', 'Earth Maneuver'},
        ['Nuke'] = {'Ice Maneuver', 'Dark Maneuver', 'Light Maneuver', 'Earth Maneuver'}
    }


    -- List of pet weaponskills to check for
    petWeaponskills = S{"Slapstick", "Knockout", "Magic Mortar",
        "Chimera Ripper", "String Clipper",  "Cannibal Blade", "Bone Crusher", "String Shredder",
        "Arcuballista", "Daze", "Armor Piercer", "Armor Shatterer"}
    
    -- Map automaton heads to combat roles
    petModes = {
        ['Harlequin Head'] = 'Melee',
        ['Sharpshot Head'] = 'Ranged',
        ['Valoredge Head'] = 'Tank',
        ['Stormwaker Head'] = 'Magic',
        ['Soulsoother Head'] = 'Heal',
        ['Spiritreaver Head'] = 'Nuke'
        }

    -- Subset of modes that use magic
    magicPetModes = S{'Nuke','Heal','Magic'}
    
    -- Var to track the current pet mode.
    state.PetMode = M{['description']='Pet Mode', 'None', 'Melee', 'Ranged', 'Tank', 'Magic', 'Heal', 'Nuke'}

	update_pet_mode()
    select_default_macro_book()

	state.AutoMode = M{'Normal', 'Pet Only', 'Pet Only DT', 'Hybrid DT'}
	organizer_items = {
		cpring="Capacity Ring",
		trring="Trizek Ring",
		DThands="Oberon's Sainti",
		oil="Automat. oil +3",
		oil2="Automat. oil +3",
		oil3="Automat. oil +3",
		ohtas="Ohtas",
		
		}

	
end


-------------------------------------------------------------------------------------------------------------------
-- User setup functions for this job.  Recommend that these be overridden in a sidecar file.
-------------------------------------------------------------------------------------------------------------------

-- Setup vars that are user-dependent.  Can override this function in a sidecar file.



-------------------------------------------------------------------------------------------------------------------
-- Job-specific hooks for standard casting events.
-------------------------------------------------------------------------------------------------------------------

-- Called when pet is about to perform an action
function job_pet_midcast(spell, action, spellMap, eventArgs)
    if petWeaponskills:contains(spell.english) then
        classes.CustomClass = "Weaponskill"
    end
end

--function job_state_change(stateField, newValue, oldValue)
--    if stateField == 'Physical Defense Mode' then
        --if newValue == 'Pet' then
--            equip(sets.idle.Pet.Engaged.Tank)
--			handle_equipping_gear(player.status)
--			
--        end
--    end	
--end

-------------------------------------------------------------------------------------------------------------------
-- Job-specific hooks for non-casting events.
-------------------------------------------------------------------------------------------------------------------

-- Called when a player gains or loses a buff.
-- buff == buff gained or lost
-- gain == true if the buff was gained, false if it was lost.
function job_buff_change(buff, gain)
    if buff == 'Wind Maneuver' then
        handle_equipping_gear(player.status)
    end
end

-- Called when a player gains or loses a pet.
-- pet == pet gained or lost
-- gain == true if the pet was gained, false if it was lost.
function job_pet_change(pet, gain)
    update_pet_mode()
end

-- Called when the pet's status changes.
function job_pet_status_change(newStatus, oldStatus)
    if newStatus == 'Engaged' then
       display_pet_status()
	   handle_equipping_gear(player.status)
		--if pet.tp > 100.0 then
			--equip(sets.midcast.Pet.WeaponSkill)
		--end
    end
end

--function job_state_change(new_state_value, old_state_value)
--end


-------------------------------------------------------------------------------------------------------------------
-- User code that supplements standard library decisions.
-------------------------------------------------------------------------------------------------------------------

-- Called by the 'update' self-command, for common needs.
-- Set eventArgs.handled to true if we don't want automatic equipping of gear.
function job_update(cmdParams, eventArgs)
    update_pet_mode()
end


-- Set eventArgs.handled to true if we don't want the automatic display to be run.
function display_current_job_state(eventArgs)
    display_pet_status()
end


-------------------------------------------------------------------------------------------------------------------
-- User self-commands.
-------------------------------------------------------------------------------------------------------------------

-- Called for custom player commands.
function job_self_command(cmdParams, eventArgs)
    if cmdParams[1] == 'maneuver' then
        if pet.isvalid then
            local man = defaultManeuvers[state.PetMode.value]
            if man and tonumber(cmdParams[2]) then
                local man = man[tonumber(cmdParams[2])]
            end

            if man then
                send_command('input /pet "'..man..'" <me>')
            end
        else
            add_to_chat(123,'No valid pet.')
        end
    end
end


-------------------------------------------------------------------------------------------------------------------
-- Utility functions specific to this job.
-------------------------------------------------------------------------------------------------------------------

-- Get the pet mode value based on the equipped head of the automaton.
-- Returns nil if pet is not valid.
function get_pet_mode()
    if pet.isvalid then
		if pet.head == 'Soulsoother Head' then
			if pet.frame == 'Stormwaker Frame' then
				return 'Heal'
			elseif pet.frame == 'Harlequin Frame' then
				return 'Tank'
			elseif pet.frame == 'Valoredge Frame' then
				return 'Tank'
			else 
				return 'None'
			end
		elseif pet.head == 'Valoredge Head' then
			if pet.frame == 'Valoredge Frame' then
				return 'Melee'
			elseif pet.frame == 'Sharpshot Frame' then
				return 'Melee'
			else
				return 'None'
			end
		elseif pet.head == 'Stormwaker Head' then	
			if pet.frame == 'Stormwaker Frame' then	
				return 'Magic'
			else
				return 'None'
			end
		elseif pet.head == 'Spiritreaver Head' then
			if pet.frame == 'Stormwaker Frame' then
				return 'Nuke'
			else
				return 'None'
			end
		elseif pet.head == 'Sharpshot Head' then	
			if pet.frame == 'Sharpshot Frame' then
				return 'Ranged'
			elseif pet.frame == 'Valoredge Frame' then
				return 'Melee'
			else
				return 'None'
			end
		else
			return 'None'
		end
        --return petModes[pet.head] or 'None'
    else
        return 'None'
    end
end

-- Update state.PetMode, as well as functions that use it for set determination.
function update_pet_mode()
    state.PetMode:set(get_pet_mode())
    update_custom_groups()
end

-- Update custom groups based on the current pet.
function update_custom_groups()
    classes.CustomIdleGroups:clear()
    if pet.isvalid then
        classes.CustomIdleGroups:append(state.PetMode.value)
    end
end

function customize_idle_set(idleSet)
	if state.HybridMode.current == 'Acc' then
		idleSet = set_combine(idleSet, sets.PetAcc)
	elseif state.HybridMode.current == 'DT' then
		idleSet = set_combine(idleSet, sets.PetDT)
	end
	return idleSet
end

function customize_melee_set(meleeSet)
	if state.HybridMode.current == 'Acc' then
		meleeSet = set_combine(meleeSet, sets.PetAcc)
	elseif state.HybridMode.current == 'DT' then
		meleeSet = set_combine(meleeSet, sets.PetDT)
	end
	return meleeSet
end

-- Display current pet status.
function display_pet_status()
    if pet.isvalid then
        local petInfoString = pet.name..' ['..pet.head..'] ['..state.PetMode.value..']: '..tostring(pet.status)..'  TP='..tostring(pet.tp)..'  HP%='..tostring(pet.hpp)
        
        if magicPetModes:contains(state.PetMode.value) then
            petInfoString = petInfoString..'  MP%='..tostring(pet.mpp)
        end
        
        add_to_chat(122,petInfoString)
    end
end

-- Select default macro book on initial load or subjob change.
function select_default_macro_book()
    -- Default macro set/book
    if player.sub_job == 'DNC' then
        set_macro_page(2, 9)
    elseif player.sub_job == 'NIN' then
        set_macro_page(3, 9)
    elseif player.sub_job == 'THF' then
        set_macro_page(4, 9)
    else
        set_macro_page(1, 9)
    end
end
