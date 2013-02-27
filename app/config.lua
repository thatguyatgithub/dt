-- user-defined configuration 
--
-- Deliver shortens over SSL resources (yes/no)
-- recommended - helps avoiding hijacks
--
local useSSL        = false

-- Force shortens resources to be served under this domain (example.com/default)
--
local useDomain     = 'dt.im.org.ar'

-- 
-- >>>>>>>>>>>>>>  STOP EDITING HERE   <<<<<<<<<<<<<<<
--

-- init module engine
-- 
module(...)

function getDomain( currentDomain )
    if not useDomain then
        useDomain   = currentDomain
    end
        
    if useSSL   then
        return ('https://' .. useDomain)
    else
        return ('http://' ..  useDomain)
    end
end
