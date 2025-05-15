extern int ToxaPrintf(const char*, ...);


int main()
{
    ToxaPrintf("? = %? | %% | d = %d | c = %c | x = %x | o = %o | b = %b | s = %s",
               -264L, 'R', 0x6a4f, 0724, 0b1011100, "TOXA!!!");
    return 0;
}
