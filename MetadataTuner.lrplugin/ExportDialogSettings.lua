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
        enableAsciiConversion = propertyTable.enableAsciiConversion
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

-- Initialize property table values with default values (НЕ загружать из глобальных настроек)
function ExportDialogSettings.initializePropertyTable(propertyTable)
    -- Устанавливаем значения по умолчанию только если они еще не установлены
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
end

-- УДАЛЕНЫ функции setupObservers - настройки должны сохраняться в propertyTable автоматически

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
    }
end

return ExportDialogSettings