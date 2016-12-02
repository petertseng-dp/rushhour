# Name

[![Build Status](https://travis-ci.org/petertseng-dp/rushhour.svg?branch=master)](https://travis-ci.org/petertseng-dp/rushhour)

# Notes

I used a similar solution as a Reddit poster - represent the board as a bitfield.
The maximum supported board size is 6x6, since the borders are all set to 1 to make collision detection easier.
Car orientation is set in the low-order bits (which are usually for the border).

Confession: This was originally written in Ruby and then converted to Crystal.

# Source

https://www.reddit.com/r/dailyprogrammer/comments/56bh88
