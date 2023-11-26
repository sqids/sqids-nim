# To run these tests, simply execute `nimble test`.

import unittest
import sqids

test "simple":
  let sqids = initSqids()

  let numbers = [1'u64, 2, 3]
  let id = "86Rf07"

  check sqids.encode(numbers) == id
  check sqids.decode(id) == numbers

test "different inputs":
  let sqids = initSqids()

  let numbers = [0'u64, 0, 0, 1, 2, 3, 100, 1_000, 100_000, 1_000_000, uint64.high]
  check sqids.decode(sqids.encode(numbers)) == numbers

test "incremental numbers":
  let sqids = initSqids()

  const ids = {
    "bM": [0'u64],
    "Uk": [1'u64],
    "gb": [2'u64],
    "Ef": [3'u64],
    "Vq": [4'u64],
    "uw": [5'u64],
    "OI": [6'u64],
    "AX": [7'u64],
    "p6": [8'u64],
    "nJ": [9'u64],
  }

  for (id, numbers) in ids:
    check sqids.encode(numbers) == id
    check sqids.decode(id) == numbers

test "incremental numbers, same index 0":
  let sqids = initSqids()

  const ids = {
    "SvIz": [0'u64, 0],
    "n3qa": [0'u64, 1],
    "tryF": [0'u64, 2],
    "eg6q": [0'u64, 3],
    "rSCF": [0'u64, 4],
    "sR8x": [0'u64, 5],
    "uY2M": [0'u64, 6],
    "74dI": [0'u64, 7],
    "30WX": [0'u64, 8],
    "moxr": [0'u64, 9],
  }

  for (id, numbers) in ids:
    check sqids.encode(numbers) == id
    check sqids.decode(id) == numbers

test "incremental numbers, same index 1":
  let sqids = initSqids()

  const ids = {
    "SvIz": [0'u64, 0],
    "nWqP": [1'u64, 0],
    "tSyw": [2'u64, 0],
    "eX68": [3'u64, 0],
    "rxCY": [4'u64, 0],
    "sV8a": [5'u64, 0],
    "uf2K": [6'u64, 0],
    "7Cdk": [7'u64, 0],
    "3aWP": [8'u64, 0],
    "m2xn": [9'u64, 0],
  }

  for (id, numbers) in ids:
    check sqids.encode(numbers) == id
    check sqids.decode(id) == numbers

test "multi input":
  let sqids = initSqids()

  const numbers = [
    0'u64, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
    26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49,
    50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73,
    74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97,
    98, 99
  ]

  let output = sqids.decode(sqids.encode(numbers))
  check numbers == output

test "encoding no numbers":
  let sqids = initSqids()
  check sqids.encode([]) == ""

test "decoding empty string":
  let sqids = initSqids()
  check sqids.decode("") == newSeq[uint64]()

test "decoding an ID with an invalid character":
  let sqids = initSqids()
  check sqids.decode("*") == newSeq[uint64]()

test "encode out-of-range numbers":
  let sqids = initSqids()

  # We don't support negative numbers, since encode() accepts only unsigned integers.
  check not compiles sqids.encode([-1])

  # Uint64.max is the highest number we can encode. We can't encode Uint64.max + 1
  # because it would overflow and wrap around to 0.
  check uint64.high + 1'u64 == 0'u64
  check compiles sqids.encode([uint64.high + 1'u64])
  check sqids.encode([uint64.high + 1'u64]) == sqids.encode([0'u64])
