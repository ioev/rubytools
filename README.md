# rubytools

Some ruby tools I wrote specifically for the "Classic Controls" rom hacks.

## Bingrep

Binary grepping tool, can be used on a single file or a folder of files to grep in text or hex.

Can be run in an interactive mode: `bingrep -i ./`

And search for a hex string using something like: `? 0x0001`

You can also use "_" to print the offset relative:

`? 0x00_01`

Which can help if want a specific position in a string.

## Polypatch

Readable patch format for replacing binary data in a collection of files.

Check the examples folder for an example of the patch format.

Multiple PATCH statements can be used in a single file, and comments are marked with #