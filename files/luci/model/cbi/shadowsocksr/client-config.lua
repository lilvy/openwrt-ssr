-- Copyright (C) 2017 yushi studio <ywb94@qq.com> github.com/ywb94
-- Licensed to the public under the GNU General Public License v3.

local m, s, o, kcp_enable
local shadowsocksr = "shadowsocksr"
local uci = luci.model.uci.cursor()
local ipkg = require("luci.model.ipkg")
local fs = require "nixio.fs"
local sys = require "luci.sys"
local sid = arg[1]

local function isKcptun(file)
    if not fs.access(file, "rwx", "rx", "rx") then
        fs.chmod(file, 755)
    end
    
    local str = sys.exec(file .. " -v | awk '{printf $1}'")
    return (str:lower() == "kcptun")
end

local server_table = {}
local encrypt_methods = {
    "table",
    "rc4",
    "rc4-md5",
    "rc4-md5-6",
    "aes-128-cfb",
    "aes-192-cfb",
    "aes-256-cfb",
    "aes-128-ctr",
    "aes-192-ctr",
    "aes-256-ctr",
    "bf-cfb",
    "camellia-128-cfb",
    "camellia-192-cfb",
    "camellia-256-cfb",
    "cast5-cfb",
    "des-cfb",
    "idea-cfb",
    "rc2-cfb",
    "seed-cfb",
    "salsa20",
    "chacha20",
    "chacha20-ietf",
}

local protocol = {
    "origin",
    "verify_simple",
    "verify_sha1",
    "auth_sha1",
    "auth_sha1_v2",
    "auth_sha1_v4",
    "auth_aes128_sha1",
    "auth_aes128_md5",
}

obfs = {
    "plain",
    "http_simple",
    "http_post",
    "tls_simple",
    "tls1.2_ticket_auth",
}

m = Map(shadowsocksr, translate("客户端 - 编辑服务器配置"))
m.redirect = luci.dispatcher.build_url("admin/network/shadowsocksr")
if m.uci:get(shadowsocksr, sid) ~= "servers" then
    luci.http.redirect(m.redirect)
    return
end

-- [[ Servers Setting ]]--
s = m:section(NamedSection, sid, "servers")
s.anonymous = true
s.addremove = false

o = s:option(Value, "alias", translate("别名（可选）"))

o = s:option(Flag, "auth_enable", translate("一次验证"))
o.rmempty = false

o = s:option(Flag, "switch_enable", translate("自动切换"))
o.rmempty = false

o = s:option(Value, "server", translate("服务器地址"))
o.datatype = "host"
o.rmempty = false

o = s:option(Value, "server_port", translate("服务器端口"))
o.datatype = "port"
o.rmempty = false

o = s:option(Value, "local_port", translate("本地端口"))
o.datatype = "port"
o.default = 1234
o.rmempty = false

o = s:option(Value, "weight", translate("负载均衡权重"))
o.datatype = "uinteger"
o.default = 10
o.rmempty = false

o = s:option(Value, "timeout", translate("连接超时"))
o.datatype = "uinteger"
o.default = 60
o.rmempty = false

o = s:option(Value, "password", translate("密码"))
o.password = true
o.rmempty = false

o = s:option(ListValue, "encrypt_method", translate("加密方式"))
for _, v in ipairs(encrypt_methods) do o:value(v) end
o.rmempty = false

o = s:option(ListValue, "protocol", translate("协议"))
for _, v in ipairs(protocol) do o:value(v) end
o.rmempty = false

o = s:option(ListValue, "obfs", translate("混淆插件"))
for _, v in ipairs(obfs) do o:value(v) end
o.rmempty = false

o = s:option(Value, "obfs_param", translate("混淆参数（可选）"))

o = s:option(Flag, "fast_open", translate("TCP 快速打开"))
o.rmempty = false

kcp_enable = s:option(Flag, "kcp_enable", translate("KcpTun 启用"), translate("二进制文件：/usr/bin/ssr-kcptun"))
kcp_enable.rmempty = false

o = s:option(Value, "kcp_port", translate("KcpTun 端口"))
o.datatype = "port"
o.default = 4000
function o.validate(self, value, section)
    local kcp_file = "/usr/bin/ssr-kcptun"
    local enable = kcp_enable:formvalue(section) or kcp_enable.disabled
    if enable == kcp_enable.enabled then
        if not fs.access(kcp_file) then
            return nil, translate("Kcptun 可执行文件不存在，请下载 Kcptun 可执行文件并改名放入 /usr/bin/ssr-kcptun")
        elseif not isKcptun(kcp_file) then
            return nil, translate("Kcptun 可执行文件格式不正确，请确认是否正确下载了路由器对应的可执行文件")
        end
    end
    
    return value
end

o = s:option(Value, "kcp_password", translate("KcpTun 密码"))
o.password = true

o = s:option(Value, "kcp_param", translate("KcpTun 参数"))
o.default = "--nocomp"

return m
