local LrTasks = import 'LrTasks'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'

-- Import modules
local MetadataTemplateProcessor = require 'MetadataTemplateProcessor'
local ExportDialogSettings = require 'ExportDialocal LrTasks = import 'LrTasks'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
-- Import modules
local MetadataTemplateProcessor = require 'MetadataTemplateProcessor'
local ExportDialogSettings = require 'ExportDialogSettings'
local ExportFilterProvider = {}
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
-- Function to process with ExifTool
local function processWithExifTool(filePath, title, caption, enableAsciiConversion)
    local exifToolPath = ExportDialogSettings.getExifToolPath()
    if not exifToolPath then
        return false, "ExifTool not found. Please specify path in plugin preferences."
    end
    
    local hasChanges = false
    local commands = {}
    
    -- Process title
    if title and title ~= "" then
        local finalTitle = title
        
        if enableAsciiConversion then
            finalTitle = convertToAscii(title)
        end
        
        table.insert(commands, "-Title=" .. finalTitle)
        -- table.insert(commands, "-XMP-dc:Title=" .. finalTitle)
        -- table.insert(commands, "-IPTC:ObjectName=" .. finalTitle)
        hasChanges = true
    end
    
    -- Process caption
    if caption and caption ~= "" then
        local finalCaption = caption
        
        if enableAsciiConversion then
            finalCaption = convertToAscii(caption)
        end
        
        table.insert(commands, "-Description=" .. finalCaption)
        -- table.insert(commands, "-XMP-dc:Description=" .. finalCaption)
        -- table.insert(commands, "-IPTC:Caption-Abstract=" .. finalCaption)
        -- table.insert(commands, "-EXIF:ImageDescription=" .. finalCaption)
        -- table.insert(commands, "-XMP-exif:UserComment=" .. finalCaption)
        hasChanges = true
    end
    
    
    if not hasChanges then
        return true, "No metadata to process"
    end
    
    -- Create temporary config file for UTF-8 handling
    local tempDir = LrPathUtils.parent(filePath)
    local tempConfigFile = LrPathUtils.child(tempDir, "exiftool_config_" .. os.time() .. ".txt")
    local tempOutputFile = LrPathUtils.child(tempDir, "exiftool_output_" .. os.time() .. ".txt")
    
    -- Write commands to config file in UTF-8
    local configFile = io.open(tempConfigFile, "w")
    if not configFile then
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
    else
        -- Direct execution with UTF-8 charset parameter
        local result = LrTasks.execute(command)
        success = (result ~= nil)
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
    -- Инициализировать значения по умолчанию только если они не установлены
    ExportDialogSettings.initializePropertyTable(propertyTable)
    
    -- Return the UI section
    return ExportDialogSettings.createUISection(f)
end
-- Указать какие поля должны сохраняться в пресетах
function ExportFilterProvider.hideSections(propertyTable)
    return {}
end
function ExportFilterProvider.startDialog(propertyTable)
    -- Инициализация значений по умолчанию при создании нового пресета
    ExportDialogSettings.initializePropertyTable(propertyTable)
end
-- Поля для сохранения в пресетах теперь определены в info.lua
-- Main processing function
function ExportFilterProvider.postProcessRenderedPhotos(functionContext, filterContext)
    local exportSettings = ExportDialogSettings.getExportSettings(filterContext.propertyTable)
    
    -- Get template settings from export dialog
    local enableTemplateProcessing = exportSettings.enableTemplateProcessing
    local titleTemplate = exportSettings.titleTemplate
    local captionTemplate = exportSettings.captionTemplate
    local enableAsciiConversion = exportSettings.enableAsciiConversion
    if enableAsciiConversion == nil then 
        enableAsciiConversion = true 
    end -- Default to enabled for backward compatibility
    
    for rendition in filterContext:renditions() do
        if not rendition.wasSkipped then
            local success, pathOrMessage = rendition:waitForRender()
            
            if success then
                local photo = rendition.photo
                local filePath = pathOrMessage
                
                local originalTitle = photo:getFormattedMetadata('title') or ""
                local originalCaption = photo:getFormattedMetadata('caption') or ""
                
                -- Process templates if enabled
                local processedTitle = originalTitle
                local processedCaption = originalCaption
                local templateProcessed = false
                
                if enableTemplateProcessing then
                    if titleTemplate and titleTemplate ~= "" then
                        processedTitle = MetadataTemplateProcessor.processTemplate(titleTemplate, photo)
                        templateProcessed = true
                    end
                    
                    if captionTemplate and captionTemplate ~= "" then
                        processedCaption = MetadataTemplateProcessor.processTemplate(captionTemplate, photo)
                        templateProcessed = true
                    end
                end
                
                -- Process with ExifTool (will handle both template processing and ASCII conversion)
                -- Only process if we have templates enabled or if there's metadata that might need processing
                if templateProcessed or processedTitle ~= "" or processedCaption ~= "" then
                    local result, message = processWithExifTool(filePath, processedTitle, processedCaption, enableAsciiConversion)
                end
            end
        end
    end
end
return ExportFilterProviderlogSettings'

local ExportFilterProvider = {}

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

-- Function to process with ExifTool
local function processWithExifTool(filePath, title, caption, keywords, enableAsciiConversion)
    local exifToolPath = ExportDialogSettings.getExifToolPath()
    if not exifToolPath then
        return false, "ExifTool not found. Please specify path in plugin preferences."
    end
    
    local hasChanges = false
    local commands = {}
    
    -- Process title
    if title and title ~= "" then
        local finalTitle = title
        
        if enableAsciiConversion then
            finalTitle = convertToAscii(title)
        end
        
        table.insert(commands, "-Title=" .. finalTitle)
        table.insert(commands, "-XMP-dc:Title=" .. finalTitle)
        table.insert(commands, "-IPTC:ObjectName=" .. finalTitle)
        hasChanges = true
    end
    
    -- Process caption
    if caption and caption ~= "" then
        local finalCaption = caption
        
        if enableAsciiConversion then
            finalCaption = convertToAscii(caption)
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
        
        if enableAsciiConversion then
            finalKeywords = convertToAscii(keywords)
        end
        
        table.insert(commands, "-Keywords=" .. finalKeywords)
        table.insert(commands, "-XMP-dc:Subject=" .. finalKeywords)
        table.insert(commands, "-IPTC:Keywords=" .. finalKeywords)
        hasChanges = true
    end
    
    if not hasChanges then
        return true, "No metadata to process"
    end
    
    -- Create temporary config file for UTF-8 handling
    local tempDir = LrPathUtils.parent(filePath)
    local tempConfigFile = LrPathUtils.child(tempDir, "exiftool_config_" .. os.time() .. ".txt")
    local tempOutputFile = LrPathUtils.child(tempDir, "exiftool_output_" .. os.time() .. ".txt")
    
    -- Write commands to config file in UTF-8
    local configFile = io.open(tempConfigFile, "w")
    if not configFile then
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
    else
        -- Fallback: direct execution with UTF-8 charset parameter
        local result = LrTasks.execute(command)
        success = (result ~= nil)
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
    -- Инициализировать значения по умолчанию только если они не установлены
    ExportDialogSettings.initializePropertyTable(propertyTable)
    
    -- Return the UI section
    return ExportDialogSettings.createUISection(f)
end

-- Указать какие поля должны сохраняться в пресетах
function ExportFilterProvider.hideSections(propertyTable)
    return {}
end

function ExportFilterProvider.startDialog(propertyTable)
    -- Инициализация значений по умолчанию при создании нового пресета
    ExportDialogSettings.initializePropertyTable(propertyTable)
end

-- Поля для сохранения в пресетах теперь определены в info.lua

-- Main processing function
function ExportFilterProvider.postProcessRenderedPhotos(functionContext, filterContext)
    local exportSettings = ExportDialogSettings.getExportSettings(filterContext.propertyTable)
    
    -- Get template settings from export dialog
    local enableTemplateProcessing = exportSettings.enableTemplateProcessing
    local titleTemplate = exportSettings.titleTemplate
    local captionTemplate = exportSettings.captionTemplate
    local enableAsciiConversion = exportSettings.enableAsciiConversion
    if enableAsciiConversion == nil then 
        enableAsciiConversion = true 
    end -- Default to enabled for backward compatibility
    
    for rendition in filterContext:renditions() do
        if not rendition.wasSkipped then
            local success, pathOrMessage = rendition:waitForRender()
            
            if success then
                local photo = rendition.photo
                local filePath = pathOrMessage
                
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
                    end
                    
                    if captionTemplate and captionTemplate ~= "" then
                        processedCaption = MetadataTemplateProcessor.processTemplate(captionTemplate, photo)
                        templateProcessed = true
                    end
                end
                
                -- Process with ExifTool (will handle both template processing and ASCII conversion)
                -- Only process if we have templates enabled or if there's metadata that might need processing
                if templateProcessed or processedTitle ~= "" or processedCaption ~= "" or keywords ~= "" then
                    local result, message = processWithExifTool(filePath, processedTitle, processedCaption, keywords, enableAsciiConversion)
                end
            end
        end
    end
end

return ExportFilterProvider
