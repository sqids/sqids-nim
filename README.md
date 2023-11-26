# [Sqids Nim](https://sqids.org/nim)

[Sqids](https://sqids.org/nim) (*pronounced "squids"*) is a small library that lets you **generate unique IDs from numbers**. It's good for link shortening, fast & URL-safe ID generation and decoding back into numbers for quicker database lookups.

Features:

- **Encode multiple numbers** - generate short IDs from one or several non-negative numbers
- **Quick decoding** - easily decode IDs back into numbers
- **Unique IDs** - generate unique IDs by shuffling the alphabet once
- **ID padding** - provide minimum length to make IDs more uniform
- **URL safe** - auto-generated IDs do not contain common profanity
- **Randomized output** - Sequential input provides nonconsecutive IDs
- **Many implementations** - Support for [40+ programming languages](https://sqids.org/)

## 🧰 Use-cases

Good for:

- Generating IDs for public URLs (eg: link shortening)
- Generating IDs for internal systems (eg: event tracking)
- Decoding for quicker database lookups (eg: by primary keys)

Not good for:

- Sensitive data (this is not an encryption library)
- User IDs (can be decoded revealing user count)

## 🚀 Getting started

Install Sqids via:

```bash
nimble install https://github.com/sqids/sqids-nim
```

## 👩‍💻 Examples

Simple encode & decode:

```nim
import sqids
let sqids = initSqids()
let id = sqids.encode([1, 2, 3]) # "86Rf07"
let numbers = sqids.decode(id)   # @[1'u64, 2, 3]
```

> **Note**
> 🚧 Because of the algorithm's design, **multiple IDs can decode back into the same sequence of numbers**. If it's important to your design that IDs are canonical, you have to manually re-encode decoded numbers and check that the generated ID matches.

Enforce a *minimum* length for IDs:

```nim
import sqids
let sqids = initSqids(minLength = 10)
let id = sqids.encode([1'u64, 2, 3]) # "86Rf07xd4z"
const numbers = sqids.decode(id)     # @[1'u64, 2, 3]
```

Randomize IDs by providing a custom alphabet:

```nim
import sqids

let sqids = initSqids(
    alphabet = "FxnXM1kBN6cuhsAvjW3Co7l2RePyY8DwaU04Tzt9fHQrqSVKdpimLGIJOgb5ZE",
)
let id = sqids.encode([1'u64, 2, 3]) # "B4aajs"
let numbers = sqids.decode(id)   # @[1, 2, 3]
```

Prevent specific words from appearing anywhere in the auto-generated IDs:

```nim
import std / sets
import sqids

let sqids = initSqids(blocklist = ["86Rf07"].toHashSet())
let id = sqids.encode([1'u64, 2, 3]) # "se8ojk"
let numbers = sqids.decode(id)       # @[1'u64, 2, 3]
```

## 📝 License

[MIT](LICENSE)
