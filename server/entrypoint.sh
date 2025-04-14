#!/usr/bin/env sh

# Inject the configuration files from config volume into paper
./palimpsest -o /opt/paper -o /overlays/base -o /overlays/env -t /opt/paper

#for file in /overlay/*; do
#  base=$(basename "$file")
#  path=$(echo "$base" | sed 's/__/\//g')
#  mkdir -p "/opt/paper/$(dirname "$path")"
#  cp "$file" "/opt/paper/$path"
#done


exec java -Xms2048M -Xmx2048M -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar paper.jar nogui &
pid=$!
# Trap the SIGTERM signal and forward it to the main process (15 = SIGTERM)
trap 'kill -15 $pid; wait $pid' SIGTERM
wait $pid
