require "set"

alias Car = Char
alias Cars = Hash(Car, UInt64)

# Include the edges in these numbers.
# Constraint: With 64-bit integers, WIDTH * HEIGHT <= 64
WIDTH  = 8_u64
HEIGHT = 8_u64

# Assumption: These squares are edges so it's OK to reuse these bits.
VERTICAL   = 1_u64
HORIZONTAL = 2_u64

CAR_ORIENTATION = VERTICAL | HORIZONTAL
CAR_POSITION    = -1 & ~CAR_ORIENTATION

def square(row, col)
  1_u64 << (row * HEIGHT + col)
end

ESCAPE = square(row: 3, col: WIDTH - 1)

EDGE = (0...(WIDTH * HEIGHT)).select { |n|
  col = n % WIDTH
  row = n / WIDTH
  col == 0 || row == 0 || col == (WIDTH - 1) || row == (HEIGHT - 1)
}.map { |n| 1_u64 << n }.reduce { |a, b| a | b } & ~ESCAPE
raise "bad edge #{EDGE.to_s(16)}" unless EDGE.to_s(16) == "ff818181018181ff"

ROWS = (0...HEIGHT).map { |row| (0...WIDTH).map { |col| square(row: row, col: col) }.reduce { |a, b| a | b } }
COLS = (0...WIDTH).map { |col| (0...HEIGHT).map { |row| square(row: row, col: col) }.reduce { |a, b| a | b } }

def parse_cars(grid)
  cars = Cars.new(0_u64)
  grid.each_line.with_index.each { |line, row|
    line.chomp.each_char.with_index.each { |c, col|
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
  prev = {} of Cars => Tuple(Cars, Car, Symbol) | Nil
  prev[initial_cars] = nil
  queue = [initial_cars]
  while (current_cars = queue.shift)
    # Could mask out the orientation, but it doesn't matter
    # because the orientation is an edge
    board = current_cars.values.reduce(EDGE) { |a, b| a | b }
    current_cars.each { |car, squares_and_orientation|
      squares = squares_and_orientation & CAR_POSITION
      board_without_car = board & ~squares
      [
        {HORIZONTAL, ->(s : UInt64) { s << 1 }, :right},
        {HORIZONTAL, ->(s : UInt64) { s >> 1 }, :left},
        {VERTICAL, ->(s : UInt64) { s << WIDTH }, :down},
        {VERTICAL, ->(s : UInt64) { s >> WIDTH }, :up},
      ].each { |orientation, move_f, move_dir|
        next if squares_and_orientation & orientation == 0
        new_position = move_f.call(squares)
        next unless board_without_car & new_position == 0

        if new_position & ESCAPE != 0
          trace_current_cars = current_cars
          moves = [{car, move_dir}]
          while (prev_move = prev[trace_current_cars])
            prev_cars, prev_move_car, prev_move_dir = prev_move
            moves << {prev_move_car, prev_move_dir}
            trace_current_cars = prev_cars
          end
          return moves.reverse
        end

        # If cars ever have more than one orientation, it will be lost at the below line.
        new_cars = current_cars.merge({car => new_position | orientation})
        next if prev.has_key?(new_cars)
        queue << new_cars
        prev[new_cars] = {current_cars, car, move_dir}
      }
    }
  end
end

def chunk_moves(moves)
  prev_move = nil
  moves.each_with_object(Array(Tuple(typeof(moves[0]), UInt32)).new) { |move, chunked|
    if move == prev_move
      chunked[-1] = {chunked[-1][0], chunked[-1][1] + 1}
    else
      chunked << {move, 1_u32}
      prev_move = move
    end
  }
end
