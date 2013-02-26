-- helpers definitions
--
local gmatch        = string.gmatch
local utils         = require 'utils'
local string        = string

-- static definitions
--
local uri           = ngx.var.uri
local virtualhost   = ngx.req.get_headers()['Host']


-- initiate GET /view validator
--
ngx.header.content_type = 'text/html';

for k, e in gmatch(uri, '/view/([a-z0-9A-Z]+)/([a-z0-9A-Z]+)$') do
    key     = k
    keyEdit = e
    ngx.log(ngx.ERR, "key is: " .. key .. " | Edit key is: " .. keyEdit)
end

if keyEdit == nil then
    -- Since lua lacks POSIX regex, we have to go by two pattern matching.
    -- So if !keyEdit -> launch another pattern matching to get 'key'  
    for k, e in gmatch(uri, '/view/([a-z0-9A-Z]+)$') do
        key     = k
        ngx.log(ngx.ERR, "key is: " .. key)
    end
end

if key == nil then
    -- It's not a valid Shorten View Resource key, die now biatch
    ngx.status = ngx.HTTP_GONE
    ngx.say(uri, ': You provided an invalid redirection (target mismatch).')
    ngx.log(ngx.ERR, 'Resource was not an HTTP link (http nor https). Resource provided: ', uri)
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

-- main process
--
local res, err = red:hget(key, 'host')
if not res then
    ngx.log(ngx.ERR, 'failed to get: ', res, err)
    return
end

if  res == ngx.null or type(res) == null then
    ngx.log(ngx.ERR, 'failed to get redirection for key: ', key)
    return ngx.redirect('https://duckduckgo.com/?q=Looking+For+Something?', ngx.HTTP_MOVED_TEMPORARILY)
else
    red:hset(key, 'atime', os.time())
    red:hincrby(key, 'requested', 1)
    ngx.header['X-DT-Redirect-ctime'] = red:hget(key, 'ctime')
    ngx.header['X-DT-Redirect-Requested'] = red:hget(key, 'requested')

    if keyEdit == nil then
        local view_content = utils.readFile(ngx.var.view_html)
        ngx.say(string.format(view_content, ngx.var.base_url, key, ngx.var.base_url, key, res, res))
    else
        local eURL = utils.buildURL(virtualhost, key, 'edit', keyEdit)
        local view_and_edit_content = utils.readFile(ngx.var.view_and_edit_html)
        ngx.say(string.format(view_and_edit_content, ngx.var.base_url, key, ngx.var.base_url, key, res, res, eURL, eURL))
    end
end
