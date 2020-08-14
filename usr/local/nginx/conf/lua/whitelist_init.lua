local iputils = require("resty.iputils")
iputils.enable_lrucache()
local whitelist_ips = {
	"127.0.0.1",
	"172.19.0.0/16",
}

whitelist = iputils.parse_cidrs(whitelist_ips)