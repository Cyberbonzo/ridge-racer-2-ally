/* Ridge Racer 2 EU, Nimbus Alpha 2.2.1 x86-64. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct Lift {
    uint32_t version, size;
    unsigned char metadata[32];
    void (*dispatch)(void *);
    void *trailer;
};

extern uint64_t nimbus_psp_machine_field(void *machine);
static struct Lift game;
static void (*run_original)(void *);
/* The pinned EU core exposes its PSP address space and machine in this context. */
static uint64_t last_field = UINT64_MAX;

static void run_with_nitro(void *cpu)
{
    unsigned char *ram;
    void *machine;
    memcpy(&ram, (char *)cpu + 0x368, sizeof ram);
    memcpy(&machine, (char *)cpu + 0x370, sizeof machine);
    uint64_t field = nimbus_psp_machine_field(machine);
    if (field != last_field) {
        last_field = field;
        /* Only the local player's car owns this three-bottle reserve. */
        uint32_t car;
        memcpy(&car, ram + 0x08a15658, sizeof car);
        if (car >= 0x08800000 && car <= 0x09ffffff - 0x3c44 && !(car & 3)) {
            float charge;
            memcpy(&charge, ram + car + 0x3c40, sizeof charge);
            if (getenv("RR2_NITRO_LOG") && field % 60 == 0)
                fprintf(stderr, "[nitro] field=%llu car=%08x charge=%.2f\n",
                        (unsigned long long)field, car, charge);
            if (charge >= 0.0f && charge < 300.0f) {
                charge = 300.0f;
                memcpy(ram + car + 0x3c40, &charge, sizeof charge);
            }
        }
    }
    run_original(cpu);
}

const struct Lift *nimbus_psp_get_lift_info(void)
{
    void *original = dlopen("$ORIGIN/UCES00422.so", RTLD_NOW | RTLD_LOCAL);
    if (!original)
        return NULL;
    const struct Lift *(*get_original)(void) = dlsym(original, "nimbus_psp_get_lift_info");
    const struct Lift *info = get_original ? get_original() : NULL;
    if (!info || info->version != 1 || info->size != sizeof game || !info->dispatch)
        return NULL;
    game = *info;
    run_original = game.dispatch;
    game.dispatch = run_with_nitro;
    return &game;
}
