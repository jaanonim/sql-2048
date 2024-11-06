get_key_press() {
    stty -echo
    stty raw
    read -rsn1 key
    if [[ $key == $'\e' ]]; then
        key=$(dd bs=1 count=2 2>/dev/null)
    fi
    stty -raw
    stty echo
    echo "$key"
}

run_query() {
    local key=$1
    shift
    psql -t "$@" -c "SELECT get_key('$key');" 
}

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
QUERY=$(cat < $SCRIPTPATH/setup.sql)
psql "$@" -c "$QUERY" >/dev/null 2>&1

while true; do
    key=$(get_key_press)
    run_query "$key" "$@"
done
