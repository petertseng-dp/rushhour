require "spec"
require "../src/rushhour"

inputs = [
  {
    "
......
......
RR....>
......
......
......
  ",
    5,
  },
  {
    "
..A...
..A...
RRA...>
......
......
......
",
    8,
  },
  {
    # I originally cared about this case because my code would move Z, Y, W, Y
    # and I wanted to see if I could get it to move Z, W, Y instead.
    # It's the same number of single-square moves, but fewer cars move.
    # The number of single-square moves should still be the primary to optimise for.
    # The number of distinct cars moved would have been the secondary.
    # I did not implement this secondary.
    "
.....Y
.....Y
...RRY>
...ZZZ
......
...WWW
",
    7,
  },
  {
    "
GAA..Y
G.V..Y
RRV..Y>
..VZZZ
....B.
WWW.B.
",
    34,
  },
  {
    "
TTTAU.
...AU.
RR..UB>
CDDFFB
CEEG.H
VVVG.H
",
    14,
  },
  {
    "
QQQWEU
TYYWEU
T.RREU>
IIO...
.PO.AA
.PSSDD
",
    94,
  },
  {
    "
..ABBC
..A..C
..ARRC>
...EFF
GHHE..
G..EII
",
    84,
  },
]

describe :solve do
  it "solves" do
    inputs.each { |board, moves|
      cars = parse_cars(board.strip)
      soln = solve(cars).not_nil!
      soln.size.should eq(moves)
    }
  end
end
