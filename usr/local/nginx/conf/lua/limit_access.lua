local ip_block_time=10 --封禁IP时间（秒）
local ip_time_out=300    --指定ip访问频率时间段（秒）
local ip_max_count=10 --指定ip访问频率计数最大值（次）
local BUSINESS = ngx.var.business --nginx的location中定义的业务标识符

--连接redis
local redis = require "resty.redis"  
local conn = redis:new()  
ok, err = conn:connect("172.19.2.2", 6379)  
conn:set_timeout(2000) --超时时间2秒

local count, err = conn:get_reused_times()
if 0 == count then
    ok, err = conn:auth("OTUyZGIzYjJhNTE2M2")
    if not ok then
        ngx.log(ngx.ERR, "failed to auth:", err)
        --ngx.say("failed to auth: ", err)
        --ngx.log(ngx.INFO, " string:", str)
        goto FLAG
    end
elseif err then
    ngx.log(ngx.ERR, "failed to get reused times:", err)
    goto FLAG
end

--如果连接失败，跳转到脚本结尾
if not ok then
    goto FLAG
end

--查询ip是否被禁止访问，如果存在则返回403错误代码
is_block, err = conn:get(BUSINESS.."-BLOCK-"..ngx.var.remote_addr)  
if is_block == '1' then
    ngx.exit(403)
    goto FLAG
end

--查询redis中保存的ip计数器
ip_count, err = conn:get(BUSINESS.."-COUNT-"..ngx.var.remote_addr)

if ip_count == ngx.null then --如果不存在，则将该IP存入redis，并将计数器设置为1、该KEY的超时时间为ip_time_out
    res, err = conn:set(BUSINESS.."-COUNT-"..ngx.var.remote_addr, 1)
	res, err = conn:expire(BUSINESS.."-COUNT-"..ngx.var.remote_addr, ip_time_out)
else
    ip_count = ip_count + 1 --存在则将单位时间内的访问次数加1
  
    if ip_count > ip_max_count then --如果超过单位时间限制的访问次数，则添加限制访问标识，限制时间为ip_block_time
        res, err = conn:set(BUSINESS.."-BLOCK-"..ngx.var.remote_addr, 1)
        res, err = conn:expire(BUSINESS.."-BLOCK-"..ngx.var.remote_addr, ip_block_time)
	else
        res, err = conn:set(BUSINESS.."-COUNT-"..ngx.var.remote_addr,ip_count)
		res, err = conn:expire(BUSINESS.."-COUNT-"..ngx.var.remote_addr, ip_time_out)
    end
end

-- 结束标记
::FLAG::
local ok, err = conn:close()
