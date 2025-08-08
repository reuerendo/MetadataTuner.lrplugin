local AsciiConverter = {}

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

-- Function to convert text to ASCII
function AsciiConverter.convertToAscii(text)
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

return AsciiConverter