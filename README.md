# [Damsteen](http://damsteen.nl) operating system

Experimental operating system based on fiddling with assembly and C.

32-bit protected mode OS. Bootloader set-ups up protected mode with the GDT, `kinit` set-up interrupts and exception handling.

## Prequisites

OS: Debian or "Windows subsystem for Linux" (WSL) with Ubuntu.
GCC 4.9

```
apt-get install build-essential make nasm qemu gcc-multilib g++-multilib
```

If using *WSL*, don't forget to [install an X display server like XMing](https://damsteen.nl/blog/2016/08/20/run-gui-programs-on-bash-on-ubuntu-on-windows), and set the `DISPLAY` variable.

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