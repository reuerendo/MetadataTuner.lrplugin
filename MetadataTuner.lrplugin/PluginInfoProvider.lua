local LrView = import 'LrView'
local LrHttp = import 'LrHttp'
local LrPrefs = import 'LrPrefs'
local LrDialogs = import 'LrDialogs'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'

local PluginInfoProvider = {}

-- Function to browse for ExifTool
local function browseForExifTool()
    local prefs = LrPrefs.prefsForPlugin()
    
    local result = LrDialogs.runOpenPanel {
        title = "Select ExifTool executable",
        prompt = "Choose",
        allowsMultipleSelection = false,
        canChooseFiles = true,
        canChooseDirectories = false,
        allowedFileTypes = WIN_ENV and {"exe"} or nil,
    }
    
    if result and #result > 0 then
        prefs.exifToolPath = result[1]
    end
end

function PluginInfoProvider.sectionsForTopOfDialog(f, propertyTable)
    local prefs = LrPrefs.prefsForPlugin()
    
    -- Initialize preferences if they don't exist
    if prefs.exifToolPath == nil then
        prefs.exifToolPath = ""
    end
    if prefs.verboseLogging == nil then
        prefs.verboseLogging = false
    end

    return {
        {
            title = "Settings",
            
            f:row {
                f:static_text {
                    title = "ExifTool Path:",
                    width = LrView.share "label_width",
                },
                
                f:edit_field {
                    value = LrView.bind { key = 'exifToolPath', object = prefs },
                    width_in_chars = 35,
                    tooltip = "Path to ExifTool executable. Leave empty to use default location (plugin/exiftool/).",
                },
                
                f:push_button {
                    title = "Browse...",
                    action = browseForExifTool,
                },
            },
            
            f:row {
                f:static_text {
                    title = "",
                    width = LrView.share "label_width",
                },
                
                f:static_text {
                    title = "Leave empty to use default location: plugin/exiftool/",
                    width_in_chars = 45,
                    text_color = LrView.kColorLabel,
                },
            },
        },
        
        {
            title = "About Plugin",
            
            f:row {
                f:static_text {
                    title = "Metadata Tuner",
                    font = '<system/bold>',
                },
            },
            
            f:row {
                f:static_text {
                    title = "This export filter converts diacritic characters (ą, ć, ę, ś, ź, ż, ó, ł, ń, etc.) to ASCII characters in image metadata during export.",
                    width_in_chars = 60,
                    height_in_lines = 2,
                },
            },
            
            f:row {
                f:static_text {
                    title = "How to use:",
                    font = '<system/bold>',
                },
            },
            
            f:row {
                f:static_text {
                    title = "1. During export, find 'Metadata Tuner' in the 'Post-Process Actions' section\n2. Enable the filter\n3. Export images as usual",
                    width_in_chars = 70,
                    height_in_lines = 3,
                },
            },
            
            f:row {
                f:static_text {
                    title = "Requirements:",
                    font = '<system/bold>',
                },
            },
            
            f:row {
                f:static_text {
                    title = "ExifTool is required for the plugin to work. You can either:\n• Place ExifTool in the 'exiftool' folder inside the plugin directory (default)\n• Specify custom path in the Settings section above",
                    width_in_chars = 60,
                    height_in_lines = 2,
                },
            },
            
            f:row {
                f:static_text {
                    title = "Download ExifTool:",
                    font = '<system/bold>',
                },
            },
            
            f:row {
                f:static_text {
                    title = "Download from https://exiftool.org/\nFor Windows: download the Windows Executable\nFor Mac/Linux: download the stand-alone executable",
                    width_in_chars = 60,
                    height_in_lines = 3,
                },
            },
            
            f:row {
                f:static_text {
                    title = "Supported characters:",
                    font = '<system/bold>',
                },
            },
            
            f:row {
                f:static_text {
                    title = "• Polish: ą, ć, ę, ł, ń, ó, ś, ź, ż\n• French: à, á, â, ã, ä, è, é, ê, ë, ì, í, î, ï, ò, ó, ô, õ, ö, ù, ú, û, ü, ý, ÿ, ç, ñ\n• German: ß\n• Other: æ, œ, ø, å, đ",
                    width_in_chars = 70,
                    height_in_lines = 4,
                },
            },
        },
    }
end

return PluginInfoProvider