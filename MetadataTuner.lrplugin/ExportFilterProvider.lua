local LrTasks = import 'LrTasks'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
-- Import modules
local MetadataTemplateProcessor = require 'MetadataTemplateProcessor'
local ExportDialogSettings = require 'ExportDialogSettings'
local MetadataRemover = require 'MetadataRemover'
local AsciiConverter = require 'AsciiConverter'

local ExportFilterProvider = {}

-- Function to properly escape command line arguments for Windows cmd.exe
local function escapeArgument(arg)
    -- Simple approach: wrap in double quotes and escape internal quotes with \"
    local escaped = string.gsub(arg, '"', '\\"')
    return '"' .. escaped .. '"'
end

-- Function to process with ExifTool directly, without temporary files
local function processWithExifTool(filePath, title, caption, enableAsciiConversion)
    local exifToolPath = ExportDialogSettings.getExifToolPath()
    if not exifToolPath then
        return false, "ExifTool not found. Please specify path in plugin preferences."
    end

    local commandArgs = {}
    
    -- Process title
    if title and title ~= "" then
        local finalTitle = enableAsciiConversion and AsciiConverter.convertToAscii(title) or title
        table.insert(commandArgs, escapeArgument("-Title=" .. finalTitle))
        table.insert(commandArgs, escapeArgument("-XMP-dc:Title=" .. finalTitle))
        table.insert(commandArgs, escapeArgument("-IPTC:ObjectName=" .. finalTitle))
    end
    
    -- Process caption
    if caption and caption ~= "" then
        local finalCaption = enableAsciiConversion and AsciiConverter.convertToAscii(caption) or caption
        table.insert(commandArgs, escapeArgument("-Description=" .. finalCaption))
        table.insert(commandArgs, escapeArgument("-XMP-dc:Description=" .. finalCaption))
        table.insert(commandArgs, escapeArgument("-IPTC:Caption-Abstract=" .. finalCaption))
        table.insert(commandArgs, escapeArgument("-EXIF:ImageDescription=" .. finalCaption))
    end
    
    -- If no metadata to change, do nothing
    if #commandArgs == 0 then
        return true, "No metadata to process"
    end
    
    -- Build the full ExifTool command
    local exiftoolCommand = escapeArgument(exifToolPath)
    
    local baseArgs = {
        escapeArgument("-charset=UTF8"),
        escapeArgument("-overwrite_original")
    }
    
    -- Combine all arguments
    local allArgs = table.concat(baseArgs, " ") .. " " .. table.concat(commandArgs, " ") .. " " .. escapeArgument(filePath)
    
    -- Construct the final command to be executed via cmd.exe to handle UTF-8
    -- 'chcp 65001 > nul' sets the codepage to UTF-8
    local finalCommand = 'cmd /c "chcp 65001 > nul && ' .. exiftoolCommand .. ' ' .. allArgs .. '"'
    
    -- Execute the command
    local result = LrTasks.execute(finalCommand)
    local success = (result ~= nil)
    local message = ""

    if success then
        message = "Metadata processed successfully."
    else
        message = "Processing error: ExifTool command execution failed."
    end
    
    return success, message
end

-- Create settings interface using the separate module
function ExportFilterProvider.sectionForFilterInDialog(f, propertyTable)
    -- Initialize default values only if they are not set
    ExportDialogSettings.initializePropertyTable(propertyTable)
    
    -- Return the UI section
    return ExportDialogSettings.createUISection(f)
end

-- Specify which fields should be saved in presets
function ExportFilterProvider.hideSections(propertyTable)
    return {}
end

function ExportFilterProvider.startDialog(propertyTable)
    -- Initialize default values when creating new preset
    ExportDialogSettings.initializePropertyTable(propertyTable)
end

-- Main processing function
function ExportFilterProvider.postProcessRenderedPhotos(functionContext, filterContext)
    local exportSettings = ExportDialogSettings.getExportSettings(filterContext.propertyTable)
    
    -- Get settings from export dialog
    local enableTemplateProcessing = exportSettings.enableTemplateProcessing
    local titleTemplate = exportSettings.titleTemplate
    local captionTemplate = exportSettings.captionTemplate
    local enableAsciiConversion = exportSettings.enableAsciiConversion
    local enableCrsDataRemoval = exportSettings.enableCrsDataRemoval
    local enableSoftwareInfoRemoval = exportSettings.enableSoftwareInfoRemoval
    local enableLocationInfoRemoval = exportSettings.enableLocationInfoRemoval
    local enableEquipmentInfoRemoval = exportSettings.enableEquipmentInfoRemoval
    local enableShootingInfoRemoval = exportSettings.enableShootingInfoRemoval
    local enableIptcInfoRemoval = exportSettings.enableIptcInfoRemoval
    
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
                
                -- Process with ExifTool (handles template processing and ASCII conversion)
                if templateProcessed or processedTitle ~= "" or processedCaption ~= "" then
                    local result, message = processWithExifTool(filePath, processedTitle, processedCaption, enableAsciiConversion)
                    -- You might want to add logging for 'message' here if needed
                end
                
                -- Remove metadata if any removal options are enabled
                if enableCrsDataRemoval or enableSoftwareInfoRemoval or enableLocationInfoRemoval or enableEquipmentInfoRemoval or enableShootingInfoRemoval or enableIptcInfoRemoval then
                    local exifToolPath = ExportDialogSettings.getExifToolPath()
                    if exifToolPath then
                        local removalOptions = {
                            removeCrsData = enableCrsDataRemoval,
                            removeSoftwareInfo = enableSoftwareInfoRemoval,
                            removeLocationInfo = enableLocationInfoRemoval,
                            removeEquipmentInfo = enableEquipmentInfoRemoval,
                            removeShootingInfo = enableShootingInfoRemoval,
                            removeIptcInfo = enableIptcInfoRemoval
                        }
                        local removalResult, removalMessage = MetadataRemover.removeMetadata(filePath, exifToolPath, removalOptions)
                        -- You might want to add logging for 'removalMessage' here if needed
                    end
                end
            end
        end
    end
end

return ExportFilterProvider