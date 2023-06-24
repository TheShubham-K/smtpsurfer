# split socat or ncat into 2 parts
sudo socat tcp-l:1010,reuseaddr,fork - | tee >(socat - tcp:localhost:2020) | socat - tcp:localhost:3030