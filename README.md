# [Damsteen](http://damsteen.nl) operating system

Experimental operating system based on fiddling with assembly and C.

16-bit BIOS dependent OS.

## Prequisites

OS: Debian or Ubuntu on Windows.

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