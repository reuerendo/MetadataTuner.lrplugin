local LrTasks = import 'LrTasks'
local LrFileUtils = import 'LrFileUtils'

local MetadataRemover = {}

-- Function to properly escape command line arguments for cmd.exe
local function escapeArgument(arg)
    -- Wrap in quotes and escape any internal quotes for the command processor
    return '"' .. string.gsub(arg, '"', '""') .. '"'
end

-- Predefined command sets for each removal type (location removal section removed)
local REMOVAL_COMMANDS = {
    crs = {
        "-XMP-crs:all="
    },
    
    software = {
        "-Software=",
        "-CreatorTool=",
        "-XMP-xmp:CreatorTool=",
        "-XMP-tiff:Software=",
        "-EXIF:Software=",
        "-IPTC:By-line=",
        "-IPTC:Writer-Editor=",
        "-ProcessingSoftware=",
        "-XMP-xmp:MetadataDate=",
        "-XMP-xmp:ModifyDate=",
        "-XMP-xmpMM:all="
    },
    
    shooting = {
        -- Main shooting parameters
        "-ExposureTime=", "-ShutterSpeed=", "-ShutterSpeedValue=",
        "-FNumber=", "-Aperture=", "-ApertureValue=",
        "-ISO=", "-ISOSpeedRatings=", "-RecommendedExposureIndex=", "-SensitivityType=",
        
        -- EXIF versions
        "-EXIF:ExposureTime=", "-EXIF:ShutterSpeedValue=", "-EXIF:FNumber=", "-EXIF:ApertureValue=",
        "-EXIF:ISO=", "-EXIF:ISOSpeedRatings=", "-EXIF:RecommendedExposureIndex=", "-EXIF:SensitivityType=",
        
        -- XMP versions
        "-XMP-exif:ExposureTime=", "-XMP-exif:ShutterSpeedValue=", "-XMP-exif:FNumber=", "-XMP-exif:ApertureValue=",
        "-XMP-exif:ISOSpeedRatings=", "-XMP-exif:RecommendedExposureIndex=", "-XMP-exif:SensitivityType=",
        
        -- Resolution
        "-XResolution=", "-YResolution=", "-ResolutionUnit=",
        "-EXIF:XResolution=", "-EXIF:YResolution=", "-EXIF:ResolutionUnit=",
        "-XMP-tiff:XResolution=", "-XMP-tiff:YResolution=", "-XMP-tiff:ResolutionUnit=",
        
        -- Additional parameters
        "-FocalLength=", "-FocalLengthIn35mmFormat=", "-ExposureMode=", "-ExposureProgram=",
        "-MeteringMode=", "-Flash=", "-WhiteBalance=", "-ExposureBiasValue=", "-MaxApertureValue=",
        "-SubjectDistance=", "-SceneCaptureType=", "-GainControl=", "-Contrast=", "-Saturation=", "-Sharpness=",
        
        -- EXIF versions of additional parameters
        "-EXIF:FocalLength=", "-EXIF:FocalLengthIn35mmFormat=", "-EXIF:ExposureMode=", "-EXIF:ExposureProgram=",
        "-EXIF:MeteringMode=", "-EXIF:Flash=", "-EXIF:WhiteBalance=", "-EXIF:ExposureBiasValue=",
        "-EXIF:MaxApertureValue=", "-EXIF:SubjectDistance=", "-EXIF:SceneCaptureType=", "-EXIF:GainControl=",
        "-EXIF:Contrast=", "-EXIF:Saturation=", "-EXIF:Sharpness=",
        
        -- XMP versions of additional parameters
        "-XMP-exif:FocalLength=", "-XMP-exif:FocalLengthIn35mmFormat=", "-XMP-exif:ExposureMode=",
        "-XMP-exif:ExposureProgram=", "-XMP-exif:MeteringMode=", "-XMP-exif:Flash=", "-XMP-exif:WhiteBalance=",
        "-XMP-exif:ExposureBiasValue=", "-XMP-exif:MaxApertureValue=", "-XMP-exif:SubjectDistance=",
        "-XMP-exif:SceneCaptureType=", "-XMP-exif:GainControl=", "-XMP-exif:Contrast=",
        "-XMP-exif:Saturation=", "-XMP-exif:Sharpness="
    },
    
    equipment = {
        -- Main camera and lens information
        "-Make=", "-Model=", "-LensModel=", "-LensMake=", "-Lens=", "-LensInfo=",
        "-SerialNumber=", "-InternalSerialNumber=",
        
        -- XMP versions
        "-XMP-tiff:Make=", "-XMP-tiff:Model=", "-XMP-aux:Lens=", "-XMP-aux:LensModel=",
        "-XMP-aux:LensInfo=", "-XMP-aux:LensMake=", "-XMP-aux:SerialNumber=",
        "-XMP-exifEX:LensModel=", "-XMP-exifEX:LensMake=",
        
        -- EXIF versions
        "-EXIF:Make=", "-EXIF:Model=", "-EXIF:LensModel=", "-EXIF:LensMake=", "-EXIF:LensInfo=",
        "-EXIF:Lens=", "-EXIF:SerialNumber=", "-EXIF:CameraSerialNumber=", "-EXIF:LensSerialNumber=",
        "-EXIF:InternalSerialNumber=", "-EXIF:BodySerialNumber="
    },
    
    iptc = {
        -- Main IPTC tags
        "-IPTC:ObjectName=",
        "-IPTC:EditStatus=",
        "-IPTC:EditorialUpdate=",
        "-IPTC:Urgency=",
        "-IPTC:Subject-Reference=",
        "-IPTC:Category=",
        "-IPTC:SupplementalCategories=",
        "-IPTC:FixtureIdentifier=",
        "-IPTC:Keywords=",
        "-IPTC:ContentLocationCode=",
        "-IPTC:ContentLocationName=",
        "-IPTC:ReleaseDate=",
        "-IPTC:ReleaseTime=",
        "-IPTC:ExpirationDate=",
        "-IPTC:ExpirationTime=",
        "-IPTC:SpecialInstructions=",
        "-IPTC:ActionAdvised=",
        "-IPTC:ReferenceService=",
        "-IPTC:ReferenceDate=",
        "-IPTC:ReferenceNumber=",
        "-IPTC:DateCreated=",
        "-IPTC:TimeCreated=",
        "-IPTC:DigitalCreationDate=",
        "-IPTC:DigitalCreationTime=",
        "-IPTC:OriginatingProgram=",
        "-IPTC:ProgramVersion=",
        "-IPTC:ObjectCycle=",
        "-IPTC:By-line=",
        "-IPTC:By-lineTitle=",
        "-IPTC:City=",
        "-IPTC:Sub-location=",
        "-IPTC:Province-State=",
        "-IPTC:Country-PrimaryLocationCode=",
        "-IPTC:Country-PrimaryLocationName=",
        "-IPTC:OriginalTransmissionReference=",
        "-IPTC:Headline=",
        "-IPTC:Credit=",
        "-IPTC:Source=",
        "-IPTC:CopyrightNotice=",
        "-IPTC:Contact=",
        "-IPTC:Caption-Abstract=",
        "-IPTC:Writer-Editor=",
        "-IPTC:RasterizedCaption=",
        "-IPTC:ImageType=",
        "-IPTC:ImageOrientation=",
        "-IPTC:LanguageIdentifier=",
        "-IPTC:AudioType=",
        "-IPTC:AudioSamplingRate=",
        "-IPTC:AudioSamplingResolution=",
        "-IPTC:AudioDuration=",
        "-IPTC:AudioOutcue=",
        "-IPTC:ObjectDataPreviewFileFormat=",
        "-IPTC:ObjectDataPreviewFileFormatVersion=",
        "-IPTC:ObjectDataPreviewData=",
        
        -- XMP-iptc tags (excluding XMP-dc)
        "-XMP-iptc:CountryCode=",
        "-XMP-iptc:IntellectualGenre=",
        "-XMP-iptc:Scene=",
        "-XMP-iptc:SubjectCode=",
        "-XMP-iptc:Location=",
        "-XMP-iptc:City=",
        "-XMP-iptc:State=",
        "-XMP-iptc:Country=",
        
        -- XMP-photoshop tags
        "-XMP-photoshop:AuthorsPosition=",
        "-XMP-photoshop:CaptionWriter=",
        "-XMP-photoshop:Category=",
        "-XMP-photoshop:City=",
        "-XMP-photoshop:Country=",
        "-XMP-photoshop:Credit=",
        "-XMP-photoshop:DateCreated=",
        "-XMP-photoshop:Headline=",
        "-XMP-photoshop:Instructions=",
        "-XMP-photoshop:Source=",
        "-XMP-photoshop:State=",
        "-XMP-photoshop:SupplementalCategories=",
        "-XMP-photoshop:TransmissionReference=",
        "-XMP-photoshop:Urgency="
    }
}

-- Function for building removal commands (location removal removed)
local function buildRemovalCommands(options)
    local commands = {}
    
    if options.removeCrsData then
        for _, cmd in ipairs(REMOVAL_COMMANDS.crs) do
            table.insert(commands, cmd)
        end
    end
    
    if options.removeSoftwareInfo then
        for _, cmd in ipairs(REMOVAL_COMMANDS.software) do
            table.insert(commands, cmd)
        end
    end
    
    if options.removeShootingInfo then
        for _, cmd in ipairs(REMOVAL_COMMANDS.shooting) do
            table.insert(commands, cmd)
        end
    end
    
    if options.removeEquipmentInfo then
        for _, cmd in ipairs(REMOVAL_COMMANDS.equipment) do
            table.insert(commands, cmd)
        end
    end
    
    if options.removeIptcInfo then
        for _, cmd in ipairs(REMOVAL_COMMANDS.iptc) do
            table.insert(commands, cmd)
        end
    end
    
    return commands
end

-- Function for executing ExifTool command directly
local function executeExifTool(exifToolPath, filePath, commands)
    local commandArgs = {}
    for _, cmd in ipairs(commands) do
        table.insert(commandArgs, escapeArgument(cmd))
    end
    
    local exiftoolCommand = escapeArgument(exifToolPath)
    
    local baseArgs = {
        escapeArgument("-charset=UTF8"),
        escapeArgument("-overwrite_original")
    }
    
    -- Combine all arguments into a single command string
    local allArgs = table.concat(baseArgs, " ") .. " " .. table.concat(commandArgs, " ") .. " " .. escapeArgument(filePath)
    
    -- Construct the final command to be executed via cmd.exe
    local finalCommand = 'cmd /c "chcp 65001 > nul && ' .. exiftoolCommand .. ' ' .. allArgs .. '"'
    
    -- Execute command
    local result = LrTasks.execute(finalCommand)
    local success = (result ~= nil)
    
    local message = success and "Metadata removed successfully" or "Failed to remove metadata"
    
    return success, message
end

-- Main function for removing metadata (location removal parameter removed)
function MetadataRemover.removeMetadata(filePath, exifToolPath, options)
    -- Quick checks
    if not exifToolPath or not LrFileUtils.exists(exifToolPath) then
        return false, "ExifTool not found"
    end
    
    if not LrFileUtils.exists(filePath) then
        return false, "File not found: " .. filePath
    end
    
    -- Build commands
    local commands = buildRemovalCommands(options)
    if #commands == 0 then
        return true, "No metadata removal options selected"
    end
    
    -- Execute command directly
    return executeExifTool(exifToolPath, filePath, commands)
end

return MetadataRemover