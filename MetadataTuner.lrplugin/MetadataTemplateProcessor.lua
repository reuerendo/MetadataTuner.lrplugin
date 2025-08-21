local LrDate = import 'LrDate'
local LrStringUtils = import 'LrStringUtils'

local MetadataTemplateProcessor = {}

-- Function to get date components from photo
local function getDateComponents(photo)
    local dateTimeOriginal = photo:getRawMetadata('dateTimeOriginal')
    local dateTime = photo:getRawMetadata('dateTime')
    local captureTime = dateTimeOriginal or dateTime

    if not captureTime then
        return {}
    end

    -- Try to get formatted date string first (safest approach)
    local formattedDate = photo:getFormattedMetadata('dateTimeOriginal') or photo:getFormattedMetadata('dateTime')
    
    if formattedDate then
        -- Parse date components from formatted date string
        -- Handle various date formats: MM/DD/YYYY, YYYY-MM-DD, DD.MM.YYYY, etc.
        local year, month, day
        
        -- Try different date formats
        year, month, day = formattedDate:match("(%d%d%d%d)-(%d%d)-(%d%d)")  -- YYYY-MM-DD
        if not year then
            month, day, year = formattedDate:match("(%d%d)/(%d%d)/(%d%d%d%d)")  -- MM/DD/YYYY
        end
        if not year then
            day, month, year = formattedDate:match("(%d%d)%.(%d%d)%.(%d%d%d%d)")  -- DD.MM.YYYY
        end
        if not year then
            day, month, year = formattedDate:match("(%d%d)/(%d%d)/(%d%d%d%d)")  -- DD/MM/YYYY
        end
        if not year then
            -- Try to extract year, month, day separately if combined patterns fail
            year = formattedDate:match("(%d%d%d%d)")
            if year then
                -- Look for month and day patterns near the year
                local dateOnly = formattedDate:match("([%d/%-%.]+)")
                if dateOnly then
                    local parts = {}
                    for part in dateOnly:gmatch("(%d+)") do
                        table.insert(parts, part)
                    end
                    
                    if #parts >= 3 then
                        -- Determine format based on year position
                        if parts[1] == year then
                            -- YYYY-MM-DD format
                            month, day = parts[2], parts[3]
                        elseif parts[3] == year then
                            if tonumber(parts[1]) > 12 then
                                -- DD-MM-YYYY format
                                day, month = parts[1], parts[2]
                            else
                                -- MM-DD-YYYY format  
                                month, day = parts[1], parts[2]
                            end
                        end
                    end
                end
            end
        end
        
        if year and month and day then
            local monthNum = tonumber(month) or 1
            local dayNum = tonumber(day) or 1
            
            -- Validate parsed values
            if monthNum >= 1 and monthNum <= 12 and dayNum >= 1 and dayNum <= 31 then
                local monthNamesFull = {
                    "January", "February", "March", "April", "May", "June",
                    "July", "August", "September", "October", "November", "December"
                }

                local monthNamesShort = {
                    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
                }
                
                return {
                    YYYY = year,
                    YY = year:sub(-2),
                    MM = string.format("%02d", monthNum),
                    MMM = monthNamesShort[monthNum] or "Jan",
                    MMMM = monthNamesFull[monthNum] or "January",
                    DD = string.format("%02d", dayNum),
                    D = tostring(dayNum),
                    DDD = "Mon", -- Default values for day names
                    DDDD = "Monday",
                }
            end
        end
    end

    -- Fallback: use raw timestamp if available
    if type(captureTime) == "number" then
        local date = os.date("*t", captureTime)
        if date and date.year > 1900 then  -- Sanity check
            local monthNamesFull = {
                "January", "February", "March", "April", "May", "June",
                "July", "August", "September", "October", "November", "December"
            }

            local monthNamesShort = {
                "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
            }

            local dayNamesFull = {
                "Sunday", "Monday", "Tuesday", "Wednesday",
                "Thursday", "Friday", "Saturday"
            }

            local dayNamesShort = {
                "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"
            }

            return {
                YYYY = tostring(date.year),
                YY = tostring(date.year):sub(-2),
                MM = string.format("%02d", date.month),
                MMM = monthNamesShort[date.month] or "Jan",
                MMMM = monthNamesFull[date.month] or "January",
                DD = string.format("%02d", date.day),
                D = tostring(date.day),
                DDD = dayNamesShort[date.wday] or "Mon",
                DDDD = dayNamesFull[date.wday] or "Monday",
            }
        end
    end
    
    return {}
end

-- Function to get location metadata
local function getLocationMetadata(photo)
    return {
        City = photo:getFormattedMetadata('city') or '',
        State = photo:getFormattedMetadata('stateProvince') or '',
        Country = photo:getFormattedMetadata('country') or '',
		Sublocation = photo:getFormattedMetadata('location') or '',
    }
end

-- Function to get basic metadata
local function getBasicMetadata(photo)
    local title = photo:getFormattedMetadata('title') or ''
    local caption = photo:getFormattedMetadata('caption') or ''
    
    -- Keywords functionality removed
    
    return {
        Title = title,
        Caption = caption,
    }
end

-- Function to process template string with metadata
function MetadataTemplateProcessor.processTemplate(template, photo)
    if not template or template == "" then
        return ""
    end
    
    -- Get all metadata
    local dateComponents = getDateComponents(photo)
    local locationMetadata = getLocationMetadata(photo)
    local basicMetadata = getBasicMetadata(photo)
    
    -- Combine all metadata
    local allMetadata = {}
    for k, v in pairs(dateComponents) do
        allMetadata[k] = v
    end
    for k, v in pairs(locationMetadata) do
        allMetadata[k] = v
    end
    for k, v in pairs(basicMetadata) do
        allMetadata[k] = v
    end
    
    -- Process template
    local result = template
    
    -- Replace placeholders with actual values
    for key, value in pairs(allMetadata) do
        local placeholder = "{" .. key .. "}"
        if value and value ~= "" then
            result = result:gsub(placeholder, value)
        else
            result = result:gsub(placeholder, "")
        end
    end
    
    -- Clean up multiple spaces and trim
    result = result:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    
    -- Clean up common formatting issues
    result = result:gsub(",%s*,", ",") -- Remove empty commas
    result = result:gsub("^[,%s-]+", "") -- Remove leading commas, spaces, dashes
    result = result:gsub("[,%s-]+$", "") -- Remove trailing commas, spaces, dashes
    result = result:gsub("%s*-%s*$", "") -- Remove trailing dashes with spaces
    result = result:gsub("^%s*-%s*", "") -- Remove leading dashes with spaces
    
    return result
end

-- Function to get template help text
function MetadataTemplateProcessor.getTemplateHelp()
    return [[Available placeholders:

Date & Time:
{YYYY} - Full year (2024)
{YY} - Short year (24)
{MM} - Month with zero (01-12)
{MMM} - Short month name (Jan)
{MMMM} - Full month name (January)
{DD} - Day with zero (01-31)
{D} - Day without zero (1-31)
{DDD} - Short day name (Mon)
{DDDD} - Full day name (Monday)

Location:
{City} - City name
{State} - State/Province
{Country} - Country name
{Sublocation} - Sublocation field

Metadata:
{Title} - Photo title
{Caption} - Photo caption

Example templates:
{City}, {Country} - {MMMM} {D}, {YYYY}: {Caption}
{Sublocation} ({DD}.{MM}.{YYYY})
{Title} - {City}, {State}]]
end

return MetadataTemplateProcessor