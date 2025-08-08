local LrView = import 'LrView'
local LrDialogs = import 'LrDialogs'
local LrPrefs = import 'LrPrefs'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'

-- Import the template processor for help dialog
local MetadataTemplateProcessor = require 'MetadataTemplateProcessor'

local ExportDialogSettings = {}

-- Show template help dialog
local function showTemplateHelp()
    LrDialogs.message(
        "Template Placeholders Help",
        MetadataTemplateProcessor.getTemplateHelp(),
        "info"
    )
end

-- Function to get ExifTool path from plugin preferences or default location
function ExportDialogSettings.getExifToolPath()
    local prefs = LrPrefs.prefsForPlugin()
    
    -- First check if custom path is set in preferences
    if prefs.exifToolPath and prefs.exifToolPath ~= "" then
        if LrFileUtils.exists(prefs.exifToolPath) then
            return prefs.exifToolPath
        end
    end
    
    -- Fallback to default plugin location
    local pluginPath = _PLUGIN.path
    local exifToolFolder = LrPathUtils.child(pluginPath, "exiftool")
    
    local exifToolExe = LrPathUtils.child(exifToolFolder, "exiftool.exe")
    local exifTool = LrPathUtils.child(exifToolFolder, "exiftool")
    
    if LrFileUtils.exists(exifToolExe) then
        return exifToolExe
    elseif LrFileUtils.exists(exifTool) then
        return exifTool
    else
        return nil
    end
end

-- Function to get all export settings
function ExportDialogSettings.getExportSettings(propertyTable)
    return {
        enableTemplateProcessing = propertyTable.enableTemplateProcessing or false,
        titleTemplate = propertyTable.titleTemplate or "",
        captionTemplate = propertyTable.captionTemplate or "",
        enableAsciiConversion = propertyTable.enableAsciiConversion,
        enableCrsDataRemoval = propertyTable.enableCrsDataRemoval or false,
        enableSoftwareInfoRemoval = propertyTable.enableSoftwareInfoRemoval or false,
        enableLocationInfoRemoval = propertyTable.enableLocationInfoRemoval or false,
        enableEquipmentInfoRemoval = propertyTable.enableEquipmentInfoRemoval or false,
        enableShootingInfoRemoval = propertyTable.enableShootingInfoRemoval or false,
        enableIptcInfoRemoval = propertyTable.enableIptcInfoRemoval or false
    }
end

-- Function to validate ExifTool path
function ExportDialogSettings.validateExifToolPath(path)
    if not path or path == "" then
        return false, "Path is empty"
    end
    
    if not LrFileUtils.exists(path) then
        return false, "File does not exist"
    end
    
    -- Check if it's actually ExifTool by checking filename
    local filename = LrPathUtils.leafName(path):lower()
    if not (filename == "exiftool.exe" or filename == "exiftool") then
        return false, "File is not ExifTool executable"
    end
    
    return true, "Valid ExifTool path"
end

-- Initialize property table values with default values
function ExportDialogSettings.initializePropertyTable(propertyTable)
    -- Set default values only if they are not already set
    if propertyTable.enableTemplateProcessing == nil then
        propertyTable.enableTemplateProcessing = false
    end
    if propertyTable.titleTemplate == nil then
        propertyTable.titleTemplate = ""
    end
    if propertyTable.captionTemplate == nil then
        propertyTable.captionTemplate = ""
    end
    if propertyTable.enableAsciiConversion == nil then
        propertyTable.enableAsciiConversion = true
    end
    if propertyTable.enableCrsDataRemoval == nil then
        propertyTable.enableCrsDataRemoval = false
    end
    if propertyTable.enableSoftwareInfoRemoval == nil then
        propertyTable.enableSoftwareInfoRemoval = false
    end
    if propertyTable.enableLocationInfoRemoval == nil then
        propertyTable.enableLocationInfoRemoval = false
    end
    if propertyTable.enableEquipmentInfoRemoval == nil then
        propertyTable.enableEquipmentInfoRemoval = false
    end
    if propertyTable.enableShootingInfoRemoval == nil then
        propertyTable.enableShootingInfoRemoval = false
    end
    -- Новая настройка для удаления IPTC тегов
    if propertyTable.enableIptcInfoRemoval == nil then
        propertyTable.enableIptcInfoRemoval = false
    end
end

-- Create the UI section for the export dialog
function ExportDialogSettings.createUISection(f)
    return {
        title = "Metadata Tuner",
        
        f:row {
            f:checkbox {
                title = "Enable metadata template processing",
                value = LrView.bind { key = 'enableTemplateProcessing' },
            },
        },
        
        f:row {
            f:static_text {
                title = "Title Template:",
                width = LrView.share "label_width",
                enabled = LrView.bind { key = 'enableTemplateProcessing' },
            },
            
            f:edit_field {
                value = LrView.bind { key = 'titleTemplate' },
                width_in_chars = 35,
                enabled = LrView.bind { key = 'enableTemplateProcessing' },
                tooltip = "Template for title field. Leave empty to use original title.",
            },
        },
        
        f:row {
            f:static_text {
                title = "Caption Template:",
                width = LrView.share "label_width",
                enabled = LrView.bind { key = 'enableTemplateProcessing' },
            },
            
            f:edit_field {
                value = LrView.bind { key = 'captionTemplate' },
                width_in_chars = 35,
                enabled = LrView.bind { key = 'enableTemplateProcessing' },
                tooltip = "Template for caption field. Leave empty to use original caption.",
            },
        },
        
        f:row {
            f:static_text {
                title = "",
                width = LrView.share "label_width",
            },
            
            f:push_button {
                title = "Template Help",
                action = showTemplateHelp,
                enabled = LrView.bind { key = 'enableTemplateProcessing' },
            },
        },
        
        f:row {
            f:static_text {
                title = "Example: {City}, {Country} - {MMM} {D}, {YYYY}: {Caption}",
                width_in_chars = 55,
                text_color = LrView.kColorLabel,
                enabled = LrView.bind { key = 'enableTemplateProcessing' },
            },
        },
        
        f:spacer { height = 10 },
        
        f:row {
            f:checkbox {
                title = "Enable ASCII conversion of diacritic characters",
                value = LrView.bind { key = 'enableAsciiConversion' },
                tooltip = "Convert characters with diacritics (ą, ę, ł, etc.) to ASCII equivalents (a, e, l, etc.)",
            },
        },
        
        f:spacer { height = 10 },
        
        f:row {
            f:static_text {
                title = "Remove metadata:",
                font = '<system/bold>',
            },
        },
        
        f:row {
            f:checkbox {
                title = "Remove Camera Raw Settings data",
                value = LrView.bind { key = 'enableCrsDataRemoval' },
                tooltip = "Remove all CRS (Camera Raw Settings) data from image metadata",
            },
        },
        
        f:row {
            f:checkbox {
                title = "Remove software information",
                value = LrView.bind { key = 'enableSoftwareInfoRemoval' },
                tooltip = "Remove software and processing application information (Software, CreatorTool, etc.)",
            },
        },
        
        f:row {
            f:checkbox {
                title = "Remove location information",
                value = LrView.bind { key = 'enableLocationInfoRemoval' },
                tooltip = "Remove GPS coordinates and location names (City, Country, GPS data, etc.)",
            },
        },
        
        f:row {
            f:checkbox {
                title = "Remove equipment information",
                value = LrView.bind { key = 'enableEquipmentInfoRemoval' },
                tooltip = "Remove camera and lens information (Make, Model, LensModel, SerialNumber, etc.)",
            },
        },
        
        f:row {
            f:checkbox {
                title = "Remove shooting parameters",
                value = LrView.bind { key = 'enableShootingInfoRemoval' },
                tooltip = "Remove exposure settings (shutter speed, aperture, ISO, focal length, etc.)",
            },
        },
        
        -- Новый checkbox для удаления IPTC тегов
        f:row {
            f:checkbox {
                title = "Remove IPTC tags (preserves DC tags)",
                value = LrView.bind { key = 'enableIptcInfoRemoval' },
                tooltip = "Remove IPTC metadata tags",
            },
        },
    }
end

return ExportDialogSettings