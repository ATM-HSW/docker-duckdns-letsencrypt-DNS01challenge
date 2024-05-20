#!/bin/sh

for dir in $(ls -d /etc/letsencrypt/live/*); do
    if [ -d $dir ]; then
        cat $dir/privkey.pem $dir/cert.pem > $dir/combinekeycert.pem
        cat $dir/privkey.pem $dir/fullchain.pem > $dir/combinekeyfullchain.pem
    fi
done
