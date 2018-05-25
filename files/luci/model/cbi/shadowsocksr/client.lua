-- Copyright (C) 2017 yushi studio <ywb94@qq.com> github.com/ywb94
-- Licensed to the public under the GNU General Public License v3.

local m, s, sec, o, kcp_enable
local shadowsocksr = "shadowsocksr"
local uci = luci.model.uci.cursor()
local ipkg = require("luci.model.ipkg")

local sys = require "luci.sys"

local gfwmode = 0

local pdnsd_flag = 0
local haproxy_flag = 0

if nixio.fs.access("/etc/dnsmasq.ssr/gfw_list.conf") then
    gfwmode = 1
end

if nixio.fs.access("/etc/pdnsd.conf") then
    pdnsd_flag = 1
end
if nixio.fs.access("/etc/haproxy.cfg") then
    haproxy_flag = 1
end

local tabname = {translate("客户端"), translate("服务器"), translate("状态")};
local tabmenu = {
    luci.dispatcher.build_nodeurl("admin", "network", "shadowsocksr"),
    luci.dispatcher.build_nodeurl("admin", "network", "shadowsocksr", "server"),
    luci.dispatcher.build_nodeurl("admin", "network", "shadowsocksr", "status"),
};
local isact = {true, false, false};
local tabcount = #tabname;

m = Map("shadowsocksr", translate(""))
m.description = translate("客户端配置")
m.istabform = true
m.tabcount = tabcount
m.tabname = tabname;
m.tabmenu = tabmenu;
m.isact = isact;

local server_table = {}
local server_count = 0
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

uci:foreach(shadowsocksr, "servers", function(s)
    if s.alias then
        server_table[s[".name"]] = s.alias
    elseif s.server and s.server_port then
        server_table[s[".name"]] = "%s:%s" % {s.server, s.server_port}
    end
    server_count = server_count + 1
end)

-- [[ Global Setting ]]--
s = m:section(TypedSection, "global", translate("全局设置"))
s.anonymous = true

o = s:option(Flag, "enable", translate("启用"))
o.rmempty = false

o = s:option(ListValue, "global_server", translate("服务器"), translate("提示：到页面底部管理服务器"))
if haproxy_flag == 1 and server_count > 1 then
    o:value("__haproxy__", translate("负载均衡"))
end
for k, v in pairs(server_table) do o:value(k, v) end
o.default = "nil"
o.rmempty = false

o = s:option(ListValue, "udp_relay_server", translate("UDP 中继服务器"))
o:value("", translate("停用"))
o:value("same", translate("与全局服务器相同"))
for k, v in pairs(server_table) do o:value(k, v) end

o = s:option(Flag, "monitor_enable", translate("启用进程监控"))
o.rmempty = false

o = s:option(Flag, "enable_switch", translate("启用自动切换"))
o.rmempty = false

o = s:option(Value, "switch_time", translate("自动切换检查周期（秒）"))
o.datatype = "uinteger"
o:depends("enable_switch", "1")
o.default = 600

o = s:option(Value, "switch_timeout", translate("切换检查超时时间（秒）"))
o.datatype = "uinteger"
o:depends("enable_switch", "1")
o.default = 3

if gfwmode == 0 then
    o = s:option(Flag, "tunnel_enable", translate("启用隧道（DNS）转发"))
    o.default = 0
    o.rmempty = false
    
    o = s:option(Value, "tunnel_port", translate("隧道（DNS）本地端口"))
    o.datatype = "port"
    o.default = 5300
    o.rmempty = false
    
else
    o = s:option(ListValue, "gfw_enable", translate("运行模式"))
    o:value("router", translate("IP 路由模式"))
    o:value("gfw", translate("GFW 列表模式"))
    o.rmempty = false
    
    if pdnsd_flag == 1 then
        o = s:option(ListValue, "pdnsd_enable", translate("DNS 解析方式"))
        o:value("0", translate("使用 DNS 隧道"))
        o:value("1", translate("使用 pdnsd"))
        o.rmempty = false
    end
    
end

o = s:option(Value, "tunnel_forward", translate("DNS 服务器地址和端口"))
o.default = "8.8.4.4:53"
o.rmempty = false

-- [[ SOCKS5 Proxy ]]--
s = m:section(TypedSection, "socks5_proxy", translate("SOCKS5 代理"))
s.anonymous = true

o = s:option(ListValue, "server", translate("服务器"))
o:value("nil", translate("停用"))
for k, v in pairs(server_table) do o:value(k, v) end
o.default = "nil"
o.rmempty = false

o = s:option(Value, "local_port", translate("本地端口"))
o.datatype = "port"
o.default = 1234
o.rmempty = false

-- [[ Access Control ]]--
s = m:section(TypedSection, "access_control", translate("访问控制"))
s.anonymous = true

-- Part of WAN
s:tab("wan_ac", translate("接口 - WAN"))

o = s:taboption("wan_ac", Value, "wan_bp_list", translate("被忽略 IP 列表"))
o:value("/dev/null", translate("留空 - 作为全局代理"))

o.default = "/dev/null"
o.rmempty = false

o = s:taboption("wan_ac", DynamicList, "wan_bp_ips", translate("额外被忽略 IP"))
o.datatype = "ip4addr"

o = s:taboption("wan_ac", DynamicList, "wan_fw_ips", translate("强制走代理 IP"))
o.datatype = "ip4addr"

-- Part of LAN
s:tab("lan_ac", translate("接口 - LAN"))

o = s:taboption("lan_ac", ListValue, "router_proxy", translate("路由器访问控制"))
o:value("1", translatef("正常代理"))
o:value("0", translatef("不走代理"))
o:value("2", translatef("强制走代理"))
o.rmempty = false

o = s:taboption("lan_ac", ListValue, "lan_ac_mode", translate("内网访问控制"))
o:value("0", translate("停用"))
o:value("w", translate("仅允许列表内"))
o:value("b", translate("仅允许列表外"))
o.rmempty = false

o = s:taboption("lan_ac", DynamicList, "lan_ac_ips", translate("内网主机列表"))
o.datatype = "ipaddr"

-- [[ Servers Setting ]]--
sec = m:section(TypedSection, "servers", translate("服务器配置"))
sec.anonymous = true
sec.addremove = true
sec.sortable = true
sec.template = "cbi/tblsection"
sec.extedit = luci.dispatcher.build_url("admin/network/shadowsocksr/client/%s")
function sec.create(...)
    local sid = TypedSection.create(...)
    if sid then
        luci.http.redirect(sec.extedit % sid)
        return
    end
end

sec:tab("shadowsocksr", translate("客户端"))

o = sec:option(DummyValue, "alias", translate("别名"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or translate("None")
end

o = sec:option(DummyValue, "server", translate("服务器地址"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "server_port", translate("服务器端口"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "encrypt_method", translate("加密方式"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "protocol", translate("协议"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "obfs", translate("混淆插件"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "kcp_enable", translate("KcpTun"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "switch_enable", translate("自动切换"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or "0"
end

return m
