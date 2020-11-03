#!/bin/bash
cd addons/sourcemod/scripting
set -e
SDK_PATH="/Users/chaos/Downloads/sourcemod-1.10.0-git6499-mac/addons/sourcemod/scripting"

for SPFILE in gungame gungame_afk gungame_bot gungame_config gungame_display_winner gungame_logging gungame_mapvoting gungame_mvp gungame_one_shot_awp gungame_stats gungame_tk gungame_warmup_configs gungame_winner_effects
do
  echo "#####################"
  echo "##### $SPFILE"
  echo "#####################"
  if [ -f ../plugins/$SPFILE.smx ]; then rm ../plugins/$SPFILE.smx; fi
  $SDK_PATH/spcomp -i $SDK_PATH/include -iinclude $SPFILE.sp WITH_SDKHOOKS=1
  mv $SPFILE.smx ../plugins/
done
