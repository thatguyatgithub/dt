-- local definitions
--
local math          = math
local pairs         = pairs
local sub           = string.sub
local len           = string.len 
local concat        = table.concat

local BASE          = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
local BASE_lenght   = len(BASE)

-- init module engine
-- 
module(...)

-- helper functions
--
function tabletostr(s)
    local t = { }
    for k,v in pairs(s) do
        t[#t+1] = k .. ':' .. v
    end
    return concat(t,'|')
end

function buildURL(domain, key, role, keyEdit)
    local temporalURL = 'http://' .. domain  
    if role then 
        temporalURL = temporalURL .. '/' .. role 
    end ; temporalURL = temporalURL .. '/' .. key ; 
    if keyEdit then 
        temporalURL = temporalURL .. '/' .. keyEdit
    end
    return temporalURL
end


local function divmod(x, y)
    return math.floor(x/y), x%y 
end

function baseEncode(num)
    encoding = ''
    local rem 
    while num ~= 0 do
        num, rem = divmod(num, BASE_lenght)
        encoding = encoding .. sub(BASE, rem, rem)
    end 
    return encoding
end
