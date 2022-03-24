#!/usr/bin/env python3
import argparse


def extract(v, i, n):
    return (v >> i) & ((1 << n) - 1)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('addr', type=lambda v: int(v, 0), nargs='*')
    args = parser.parse_args()

    for addr in args.addr:
        print(f'{addr:#x}')
        print(f'    L0 index: {extract(addr, 39, 9)}')
        print(f'    L1 index: {extract(addr, 30, 9)}')
        print(f'    L2 index: {extract(addr, 21, 9)}')
        print(f'    L3 index: {extract(addr, 12, 9)}')
        print(f'    4K page offset: {extract(addr, 0, 12):#x}')
        print(f'    2M page offset: {extract(addr, 0, 21):#x}')
        print(f'    1G page offset: {extract(addr, 0, 30):#x}')

    print()
    print('Distances:')
    for j, a2 in enumerate(args.addr):
        for a1 in args.addr[:j]:
            k = abs(a2 - a1) / 1024
            m = k / 1024
            g = m / 1024
            t = g / 1024
            print(f'    {a1:#x} -> {a2:#x}: {k:.0f}K / {m:.0f}M / {g:.0f}G / {t:.0f}T')

if __name__ == '__main__':
    main()
