FROM pspdev/pspdev:develop

# nim, nimble — из edge/community если нет в main
# xmake и ninja нужны для сборки
RUN apk add --no-cache nim nimble xmake ninja

ENV XMAKE_ROOT=y

# Проверяем что nim нашёл пути
RUN nim --version && psp-gcc --version
