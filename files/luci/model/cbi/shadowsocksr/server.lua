-- Copyright (C) 2017 yushi studio <ywb94@qq.com>
-- Licensed to the public under the GNU General Public License v3.

local m, sec, o
local shadowsocksr = "shadowsocksr"
local uci = luci.model.uci.cursor()
local ipkg = require("luci.model.ipkg")

local tabname = {translate("客户端"), translate("服务器"), translate("状态")};
local tabmenu = {
    luci.dispatcher.build_nodeurl("admin", "network", "shadowsocksr"),
    luci.dispatcher.build_nodeurl("admin", "network", "shadowsocksr", "server"),
    luci.dispatcher.build_nodeurl("admin", "network", "shadowsocksr", "status"),
};
local isact = {false, true, false};
local tabcount = #tabname;

m = Map(shadowsocksr, translate(""))
m.description = translate("服务器配置")
m.istabform = true
m.tabcount = tabcount
m.tabname = tabname;
m.tabmenu = tabmenu;
m.isact = isact;

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

-- [[ Global Setting ]]--
sec = m:section(TypedSection, "server_global", translate("全局设置"))
sec.anonymous = true

o = sec:option(Flag, "enable_server", translate("启用"))
o.rmempty = false

-- [[ Server Setting ]]--
sec = m:section(TypedSection, "server_config", translate("服务端配置"))
sec.anonymous = true
sec.addremove = true
sec.sortable = true
sec.template = "cbi/tblsection"
sec.extedit = luci.dispatcher.build_url("admin/network/shadowsocksr/server/%s")
function sec.create(...)
    local sid = TypedSection.create(...)
    if sid then
        luci.http.redirect(sec.extedit % sid)
        return
    end
end

o = sec:option(Flag, "enable", translate("启用"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or translate("0")
end
o.rmempty = false

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
    local v = Value.cfgvalue(...)
    return v and v:upper() or "?"
end

o = sec:option(DummyValue, "protocol", translate("协议"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "obfs", translate("混淆插件"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or "?"
end

return m
