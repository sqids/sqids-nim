# To run these tests, simply execute `nimble test`.

import unittest
import sqids

test "simple":
  let sqids = initSqids(alphabet = "0123456789abcdef")

  let numbers = @[1'u64, 2, 3]
  let id = "489158"

  check sqids.encode(numbers) == id
  check sqids.decode(id) == numbers

test "short alphabet":
  let sqids = initSqids(alphabet = "abc")

  let numbers = @[1'u64, 2, 3]
  check sqids.decode(sqids.encode(numbers)) == numbers

test "long alphabet":
  let sqids = initSqids(alphabet = """abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_+|{}[];:\'"/?.>,<`~""")

  let numbers = @[1'u64, 2, 3]
  check sqids.decode(sqids.encode(numbers)) == numbers

test "multibyte characters":
  expect ValueError:
    # Alphabet cannot contain multibyte characters
    discard initSqids(alphabet = "ë1092")

test "repeating alphabet characters":
  expect ValueError:
    # Alphabet must contain unique characters
    discard initSqids(alphabet = "aabcdefg")

test "too short of an alphabet":
  expect ValueError:
    # Alphabet length must be at least 3
    discard initSqids(alphabet = "ab")
