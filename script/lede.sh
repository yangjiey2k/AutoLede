#!/bin/bash

# Clone community packages to package/community
mkdir -p package/community
pushd package/community

# Add luci-app-unblockneteasemusic
git clone https://github.com/UnblockNeteaseMusic/luci-app-unblockneteasemusic.git

# Add luci-app-passwall
git clone --branch 4fd4bf8 --single-branch https://github.com/xiaorouji/openwrt-passwall
svn export --force https://github.com/xiaorouji/openwrt-passwall/branches/luci/luci-app-passwall

# Add luci-theme-argon
git clone --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config
cp -f $GITHUB_WORKSPACE/pics/bg1.jpg luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
popd

# Modify default IP and hostname
sed -i 's/192.168.1.1/192.168.1.202/g' package/base-files/files/bin/config_generate
sed -i '/uci commit system/i\uci set system.@system[0].hostname='NibiruWrt'' package/lean/default-settings/files/zzz-default-settings
sed -i "s/OpenWrt /KoNan - Nibiru /g" package/lean/default-settings/files/zzz-default-settings

# Test kernel 6.1
sed -i 's/5.15/6.1/g' target/linux/x86/Makefile

# Network Configuration
sed -i "/exit/i\
uci set network.lan.gateway='192.168.1.201'\n\
uci set network.lan.dns='119.29.29.29 223.5.5.5'\n\
uci commit network\n\
uci set dhcp.lan.ignore='1'\n\
uci set dhcp.lan.dhcpv6='disabled'\n\
uci commit dhcp\n" package/lean/default-settings/files/zzz-default-settings

# nlbwmon netlink buffer size
echo -e "net.core.wmem_max=16777216\nnet.core.rmem_max=16777216" >> package/base-files/files/etc/sysctl.conf

# Modify ShadowSocksR Plus+ Menu order
find package/*/ feeds/*/ -maxdepth 6 -path "*helloworld/luci-app-ssr-plus/luasrc/controller/shadowsocksr.lua" | xargs -i sed -i 's/"ShadowSocksR Plus+")\, 10/"ShadowSocksR Plus+")\, 0/g' {}

# Custom configs
echo -e " KoNan's NibiruWrt built on $(date +%Y.%m.%d)\n -----------------------------------------------------" >> package/base-files/files/etc/banner
echo -e 'net.bridge.bridge-nf-call-iptables=0\n\
net.bridge.bridge-nf-call-ip6tables=0\n\
net.bridge.bridge-nf-call-arptables=0\n\
net.bridge.bridge-nf-filter-vlan-tagged=0' >> package/base-files/files/etc/sysctl.conf
