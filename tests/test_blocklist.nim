# To run these tests, simply execute `nimble test`.

import unittest
import sqids

import std / [sets]

test "if no custom blocklist param, use the default blocklist":
  let sqids = initSqids()

  check sqids.decode("aho1e") == @[4572721'u64]
  check sqids.encode([4572721'u64]) == "JExTR"

test "if an empty blocklist param passed, don't use any blocklist":
  let sqids = initSqids(blocklist = initHashSet[string]())

  check sqids.decode("aho1e") == @[4572721'u64]
  check sqids.encode([4572721'u64]) == "aho1e"

test "if a non-empty blocklist param passed, use only that":
  let sqids = initSqids(blocklist = ["ArUO"].toHashSet())  # originally encoded [100000]

  # make sure we don't use the default blocklist
  check sqids.decode("aho1e") == @[4572721'u64]
  check sqids.encode([4572721'u64]) == "aho1e"

  # make sure we are using the passed blocklist
  check sqids.decode("ArUO") == @[100000'u64]
  check sqids.encode([100000'u64]) == "QyG4"
  check sqids.decode("QyG4") == @[100000'u64]

test "blocklist":
  let sqids = initSqids(blocklist = [
    "JSwXFaosAN",  # normal result of 1st encoding, let's block that word on purpose
    "OCjV9JK64o",  # result of 2nd encoding
    "rBHf",  # result of 3rd encoding is `4rBHfOiqd3`, let's block a substring
    "79SM",  # result of 4th encoding is `dyhgw479SM`, let's block the postfix
    "7tE6",  # result of 4th encoding is `7tE6jdAHLe`, let's block the prefix
  ].toHashSet())

  check sqids.encode([1_000_000'u64, 2_000_000]) == "1aYeB7bRUt"
  check sqids.decode("1aYeB7bRUt") == @[1_000_000'u64, 2_000_000]

test "decoding blocklist words should still work":
  let sqids = initSqids(blocklist = ["86Rf07", "se8ojk", "ARsz1p", "Q8AI49", "5sQRZO"].toHashSet())

  check sqids.decode("86Rf07") == @[1'u64, 2, 3]
  check sqids.decode("se8ojk") == @[1'u64, 2, 3]
  check sqids.decode("ARsz1p") == @[1'u64, 2, 3]
  check sqids.decode("Q8AI49") == @[1'u64, 2, 3]
  check sqids.decode("5sQRZO") == @[1'u64, 2, 3]

test "match against a short blocklist word":
  let sqids = initSqids(blocklist = ["pnd"].toHashSet())

  check sqids.decode(sqids.encode([1000'u64])) == @[1000'u64]

test "blocklist filtering in constructor":
  let sqids = initSqids(
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
    blocklist = ["sxnzkl"].toHashSet()  # lowercase blocklist in only-uppercase alphabet
  )

  let id = sqids.encode([1'u64, 2, 3])
  let numbers = sqids.decode(id)

  check id == "IBSHOZ"
  check numbers == @[1'u64, 2, 3]

test "max encoding attempts":
  const
    alphabet = "abc"
    minLength = 3
    blocklist = ["cab", "abc", "bca"].toHashSet()

  let sqids = initSqids(
    alphabet = alphabet,
    minLength = minLength,
    blocklist = blocklist,
  )

  check sqids.alphabet.len == minLength
  check sqids.blocklist.len == minLength

  expect ValueError:
    # Reached max attempts to re-generate the ID
    discard sqids.encode([0'u64])
