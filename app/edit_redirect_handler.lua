-- helpers definitions
--
local gmatch        = string.gmatch
local utils         = require 'utils'

-- static definitions
--
local uri           = ngx.var.uri
local config        = require 'config'
local useDomain     = config.getDomain(ngx.req.get_headers()['Host'])
local newhost       = ngx.req.get_uri_args(1)['newhost'] 

-- initiate GET /edit validator
--
ngx.header.content_type = 'text/html';

for k, e in gmatch(uri, '/edit/([a-z0-9A-Z]+)/([a-z0-9A-Z]+)$') do
    key     = k
    keyEdit = e
    ngx.log(ngx.ERR, "key is: " .. key .. " | Edit key is: " .. keyEdit)
end

if keyEdit == nil then
    -- It's not a valid Shorten Edit Resource key, die now biatch
    ngx.status = ngx.HTTP_GONE
    ngx.say(uri, ': You provided an invalid redirect/edit keys.')
    ngx.log(ngx.ERR, 'Invalid redirect/edit keys. Provided: ', uri)
    ngx.exit(ngx.HTTP_OK)
end

-- initialize redis
--
local redis = require 'redis'
local red = redis:new()
red:set_timeout(100)  -- in miliseconds

local ok, err = red:connect('127.0.0.1', 6379)
if not ok then
    ngx.log(ngx.ERR, 'failed to connect: ', err)
    return
end

-- Main process
--
local res, err = red:hmget(key, 'keyEdit', 'host')
if not res then
    ngx.log(ngx.ERR, 'failed to get: ', res, err)
    return
end

if res == ngx.null or res[1] == ngx.null then
    ngx.log(ngx.ERR, ngx.var.remote_addr, 
            ':: ERR Stage I :: Invalid redirection key: ', key)
    return ngx.redirect('https://duckduckgo.com/?q=Looking+For+Something?', 
            ngx.HTTP_MOVED_TEMPORARILY)
else
    if res[1] ~= keyEdit then
        ngx.log(ngx.ERR, ngx.var.remote_addr, 
                ':: ERR Stage II :: Invalid modification key: ', keyEdit)
        return ngx.redirect('https://duckduckgo.com/?q=Looking+For+Something?',
                ngx.HTTP_MOVED_TEMPORARILY)
    end
end

-- Up this moment, we have a valid set of credentials
if newhost == nil then
    ngx.log(ngx.ERR, ngx.var.remote_addr, ': Requested modification for ', uri)
    ngx.say('<html> <head> <meta charset="utf-8"> <title>DT - URL shortening Service</title> <link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/2.1.1/css/bootstrap.min.css"> </head> <body style="padding-top: 50px;"> <div class="container"> <form id="form" action="/edit/', key, '/', keyEdit, '" method="get" class="form-horizontal form-inline"> <div class="input-append"> <input type="text" id="newhost" name="newhost" class="input-xxlarge input-block-level" placeholder="Insert the NEW url redirection here"/> <button class="btn btn-short btn-primary" type="submit">Load</button> </div> </form> </div> </body> </html>')

elseif type(newhost) == string or 
    string.find(string.lower(newhost), '^https?://') then

    ok, err = red:hmset(key, 'host', newhost, 'keyEdit', keyEdit, 'mtime', os.time(), 'ip', ngx.var.remote_addr, 'orig_headers', utils.tabletostr(ngx.req.get_headers()))
    if not ok then
        ngx.say('failed to storage candidate redirection hash: ', err)
        return
    else
        return ngx.redirect(utils.buildURL(useDomain, key, 'view', keyEdit), ngx.HTTP_MOVED_TEMPORARILY)
    end
else
    ngx.status = ngx.HTTP_GONE
    ngx.say('Invalid new redirection host: ', newhost )
    ngx.log(ngx.ERR, 'Invalid new redirection host: ', newhost )
    ngx.exit(ngx.HTTP_OK)
end
