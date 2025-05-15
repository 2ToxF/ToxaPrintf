# ToxaPrintf
My implementation of C standard lib printf() function


## Usage as module
If you want to use ToxaPrintf.s as module in C files, you should compile and assemble your C files without linking:
```
gcc -c <your C file>
```

Also you need to assemble ToxaPrintf.s without linking:
```
nasm -f elf64 ToxaPrintf.s
```

And then link them with ToxaPrintf.o (!!!pay attentrion, that code in `ToxaPrintf.s` is position-dependent, so `-no-pie` flag is neccessary):
```
gcc -no-pie <your object files> ToxaPrintf.o
```


## Peculiarities
Available specificators: \
`%d` - signed decimal \
`%b` - binary representation of a number \
`%o` - octal representation of a number \
`%x` - hexadecimal representation of a number \
`%c` - character from ASCII-table \
`%s` - string \
`%%` - `%` character

If you want to print negative number with `%d`, you should pass argument as long long.
