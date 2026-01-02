# LGOS i386 boot makefile

include $(SOURCEDIR)/common.mk

hd_ext2_img := $(builddir)/hd_ext2.img

$(hd_ext2_img): $(boot_mbr_elf) $(boot_ext2_elf) $(loader_elf) | $(builddir)
	$(sourcedir)/mkimg.sh "$@" hd 100M 2048 20480 Ext2 $^

hd_fat_img := $(builddir)/hd_fat.img

$(hd_fat_img): $(boot_mbr_elf) $(boot_fat_elf) $(loader_elf) | $(builddir)
	$(sourcedir)/mkimg.sh "$@" hd 100M 2048 20480 FAT $^
