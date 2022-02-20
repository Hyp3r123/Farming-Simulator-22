--[[
Script to add new store category(s) in the mod view

Author:		Ifko[nator]
Date:		18.11.2021
Version:	3.0

History:	v1.0 @16.11.2015 - initial release in FS 15
			----------------------------------------------------------------------------------------------
			v1.1 @09.12.2015 - bug fix for wrong placement of the new category in the mod view
			----------------------------------------------------------------------------------------------
			v1.5 @25.10.2016 - add support for the new categories from FS 17
			----------------------------------------------------------------------------------------------
			v1.8 @27.11.2017 - some improvements in the script, now it is smaller
			----------------------------------------------------------------------------------------------
			v2.0 @21.01.2019 - add support for the new store from FS 19
			----------------------------------------------------------------------------------------------
			v2.1 @07.08.2019 - added posibility to add the new category to the GPS Mod from Wopster
			----------------------------------------------------------------------------------------------
			v2.2 @06.12.2020 - added posibility to add the new category to the tireSound Mod from PeterAH
			----------------------------------------------------------------------------------------------
			v2.3 @13.06.2021 - minior adjustments
			----------------------------------------------------------------------------------------------
			v3.0 @18.11.2021 - convert to FS 22
							 - removed function for tireSound and GPS Mod

]]

AddStoreCategory = {};

AddStoreCategory.currentModDirectory = g_currentModDirectory;
AddStoreCategory.debugPriority = 0;
AddStoreCategory.newCategories = {};

local function printError(errorMessage, isWarning, isInfo)
	local prefix = "::ERROR:: ";
	
	if isWarning then
		prefix = "::WARNING:: ";
	elseif isInfo then
		prefix = "::INFO:: ";
	end;
	
	print(prefix .. "from the AddStoreCategory.lua: " .. tostring(errorMessage));
end;

local function printDebug(debugMessage, priority, addString)
	if AddStoreCategory.debugPriority >= priority then
		local prefix = "";
		
		if addString then
			prefix = "::DEBUG:: from the AddStoreCategory.lua: ";
		end;
		
		setFileLogPrefixTimestamp(false);
		print(prefix .. tostring(debugMessage));
		setFileLogPrefixTimestamp(true);
	end;
end;

local function addCategory()
    printDebug("Run initSpecialization.", 1, true);
	
	local modDesc = loadXMLFile("modDesc", AddStoreCategory.currentModDirectory .. "modDesc.xml");
	
	AddStoreCategory.debugPriority = Utils.getNoNil(getXMLFloat(modDesc, "modDesc.storeItems.newStoreCategories#debugPriority"), AddStoreCategory.debugPriority);
	
	local categoryNumber = 0;
	
	local supportedCategoryTypes = {
		"VEHICLE",
		"TOOL",
		"PLACEABLE",
		"OBJECT"
	};
	
	while true do
		local categoryKey = "modDesc.storeItems.newStoreCategories.newStoreCategory(" .. tostring(categoryNumber) .. ")";
		
		if not hasXMLProperty(modDesc, categoryKey) then
			break;
		end;
		
		local newCategory = {};
		
		newCategory.name = getXMLString(modDesc, categoryKey .. "#name");
		
		if newCategory.name ~= nil  then
			newCategory.title = Utils.getNoNil(getXMLString(modDesc, categoryKey .. "#title"), newCategoryName);
			newCategory.type = Utils.getNoNil(string.upper(getXMLString(modDesc, categoryKey .. "#type")), "VEHICLE");
			newCategory.image = Utils.getNoNil(getXMLString(modDesc, categoryKey .. "#image"), "imageNotDefined");
			
			local function getIsValidCategoryType(categoryType)
				for _, supportedCategoryType in pairs(supportedCategoryTypes) do
					if categoryType == supportedCategoryType then
						return true;
					end;
				end;
				
				return false;
			end;
			
			if getIsValidCategoryType(newCategory.type) then		
				if string.find(newCategory.image, ".png") then
					newCategory.image = string.sub(newCategory.image, 1, string.len(newCategory.image) - 3) .. "dds";
				end;
				
				newCategory.imageToCheck = newCategory.image;
				
				if string.sub(newCategory.title, 1, 6) == "$l10n_" then
					newCategory.title = g_i18n:getText(string.sub(newCategory.title, 7));
				elseif g_i18n:hasText(newCategory.title) then
					newCategory.title = g_i18n:getText(newCategory.title);
				end;
				
				if string.sub(newCategory.image, 1, 1) == "$" then
					newCategory.imageToCheck = string.sub(newCategory.image, 2);
				else
					newCategory.imageToCheck = Utils.getFilename(newCategory.image, AddStoreCategory.currentModDirectory);
				end;
				
				if fileExists(newCategory.imageToCheck) then
					printDebug("(addCategory) :: Added category '" .. newCategory.name .. "' successfully!", 1, true);
					printDebug("(addCategory) :: Facts of category '" .. newCategory.name .. "':", 2, true);
					printDebug("    Title = '" .. newCategory.title .. "'.", 2, false);
					printDebug("    image filename = '" .. newCategory.image .. "'.", 2, false);
					printDebug("    Type = '" .. newCategory.type .. "'.", 2, false);
					printDebug("", 2, false);
					
					g_storeManager:addCategory(newCategory.name, newCategory.title, newCategory.image, newCategory.type, AddStoreCategory.currentModDirectory);

					table.insert(AddStoreCategory.newCategories, newCategory);
				else
					if newCategoryImage == "imageNotDefined" then
						printError("(addCategory) :: No image for the category '" .. newCategory.name .. "' defined! This category will be NOT added!", false, false);
					else
						printError("(addCategory) :: Failed to load '" .. newCategory.imageToCheck .. "'! The category '" .. newCategory.name .. "' will be NOT added!", false, false);
					end;
				end;
			else
				printError("(addCategory) :: The category type '" .. newCategory.type .. "' are not exists! Set the Type to 'VEHICLE', 'TOOL', 'PLACEABLE' or 'OBJECT' instead! The category '" .. newCategory.name .. "' will be NOT added!", false, false);
			end;
		else
			printError("(addCategory) :: Missing the category name for category " .. categoryNumber	.. "! This category will be NOT added!", false, false);
		end;
		
		categoryNumber = categoryNumber + 1;
	end;
end;

Vehicle.init = Utils.appendedFunction(Vehicle.init, addCategory);