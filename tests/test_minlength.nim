# To run these tests, simply execute `nimble test`.

import unittest
import sqids
from sqids / defaults import defaultAlphabet, defaultMinLength, defaultBlocklist

test "simple":
  let sqids = initSqids(minLength = defaultAlphabet.len)

  let numbers = [1'u64, 2, 3]
  let id = "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTM"

  check sqids.encode(numbers) == id
  check sqids.decode(id) == numbers

test "incremental":
  let numbers = [1'u64, 2, 3]

  const map = {
    6: "86Rf07",
    7: "86Rf07x",
    8: "86Rf07xd",
    9: "86Rf07xd4",
    10: "86Rf07xd4z",
    11: "86Rf07xd4zB",
    12: "86Rf07xd4zBm",
    13: "86Rf07xd4zBmi",
    defaultAlphabet.len + 0:
      "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTM",
    defaultAlphabet.len + 1:
      "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMy",
    defaultAlphabet.len + 2:
      "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMyf",
    defaultAlphabet.len + 3:
      "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMyf1",
  }

  for (minLength, id) in map:
    let sqids = initSqids(minLength = uint8(minLength))
    check sqids.encode(numbers) == id
    check sqids.encode(numbers).len == minLength
    check sqids.decode(id) == numbers

test "incremental numbers":
  let sqids = initSqids(minLength = defaultAlphabet.len)

  const ids = {
    "SvIzsqYMyQwI3GWgJAe17URxX8V924Co0DaTZLtFjHriEn5bPhcSkfmvOslpBu": [0'u64, 0],
    "n3qafPOLKdfHpuNw3M61r95svbeJGk7aAEgYn4WlSjXURmF8IDqZBy0CT2VxQc": [0, 1],
    "tryFJbWcFMiYPg8sASm51uIV93GXTnvRzyfLleh06CpodJD42B7OraKtkQNxUZ": [0, 2],
    "eg6ql0A3XmvPoCzMlB6DraNGcWSIy5VR8iYup2Qk4tjZFKe1hbwfgHdUTsnLqE": [0, 3],
    "rSCFlp0rB2inEljaRdxKt7FkIbODSf8wYgTsZM1HL9JzN35cyoqueUvVWCm4hX": [0, 4],
    "sR8xjC8WQkOwo74PnglH1YFdTI0eaf56RGVSitzbjuZ3shNUXBrqLxEJyAmKv2": [0, 5],
    "uY2MYFqCLpgx5XQcjdtZK286AwWV7IBGEfuS9yTmbJvkzoUPeYRHr4iDs3naN0": [0, 6],
    "74dID7X28VLQhBlnGmjZrec5wTA1fqpWtK4YkaoEIM9SRNiC3gUJH0OFvsPDdy": [0, 7],
    "30WXpesPhgKiEI5RHTY7xbB1GnytJvXOl2p0AcUjdF6waZDo9Qk8VLzMuWrqCS": [0, 8],
    "moxr3HqLAK0GsTND6jowfZz3SUx7cQ8aC54Pl1RbIvFXmEJuBMYVeW9yrdOtin": [0, 9]
  }

  for (id, numbers) in ids:
    check sqids.encode(numbers) == id
    check sqids.decode(id) == numbers

test "min lengths":
  for minLength in [0, 1, 5, 10, defaultAlphabet.len]:
    for numbers in [
      @[0'u64],
      @[0, 0, 0, 0, 0],
      @[1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      @[100, 200, 300],
      @[1_000, 2_000, 3_000],
      @[1_000_000],
      @[uint64.high]
    ]:
      let sqids = initSqids(minLength = uint8(minLength))
      let id = sqids.encode(numbers)
      check id.len >= minLength
      check sqids.decode(id) == numbers

# test "out-of-range invalid min length"
# for those langs that don't support `u8`
