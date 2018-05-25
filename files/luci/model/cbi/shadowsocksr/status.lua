-- Copyright (C) 2017 yushi studio <ywb94@qq.com>
-- Licensed to the public under the GNU General Public License v3.

local IPK_Version = "1.2.1"
local m, s, o
local redir_run = 0
local reudp_run = 0
local sock5_run = 0
local server_run = 0
local kcptun_run = 0
local tunnel_run = 0
local pdnsd_flag = 0
local pdnsd_run = 0
local haproxy_flag = 0
local haproxy_run = 0
local gfw_count = 0
local ad_count = 0
local ip_count = 0
local gfwmode = 0

if nixio.fs.access("/etc/dnsmasq.ssr/gfw_list.conf") then
    gfwmode = 1
end

local shadowsocksr = "shadowsocksr"
-- html constants
font_blue = [[<font color="blue">]]
font_off = [[</font>]]
bold_on = [[<strong>]]
bold_off = [[</strong>]]

local fs = require "nixio.fs"
local sys = require "luci.sys"
local kcptun_version = translate("Unknown")
local kcp_file = "/usr/bin/ssr-kcptun"
if not fs.access(kcp_file) then
    kcptun_version = translate("未安装可执行文件")
else
    if not fs.access(kcp_file, "rwx", "rx", "rx") then
        fs.chmod(kcp_file, 755)
    end
    kcptun_version = sys.exec(kcp_file .. " -v | awk '{printf $3}'")
    if not kcptun_version or kcptun_version == "" then
        kcptun_version = translate("Unknown")
    end
    
end

if gfwmode == 1 then
    gfw_count = tonumber(sys.exec("cat /etc/dnsmasq.ssr/gfw_list.conf | wc -l")) / 2
    if nixio.fs.access("/etc/dnsmasq.ssr/ad.conf") then
        ad_count = tonumber(sys.exec("cat /etc/dnsmasq.ssr/ad.conf | wc -l"))
    end
end

if nixio.fs.access("/etc/china_ssr.txt") then
    ip_count = sys.exec("cat /etc/china_ssr.txt | wc -l")
end

local icount = sys.exec("ps -w | grep ssr-reudp |grep -v grep| wc -l")
if tonumber(icount) > 0 then
    reudp_run = 1
else
    icount = sys.exec("ps -w | grep ssr-retcp |grep \"\\-u\"|grep -v grep| wc -l")
    if tonumber(icount) > 0 then
        reudp_run = 1
    end
end

if luci.sys.call("pidof ssr-redir >/dev/null") == 0 then
    redir_run = 1
end

if luci.sys.call("pidof ssr-local >/dev/null") == 0 then
    sock5_run = 1
end

if luci.sys.call("pidof ssr-kcptun >/dev/null") == 0 then
    kcptun_run = 1
end

if luci.sys.call("pidof ssr-server >/dev/null") == 0 then
    server_run = 1
end

if luci.sys.call("pidof ssr-tunnel >/dev/null") == 0 then
    tunnel_run = 1
end

if nixio.fs.access("/etc/pdnsd.conf") then
    pdnsd_flag = 1
    if luci.sys.call("pidof pdnsd >/dev/null") == 0 then
        pdnsd_run = 1
    end
end

if nixio.fs.access("/etc/haproxy.cfg") then
    haproxy_flag = 1
    if luci.sys.call("pidof haproxy >/dev/null") == 0 then
        haproxy_run = 1
    end
end

local tabname = {translate("客户端"), translate("服务器"), translate("状态")};
local tabmenu = {
    luci.dispatcher.build_nodeurl("admin", "network", "shadowsocksr"),
    luci.dispatcher.build_nodeurl("admin", "network", "shadowsocksr", "server"),
    luci.dispatcher.build_nodeurl("admin", "network", "shadowsocksr", "status"),
};
local isact = {false, false, true};
local tabcount = #tabname;

m = SimpleForm("Version", translate("运行状态"))
m.istabform = true
m.tabcount = tabcount
m.tabname = tabname;
m.tabmenu = tabmenu;
m.isact = isact;
m.reset = false
m.submit = false

s = m:field(DummyValue, "redir_run", translate("SSR 客户端"))
s.rawhtml = true
if redir_run == 1 then
    s.value = font_blue .. bold_on .. translate("运行中") .. bold_off .. font_off
else
    s.value = translate("未运行")
end

s = m:field(DummyValue, "server_run", translate("SSR 服务端"))
s.rawhtml = true
if server_run == 1 then
    s.value = font_blue .. bold_on .. translate("运行中") .. bold_off .. font_off
else
    s.value = translate("未运行")
end

s = m:field(DummyValue, "reudp_run", translate("UDP 中继"))
s.rawhtml = true
if reudp_run == 1 then
    s.value = font_blue .. bold_on .. translate("运行中") .. bold_off .. font_off
else
    s.value = translate("未运行")
end

s = m:field(DummyValue, "sock5_run", translate("SOCKS5 代理"))
s.rawhtml = true
if sock5_run == 1 then
    s.value = font_blue .. bold_on .. translate("运行中") .. bold_off .. font_off
else
    s.value = translate("未运行")
end

s = m:field(DummyValue, "tunnel_run", translate("DNS 隧道"))
s.rawhtml = true
if tunnel_run == 1 then
    s.value = font_blue .. bold_on .. translate("运行中") .. bold_off .. font_off
else
    s.value = translate("未运行")
end

if pdnsd_flag == 1 then
    s = m:field(DummyValue, "pdnsd_run", translate("pdnsd 服务器"))
    s.rawhtml = true
    if pdnsd_run == 1 then
        s.value = font_blue .. bold_on .. translate("运行中") .. bold_off .. font_off
    else
        s.value = translate("未运行")
    end
end

if haproxy_flag == 1 then
    s = m:field(DummyValue, "haproxy_run", translate("haproxy 服务器"))
    s.rawhtml = true
    if haproxy_run == 1 then
        local uci = require "luci.model.uci".cursor()
        local stats_url = "http://" .. uci:get("network", "lan", "ipaddr") .. ":1111/stats"
        local haproxy_stats = bold_on .. [[<a target="_blank" href="]] .. stats_url .. [[">]] .. translate("查看状态") .. [[</a>]] .. bold_off
        s.value = font_blue .. bold_on .. translate("运行中") .. bold_off .. font_off .. " (" .. haproxy_stats .. ")"
    else
        s.value = translate("未运行")
    end
end

s = m:field(DummyValue, "kcptun_run", translate("KcpTun"))
s.rawhtml = true
if kcptun_run == 1 then
    s.value = font_blue .. bold_on .. translate("运行中") .. bold_off .. font_off
else
    s.value = translate("未运行")
end

s = m:field(DummyValue, "google", translate("【谷歌】连通性检查"))
s.value = translate("未检查")
s.template = "shadowsocksr/check"

s = m:field(DummyValue, "baidu", translate("【百度】连通性检查"))
s.value = translate("未检查")
s.template = "shadowsocksr/check"

if gfwmode == 1 then
    s = m:field(DummyValue, "gfw_data", translate("【GFW列表】数据库"))
    s.rawhtml = true
    s.template = "shadowsocksr/refresh"
    s.value = tostring(math.ceil(gfw_count)) .. " " .. translate("条记录")
    
    s = m:field(DummyValue, "ad_data", translate("【广告屏蔽】数据库"))
    s.rawhtml = true
    s.template = "shadowsocksr/refresh"
    s.value = tostring(math.ceil(ad_count)) .. " " .. translate("条记录")
end

s = m:field(DummyValue, "ip_data", translate("【国内IP段】数据库"))
s.rawhtml = true
s.template = "shadowsocksr/refresh"
s.value = ip_count .. " " .. translate("条记录")

s = m:field(DummyValue, "check_port", translate("【服务器端口】检查"))
s.template = "shadowsocksr/checkport"
s.value = translate("未检查")

s = m:field(DummyValue, "version", translate("IPK 版本号"))
s.rawhtml = true
s.value = IPK_Version

s = m:field(DummyValue, "kcp_version", translate("KcpTun 版本号"))
s.rawhtml = true
s.value = kcptun_version

s = m:field(DummyValue, "project", translate("项目地址"))
s.rawhtml = true
s.value = bold_on .. [[<a href="]] .. "https://github.com/tsl0922/openwrt-ssr" .. [[" >]]
.. "https://github.com/tsl0922/openwrt-ssr" .. [[</a>]] .. bold_off

return m
