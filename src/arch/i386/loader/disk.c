/* LGOS i386 loader disk C file */

#include "disk.h"
#include "misc.h"
#include "video.h"

#define DISK_INT        0x13    /* disk interrupt */
#define DISK_RESET      0x00    /* reset disk system */
#define DISK_GETST      0x01    /* get status of last operation */
#define DISK_READSEC    0x02    /* read sectors */
#define DISK_GETPRM     0x08    /* get drive parameters */
#define DISK_EXTCHK     0x41    /* int13 ext. installation check */
#define DISK_EXTREAD    0x42    /* int13 ext. read, LBA */

#define DISK_FDDRETRY   0x05    /* retry FDD reads this many times */

#define HDFLAG          0x80    /* HDD bit in disk number */

#define NDISK           0x10    /* max number of disk */

#define SECSZ           0x200   /* sector size */
#define CACHESZ         (0x10000 / (SECSZ))     /* cache size in sectors */

#define IS_HD(drive)    (((drive) & HDFLAG) != 0)  /* drive is a HD */
#define IS_FD(drive)    (! IS_HD(drive))           /* drive is a FD */

/* BIOS drive number to s_diskgeo array index:
   FDD A: = 0, FDD B: = 1, HDD C: = 2, HDD D: = 3, ... */
#define DRV2IDX(drive)  (IS_FD(drive) ? (drive) : (drive) - 0x80 + 2)

struct s_diskgeo {
  uint8_t drive;                /* BIOS nulmber of disk drive */
  uint8_t lba;                  /* ext int13, LBA read */
  uint16_t cyls;                /* number of cylinders, starts by 0 */
  uint16_t heads;               /* number of heads, starts by 0 */
  uint8_t secs;                 /* number of sectors, starts by 1 */
  uint8_t _;                    /* padding */
};

static struct s_diskgeo a_diskgeo[NDISK];       /* array of disk geos */

struct s_cache {                /* read cache, 64 KB above program segment */
  uint8_t drive;                /* BIOS drive */
  uint8_t flag;                 /* 0 = not used, used */
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

static int floppy_detect(uint8_t drive);
static void init_drive(uint8_t drive);
static void readsec_chs(uint8_t drive, uint16_t cyl, uint8_t head,
                        uint8_t sec, uint16_t seg, uint16_t offs);
static void readsec_lba(uint8_t drive, uint32_t lba, uint16_t seg,
                        uint16_t offs);
static uint16_t readsec_cache(uint8_t drive, uint32_t lba);

void init_disk(void) {
  uint16_t ds;

  for (int i = 0; i < NDISK; i ++) {
    a_diskgeo[i].drive = 0;
    a_diskgeo[i].lba = 0;
    a_diskgeo[i].cyls = 0;
    a_diskgeo[i].heads = 0;
    a_diskgeo[i].secs = 0;
  }

  __asm__ __volatile__(
        "movw   %%ds, %[ds]                     \n"
        : [ds] "=m" (ds)
  );
  cacheseg = (uint16_t)(ds + 0x1000);

  for (int i = 0; i < CACHESZ; i ++) {
    a_cache[i].drive = 0;
    a_cache[i].flag = 0;
    a_cache[i].counter = 0;
    a_cache[i].lba = 0;
  }
readsec_cache(0x80, 0);   //////////////////////
}

/*
  retrun C   H  S      type
  0       -  -   -     unknown or not exists
  1      40  2   9     360 KB, 5 1/4"
  2      80  2  15     1.2 MB, 5 1/4"
  3      80  2   9     720 KB, 3 1/2"
  4      80  2  18     1.44 MB, 3 1/2"
*/
static int floppy_detect(uint8_t drive) {
//  readsec_chs(drive, 0, 0, 18, seg, offs);
  return drive + 1;  ///////////////////////
}

static void init_drive(uint8_t drive) {
  uint8_t cf;
  uint16_t cx;
  uint16_t dx;

  int idx;
  idx = DRV2IDX(drive);

  if (idx >= NDISK) {   /* is there room in disk geo array for this disk? */
    halt("init_drive: no room for disk %02llx.\n", drive);
  }

  if (a_diskgeo[idx].drive == drive) {  /* initialized yet? */
    // TODO: reinitialize floppy after media change
    return;
  }

  if (IS_HD(drive)) {           /* if HDD */
    uint16_t bx;
    uint16_t apisubset;

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

    if (! cf && bx == 0xaa55 && apisubset & 1) {  /* extensions installed? */
      a_diskgeo[idx].drive = drive;
      a_diskgeo[idx].lba = 1;
    }
    else {
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

        "pushfw                                 \n"
        "movb   %[disk_getst], %%ah             \n"
        "movb   %[drive], %%dl                  \n"
        "int    %[disk_int]                     \n"
        "popfw                                  \n"

        : [cf] "=m" (cf),
          [cx] "=m" (cx),
          [dx] "=m" (dx)
        : [disk_getprm] "i" (DISK_GETPRM),
          [drive]       "m" (drive),
          [disk_int]    "i" (DISK_INT),
          [disk_getst]  "i" (DISK_GETST)
        : "ax", "bl", "cx", "dx", "di", "cc"
      );

      if (cf && (cx & 0x3f) > 0) {
        halt("Can not initialize disk 0x%02hhx.", drive);
      }

      a_diskgeo[idx].drive = drive;
      a_diskgeo[idx].cyls = (uint16_t)(((cx << 2 & 0x300) |
                                           (cx >> 8 & 0xff)) + 1);
      a_diskgeo[idx].heads = (uint16_t)((dx >> 8 & 0xff) + 1);
      a_diskgeo[idx].secs = cx & 0x3f;
    }
  }
  else {                        /* if FDD */
    switch (floppy_detect(drive)) {
      case 1:                   /* 360 KB, 5 1/4" */
        a_diskgeo[idx].drive = drive;
        a_diskgeo[idx].cyls = 40;
        a_diskgeo[idx].heads = 2;
        a_diskgeo[idx].secs = 9;
        break;
      case 2:                   /* 1.2 MB, 5 1/4" */
        a_diskgeo[idx].drive = drive;
        a_diskgeo[idx].cyls = 80;
        a_diskgeo[idx].heads = 2;
        a_diskgeo[idx].secs = 15;
        break;
      case 3:                   /* 720 KB, 3 1/2" */
        a_diskgeo[idx].drive = drive;
        a_diskgeo[idx].cyls = 80;
        a_diskgeo[idx].heads = 2;
        a_diskgeo[idx].secs = 9;
        break;
      case 4:                   /* 1.44 MB, 3 1/2" */
        a_diskgeo[idx].drive = drive;
        a_diskgeo[idx].cyls = 80;
        a_diskgeo[idx].heads = 2;
        a_diskgeo[idx].secs = 18;
        break;
      default:                  /* unknown or no floppy */
        a_diskgeo[idx].drive = 0;
        a_diskgeo[idx].cyls = 0;
        a_diskgeo[idx].heads = 0;
        a_diskgeo[idx].secs = 0;
        break;
        break;
    }
  }
}

static void readsec_chs(uint8_t drive, uint16_t cyl, uint8_t head,
                        uint8_t sec, uint16_t seg, uint16_t offs) {
  uint16_t cylw;
  uint8_t  cf;
  uint8_t  stat;

  int cnt = 0;
  cylw = (uint16_t)((cyl & 0xff) << 8 | (cyl & 0x300) >> 2 | (sec & 0x3f));

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

  if (cf) {
    halt("Disk 0x%02hhx error, status = 0x%02hhx.", drive, stat);
  }
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
  int idx;
  uint16_t p;

  for (int i = 0; i < CACHESZ; i ++) {  /* search in cache */
    if (a_cache[i].drive == drive && a_cache[i].flag) {
      p = (uint16_t)(idx * SECSZ);
      return p;                 /* cache hit       */
    }
  }

  idx = 0;                      /* find least recent cache block */
  for (int i = 0; i < CACHESZ; i ++) {
    if (! a_cache[i].flag) {            /* not used cache block */
      idx = i;
      break;
    }
    else {
      if (a_cache[i].counter < a_cache[idx].counter) {
        idx = i;
      }
    }
  }
  p = (uint16_t)(idx * SECSZ);


  int drvidx;
  drvidx = DRV2IDX(drive);
  if (drvidx >= NDISK) {  /* is there room in disk geo array for this disk? */
    halt("readsec_cache: invalid disk drive: %02llx.\n", drive);
  }
  if (! a_diskgeo[drvidx].drive) {
    init_drive(drive);
  }

  if (a_diskgeo[drvidx].lba) {     /* LBA read */
    readsec_lba(drive, lba, cacheseg, p);
  }
  else {                        /* CHS read */
    uint16_t cyl;
    uint8_t head;
    uint8_t sec;

    cyl = (uint16_t)(lba / a_diskgeo[drvidx].secs / a_diskgeo[drvidx].heads);
    if (cyl > a_diskgeo[drvidx].cyls) {
      halt("Geom error on disk %02hhx.\n", drive);
    }
    head = (uint8_t)(lba / a_diskgeo[drvidx].secs % a_diskgeo[drvidx].heads);
    sec = (uint8_t)(lba % a_diskgeo[drvidx].secs + 1);
    readsec_chs(drive, cyl, head, sec, cacheseg, p);
  }

  a_cache[idx].drive = drive;
  a_cache[idx].flag = 1;
  a_cache[idx].counter = read_cnt ++;
  a_cache[idx].lba = lba;

  return p;
}
