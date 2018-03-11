#!/bin/bash
cd addons/sourcemod/scripting


for SPFILE in gungame gungame_afk gungame_bot gungame_config gungame_display_winner gungame_logging gungame_mapvoting gungame_mvp gungame_stats gungame_tk gungame_warmup_configs gungame_winner_effects
do
  echo "#####################"
  echo "##### $SPFILE"
  echo "#####################"
  rm ../plugins/$SPFILE.smx
  ~/Downloads/sourcemod_scripting/spcomp -i /Users/chaos/Downloads/sourcemod_scripting/include -iinclude $SPFILE.sp WITH_SDKHOOKS=1
  mv $SPFILE.smx ../plugins/
done
