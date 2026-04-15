Goal
Портировать PSP homebrew hello-world проект с C++ на Nim, собирать через Docker с PSP toolchain (pspdev/pspdev:develop). Итоговый артефакт — EBOOT.PBP, запускаемый на PSP или в PPSSPP.
Instructions
- Отвечать по-русски
- Сборка происходит внутри Docker-контейнера, локального PSP toolchain нет
- Сборочный инструмент — xmake, который вручную вызывает nim c --compileOnly, компилирует .c → .o через psp-gcc, затем линкует
- Nim флаги: --cpu:mipsel --os:standalone --mm:arc --noMain --compileOnly -d:danger -d:noSignalHandler
- panicoverride.nim должен лежать в корне проекта (там же где nim.cfg)
- assertions.nim.c всегда пропускается при компиляции (дублирует символы из system.nim.c)
Discoveries
- Nim генерирует 3 .c файла: @mmain.nim.c, @m..@s..@susr@slib@snim@ssystem.nim.c, @m..@s..@susr@slib@snim@sstd@sassertions.nim.c
- assertions.nim.c содержит только rawoutput и panic — полный дубликат того, что есть в system.nim.c. Его нужно всегда пропускать при компиляции (фильтр по имени assertions в xmake.lua)
- N_LIB_PRIVATE в Nim-сгенерированном C не раскрывается в static, поэтому дублирующиеся символы вызывают ошибку линкера multiple definition
- Флаг -G0 обязателен в CFLAGS для PSP — без него возникает несовместимость MIPS ABI между объектными файлами (invalid operation от линкера)
- -s (strip) нужно убрать из LDFLAGS на время диагностики; -Wl,--gc-sections конфликтует с -Wl,-q для PRX и был убран
- PSP_MODULE_INFO в {.emit.} блоке — Nim корректно вставляет его после #include, поэтому макрос определён
- import panicoverride не нужен в main.nim — Nim подхватывает panicoverride.nim автоматически при --os:standalone
- Предупреждение psp-fixup-imports: stubs out of order решается переносом -lpspsdk в конец списка библиотек (он содержит stub resolver)
- Сборка успешно завершилась: EBOOT.PBP создан (162174 байта PRX + PARAM.SFO)
Accomplished
Завершено
- ✅ src/main.nim — написан с PSP bindings, callback loop, debug screen loop, PSP_MODULE_INFO через {.emit.}
- ✅ panicoverride.nim — в корне проекта, rawoutput и panic через {.exportc.}
- ✅ nim.cfg — PSP cross-compilation настройки, -G0, include/lib paths
- ✅ xmake.lua — полный кастомный build pipeline: nim → C → obj → ELF → PRX → EBOOT.PBP
- ✅ Dockerfile — FROM pspdev/pspdev:develop, apk add nim nimble xmake ninja
- ✅ Устранена ошибка multiple definition of rawoutput/panic (пропуск assertions.nim.c)
- ✅ Устранена ошибка final link failed: invalid operation (добавлен -G0, убран --gc-sections)
- ✅ EBOOT.PBP успешно собран
В процессе / Осталось
- ⚠️ Предупреждение psp-fixup-imports: stubs out of order — исправлено в последнем коммите (перенос -lpspsdk в конец), но ещё не проверено новым запуском сборки
- ⬜ Проверить сборку после перестановки порядка библиотек (убедиться что предупреждение ушло)
- ⬜ Протестировать EBOOT.PBP в PPSSPP или на железе
- ⬜ Возможно: вернуть -s (strip) и --gc-sections в финальную конфигурацию после проверки работоспособности
- ⬜ Возможно: убрать -v из команды линковки (добавлен для диагностики)
Relevant files / directories
W:\projects\homebrew\
├── src\
│   └── main.nim              # Основной Nim entrypoint (PSP bindings, callbacks, main loop)
├── panicoverride.nim          # Panic override для --os:standalone (корень проекта)
├── nim.cfg                    # PSP cross-compilation настройки для Nim
├── xmake.lua                  # Кастомный build pipeline (nim→C→obj→ELF→PRX→EBOOT.PBP)
├── Dockerfile                 # Docker образ на базе pspdev/pspdev:develop
├── main.cpp                   # Оригинальный C++ hello-world (референс, не трогается)
├── CMakeLists.txt             # Оригинальный CMake для C++ (референс, не трогается)
├── nimcache\                  # Генерируется Nim (3 .c файла + main.json)
│   ├── @mmain.nim.c
│   ├── @m..@s..@susr@slib@snim@ssystem.nim.c
│   ├── @m..@s..@susr@slib@snim@sstd@sassertions.nim.c   # пропускается при компиляции
│   └── main.json
└── build\
    └── psp\mips\release\
        ├── hello_psp          # ELF
        ├── hello_psp.prx      # PRX (162174 байт)
        ├── PARAM.SFO          # (408 байт)
        └── EBOOT.PBP          # Финальный артефакт ✅
