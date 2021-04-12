CC = gcc
STRIP = strip
#CC = musl-gcc
STATIC = -static

W_APPS = debdb2pupdb find_cat vercmp

all: $(W_APPS)

#===
debdb2pupdb:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o debdb2pupdb debdb2pupdb.c
	$(STRIP) debdb2pupdb

find_cat:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o find_cat find_cat.c
	$(STRIP) find_cat

vercmp:
	$(CC) $(STATIC) -O3 -fomit-frame-pointer -ffunction-sections -fdata-sections -fmerge-all-constants -Wl,--sort-common -Wl,-gc-sections -o vercmp vercmp.c
	$(STRIP) vercmp
#===

clean:
	rm -f $(W_APPS)

install: all
	mkdir -p $(DESTDIR)/bin/
	install -m 755 $(W_APPS) $(DESTDIR)/bin/
