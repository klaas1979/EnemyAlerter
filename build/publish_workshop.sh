#!/usr/bin/env bash
# get login parameter from other file as variables
source $(dirname "$0")/../steamcredentials.sh

sdk_dir=/Users/klaas/JupiterHell_mods/steamworks_sdk_160

# see the manual for publishing
# https://partner.steamgames.com/doc/features/workshop/implementation?l=english#SteamCmd
$sdk_dir/tools/ContentBuilder/builder_osx/steamcmd.sh +login $login $password +workshop_build_item /Users/klaas/JupiterHell_mods/EnemyAlerter/steam-workshop/ea-definition.vdf +quit
