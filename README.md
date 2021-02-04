# Fetch

A description of this package.

Example
```swift
fetch("https://example.com") {
    switch $0 {
    case .failure(let error):
        print(error)
    case .success(let response):
        print(response.data.text()!)
    }
}
```
