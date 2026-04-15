docker build -t psp-nim .
docker run --rm -v ${pwd}:/src -w /src psp-nim xmake -v
