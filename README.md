# BlackBox

An tiny Swift package providing a single identity function `func blackBox(_:)` that hints to the compiler to be maximally pessimistic about what it could do.

This property makes `blackBox(_:)` useful for writing code in which certain optimizations are not desired, such as benchmarks.

```swift
@discardableResult
@inline(never)
public func blackBox<T>(_ t: T) -> T {
    return t
}
```

(It is important that this function is defined in another module than the tests which are using it, hence this package.)

Note however, that `blackBox(_:)` is only (and can only be) provided on a “best-effort” basis. The extent to which it can block optimizations may vary depending upon the platform and code-gen backend used. Programs cannot rely on `blackBox(_:)` for correctness, beyond it behaving as the identity function. As such, it must not be relied upon to control critical program behavior. This immediately precludes any direct use of this function for cryptographic or security purposes.

## Examples

While not suitable in those mission-critical cases, `blackBox`’s functionality can generally be relied upon for benchmarking, and should be used there. It will try to ensure that the compiler doesn’t optimize away part of the intended test code based on context. For example:

```swift
func sequence<S>(_ sequence: S, contains element: S.Element) -> Bool
where
    S: Sequence,
    S.Element: Equatable
{
    sequence.contains(element)
}

func benchmark() {
    let haystack = ["abc", "def", "ghi", "jkl", "mno"]
    let needle = "ghi"
    for _ in 0..<10 {
        // warning:  warning: result of call to 'sequence(_:contains:)' is unused
        sequence(haystack, contains: needle)
    }
}
```

The compiler could theoretically make optimizations like the following:

- `needle` and `haystack` are always the same, move the call to contains outside the loop and delete the loop
- inline `.sequence(_:contains:)`
- `needle` and `haystack` have values known at compile time, `.sequence(_:contains:)` is always `true`, so remove the call and replace with `true`.
- nothing is done with the result of `.sequence(_:contains:)`: delete this function call entirely
- benchmark now has no purpose: delete this function

It is not likely that all of the above happens, but the compiler is definitely able to make some optimizations that could result in a very inaccurate benchmark.

This is where `blackBox(_:)` comes in:

```swift
// ...

func benchmark() {
    let haystack = ["abc", "def", "ghi", "jkl", "mno"]
    let needle = "ghi"
    for _ in 0..<10 {
        blackBox(sequence(blackBox(haystack), contains: blackBox(needle)))
    }
}
```

This essentially tells the compiler to block optimizations across any calls to `blackBox(_:)`. So, it now:

- Treats both arguments to `.sequence(_:contains:)` as unpredictable: the body of `.sequence(_:contains:)` can no longer be optimized based on argument values
- Treats the call to `.sequence(_:contains:)` and its result as volatile: the body of benchmark cannot optimize this away

This makes our benchmark much more realistic to how the function would be used in situ, where arguments are usually not known at compile time and the result is used in some way.

## Installation

### Swift Package Manager

Add the following to your project's `Package.swift` manifest file:

```swift
.package(url: "https://github.com/regexident/BlackBox.git", from: "1.0.0")
```

## License

**BlackBox** is available under the [**MPL-2.0**](https://www.mozilla.org/en-US/MPL/2.0/) ([tl;dr](https://tldrlegal.com/license/mozilla-public-license-2.0-(mpl-2))) license (see `LICENSE` file).
