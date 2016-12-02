require 'set'

# Include the edges in these numbers.
# Constraint: With 64-bit integers, WIDTH * HEIGHT <= 64
WIDTH = 8
HEIGHT = 8

# Assumption: These squares are edges so it's OK to reuse these bits.
VERTICAL = 1
HORIZONTAL = 2

CAR_ORIENTATION = VERTICAL | HORIZONTAL
CAR_POSITION = -1 & ~CAR_ORIENTATION

def square(row:, col:)
  1 << (row * HEIGHT + col)
end

ESCAPE = square(row: 3, col: WIDTH - 1)

EDGE = (0...(WIDTH * HEIGHT)).select { |n|
  col = n % WIDTH
  row = n / WIDTH
  col == 0 || row == 0 || col == (WIDTH - 1) || row == (HEIGHT - 1)
}.map { |n| 1 << n }.reduce(:|) & ~ESCAPE
raise "bad edge #{EDGE.to_s(16)}" unless EDGE.to_s(16) == 'ff818181018181ff'

ROWS = (0...HEIGHT).map { |row| (0...WIDTH).map { |col| square(row: row, col: col) }.reduce(:|) }
COLS = (0...WIDTH).map { |col| (0...HEIGHT).map { |row| square(row: row, col: col) }.reduce(:|) }

def parse_cars(grid)
  cars = Hash.new(0)
  grid.each_line.with_index { |line, row|
    line.chomp.each_char.with_index { |c, col|
      next if c == '>' || c == '.'
      cars[c] |= square(row: row + 1, col: col + 1)
    }
  }

  cars.each { |car, squares|
    horiz_car, vert_car = [ROWS, COLS].map { |lines|
      lines.count { |line| squares & line != 0 } == 1
    }
    raise "#{car} can't be both vertical and horizontal" if horiz_car && vert_car
    raise "#{car} can't be neither vertical nor horizontal" if !horiz_car && !vert_car
    cars[car] |= HORIZONTAL if horiz_car
    cars[car] |= VERTICAL if vert_car
  }

  cars
end

def solve(initial_cars)
  # prev[current_board] = [cars, car, dir]
  prev = {initial_cars => nil}
  queue = [initial_cars]
  while (current_cars = queue.shift)
    # Could mask out the orientation, but it doesn't matter
    # because the orientation is an edge
    board = current_cars.values.reduce(EDGE, :|)
    current_cars.each { |car, squares_and_orientation|
      squares = squares_and_orientation & CAR_POSITION
      board_without_car = board & ~squares
      [
        [HORIZONTAL, ->(s) { s << 1 }, :right],
        [HORIZONTAL, ->(s) { s >> 1 }, :left],
        [VERTICAL, ->(s) { s << WIDTH }, :down],
        [VERTICAL, ->(s) { s >> WIDTH }, :up],
      ].each { |orientation, move_f, move_dir|
        next if squares_and_orientation & orientation == 0
        new_position = move_f[squares]
        next unless board_without_car & new_position == 0

        if new_position & ESCAPE != 0
          trace_current_cars = current_cars
          moves = [[car, move_dir]]
          while (prev_move = prev[trace_current_cars])
            prev_cars, prev_move_car, prev_move_dir = prev_move
            moves << [prev_move_car, prev_move_dir]
            trace_current_cars = prev_cars
          end
          return moves.reverse
        end

        # If cars ever have more than one orientation, it will be lost at the below line.
        new_cars = current_cars.merge(car => new_position | orientation)
        next if prev.has_key?(new_cars)
        queue << new_cars
        prev[new_cars] = [current_cars, car, move_dir]
      }
    }
  end
end

def chunk_moves(moves)
  prev_move = nil
  moves.each_with_object([]) { |move, chunked|
    if move == prev_move
      chunked[-1][-1] += 1
    else
      chunked << move + [1]
      prev_move = move
    end
  }
end

INPUTS = ['
......
......
RR....>
......
......
......
','
..A...
..A...
RRA...>
......
......
......
','
GAA..Y
G.V..Y
RRV..Y>
..VZZZ
....B.
WWW.B.
','
.....Y
.....Y
...RRY>
...ZZZ
......
...WWW
','
TTTAU.
...AU.
RR..UB>
CDDFFB
CEEG.H
VVVG.H
','
QQQWEU
TYYWEU
T.RREU>
IIO...
.PO.AA
.PSSDD
','
..ABBC
..A..C
..ARRC>
...EFF
GHHE..
G..EII
'].map(&:strip)

INPUTS.each { |input|
  start = Time.now
  cars = parse_cars(input)
  soln = solve(cars)
  puts input
  chunk_moves(soln).each_with_index { |(car, dir, n), i|
    puts '%2d. %s %5s %d' % [i + 1, car, dir, n]
  }
  puts "Cars moved a total of #{soln.size} spaces"
  puts "Solved in #{Time.now - start}"
  puts
}
