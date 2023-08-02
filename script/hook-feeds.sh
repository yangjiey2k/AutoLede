#!/bin/bash

# Set to local feeds
pushd customfeeds/packages > /dev/null
packages_feed="$(pwd)"
popd > /dev/null

pushd customfeeds/luci > /dev/null
luci_feed="$(pwd)"
popd > /dev/null

# Add custom feeds to feeds.conf.default
sed -i '/src-git packages/d' feeds.conf.default
echo "src-link packages $packages_feed" >> feeds.conf.default

sed -i '/src-git luci/d' feeds.conf.default
echo "src-link luci $luci_feed" >> feeds.conf.default

sed -i '/helloworld/d' feeds.conf.default
echo "src-git helloworld https://github.com/fw876/helloworld.git" >> feeds.conf.default

# Update feeds
./scripts/feeds update -a
