CC=gcc
INSTALL_PATH=/usr/sbin
INSTALL_PATH2=/usr/bin
INSTALL_XDG_START=/root/.config/autostart

CAIRO_FLAGS=-Wall -pedantic -std=gnu99 $(shell pkg-config cairo --cflags --libs)
PANGOCAIRO_FLAGS=-Wall -pedantic -std=gnu99 $(shell pkg-config pangocairo --cflags --libs)
GTK2_FLAGS=-Wall -pedantic -std=gnu99 $(shell pkg-config gtk+-2.0 --cflags --libs)
GTK3_FLAGS=-Wall -pedantic -std=gnu99 $(shell pkg-config gtk+-3.0 --cflags --libs)
X11_FLAGS=-Wall -pedantic -std=gnu99 $(shell pkg-config x11 --libs)

all: freememapplet \
	getcurpos \
	mpscan \
	pm13tray \
	picscale \
	setvol

freememapplet:
	xgettext --keyword="_" gtk/freememapplet/freememapplet.c -o freememapplet.pot
	$(CC) -o freememapplet $(CFLAFS) $(GTK2_FLAGS) gtk/freememapplet/freememapplet.c

getcurpos:
	$(CC) -o getcurpos $(CFLAFS) $(X11_FLAGS) x/getcurpos.c

mpscan:
	$(CC) -o mpscan $(CFLAFS) cli/mpscan.c

pm13tray:
	$(CC) -o pm13tray $(CFLAFS) $(GTK2_FLAGS) gtk/pm13tray.c

picscale:
	$(CC) -o picscale $(CFLAFS) $(GTK2_FLAGS) gtk/picscale.c

setvol:
	$(CC) -o setvol $(CFLAFS) $(GTK2_FLAGS) cli/setvol.c

install:
	#--
	install -d $(DESTDIR)$(INSTALL_PATH)
	install -s -m 0755 freememapplet $(DESTDIR)$(INSTALL_PATH)
	install -m 0755 gtk/freememapplet/freememappletshell $(DESTDIR)$(INSTALL_PATH)
	ln -snf freememappletshell $(DESTDIR)$(INSTALL_PATH)/freememapplet_tray
	install -d $(DESTDIR)$(INSTALL_XDG_START)
	install -m 0644 gtk/freememapplet/freememapplet_tray.desktop $(DESTDIR)$(INSTALL_XDG_START)
	#--
	install -s -m 0755 getcurpos $(DESTDIR)$(INSTALL_PATH)
	install -s -m 0755 mpscan $(DESTDIR)$(INSTALL_PATH)
	install -s -m 0755 pm13tray $(DESTDIR)$(INSTALL_PATH)
	#--
	install -s -m 0755 picscale $(DESTDIR)$(INSTALL_PATH)
	install -s -m 0755 setvol $(DESTDIR)$(INSTALL_PATH)

uninstall:
	#--
	rm $(INSTALL_PATH)/freememapplet
	rm $(INSTALL_PATH)/freememapplet_tray
	rm $(INSTALL_PATH)/freememappletshell
	rm $(INSTALL_XDG_START)/freememapplet_tray.desktop
	#--
	rm $(INSTALL_PATH)/getcurpos
	rm $(INSTALL_PATH)/pm13tray
	rm $(INSTALL_PATH)/mpscan
	rm $(INSTALL_PATH)/picscale
	rm $(INSTALL_PATH)/setvol

clean:
	-find -name '*.o' -delete
	-rm -f freememapplet* \
	getcurpos \
	pm13tray \
	mpscan \
	picscale \
	setvol
