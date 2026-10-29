error() {
  echo " !     $*" >&2
  exit 1
}

status() {
  echo "-----> $*"
}

protip() {
  echo
  echo "PRO TIP: $*" | indent
  echo "See https://devcenter.heroku.com/articles/nodejs-support" | indent
  echo
}

# sed -l basically makes sed replace and buffer through stdin to stdout
# so you get updates while the command runs and dont wait for the end
# e.g. npm install | indent
indent() {
  c='s/^/       /'
  case $(uname) in
    Darwin) sed -l "$c";; # mac/bsd sed: -l buffers on line boundaries
    *)      sed -u "$c";; # unix/gnu sed: -u unbuffered (arbitrary) chunks of data
  esac
}

cat_npm_debug_log() {
  test -f $build_dir/npm-debug.log && cat $build_dir/npm-debug.log
}

export_env_dir() {
  env_dir=$1
  whitelist_regex=${2:-''}
  blacklist_regex=${3:-'^(PATH|GIT_DIR|CPATH|CPPATH|LD_PRELOAD|LIBRARY_PATH)$'}
  if [ -d "$env_dir" ]; then
    for e in $(ls $env_dir); do
      echo "$e" | grep -E "$whitelist_regex" | grep -qvE "$blacklist_regex" &&
      export "$e=$(cat $env_dir/$e)"
      :
    done
  fi
}

# Resolve the engines.node range to a release listed in nodejs.org's index.
# Handles exact versions (0.10.32), x-ranges (0.10.x, 0.10, 22.x, 22), and ^ and
# ~ as their major and minor lines. An empty range or * means the latest LTS
# release; so does anything else, with a warning.
resolve_node_version() {
  local range=${1#v} releases pattern
  [ "$range" == "null" ] && range=""
  releases=$(curl --silent --fail --location https://nodejs.org/dist/index.json | $bp_dir/vendor/jq -r '.[] | "\(.version) \(.lts)"') ||
    error "Unable to download the node release index from nodejs.org"
  case "$range" in
    ""|"*"|x|X)           pattern="" ;;
    ^[0-9]*)              pattern="$(echo "${range#^}" | cut -d. -f1)." ;;
    ~[0-9]*)              pattern="$(echo "${range#\~}" | cut -d. -f1-2)." ;;
    [0-9]*.[xX])          pattern="${range%[xX]}" ;;
    [0-9]*.[0-9]*.[0-9]*) pattern="$range " ;;
    [0-9]*)               pattern="$range." ;;
    *)                    pattern=""
                          echo "Unsupported engines.node range: $range; using the latest LTS release" | indent >&2 ;;
  esac
  # The index lists releases newest first, so the first match is the newest.
  if [ -z "$pattern" ]; then
    echo "$releases" | awk '$2 != "false" { split(substr($1, 2), v, "."); if (v[1] + 0 > major) { major = v[1] + 0; version = substr($1, 2) } } END { print version }'
  else
    echo "$releases" | awk -v p="v$pattern" 'index($0, p) == 1 { print substr($1, 2); exit }'
  fi
}
