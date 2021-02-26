# Simple C and ASM os for AMD64 architecture

## Purpose

This is a learning project where I have fun writing a barebone x86_64 OS.

It's neither meant as a tutorial nor as a finished product in any way; it's a sandbox for me to experiment in.

If you like the idea and want to try it for yourself, I recommend following one or more of the tutorials listed in the next section.

## Sources

From a combination of tutorials like:
 - [https://github.com/davidcallanan/os-series](CodePulse Os series)
 - [https://github.com/cfenollosa/os-tutorial](OS tutorials)

## Setup

Build an image for our build-environment:

```docker build buildenv -t osdev-buildenv```

## Build

Enter build environment:
- Linux: ```docker run --rm -it -v "$pwd":/root/env osdev-buildenv```
- MacOS: ```docker run --rm -it -v "$PWD":/root/env osdev-buildenv```
- Windows (CMD): ```docker run --rm -it -v "%cd%":/root/env osdev-buildenv```
- Windows (PowerShell): ```docker run --rm -it -v "${pwd}:/root/env" osdev-buildenv```
- NOTE: If you are having trouble with an unshared drive, ensure your docker daemon has access to the drive you're development environment is in. For Docker Desktop, this is in "Settings > Shared Drives" or "Settings > Resources > File Sharing".

Build for x86 (other architectures may come in the future):

```make build-x86_64```

To leave the build environment, enter ```exit```.

## Run

If the build was succesfull, you should be able to run the newly created iso with:
 - Windows: ```qemu-system-x86_64 -cdrom dist\x86_64\kernel.iso -L "C:\Program Files\qemu"```
 - Linux: ```qemu-system-x86_64 -cdrom dist\x86_64\kernel.iso```
 - MacOSX: ```qemu-system-x86_64 -cdrom dist\x86_64\kernel.iso```

## Cleanup

Remove the build-evironment image:

```docker rmi osdev-buildenv -f```
