ps ax | grep puma | awk '{ print $1 }' | xargs kill
puma --debug -p 4567 -d -e development --redirect-stdout /tmp/puma.out
tail -f /tmp/puma.out