# [Damsteen](http://damsteen.nl) operating system

Experimental operating system based on fiddling with assembly and C.

32-bit protected mode OS. Bootloader set-ups up protected mode with the GDT, `kinit` set-up interrupts and exception handling.

## Prequisites

OS: Debian or Ubuntu on Windows.
GCC 4.9

```
apt-get install make nasm qemu
```

## Building

Make boot disk:

```
make
```

Run:

```
make run
```

Wait for GDB to attach on port 26000:

```
make debug
```

Clean output artifacts:

```
make clean
```