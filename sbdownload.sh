#!/bin/bash

googleurl='safebrowsing.clients.google.com/safebrowsing/downloads'
yandexurl='sba.yandex.net/downloads'

listname='goog-malware-shavar'

if [ "$1" = 'yandex' ]; then
    url=$yandexurl
else
    url=$googleurl
fi

function get_download() {
    have=$1
    echo "$listname;$have" | curl -s --data-binary @- "http://$url?client=navclient-auto-ffox&appver=1.0&pver=2.2" | grep '^u:' | sed 's/^u:\(.*\)$/\1/'
}

function get_chunks() {
    for url in $1; do
        data=$(curl -s -L $url)
        echo "$data" | grep -a '[as]:[0-9]*:[0-9]*:[0-9]*$' | perl -pe 's/^.*([as]:[0-9]*):[0-9]*:[0-9]*$/\1/'
        echo "$data" >>$listname
    done
}

function get_sublist() {
    type=$1
    echo -n "$type:"
    while read num; do
        [ -z "$from" ] && from=$num
        [ -z "$to" ] && to=$num
        if [ "$to" = $((num-1)) ]; then
            to=$num
        else
            if [ "$to" -gt "$from" ]; then
                list="$list-$to"
            fi
            from=$num
            to=$num
            if [ -z "$list" ]; then
                list=$num
            else
                list="$list,$from"
            fi
        fi
        export from to
    done < <(grep "^$type:" | sed "s/$type:\([0-9]*\)/\1/")
    if [ "$to" -gt "$from" ]; then
        list="$list-$to"
    fi
    echo -n "$list"
}

function gen_have() {
    chunks="$1"

    echo "$chunks" | get_sublist a
    echo -n ":"
    echo "$chunks" | get_sublist s
}

rm -f $listname

while true; do
    download=$(get_download "$have")
    files=`echo "$download" | wc -l`
    totalfiles=$((totalfiles+files))
    newchunks=$(get_chunks "$download")
    [ -z "$newchunks" ] && break
    chunks="$chunks
$newchunks"
    have=$(gen_have "$chunks")
done
count=`echo "$chunks" | wc -l`
echo "have: $have"
echo "chunks: $count"
echo "files: $totalfiles"
echo "size: `stat -c %s $listname`"
