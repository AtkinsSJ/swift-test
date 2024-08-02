if CommandLine.arguments.count < 2 {
    print("Usage: \(CommandLine.arguments[0]) <svg-path-string>")
} else {
    let pathString = CommandLine.arguments[1]
    if let path = PathParser.parsePath(from: pathString) {
        print("Parsed a path, length \(path.length)")
        print(path.dump())
    } else {
        print("Failed to parse path")
    }
}
