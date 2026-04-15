docker build -t psp-nim .
docker run --rm -v ${pwd}:/src -w /src psp-nim xmake f --toolchain=pspdev -v && xmake build -v
