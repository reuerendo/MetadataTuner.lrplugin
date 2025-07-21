local LrView = import 'LrView'
local LrDialogs = import 'LrDialogs'
local LrPrefs = import 'LrPrefs'

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

-- Function to load settings from preferences
local function loadSettingsFromPrefs(propertyTable)
    local prefs = LrPrefs.prefsForPlugin()
    
    -- Load template processing settings from prefs
    if prefs.enableTemplateProcessing ~= nil then
        propertyTable.enableTemplateProcessing = prefs.enableTemplateProcessing
    end
    
    if prefs.titleTemplate ~= nil then
        propertyTable.titleTemplate = prefs.titleTemplate
    end
    
    if prefs.captionTemplate ~= nil then
        propertyTable.captionTemplate = prefs.captionTemplate
    end
    
    -- Load ASCII conversion setting from prefs
    if prefs.enableAsciiConversion ~= nil then
        propertyTable.enableAsciiConversion = prefs.enableAsciiConversion
    end
end

-- Function to save settings to preferences
local function saveSettingsToPrefs(propertyTable)
    local prefs = LrPrefs.prefsForPlugin()
    
    -- Save template processing settings to prefs
    prefs.enableTemplateProcessing = propertyTable.enableTemplateProcessing
    prefs.titleTemplate = propertyTable.titleTemplate
    prefs.captionTemplate = propertyTable.captionTemplate
    
    -- Save ASCII conversion setting to prefs
    prefs.enableAsciiConversion = propertyTable.enableAsciiConversion
end

-- Initialize property table values and load from preferences
function ExportDialogSettings.initializePropertyTable(propertyTable)
    -- Initialize property table values
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
        propertyTable.enableAsciiConversion = true -- Default to enabled for backward compatibility
    end
    
    -- Load saved settings
    loadSettingsFromPrefs(propertyTable)
end

-- Set up observers to save settings when changed
function ExportDialogSettings.setupObservers(propertyTable)
    propertyTable:addObserver('enableTemplateProcessing', function()
        saveSettingsToPrefs(propertyTable)
    end)
    
    propertyTable:addObserver('titleTemplate', function()
        saveSettingsToPrefs(propertyTable)
    end)
    
    propertyTable:addObserver('captionTemplate', function()
        saveSettingsToPrefs(propertyTable)
    end)
    
    propertyTable:addObserver('enableAsciiConversion', function()
        saveSettingsToPrefs(propertyTable)
    end)
end

-- Create the UI section for the export dialog
function ExportDialogSettings.createUISection(f)
    return {
        title = "Metadata Tuner",
        
        -- f:row {
            -- f:static_text {
                -- title = "Processes metadata using templates and optionally converts diacritics to ASCII.",
                -- width_in_chars = 55,
            -- },
        -- },
        
        -- f:row {
            -- f:static_text {
                -- title = "Configure ExifTool path and logging settings in Plugin Manager.",
                -- width_in_chars = 55,
                -- text_color = LrView.kColorLabel,
            -- },
        -- },
        
        -- f:spacer { height = 10 },
        
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