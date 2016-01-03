# LFNToSFN
An useful resource for OS developers to convert input text to Short FileName and Long FileName. It's made for the DOS but you can edit and use the code in your own Kernel FileSystem functions.

You can run the example as DOS 16 bit COM file.

You must compile it with [NASM](http://www.nasm.us) running the following command:

`nasm -fbin LFNToSFN.asm -o LFNToSFN.COM`

*Edit and use this code as you like in your own OS. Currently it uses DOS interrupt 21h (Because we need it for our DOS). Don't forget to remove `asm org 100h` if you aren't compiling it as COM file*
