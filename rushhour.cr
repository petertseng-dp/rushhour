require "./src/rushhour"

INPUTS = [
  "
..ABBC
..A..C
..ARRC>
...EFF
GHHE..
G..EII
  ",
].map(&.strip)

INPUTS.each { |input|
  start = Time.now
  cars = parse_cars(input)
  soln = solve(cars).not_nil!
  puts input
  chunk_moves(soln).each_with_index { |(move, n), i|
    car, dir = move
    puts "%2d. %s %5s %d" % [i + 1, car, dir, n]
  }
  puts "Cars moved a total of #{soln.size} spaces"
  puts "Solved in #{Time.now - start}"
  puts
}
