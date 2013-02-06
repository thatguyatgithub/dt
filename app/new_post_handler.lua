-- Param definitions
--
local math  = math
local len   = string.len
local sub   = string.sub

local BASE          = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
local BASE_lenght   = len(BASE)

-- Local functions
--
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

function tabletostr(s)
    local t = { }
    for k,v in pairs(s) do
        t[#t+1] = k .. ':' .. v
    end
    return table.concat(t,'|')
end

-- Init random seed
--
local key        = baseEncode(math.random(56800235584))
local keyEdit    = baseEncode(math.random(989989961727)) -- higher trigers interval is empty at 'random' 

-- Initialize redis
--
local redis = require 'resty.redis'
local red = redis:new()
red:set_timeout(100)  -- in miliseconds

local ok, err = red:connect('127.0.0.1', 6379)
if not ok then
    ngx.log(ngx.ERR, 'failed to connect: ', err)
    return
end

-- Parse POST body
--
ngx.header.content_type = 'text/html';
ngx.req.read_body()
local args              = ngx.req.get_post_args(1000)

if args['host'] == null or 
   args['host'] == ngx.null or
   string.find(string.lower(args['host']), 'https?://') == nil then

   -- It's not a HTTP Resource, die now biatch
   ngx.status = ngx.HTTP_GONE
   ngx.say(args['host'], ': You provided an invalid redirection (target is not a hypertext resource).')
   ngx.log(ngx.ERR, 'Resource was not a HTTP link (http nor https). Resource provided: ', args['host'])
   ngx.exit(ngx.HTTP_OK)
end

ok, err = red:hmset(key, 'host', args['host'], 'ctime', os.time(), 'ip', ngx.var.remote_addr, 'orig_headers', tabletostr(ngx.req.get_headers()))
if not ok then
    ngx.say('failed to storage candidate hash: ', err)
    return
else
    ok, err = red:hset(keyEdit, 'srckey', key)
    if not ok then
        ngx.say('failed to storage candidate hash edition: ', err)
        return
    else
        return ngx.redirect('http://localhost/view/' .. key .. '/' .. keyEdit, ngx.HTTP_MOVED_TEMPORARILY)
    end
end