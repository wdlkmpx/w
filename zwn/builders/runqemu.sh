#!/bin/sh
VGA_TYPE=${VGA_TYPE:-std}
REDIR_PORT=${REDIR_PORT:-3222}
QEMU=qemu-system-x86_64
! type $QEMU > /dev/null && QEMU=qemu-system-x86
! type $QEMU > /dev/null && echo "Sorry I can't find qemu" && exit

[ "$REDIR" ] && REDIR="-redir tcp:$REDIR_PORT::22"
$QEMU -sdl -vga $VGA_TYPE -enable-kvm -m 1024 $REDIR -cdrom iso/plinux.iso
