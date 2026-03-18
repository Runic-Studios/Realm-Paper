#!/usr/bin/env sh

set -euxo pipefail

echo "Copying Realm-Paper-Base..."
cp -rT /mnt/realm-paper-base/server /opt/paper/

# Copy worlds
echo "Unzipping worlds..."
unzip -q /mnt/world/worlds.zip -d /opt/paper

echo "Unzipping writer..."
unzip -q /opt/paper/rr-writer.zip -d /opt/paper
rm /opt/paper/rr-writer.zip

echo "Stacking configs..."

inflate() {
  src=$1
  dest=$2

  mkdir -p "$dest"

  find "$src" -type f | while read -r file; do
    base=$(basename "$file")
    path=$(echo "$base" | sed 's/__/\//g')
    mkdir -p "$dest/$(dirname "$path")"
    cp "$file" "$dest/$path"
  done
}

# Inflate base and env overlays
inflate /overlays/base /inflated/base
inflate /overlays/env /inflated/env

# Inject the configuration files from config volume into paper
./palimpsest -o /opt/paper -o /inflated/base -o /inflated/env -t /opt/paper

# Inject the velocity forwarding secret
echo "Injecting velocity secret..."
IFS= read -r FWD_SECRET < forwarding.secret
export FWD_SECRET=$FWD_SECRET
yq e '.proxies.velocity.secret = strenv(FWD_SECRET)' config/paper-global.yml -i


echo "Creating JVM flags..."
JVM_OPTS="
-Xms${JVM_MEMORY}M -Xmx${JVM_MEMORY}M
-XX:+AlwaysPreTouch
-XX:+DisableExplicitGC
-XX:+ParallelRefProcEnabled
-XX:+PerfDisableSharedMem
-XX:+UnlockExperimentalVMOptions
-XX:+UseG1GC
-XX:G1HeapRegionSize=8M
-XX:G1HeapWastePercent=5
-XX:G1MaxNewSizePercent=40
-XX:G1MixedGCCountTarget=4
-XX:G1MixedGCLiveThresholdPercent=90
-XX:G1NewSizePercent=30
-XX:G1RSetUpdatingPauseTimePercent=5
-XX:G1ReservePercent=20
-XX:InitiatingHeapOccupancyPercent=15
-XX:MaxGCPauseMillis=200
-XX:MaxTenuringThreshold=1
-XX:SurvivorRatio=32
-Dusing.aikars.flags=https://mcflags.emc.gs
-Daikars.new.flags=true
-XX:+UnlockDiagnosticVMOptions
-XX:+ShowMessageBoxOnError
-XX:+CreateCoredumpOnCrash
-XX:ErrorFile=/data/hs_err_pid%p.log
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/data
"

if [ "${DEBUGGER_ENABLED:-0}" = "1" ]; then
  JVM_OPTS="$JVM_OPTS -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
  JVM_OPTS="$JVM_OPTS -XX:+AllowEnhancedClassRedefinition -XX:HotswapAgent=core -Xlog:redefine+class*=info"
fi

exec java $JVM_OPTS -jar $(ls *paper*.jar | head -n 1) nogui &
pid=$!
# Trap the SIGTERM signal and forward it to the main process (15 = SIGTERM)
trap 'kill -15 $pid; wait $pid' SIGTERM
wait $pid
