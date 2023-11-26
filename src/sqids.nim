import std / [sets, unicode, algorithm, strutils]

from sqids / defaults import defaultAlphabet, defaultMinLength, defaultBlocklist


type
  Sqids* = ref object
    alphabet*: string
    minLength*: uint8
    blocklist*: HashSet[string]


# forward declaration
proc shuffle*(self: Sqids, alphabet: string): string


proc isDecimal(x: string): bool =
  try:
    discard parseInt(x)
    result = true
  except ValueError:
    result = false


proc maxValue*(sqids: Sqids): uint64 =
  ## this should be the biggest unsigned integer that the language can safely/mathematically support
  ## the spec does not specify the upper integer limit - so it's up to the individual programming languages
  ## examples as of 2023-09-24:
  ## golang: uint64
  ## rust: u128
  ## php: PHP_INT_MAX
  return uint64.high

proc toId(self: Sqids, num: uint64, alphabet: string): string =
  var id: string
  var num = num

  while true:
    id.add(alphabet[num mod uint64(alphabet.len)])
    num = num div uint64(alphabet.len)
    if num == 0:
      break

  id.reverse()
  return id

proc toNumber(self: Sqids, id: string, alphabet: string): uint64 =
  for i, c in id:
    result *= uint64(alphabet.len)
    result += uint64(alphabet.find(c))

proc isBlockedId(self: Sqids, id: string): bool =
  var id = id.toLower()
  for word in self.blocklist:
    # no point in checking words that are longer than the ID
    if word.len <= id.len:
      if id.len <= 3 or word.len <= 3:
        # short words have to match completely; otherwise, too many matches
        if id == word:
          return true
      elif word.isDecimal():
        # words with leet speak replacements are visible mostly on the ends of the ID
        if id.startsWith(word) or id.endsWith(word):
          return true
      elif word in id:
        # otherwise, check for blocked word anywhere in the string
        return true

  return false


proc encodeNumbers(
  self: Sqids,
  numbers: openArray[uint64],
  increment: int = 0,
): string =
  ## Internal function that encodes an array of unsigned integers into an ID
  ##
  ## numbers: Non-negative integers to encode into an ID
  ## increment: An internal number used to modify the `offset` variable in order to re-generate the ID
  ## returns: Generated ID

  # if increment is greater than alphabet length, we've reached max attempts
  if increment > self.alphabet.len:
    raise newException(ValueError, "Reached max attempts to re-generate the ID")

  # get a semi-random offset from input numbers
  var offset = 0
  for i, value in numbers:
    offset += ord(self.alphabet[value mod uint64(self.alphabet.len)]) + i
  offset = (offset + numbers.len) mod self.alphabet.len

  # if there is a non-zero `increment`, it's an internal attempt to re-generated the ID
  offset = (offset + increment) mod self.alphabet.len

  # re-arrange alphabet so that second-half goes in front of the first-half
  var alphabet = self.alphabet[offset .. ^1] & self.alphabet[0 ..< offset]

  # `prefix` is the first character in the generated ID, used for randomization
  let prefix = alphabet[0]

  # reverse alphabet (otherwise for [0, x] `offset` and `separator` will be the same char)
  alphabet.reverse()

  # final ID will always have the `prefix` character at the beginning
  var id: string = $prefix

  # encode input array
  for i, num in numbers:
    # the first character of the alphabet is going to be reserved for the `separator`
    let alphabetWithoutSeparator = alphabet[1 .. ^1]
    id.add(self.toId(num, alphabetWithoutSeparator))

    # if not the last number
    if i < numbers.len - 1:
      ## `separator` character is used to isolate numbers within the ID
      id.add(alphabet[0])

      ## shuffle on every iteration
      alphabet = self.shuffle(alphabet)

  # handle `minLength` requirement, if the ID is too short
  if int(self.minLength) > id.len:
    # append a separator
    id &= alphabet[0]

    # keep appending `separator` + however much alphabet is needed
    # for decoding: two separators next to each other is what tells us the rest are junk characters
    while int(self.minLength) - id.len > 0:
      alphabet = self.shuffle(alphabet)
      id &= alphabet[0 ..< min(int(self.minLength) - id.len, alphabet.len)]

  # if ID has a blocked word anywhere, restart with a +1 increment
  if self.isBlockedId(id):
    id = self.encodeNumbers(numbers, increment + 1)

  return id


proc initSqids*(
  alphabet: string = defaultAlphabet,
  minLength: uint8 = defaultMinLength,
  blocklist: HashSet[string] = defaultBlocklist,
): Sqids =
  # alphabet cannot contain multibyte characters
  if alphabet.toRunes().len != alphabet.len:
    raise newException(ValueError, "Alphabet cannot contain multibyte characters")

  # check the length of the alphabet
  if alphabet.len < 3:
    raise newException(ValueError, "Alphabet length must be at least 3")

  # check that the alphabet has only unique characters
  if toHashSet(alphabet).len != alphabet.len:
    raise newException(ValueError, "Alphabet must contain unique characters")

  # clean up blocklist:
  # 1. all blocklist words should be lowercase
  # 2. no words less than 3 chars
  # 3. if some words contain chars that are not in the alphabet, remove those
  var filteredBlocklist: HashSet[string]
  let alphabetChars = alphabet.toLower().toHashSet()

  for word in blocklist:
    if word.len >= 3:
      var wordLowercased = word.toLower()
      var wordChars = wordLowercased.toHashSet()
      if wordChars.difference(alphabetChars).len == 0:
        filteredBlocklist.incl(wordLowercased)

  result = new(Sqids)
  result.alphabet = result.shuffle(alphabet)
  result.minLength = minLength
  result.blocklist = filteredBlocklist


proc shuffle*(self: Sqids, alphabet: string): string =
  var alphabet = alphabet

  var
    i = 0
    j = len(alphabet) - 1

  while j > 0:
    let r = (i * j + ord(alphabet[i]) + ord(alphabet[j])) mod alphabet.len
    (alphabet[i], alphabet[r]) = (alphabet[r], alphabet[i])
    inc i
    dec j

  return alphabet

proc encode*(self: Sqids, numbers: openArray[uint64]): string =
  ## Encodes an array of unsigned integers into an ID
  ##
  ## These are the cases where encoding might fail:
  ## - One of the numbers passed is smaller than 0 or greater than `maxValue()`
  ## - An n-number of attempts has been made to re-generated the ID, where n is alphabet length + 1
  ##
  ## numbers: Non-negative integers to encode into an ID
  ## returns: Generated ID

  # if no numbers passed, return an empty string
  if numbers.len == 0:
    return ""

  return self.encodeNumbers(numbers)

proc decode*(self: Sqids, id: string): seq[uint64] =
  ## Decodes an ID back into an array of unsigned integers
  ##
  ## These are the cases where the return value might be an empty array:
  ## - Empty ID / empty string
  ## - Non-alphabet character is found within ID
  ##
  ## id: Encoded ID
  ## returns: Sequence of unsigned integers
  
  var id = id
  if id == "":
    return

  # if a character is not in the alphabet, return an empty array
  for c in id:
    if c notin self.alphabet:
      return

  # first character is always the `prefix`
  let prefix = id[0]

  # `offset` is the semi-random position that was generated during encoding
  let offset = self.alphabet.find(prefix)

  # re-arrange alphabet back into it's original form
  var alphabet = self.alphabet[offset .. ^1] & self.alphabet[0 ..< offset]

  # reverse alphabet
  alphabet.reverse()

  # now it's safe to remove the prefix character from ID, it's not needed anymore
  # id.delete(0 .. 0)
  id = id[1 .. ^1]

  # decode
  while id.len > 0:
    let separator = alphabet[0]

    # we need the first part to the left of the separator to decode the number
    let chunks = id.split(separator)
    if chunks.len > 0:
      # if chunk is empty, we are done (the rest are junk characters)
      if chunks[0] == "":
        return

      # decode the number without using the `separator` character
      let alphabetWithoutSeparator = alphabet[1 .. ^1]
      result.add(self.toNumber(chunks[0], alphabetWithoutSeparator))

      # if this ID has multiple numbers, shuffle the alphabet because that's what encoding function did
      if chunks.len > 1:
        alphabet = self.shuffle(alphabet)
    
    ## `id` is now going to be everything to the right of the `separator`
    id = chunks[1 .. ^1].join($separator)

  return result
