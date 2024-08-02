if let path = PathParser.parsePath(from: "M100.4-200e1m1 2 3 4m") {
    print("Parsed a path, length \(path.length)")
    print(path.dump())
} else {
    print("Failed to parse path")
}
