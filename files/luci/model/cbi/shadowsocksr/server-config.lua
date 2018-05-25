-- Copyright (C) 2017 yushi studio <ywb94@qq.com>
-- Licensed to the public under the GNU General Public License v3.

local m, s, o
local shadowsocksr = "shadowsocksr"
local sid = arg[1]

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
}

obfs = {
    "plain",
    "http_simple",
    "http_post",
    "tls1.2_ticket_auth",
}

m = Map(shadowsocksr, translate("服务器 - 编辑服务器配置"))

m.redirect = luci.dispatcher.build_url("admin/network/shadowsocksr/server")
if m.uci:get(shadowsocksr, sid) ~= "server_config" then
    luci.http.redirect(m.redirect)
    return
end

-- [[ Server Setting ]]--
s = m:section(NamedSection, sid, "server_config")
s.anonymous = true
s.addremove = false

o = s:option(Flag, "enable", translate("启用"))
o.default = 1
o.rmempty = false

o = s:option(Value, "server", translate("服务器地址"))
o.datatype = "ipaddr"
o.default = "0.0.0.0"
o.rmempty = false

o = s:option(Value, "server_port", translate("服务器端口"))
o.datatype = "port"
o.default = 8388
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

return m
