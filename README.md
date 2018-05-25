ShadowsocksR-libev for OpenWrt
===

ShadowsocksR-libev port for [gocloud](http://www.gocloud.cn) firmware.

Discuss: http://www.right.com.cn/forum/thread-321902-1-1.html

Compile
-------

Ubuntu x64 and `ramips` archtecture as example:

```
sudo apt-get install build-essential subversion libncurses5-dev zlib1g-dev gawk gcc-multilib flex git-core gettext libssl-dev
curl -sLo- http://archive.openwrt.org/barrier_breaker/14.07/ramips/mt7620a/OpenWrt-SDK-ramips-for-linux-x86_64-gcc-4.8-linaro_uClibc-0.9.33.2.tar.bz2 | tar jx
cd OpenWrt-SDK-ramips-for-linux-x86_64-gcc-4.8-linaro_uClibc-0.9.33.2
./scripts/feeds update packages
./scripts/feeds install libpcre
git clone https://github.com/tsl0922/openwrt-ssr.git package/openwrt-ssr
make defconfig
make package/openwrt-ssr/compile V=99
```

Install
-------

Read the instructions on the [Releases](https://github.com/tsl0922/openwrt-ssr/releases) page.