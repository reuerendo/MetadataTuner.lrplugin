local LrTasks = import 'LrTasks'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrApplicationView = import 'LrApplicationView'
local LrLogger = import 'LrLogger'
local LrPrefs = import 'LrPrefs'

-- Import modules
local MetadataTemplateProcessor = require 'MetadataTemplateProcessor'
local ExportDialogSettings = require 'ExportDialogSettings'

local ExportFilterProvider = {}

-- Create logger
local logger = LrLogger('MetadataAsciiConverter')
logger:enable("logfile")

-- Character mapping for ASCII conversion
local diacriticsMap = {
    -- Polish characters
    ['ą'] = 'a', ['Ą'] = 'A',
    ['ć'] = 'c', ['Ć'] = 'C',
    ['ę'] = 'e', ['Ę'] = 'E',
    ['ł'] = 'l', ['Ł'] = 'L',
    ['ń'] = 'n', ['Ń'] = 'N',
    ['ó'] = 'o', ['Ó'] = 'O',
    ['ś'] = 's', ['Ś'] = 'S',
    ['ź'] = 'z', ['Ź'] = 'Z',
    ['ż'] = 'z', ['Ż'] = 'Z',
    
    -- French characters
    ['à'] = 'a', ['À'] = 'A',
    ['á'] = 'a', ['Á'] = 'A',
    ['â'] = 'a', ['Â'] = 'A',
    ['ã'] = 'a', ['Ã'] = 'A',
    ['ä'] = 'a', ['Ä'] = 'A',
    ['è'] = 'e', ['È'] = 'E',
    ['é'] = 'e', ['É'] = 'E',
    ['ê'] = 'e', ['Ê'] = 'E',
    ['ë'] = 'e', ['Ë'] = 'E',
    ['ì'] = 'i', ['Ì'] = 'I',
    ['í'] = 'i', ['Í'] = 'I',
    ['î'] = 'i', ['Î'] = 'I',
    ['ï'] = 'i', ['Ï'] = 'I',
    ['ò'] = 'o', ['Ò'] = 'O',
    ['ó'] = 'o', ['Ó'] = 'O',
    ['ô'] = 'o', ['Ô'] = 'O',
    ['õ'] = 'o', ['Õ'] = 'O',
    ['ö'] = 'o', ['Ö'] = 'O',
    ['ù'] = 'u', ['Ù'] = 'U',
    ['ú'] = 'u', ['Ú'] = 'U',
    ['û'] = 'u', ['Û'] = 'U',
    ['ü'] = 'u', ['Ü'] = 'U',
    ['ý'] = 'y', ['Ý'] = 'Y',
    ['ÿ'] = 'y', ['Ÿ'] = 'Y',
    ['ç'] = 'c', ['Ç'] = 'C',
    ['ñ'] = 'n', ['Ñ'] = 'N',
    
    -- German characters
    ['ß'] = 'ss',
    
    -- Other common characters
    ['æ'] = 'ae', ['Æ'] = 'AE',
    ['œ'] = 'oe', ['Œ'] = 'OE',
    ['ø'] = 'o', ['Ø'] = 'O',
    ['å'] = 'a', ['Å'] = 'A',
    ['đ'] = 'd', ['Đ'] = 'D',
}

-- Function to convert to ASCII
local function convertToAscii(text)
    if not text or text == "" then
        return text, false
    end
    
    local result = text
    local hasChanges = false
    
    for diacritic, ascii in pairs(diacriticsMap) do
        local newResult = result:gsub(diacritic, ascii)
        if newResult ~= result then
            hasChanges = true
            result = newResult
        end
    end
    
    return result, hasChanges
end

-- Function to get ExifTool path from plugin preferences or default location
local function getExifToolPath()
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

-- Function to process with ExifTool
local function processWithExifTool(filePath, title, caption, keywords, enableAsciiConversion, verboseLogging)
    local exifToolPath = getExifToolPath()
    if not exifToolPath then
        if verboseLogging then
            logger:info("ExifTool not found. Please specify path in plugin preferences.")
        end
        return false, "ExifTool not found. Please specify path in plugin preferences."
    end
    
    local hasChanges = false
    local commands = {}
    
    -- Process title
    if title and title ~= "" then
        local finalTitle = title
        local titleChanged = false
        
        if enableAsciiConversion then
            finalTitle, titleChanged = convertToAscii(title)
            if titleChanged and verboseLogging then
                logger:info("Title changed: '" .. title .. "' -> '" .. finalTitle .. "'")
            end
        end
        
        table.insert(commands, "-Title=" .. finalTitle)
        table.insert(commands, "-XMP-dc:Title=" .. finalTitle)
        table.insert(commands, "-IPTC:ObjectName=" .. finalTitle)
        hasChanges = true
    end
    
    -- Process caption
    if caption and caption ~= "" then
        local finalCaption = caption
        local captionChanged = false
        
        if enableAsciiConversion then
            finalCaption, captionChanged = convertToAscii(caption)
            if captionChanged and verboseLogging then
                logger:info("Caption changed: '" .. caption .. "' -> '" .. finalCaption .. "'")
            end
        end
        
        table.insert(commands, "-Description=" .. finalCaption)
        table.insert(commands, "-XMP-dc:Description=" .. finalCaption)
        table.insert(commands, "-IPTC:Caption-Abstract=" .. finalCaption)
        table.insert(commands, "-EXIF:ImageDescription=" .. finalCaption)
        table.insert(commands, "-XMP-exif:UserComment=" .. finalCaption)
        hasChanges = true
    end
    
    -- Process keywords
    if keywords and keywords ~= "" then
        local finalKeywords = keywords
        local keywordsChanged = false
        
        if enableAsciiConversion then
            finalKeywords, keywordsChanged = convertToAscii(keywords)
            if keywordsChanged and verboseLogging then
                logger:info("Keywords changed: '" .. keywords .. "' -> '" .. finalKeywords .. "'")
            end
        end
        
        table.insert(commands, "-Keywords=" .. finalKeywords)
        table.insert(commands, "-XMP-dc:Subject=" .. finalKeywords)
        table.insert(commands, "-IPTC:Keywords=" .. finalKeywords)
        hasChanges = true
    end
    
    if not hasChanges then
        if verboseLogging then
            logger:info("No metadata to process for file: " .. filePath)
        end
        return true, "No metadata to process"
    end
    
    -- Create temporary config file for UTF-8 handling
    local tempDir = LrPathUtils.parent(filePath)
    local tempConfigFile = LrPathUtils.child(tempDir, "exiftool_config_" .. os.time() .. ".txt")
    local tempOutputFile = LrPathUtils.child(tempDir, "exiftool_output_" .. os.time() .. ".txt")
    
    -- Write commands to config file in UTF-8
    local configFile = io.open(tempConfigFile, "w")
    if not configFile then
        if verboseLogging then
            logger:info("Could not create temp config file: " .. tempConfigFile)
        end
        return false, "Could not create temp config file"
    end
    
    -- Write UTF-8 BOM to ensure proper encoding
    configFile:write("\239\187\191")
    
    for _, cmd in ipairs(commands) do
        configFile:write(cmd .. "\n")
    end
    configFile:close()
    
    -- Build command using config file approach
    local args = {
        "-charset", "UTF8",
        "-overwrite_original",
        "-@", tempConfigFile,
        filePath
    }
    
    local command = '"' .. exifToolPath .. '"'
    for _, arg in ipairs(args) do
        command = command .. ' "' .. arg .. '"'
    end
    
    if verboseLogging then
        logger:info("Executing command: " .. command)
    end
    
    -- Execute command
    local success = false
    
    -- Use batch file for Windows with proper UTF-8 handling
    local tempBatFile = LrPathUtils.child(tempDir, "exiftool_cmd_" .. os.time() .. ".bat")
    
    local batContent = '@echo off\n'
    batContent = batContent .. 'chcp 65001 > nul\n'  -- Set UTF-8 code page
    batContent = batContent .. command .. ' >"' .. tempOutputFile .. '" 2>&1\n'
    
    local batFile = io.open(tempBatFile, "w")
    if batFile then
        batFile:write(batContent)
        batFile:close()
        
        local result = LrTasks.execute(tempBatFile)
        success = (result ~= nil)
        
        -- Clean up batch file
        LrFileUtils.delete(tempBatFile)
        
        if verboseLogging then
            if success then
                logger:info("Command executed successfully for: " .. filePath)
            else
                logger:info("Command execution error for: " .. filePath)
                -- Try to read error output
                if LrFileUtils.exists(tempOutputFile) then
                    local outputFile = io.open(tempOutputFile, "r")
                    if outputFile then
                        local errorOutput = outputFile:read("*all")
                        outputFile:close()
                        logger:info("Error output: " .. errorOutput)
                    end
                end
            end
        end
    else
        -- Fallback: direct execution with UTF-8 charset parameter
        local result = LrTasks.execute(command)
        success = (result ~= nil)
        
        if verboseLogging then
            logger:info("Command executed " .. (success and "successfully" or "with error") .. " for: " .. filePath)
        end
    end
    
    -- Clean up temporary files
    if LrFileUtils.exists(tempConfigFile) then
        LrFileUtils.delete(tempConfigFile)
    end
    if LrFileUtils.exists(tempOutputFile) then
        LrFileUtils.delete(tempOutputFile)
    end
    
    return success, success and "Metadata processed" or "Processing error"
end

-- Create settings interface using the separate module
function ExportFilterProvider.sectionForFilterInDialog(f, propertyTable)
    -- Initialize property table and load settings
    ExportDialogSettings.initializePropertyTable(propertyTable)
    
    -- Set up observers to save settings when changed
    ExportDialogSettings.setupObservers(propertyTable)
    
    -- Return the UI section
    return ExportDialogSettings.createUISection(f)
end

-- Main processing function
function ExportFilterProvider.postProcessRenderedPhotos(functionContext, filterContext)
    local prefs = LrPrefs.prefsForPlugin()
    local verboseLogging = prefs.verboseLogging or false
    local exportSettings = filterContext.propertyTable
    
    -- Get template settings from export dialog (now saved in prefs)
    local enableTemplateProcessing = exportSettings.enableTemplateProcessing or false
    local titleTemplate = exportSettings.titleTemplate or ""
    local captionTemplate = exportSettings.captionTemplate or ""
    local enableAsciiConversion = exportSettings.enableAsciiConversion
    if enableAsciiConversion == nil then enableAsciiConversion = true end -- Default to enabled for backward compatibility
    
    if verboseLogging then
        logger:info("Starting processing of exported files")
        logger:info("Template processing enabled: " .. tostring(enableTemplateProcessing))
        logger:info("ASCII conversion enabled: " .. tostring(enableAsciiConversion))
        if enableTemplateProcessing then
            logger:info("Title template: '" .. titleTemplate .. "'")
            logger:info("Caption template: '" .. captionTemplate .. "'")
        end
    end
    
    for rendition in filterContext:renditions() do
        if not rendition.wasSkipped then
            local success, pathOrMessage = rendition:waitForRender()
            
            if success then
                local photo = rendition.photo
                local filePath = pathOrMessage
                
                if verboseLogging then
                    logger:info("Processing file: " .. filePath)
                end
                
                -- Get original metadata
                local originalTitle = photo:getFormattedMetadata('title') or ""
                local originalCaption = photo:getFormattedMetadata('caption') or ""
                
                local keywordTags = photo:getRawMetadata('keywords') or {}
                local keywords = ""
                if type(keywordTags) == "table" and #keywordTags > 0 then
                    local keywordList = {}
                    for _, keyword in ipairs(keywordTags) do
                        table.insert(keywordList, keyword:getName())
                    end
                    keywords = table.concat(keywordList, ", ")
                end
                
                -- Process templates if enabled
                local processedTitle = originalTitle
                local processedCaption = originalCaption
                local templateProcessed = false
                
                if enableTemplateProcessing then
                    if titleTemplate and titleTemplate ~= "" then
                        processedTitle = MetadataTemplateProcessor.processTemplate(titleTemplate, photo)
                        templateProcessed = true
                        if verboseLogging then
                            logger:info("Title processed with template: '" .. originalTitle .. "' -> '" .. processedTitle .. "'")
                        end
                    end
                    
                    if captionTemplate and captionTemplate ~= "" then
                        processedCaption = MetadataTemplateProcessor.processTemplate(captionTemplate, photo)
                        templateProcessed = true
                        if verboseLogging then
                            logger:info("Caption processed with template: '" .. originalCaption .. "' -> '" .. processedCaption .. "'")
                        end
                    end
                end
                
                if verboseLogging then
                    logger:info("Final metadata - Title: '" .. processedTitle .. "', Caption: '" .. processedCaption .. "', Keywords: '" .. keywords .. "'")
                end
                
                -- Process with ExifTool (will handle both template processing and ASCII conversion)
                -- Only process if we have templates enabled or if there's metadata that might need processing
                if templateProcessed or processedTitle ~= "" or processedCaption ~= "" or keywords ~= "" then
                    local result, message = processWithExifTool(filePath, processedTitle, processedCaption, keywords, enableAsciiConversion, verboseLogging)
                    
                    if verboseLogging then
                        logger:info("Processing result: " .. (result and "success" or "error") .. " - " .. message)
                    end
                end
            else
                if verboseLogging then
                    logger:info("File skipped due to rendering error: " .. (pathOrMessage or "unknown error"))
                end
            end
        end
    end
    
    if verboseLogging then
        logger:info("Processing completed")
    end
end

return ExportFilterProvider