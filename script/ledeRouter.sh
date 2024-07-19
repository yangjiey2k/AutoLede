#!/bin/bash
#===============================================
# Description: DIY script
# File name: ledeMainRouter.sh
# License: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#===============================================

# 移除要替换的包
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-serverchan

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1"
  repourl="$2"
  shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set "$@"
  mv -f "$@" ../package
  cd .. && rm -rf $repodir
}

# 克隆仓库函数
function clone_repo() {
  repo_url="$1"
  target_dir="$2"
  git clone --depth=1 $repo_url $target_dir || { echo "Failed to clone $repo_url"; exit 1; }
}

# 科学上网插件
clone_repo "https://github.com/fw876/helloworld" "package/luci-app-ssr-plus"
clone_repo "https://github.com/xiaorouji/openwrt-passwall-packages" "package/openwrt-passwall"
clone_repo "https://github.com/xiaorouji/openwrt-passwall" "package/luci-app-passwall"
clone_repo "https://github.com/xiaorouji/openwrt-passwall2" "package/luci-app-passwall2"
git_sparse_clone master https://github.com/vernesong/OpenClash luci-app-openclash

# Themes
clone_repo "https://github.com/kiddin9/luci-theme-edge" "package/luci-theme-edge"
clone_repo "https://github.com/jerrykuku/luci-theme-argon" "package/luci-theme-argon"
clone_repo "https://github.com/jerrykuku/luci-app-argon-config" "package/luci-app-argon-config"
clone_repo "https://github.com/xiaoqingfengATGH/luci-theme-infinityfreedom" "package/luci-theme-infinityfreedom"
git_sparse_clone main https://github.com/haiibo/packages luci-theme-atmaterial luci-theme-opentomcat luci-theme-netgear

# 更改 Argon 主题背景
if [ -f "$GITHUB_WORKSPACE/pics/bg1.jpg" ]; then
  cp -f $GITHUB_WORKSPACE/pics/bg1.jpg package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
else
  echo "Background image not found!"
fi

# 在线用户
git_sparse_clone main https://github.com/haiibo/packages luci-app-onliner
sed -i '$i uci set nlbwmon.@nlbwmon[0].refresh_interval=2s' package/lean/default-settings/files/zzz-default-settings
sed -i '$i uci commit nlbwmon' package/lean/default-settings/files/zzz-default-settings
chmod 755 package/luci-app-onliner/root/usr/share/onliner/setnlbw.sh

# x86 型号只显示 CPU 型号
sed -i 's/${g}.*/${a}${b}${c}${d}${e}${f}${hydrid}/g' package/lean/autocore/files/x86/autocore

# 修改本地时间格式
sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' package/lean/autocore/files/*/index.htm

# 修改版本为编译日期
date_version=$(date +"%y.%m.%d")
orig_version=$(grep DISTRIB_REVISION= package/lean/default-settings/files/zzz-default-settings | awk -F "'" '{print $2}')
sed -i "s/${orig_version}/R${date_version} by KoNan/g" package/lean/default-settings/files/zzz-default-settings

# 修改 Makefile
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -I {} sed -i 's#../../luci.mk#$(TOPDIR)/feeds/luci/luci.mk#g' "{}"
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -I {} sed -i 's#../../lang/golang/golang-package.mk#$(TOPDIR)/feeds/packages/lang/golang/golang-package.mk#g' "{}"
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -I {} sed -i 's#PKG_SOURCE_URL:=@GHREPO#PKG_SOURCE_URL:=https://github.com#g' "{}"
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -I {} sed -i 's#PKG_SOURCE_URL:=@GHCODELOAD#PKG_SOURCE_URL:=https://codeload.github.com#g' "{}"

# 取消主题默认设置
find package/luci-theme-*/* -type f -name '*luci-theme-*' -exec sed -i '/set luci.main.mediaurlbase/d' {} \;

# AdGuard Home
mkdir -p package/adguardhome
git clone --depth=1 https://github.com/AdguardTeam/AdGuardHome package/adguardhome

# 创建AdGuard Home的Makefile
cat << 'EOF' > package/adguardhome/Makefile
include $(TOPDIR)/rules.mk

PKG_NAME:=adguardhome
PKG_VERSION:=0.107.0
PKG_RELEASE:=1

PKG_SOURCE_URL:=https://github.com/AdguardTeam/AdGuardHome/releases/download/v$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)_$(PKG_VERSION)_linux_amd64.tar.gz
PKG_HASH:=2b9d518bd18d93b7a83d0c4856e7a59e9e9183f08a1bcf39e168614f6f383e76

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/adguardhome
  SECTION:=net
  CATEGORY:=Network
  TITLE:=AdGuard Home
  URL:=https://github.com/AdguardTeam/AdGuardHome
  DEPENDS:=
endef

define Package/adguardhome/description
  AdGuard Home is a network-wide software for blocking ads and trackers.
endef

define Build/Prepare
  mkdir -p $(PKG_BUILD_DIR)
  tar -C $(PKG_BUILD_DIR) -xzvf $(DL_DIR)/$(PKG_SOURCE)
endef

define Package/adguardhome/install
  $(INSTALL_DIR) $(1)/usr/bin
  $(INSTALL_BIN) $(PKG_BUILD_DIR)/AdGuardHome/AdGuardHome $(1)/usr/bin/
endef

$(eval $(call BuildPackage,adguardhome))
EOF

./scripts/feeds update -a || { echo "Failed to update feeds"; exit 1; }
./scripts/feeds install -a || { echo "Failed to install feeds"; exit 1; }

# 动态获取网卡接口名称
network_interface=$(ip -o -4 route show to default | awk '{print $5}')
if [ -z "$network_interface" ]; then
  echo "No network interface found!"
  exit 1
fi

# 网络配置
sed -i "/exit/i uci set network.lan.ifname='$network_interface'\nuci set network.lan.netmask='255.255.255.0'\nuci set network.lan.dns='192.168.1.207 119.29.29.29 223.5.5.5'\nuci set network.lan.gateway='192.168.1.201'\nuci commit network" package/lean/default-settings/files/zzz-default-settings

# 修改默认IP
sed -i 's/192.168.1.1/192.168.1.228/g' package/base-files/files/bin/config_generate
sed -i '/uci commit system/i uci set system.@system[0].hostname='NibiruWrt'' package/lean/default-settings/files/zzz-default-settings
sed -i "s/OpenWrt /KoNan @ NibiruWrt /g" package/lean/default-settings/files/zzz-default-settings

# 防火墙配置，关闭SYN-flood防御
uci set firewall.@defaults[0].syn_flood='0'
uci commit firewall
/etc/init.d/firewall restart

echo "Configuration complete!"
