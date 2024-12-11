/* LGOS i386 loader disk C file */

#include "disk.h"
#include "misc.h"
#include "video.h"

#define DISK_INT        0x13    /* disk interrupt */
#define DISK_RESET      0x00    /* reset disk system */
#define DISK_READSEC    0x02    /* read sectors */
#define DISK_GETPRM     0x08    /* get drive parameters */
#define DISK_GETTYPE    0x15    /* get disk type */
#define DISK_EXTCHK     0x41    /* int13 ext. installation check */
#define DISK_EXTGETPRM  0x48    /* int13 ext. get drive parameters */
#define DISK_EXTREAD    0x42    /* int13 ext. read, LBA */

#define DISK_FDDRETRY   0x05    /* retry FDD reads this many times */

#define NDISK           0x10    /* max number of disks */

#define SECSZ           0x200   /* sector size */
#define CACHESZ         (0x10000 / (SECSZ))     /* cache size in sectors */

#define HDFLAG          0x80    /* HDD bit in disk number */
#define IS_HD(drive)    (((drive) & HDFLAG) != 0)  /* drive is a HD */
#define IS_FD(drive)    (! IS_HD(drive))           /* drive is a FD */

#define FDD_360         0x01    /* 5 1/4" 360 KB */
#define FDD_12          0x02    /* 5 1/4" 1.2 MB */
#define FDD_720         0x03    /* 3 1/2" 720 KB */
#define FDD_144         0x04    /* 3 1/2" 1.44 MB */
#define FDD_288A        0x05    /* 3 1/2" 2.88 MB, some AMI 486 BIOS */
#define FDD_288         0x06    /* 3 1/2" 2.88 MB */
#define FDD_UNK         0xff    /* unknown FDD type */

struct s_diskgeo {
  uint8_t initialized;          /* this disk is initialized */
  uint8_t drive;                /* BIOS nulmber of disk drive */
  uint8_t lba;                  /* ext int13, LBA read */
  uint8_t ftype;                /* floppy type */
  uint16_t cyls;                /* number of cylinders, starts by 0 */
  uint16_t heads;               /* number of heads, starts by 0 */
  uint64_t lbatotsec;           /* total number of LBA sectors on device */
  uint8_t secs;                 /* number of sectors, starts by 1 */
  uint8_t valid;                /* using this record */
  uint8_t chng;                 /* removable disk, can test disk change */
  uint8_t extchng;              /* extended int13 disk change */
  uint8_t media;                /* is media in drive? */
  uint8_t _[3];
};

static struct s_diskgeo a_diskgeo[NDISK];       /* array of disk geos */

struct s_cache {                /* read cache, 64 KB above program segment */
  uint8_t drive;                /* BIOS drive */
  uint8_t valid;                /* 0 = not used, 1 = used */
  uint16_t counter;             /* number of read operation */
  uint32_t lba;                 /* LBA of sector */
};

static uint16_t read_cnt = 0;
static uint16_t cacheseg;
static struct s_cache a_cache[CACHESZ];

struct s_dpa {                  /* disk address packet for ext int13 read */
  uint8_t size;                 /* size of packet */
  uint8_t zero;                 /* reserved byte = 0 */
  uint16_t cnt;                 /* number of blocks to transfer */
  uint16_t offs;                /* pointer to buffer, offset */
  uint16_t seg;                 /* pointer to buffer, seg */
  uint64_t lba;                 /* LBA address of 1st sector to read */
};

struct s_e13drvpar {            /* ext int13 drive parameters */
  uint16_t size;                /* size of buffer; call */
  uint16_t flags;               /* information flags */
  uint32_t pcyls;               /* number of phys cylinders */
  uint32_t pheads;              /* number of phys heads */
  uint32_t psecs;               /* number of phys sectors */
  uint64_t totsec;              /* total number of sectors */
  uint16_t bytespsecs;          /* bytes per sectors */
} __attribute__ ((packed));

struct s_floppytyp {            /* floppy type structure */
  uint8_t cyls;
  uint8_t heads;
  uint8_t secs;
};

#define FD160           0       /* floppy disk types    */
#define FD180           1
#define FD320           2
#define FD360           3
#define FD12            4
#define FD720           5
#define FD144           6
#define FD288           7

static struct s_floppytyp a_floppytyp[] = {
  {40, 1, 8},                   /* 160 KB, 5 1/4" */
  {40, 1, 9},                   /* 180 KB, 5 1/4" */
  {40, 2, 8},                   /* 320 KB, 5 1/4" */
  {40, 2, 9},                   /* 360 KB, 5 1/4" */
  {80, 2, 15},                  /* 1.2 MB, 5 1/4" */
  {80, 2, 9},                   /* 720 KB, 3 1/2" */
  {80, 2, 18},                  /* 1.44 MB, 3 1/2" */
  {80, 2, 36}                   /* 2.88 MB, 3 1/2" */
};

static uint16_t dseg;
static uint8_t tmpsec[SECSZ];

static int drv2idx(uint8_t drive);
static int media_changed(int idx);
static void init_drive(uint8_t drive);
static int readsec_chs(uint8_t drive, uint16_t cyl, uint8_t head,
                       uint8_t sec, uint16_t seg, uint16_t offs,
                       int ignorefault);
static void readsec_lba(uint8_t drive, uint32_t lba, uint16_t seg,
                        uint16_t offs);
static uint16_t readsec_cache(uint8_t drive, uint32_t lba);

void init_disk(void) {
  __asm__ __volatile__(
        "movw   %%ds, %[dseg]                   \n"
        : [dseg] "=m" (dseg)
  );
  cacheseg = (uint16_t)(dseg + 0x1000);

printf("%C1.\n", 7);     ///
readsec_cache(0x00, 0);   ///
printf("2.\n");          ///
readsec_cache(0x00, 1);   ///
printf("3.\n");          ///
}

static int drv2idx(uint8_t drive) {
  for (int i = 0; i < NDISK; i ++) {    /* find existing record */
    if (a_diskgeo[i].valid && a_diskgeo[i].drive == drive) {
      return i;
    }
  }

  for (int i = 0; i < NDISK; i ++) {    /* allocate a new record */
    if (! a_diskgeo[i].valid) {
      a_diskgeo[i].valid = 1;
      a_diskgeo[i].drive = drive;
      return i;
    }
  }

  return NDISK;                 /* not enough room for a new drive */
}

static int media_changed(int idx) {
  if (idx >= NDISK) {   /* is there room in disk geo array for this disk? */
    halt("media_changed: bad index %02hd.\n", idx);
  }

  if (a_diskgeo[idx].chng) {
    /// check media change
    __asm__ __volatile__ (
        "nop                            \n"
    );
    return 1;
  }

  if (a_diskgeo[idx].extchng) {
    /// check media change
    return 1;
  }

  return 1;     ///
  return 0;
}

static void init_drive(uint8_t drive) {
  uint8_t cf;
  uint16_t cx;
  uint16_t dx;

  int idx;
  idx = drv2idx(drive);
  if (idx >= NDISK) {   /* is there room in disk geo array for this disk? */
    halt("init_drive: no room for disk %02llx.\n", drive);
  }

  if (IS_HD(drive)) {           /* if HDD */
    uint16_t bx;
    uint16_t apisubset;

    if (! a_diskgeo[idx].initialized) {
      bx = 0x55aa;
      __asm__ __volatile__ (      /* INT13 ext installation check */
        "movb   %[disk_extchk], %%ah            \n"
        "movw   %[bx], %%bx                     \n"
        "movb   %[drive], %%dl                  \n"
        "int    %[disk_int]                     \n"
        "setcb  %[cf]                           \n"
        "movw   %%cx, %[apisubset]              \n"
        "movw   %%bx, %[bx]                     \n"
        : [cf]        "=m" (cf),
          [bx]        "+m" (bx),
          [apisubset] "=m" (apisubset)
        : [disk_extchk] "i" (DISK_EXTCHK),
          [drive]       "m" (drive),
          [disk_int]    "i" (DISK_INT)
        : "ax", "bx", "cx", "dx", "cc"
      );

      if (! cf && bx == 0xaa55) { /* extensions installed? */
        if (apisubset & 1) {
          a_diskgeo[idx].lba = 1;
        }

        if (apisubset & 2) {
          a_diskgeo[idx].extchng = 1;
        }
      }
    }

    if ((! a_diskgeo[idx].initialized || media_changed(idx)) &&
      a_diskgeo[idx].lba) {
      struct s_e13drvpar par;
printf("%Cc%C", 4, 7);  ///
      par.size = 0x1a;
      __asm__ __volatile__ (  /* INT13 ext get total number of sectors */
        "movb   %[disk_extgetprm], %%ah         \n"
        "movb   %[drive], %%dl                  \n"
        "leaw   %[par], %%si                    \n"
        "int    %[disk_int]                     \n"
        "setcb  %[cf]                           \n"
        : [cf]        "=m" (cf)
        : [disk_extgetprm] "i" (DISK_EXTGETPRM),
          [drive]          "m" (drive),
          [par]            "m" (par),
          [disk_int]       "i" (DISK_INT)
        : "ax", "dl", "si", "cc", "memory"
      );
      a_diskgeo[idx].lbatotsec = cf ? 0 : par.totsec;
    }

    if (! a_diskgeo[idx].initialized && ! a_diskgeo[idx].lba) {
      __asm__ __volatile__ (      /* get disk parameters */
        "movb   %[disk_getprm], %%ah            \n"
        "movb   %[drive], %%dl                  \n"
        "xorw   %%cx, %%cx                      \n"
        "pushw  %%es                            \n"
        "int    %[disk_int]                     \n"
        "popw   %%es                            \n"
        "setcb  %[cf]                           \n"
        "movw   %%cx, %[cx]                     \n"
        "movw   %%dx, %[dx]                     \n"

        : [cf] "=m" (cf),
          [cx] "=m" (cx),
          [dx] "=m" (dx)
        : [disk_getprm] "i" (DISK_GETPRM),
          [drive]       "m" (drive),
          [disk_int]    "i" (DISK_INT)
        : "ax", "bl", "cx", "dx", "di", "cc"
      );

      if (cf || (cx & 0x3f) == 0) {
        halt("Can not initialize disk 0x%02hhx.", drive);
      }

      a_diskgeo[idx].cyls = (uint16_t)(((cx << 2 & 0x300) |
                                           (cx >> 8 & 0xff)) + 1);
      a_diskgeo[idx].heads = (uint16_t)((dx >> 8 & 0xff) + 1);
      a_diskgeo[idx].secs = cx & 0x3f;
    }

    a_diskgeo[idx].media = 1;
  }
  else {                        /* if FDD */
    if (! a_diskgeo[idx].initialized) {
      uint8_t ftype;
      __asm__ __volatile__ (    /* get disk parameters */
        "movb   %[disk_getprm], %%ah            \n"
        "movb   %[drive], %%dl                  \n"
        "xorw   %%cx, %%cx                      \n"
        "pushw  %%es                            \n"
        "int    %[disk_int]                     \n"
        "popw   %%es                            \n"
        "setcb  %[cf]                           \n"
        "movw   %%cx, %[cx]                     \n"
        "movb   %%bl, %[ftype]                  \n"

        : [cf]    "=m" (cf),
          [cx]    "=m" (cx),
          [ftype] "=m" (ftype)
        : [disk_getprm] "i" (DISK_GETPRM),
          [drive]       "m" (drive),
          [disk_int]    "i" (DISK_INT)
        : "ax", "bl", "cx", "dx", "di", "cc"
      );
printf("%Cftype=%hhd.\n%C", 5, ftype, 7);  ///

      a_diskgeo[idx].ftype = cf || (cx & 0x3f) == 0 ? FDD_UNK : ftype;

      uint8_t ah;
      __asm__ __volatile__ (      /* get disk change line capability */
        "movb   %[disk_gettype], %%ah           \n"
        "movb   %[drive], %%dl                  \n"
        "movb   $0xff, %%al                     \n"
        "int    %[disk_int]                     \n"
        "setcb  %[cf]                           \n"
        "movb   %%ah, %[ah]                     \n"

        : [cf]    "=m" (cf),
          [ah]    "=m" (ah)
        : [disk_gettype] "i" (DISK_GETTYPE),
          [drive]        "m" (drive),
          [disk_int]     "i" (DISK_INT)
        : "ax", "cx", "dx", "cc"
      );
printf("%Cchange line: %hd, %hhd%C\n", 3, cf, ah, 7); ///
      if (! cf && ah == 2) {
        a_diskgeo[idx].chng = 1;        /* change line support */
      }
    }

    if (! a_diskgeo[idx].initialized || media_changed(idx)) {
printf("%Cd%C", 4, 7);  ///
      uint16_t offs;
      offs = (uint16_t)(uintptr_t)&tmpsec;

      int disktype;
      disktype = FDD_UNK;

      switch (a_diskgeo[idx].ftype) {  /* what type of disk is in the drive? */
        case FDD_288:
        case FDD_288A:
          if (readsec_chs(drive, 0, 0, a_floppytyp[FD288].secs, dseg, offs, 1)) {
            disktype = FD288;       /* 2.88 MB */
          }
          __attribute__ ((fallthrough));
        case FDD_144:
          if (readsec_chs(drive, 0, 0, a_floppytyp[FD144].secs, dseg, offs, 1)) {
            disktype = FD144;       /* 1.44 MB */
          }
          __attribute__ ((fallthrough));
        case FDD_720:
          if (readsec_chs(drive, 0, 0, a_floppytyp[FD720].secs, dseg, offs, 1)) {
            disktype = FD720;       /* 720 KB */
          }
          break;
        case FDD_12:
          if (readsec_chs(drive, 0, 0, a_floppytyp[FD12].secs, dseg, offs, 1)) {
            disktype = FD12;        /* 1.2 MB */
          }
          __attribute__ ((fallthrough));
        case FDD_360:
          if (readsec_chs(drive, 0, 0, a_floppytyp[FD360].secs, dseg, offs, 1)) {
            if (readsec_chs(drive, 0, (uint8_t)(a_floppytyp[FD360].heads - 1),
              a_floppytyp[FD360].secs, dseg, offs, 1)) {
              disktype = FD360;     /* 360 MB */
            }
            else {
              disktype = FD180;     /* 180 MB */
            }
          }
          if (readsec_chs(drive, 0, 0, a_floppytyp[FD320].secs, dseg, offs, 1)) {
            if (readsec_chs(drive, 0, (uint8_t)(a_floppytyp[FD320].heads - 1),
              a_floppytyp[FD320].secs, dseg, offs, 1)) {
              disktype = FD320;     /* 320 MB */
            }
            else {
              disktype = FD160;     /* 160 MB */
            }
          }
          break;
        default:
          break;
      }

      if (disktype == FDD_UNK) {
        a_diskgeo[idx].media = 0;
        a_diskgeo[idx].cyls = 0;
        a_diskgeo[idx].heads = 0;
        a_diskgeo[idx].secs = 0;
      }
      else {
        a_diskgeo[idx].media = 1;
        a_diskgeo[idx].cyls = a_floppytyp[disktype].cyls;
        a_diskgeo[idx].heads = a_floppytyp[disktype].heads;
        a_diskgeo[idx].secs = a_floppytyp[disktype].secs;
      }
    }
  }

  a_diskgeo[idx].initialized = 1;
}

static int readsec_chs(uint8_t drive, uint16_t cyl, uint8_t head,
                       uint8_t sec, uint16_t seg, uint16_t offs,
                       int ignorefault) {
  uint16_t cylw;
  uint8_t  cf;
  uint8_t  stat;

  int cnt = 0;
  cylw = (uint16_t)((cyl & 0xff) << 8 | (cyl & 0x300) >> 2 | (sec & 0x3f));
printf("readsec_chs: %d, %d, %d\n", cyl, head, sec);  ///

  do {
    __asm__ __volatile__ (      /* read 1 sector */
        "movb   %[disk_readsec], %%ah           \n"
        "movb   $1, %%al                        \n"     /* number of secs */
        "movw   %[cylw], %%cx                   \n"
        "movb   %[head], %%dh                   \n"
        "movb   %[drive], %%dl                  \n"
        "pushw  %%es                            \n"
        "movw   %[seg], %%es                    \n"
        "movw   %[offs], %%bx                   \n"
        "stc                                    \n"     /* BIOS bug */
        "int    %[disk_int]                     \n"
        "sti                                    \n"     /* BIOS bug */
        "popw   %%es                            \n"
        "setcb  %[cf]                           \n"
        "movb   %%ah, %[stat]                   \n"
        : [cf]           "=m" (cf),
          [stat]         "=m" (stat)
        : [disk_readsec] "i" (DISK_READSEC),
          [cylw]         "m" (cylw),
          [head]         "m" (head),
          [drive]        "m" (drive),
          [seg]          "m" (seg),
          [offs]         "m" (offs),
          [disk_int]     "i" (DISK_INT)
        : "ax", "bx", "cx", "dx", "cc", "memory"
    );

    if (cf) {                   /* error */
      uint8_t  rcf;
      uint8_t  rstat;
printf("*");  ///

      __asm__ __volatile__ (    /* disk reset */
        "movb   %[disk_reset], %%ah             \n"
        "movb   %[drive], %%dl                  \n"
        "int    %[disk_int]                     \n"
        "setcb  %[rcf]                          \n"
        "movb   %%ah, %[rstat]                  \n"
        : [rcf]   "=m" (rcf),
          [rstat] "=m" (rstat)
        : [disk_reset] "i" (DISK_RESET),
          [drive]      "m" (drive),
          [disk_int]   "i" (DISK_INT)
        : "ah", "dl", "cc"
      );

      if (rcf) {
        halt("Disk 0x%02hhx reset error, status = 0x%02hhx.", drive, rstat);
      }
    }
  } while (cf && IS_FD(drive) && ++ cnt < DISK_FDDRETRY);

  if (cf && ! ignorefault) {
    halt("Disk 0x%02hhx error, status = 0x%02hhx.", drive, stat);
  }

  return ! cf;
}

static void readsec_lba(uint8_t drive, uint32_t lba, uint16_t seg,
                        uint16_t offs) {
  uint8_t  cf;
  uint8_t  stat;
  struct s_dpa dpa;

  dpa.size = sizeof(dpa);
  dpa.zero = 0;
  dpa.cnt = 1;
  dpa.seg = seg;
  dpa.offs = offs;
  dpa.lba = lba;

  __asm__ __volatile__ (      /* read 1 sector */
        "movb   %[disk_extread], %%ah           \n"
        "movb   %[drive], %%dl                  \n"
        "leaw   %[dpa], %%si                    \n"
        "int    %[disk_int]                     \n"
        "setcb  %[cf]                           \n"
        "movb   %%ah, %[stat]                   \n"
        : [cf]           "=m" (cf),
          [stat]         "=m" (stat)
        : [disk_extread] "i" (DISK_EXTREAD),
          [drive]        "m" (drive),
          [dpa]          "m" (dpa),
          [disk_int]     "i" (DISK_INT)
        : "ah", "dl", "si", "cc", "memory"
  );

  if (cf) {
    halt("Disk 0x%02hhx error, status = 0x%02hhx.", drive, stat);
  }
}

static uint16_t readsec_cache(uint8_t drive, uint32_t lba) {
  int cidx;
  uint16_t p;
printf("readsec_cache: %02hhx, %ld.  ----------------------\n", drive, lba);  ///

  for (int i = 0; i < CACHESZ; i ++) {  /* search in cache */
    if (a_cache[i].valid && a_cache[i].drive == drive &&
      a_cache[i].lba == lba) {
      p = (uint16_t)(cidx * SECSZ);
      return p;                 /* cache hit       */
    }
  }

  cidx = 0;                     /* find least recent cache block */
  for (int i = 0; i < CACHESZ; i ++) {
    if (! a_cache[i].valid) {   /* not used cache block */
      cidx = i;
      break;
    }
    else {
      if (a_cache[i].counter < a_cache[cidx].counter) {
        cidx = i;
      }
    }
  }
  p = (uint16_t)(cidx * SECSZ);

  int idx;
  idx = drv2idx(drive);
  if (idx >= NDISK) {   /* is there room in disk geo array for this disk? */
    halt("readsec_cache: invalid disk drive: %02llx.\n", drive);
  }
printf("%Ca%C", 2, 7);  ///
  init_drive(drive);
printf("%Cb%C", 2, 7);  ///

  if (a_diskgeo[idx].lba) {     /* LBA read */
    /// test a_diskgeo lbatotsec against lba
    /// test what happens when no CD in CD-ROM drive
    readsec_lba(drive, lba, cacheseg, p);
  }
  else {                        /* CHS read */
    if (a_diskgeo[idx].media) {
      uint16_t cyl;
      uint8_t head;
      uint8_t sec;

      cyl = (uint16_t)(lba / a_diskgeo[idx].secs / a_diskgeo[idx].heads);
      if (cyl > a_diskgeo[idx].cyls) {
        halt("Geom error on disk %02hhx.\n", drive);
      }
      head = (uint8_t)(lba / a_diskgeo[idx].secs % a_diskgeo[idx].heads);
      sec = (uint8_t)(lba % a_diskgeo[idx].secs + 1);
      readsec_chs(drive, cyl, head, sec, cacheseg, p, 0);
    }
    else {
      halt("No media found in disk 0x%02hhx.", drive);
    }
  }

  a_cache[idx].drive = drive;
  a_cache[idx].valid = 1;
  a_cache[idx].counter = read_cnt ++;
  a_cache[idx].lba = lba;

  return p;
}
