#!/bin/ruby

require 'json'
require 'stringio'



#
# Complete the 'findLargestSquareSize' function below.
#
# The function is expected to return an INTEGER.
# The function accepts 2D_INTEGER_ARRAY samples as parameter.
#

def findLargestSquareSize(samples)
  # Write your code here
  size = 0
  samples.each_with_index do |row, ridx|
    row.each_with_index do |value, cidx|
      range = 1
      if  value == 1
        size = check_defective(samples, ridx, cidx, range)
      end
    end
  end
  return size
end

def check_defective(samples, row, col, range)
  if arround_defect?(samples, row, col, range)
    check_defective(samples, row, col, range+1)
  end
  range
end

def arround_defect?(samples, row, col, range)
  cell = samples[row][col]
  return false if cell == 0

  #indices cardinales
  indices = [
    [row, col + range],
    [row + range, col + range ],
    [row + range, col],
    [row + range, col - range],
    [row , col - range],
    [row - range, col - range],
    [row - range, col],
    [row - range, col + range]
  ]

  indices.each do |r|
    #fuera de rango
    next if r[0] < 0 || r[1] < 0 || r[1] > samples[0].size-1

    return false if samples[r[0]][r[1]] == 0
  end
  true
end

sample = [
  [1,1,1,0,0],
  [1,1,1,0,0],
  [1,1,1,0,0],
  [0,0,0,0,0],
  [0,0,0,0,0],
]

result = findLargestSquareSize(sample)
puts result
