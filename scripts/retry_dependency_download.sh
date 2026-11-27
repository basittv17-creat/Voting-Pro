#!/usr/bin/env bash
# Retry only a rate-limited dependency fetch. Preserve compiler and signing failures.
set -eu
log=$(mktemp)
mirror_init=''
cleanup() {
  rm -f "$log"
  if [[ -n "$mirror_init" ]]; then rm -f "$mirror_init"; fi
}
trap cleanup EXIT
for delay in 15 45 0; do
  set +e
  "$@" 2>&1 | tee "$log"
  statuses=("${PIPESTATUS[@]}")
  set -e
  if (( statuses[1] != 0 )); then exit "${statuses[1]}"; fi
  if (( statuses[0] == 0 )); then exit 0; fi
  if (( delay == 0 )) || ! grep -Eiq 'status code 429|HTTP[^[:alnum:]]+429|429 Too Many Requests' "$log"; then
    exit "${statuses[0]}"
  fi
  # The plugin portal redirects Central artifacts to the same throttled host.
  # Apply the mirror to included Flutter plugin builds as well as the app.
  if [[ "${GITHUB_ACTIONS:-}" == true && -z "$mirror_init" ]]; then
    init_dir="${GRADLE_USER_HOME:-$HOME/.gradle}/init.d"
    mkdir -p "$init_dir"
    mirror_init=$(mktemp --suffix=.gradle "$init_dir/voting-pro-central-XXXXXXXX")
    cat > "$mirror_init" <<'GRADLE'
def addCentralMirror = { repos ->
    repos.maven {
        url = uri('https://maven-central.storage-download.googleapis.com/maven2/')
    }
}
gradle.beforeSettings { settings ->
    if (settings.settingsDir.path.endsWith("/packages/flutter_tools/gradle")) {
        addCentralMirror(settings.pluginManagement.repositories)
        settings.pluginManagement.repositories.gradlePluginPortal()
    }
}
gradle.beforeProject { project ->
    if (project.rootDir.path.endsWith("/packages/flutter_tools/gradle")) {
        addCentralMirror(project.buildscript.repositories)
    }
}
GRADLE
  fi
  sleep "$delay"
done
