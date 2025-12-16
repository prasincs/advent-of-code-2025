I tried to do most of the problems myself using zig but when I was strapped for time or if some problems looked like I could figure it out quickly but AI might struggle, I used AI - particularly claude code

## Day 6 - Part 2 

This one's one of those problems. I knew pretty soon that this was a matter of visually scanning it but I was too lazy to write the code in Zig and I intuited that Claude would too - so after many iterations, I finally got claude to get it and then I asked what would've helped it get to the problem faster.

```
Most effective prompt would have been:

  "Parse the input character-by-character, not token-by-token. Problems are separated by columns where ALL rows (including 
  the operator line) have only spaces. Within each problem, read each character column from right-to-left, and for each 
  character column, read the digits top-to-bottom to form one number."

  Key elements that would have accelerated debugging:

  1. "Character-by-character, not token-based" - This would have immediately stopped me from using parseInts() and
  space-tokenization
  2. "Space-only columns across ALL lines" - This is the critical detail I missed. I kept trying to use the operator line
  alone to find boundaries
  3. "Show me the exact character grid with positions" - If you had asked me to visualize the input like:
  Pos: 0123456789...
       123 328  51...
       ...
  3. I would have seen the column structure immediately
  4. "Write a test script first" - You suggesting to test in isolation (/tmp/test_parse.zig) was extremely helpful. Asking
  this earlier would have saved time.

  What slowed me down:

  - I kept trying to interpret the problem description abstractly instead of looking at the literal visual layout
  - I assumed "space-separated" meant using tokenization, not visual column analysis
  - I didn't realize you meant "check the EXACT spacing in sample1.txt" meant literally examining every character position

  Better initial guidance:
  "Ignore space-separated token parsing. Treat the input as a visual grid. Find columns where every single row is a space 
  character - these separate problems. Then process each problem column-by-column."

  This would have gotten me to the correct solution in probably 2-3 iterations instead of the many we went through!
```

The goal here isn't to use AI but I thought this was kinda neat.
