SiegeUnitConverterErl
=====================

Siege Unit Converter, in Erlang.

An experimental rewriting of the very old C++ version of this program - converting sprites from the old game Siege to BMP, and back again. I originally wrote this to test if I had got the basics of the sequential parts of Erlang nailed.

This program will convert 256-colour bitmaps to Siege's proprietary MUT format, and back again, allowing you to replace sprites for units in the game.

Call the functions to_bmp and to_mut with the path to the file to work the magic. Alternatively, pass a list of paths to many_to_mut or many_to_bmp to convert batches.

Siege Unit Converter is MIT Licensed.

Siege is copyright Mindcraft Software, Inc.
http://www.mobygames.com/game/siege/
