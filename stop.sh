ps ax | grep puma | awk '{ print $1 }' | xargs kill

