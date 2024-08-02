/**
 * Using https://www.w3.org/TR/SVG11/paths.html#PathDataBNF because the SVG2 grammar is incorrect and weird.
 */

// TODO:
// - Error reporting
// - How are we supposed to treat input that's partially parsable?

public class PathParser {
    let stream: CharStream

    init(stream: CharStream) {
        self.stream = stream
    }

    static func parsePath(from input: String) -> Path? {
        print("Parsing path: `\(input)`")
        let stream = CharStream(of: input)
        let parser = PathParser(stream: stream)
        return parser.parseSvgPath()
    }

    private func parseSvgPath() -> Path? {
        // svg-path:
        //     wsp* moveto-drawto-command-groups? wsp*
        return stream.transaction {
            let _ = parseWsp()
            let commands = parseMoveToDrawToCommandGroups()
            let _ = parseWsp()
            guard stream.isDone else {
                // FIXME: Is it correct to reject the input if it wasn't all consumed?
                return nil
            }
            return Path(commands: commands ?? [])
        }
    }

    private func parseMoveToDrawToCommandGroups() -> [PathCommand]? {
        // moveto-drawto-command-groups:
        //     moveto-drawto-command-group
        //     | moveto-drawto-command-group wsp* moveto-drawto-command-groups
        return stream.transaction {
            guard var pathCommands = parseMoveToDrawToCommandGroup() else {
                return nil
            }

            while true {
                let group = stream.transaction {
                    let _ = parseWsp()
                    return parseMoveToDrawToCommandGroup()
                }
                guard let group else {
                    break
                }
                pathCommands.append(contentsOf: group)
            }

            return pathCommands
        }
    }

    private func parseMoveToDrawToCommandGroup() -> [PathCommand]? {
        // moveto-drawto-command-group:
        //     moveto wsp* drawto-commands?
        return stream.transaction {
            guard var pathCommands: [PathCommand] = parseMoveTo() else {
                return nil
            }
            let _ = parseWsp()

            if let drawToCommands = parseDrawToCommands() {
                pathCommands.append(contentsOf: drawToCommands)
            }

            return pathCommands
        }
    }

    private func parseDrawToCommands() -> [PathCommand]? {
        // drawto-commands:
        //     drawto-command
        //     | drawto-command wsp* drawto-commands
        return stream.transaction {
            guard var pathCommands: [PathCommand] = parseDrawToCommand() else {
                return nil
            }

            while true {
                let command = stream.transaction {
                    let _ = parseWsp()
                    return parseDrawToCommand()
                }
                guard let command else {
                    break
                }
                pathCommands.append(contentsOf: command)
            }

            return pathCommands
        }
    }

    private func parseDrawToCommand() -> [PathCommand]? {
        // drawto-command:
        //     closepath
        //     | lineto
        //     | horizontal-lineto
        //     | vertical-lineto
        //     | curveto
        //     | smooth-curveto
        //     | quadratic-bezier-curveto
        //     | smooth-quadratic-bezier-curveto
        //     | elliptical-arc
        return switch stream.peek() {
        case "Z", "z":
            if let closePath = parseClosePath() {
                [closePath]
            } else {
                nil
            }
        case "L", "l":
            parseLineTo()
        case "H", "h":
            parseHorizontalLineTo()
        case "V", "v":
            parseVerticalLineTo()
        case "C", "c":
            parseCurveTo()
        case "S", "s":
            parseSmoothCurveTo()
        case "Q", "q":
            parseQuadraticBezierCurveTo()
        case "T", "t":
            parseSmoothQuadraticBezierCurveTo()
        case "A", "a":
            parseEllipticalArc()
        default: nil
        }
    }

    private func parseMoveTo() -> [PathCommand]? {
        // moveto:
        //     ( "M" | "m" ) wsp* moveto-argument-sequence
        // moveto-argument-sequence:
        //     coordinate-pair
        //     | coordinate-pair comma-wsp? lineto-argument-sequence
        return stream.transaction { () -> [PathCommand]? in
            let m = stream.next()
            guard m == "M" || m == "m" else {
                return nil
            }
            let relative = m == "m"
            let _ = parseWsp()
            return parseArgumentSequence {
                if let coordinatePair = parseCoordinatePair() {
                    return PathCommand.Move(relative: relative, coordinatePair)
                }
                return nil
            }
        }
    }

    private func parseClosePath() -> PathCommand? {
        // closepath:
        //     ("Z" | "z")
        return stream.transaction { () -> PathCommand? in
            let c = stream.next()
            guard c == "Z" || c == "z" else {
                return nil
            }
            return PathCommand.ClosePath
        }
    }

    private func parseLineTo() -> [PathCommand]? {
        // lineto:
        //     ( "L" | "l" ) wsp* lineto-argument-sequence
        // lineto-argument-sequence:
        //     coordinate-pair
        //     | coordinate-pair comma-wsp? lineto-argument-sequence
        return stream.transaction { () -> [PathCommand]? in
            let c = stream.next()
            guard c == "L" || c == "l" else {
                return nil
            }
            let relative = c == "l"
            let _ = parseWsp()

            return parseArgumentSequence {
                if let coordinatePair = parseCoordinatePair() {
                    return PathCommand.LineTo(relative: relative, coordinatePair)
                }
                return nil
            }
        }
    }

    private func parseHorizontalLineTo() -> [PathCommand]? {
        // horizontal-lineto:
        //     ( "H" | "h" ) wsp* horizontal-lineto-argument-sequence
        // horizontal-lineto-argument-sequence:
        //     coordinate
        //     | coordinate comma-wsp? horizontal-lineto-argument-sequence
        return stream.transaction { () -> [PathCommand]? in
            let c = stream.next()
            guard c == "H" || c == "h" else {
                return nil
            }
            let relative = c == "h"
            let _ = parseWsp()

            return parseArgumentSequence {
                if let coordinate = parseCoordinate() {
                    return PathCommand.HorizontalLineTo(relative: relative, coordinate)
                }
                return nil
            }
        }
    }

    private func parseVerticalLineTo() -> [PathCommand]? {
        // vertical-lineto:
        //     ( "V" | "v" ) wsp* vertical-lineto-argument-sequence
        // vertical-lineto-argument-sequence:
        //     coordinate
        //     | coordinate comma-wsp? vertical-lineto-argument-sequence
        return stream.transaction { () -> [PathCommand]? in
            let c = stream.next()
            guard c == "V" || c == "v" else {
                return nil
            }
            let relative = c == "v"
            let _ = parseWsp()

            return parseArgumentSequence {
                if let coordinate = parseCoordinate() {
                    return PathCommand.VerticalLineTo(relative: relative, coordinate)
                }
                return nil
            }
        }
    }

    private func parseCurveTo() -> [PathCommand]? {
        // curveto:
        //     ( "C" | "c" ) wsp* curveto-argument-sequence
        // curveto-argument-sequence:
        //     curveto-argument
        //     | curveto-argument comma-wsp? curveto-argument-sequence
        // curveto-argument:
        //     coordinate-pair comma-wsp? coordinate-pair comma-wsp? coordinate-pair
        return stream.transaction { () -> [PathCommand]? in
            let c = stream.next()
            guard c == "C" || c == "c" else {
                return nil
            }
            let relative = c == "c"
            let _ = parseWsp()

            return parseArgumentSequence {
                guard let a = parseCoordinatePair() else {
                    return nil
                }
                let _ = parseCommaWsp()
                guard let b = parseCoordinatePair() else {
                    return nil
                }
                let _ = parseCommaWsp()
                guard let c = parseCoordinatePair() else {
                    return nil
                }
                return PathCommand.CurveTo(relative: relative, a, b, c)
            }
        }
    }

    private func parseSmoothCurveTo() -> [PathCommand]? {
        // smooth-curveto:
        //     ( "S" | "s" ) wsp* smooth-curveto-argument-sequence
        // smooth-curveto-argument-sequence:
        //     smooth-curveto-argument
        //     | smooth-curveto-argument comma-wsp? smooth-curveto-argument-sequence
        // smooth-curveto-argument:
        //     coordinate-pair comma-wsp? coordinate-pair
        return stream.transaction { () -> [PathCommand]? in
            let c = stream.next()
            guard c == "S" || c == "s" else {
                return nil
            }
            let relative = c == "s"
            let _ = parseWsp()

            return parseArgumentSequence {
                guard let a = parseCoordinatePair() else {
                    return nil
                }
                let _ = parseCommaWsp()
                guard let b = parseCoordinatePair() else {
                    return nil
                }
                return PathCommand.SmoothCurveTo(relative: relative, a, b)
            }
        }
    }

    private func parseQuadraticBezierCurveTo() -> [PathCommand]? {
        // quadratic-bezier-curveto:
        //     ( "Q" | "q" ) wsp* quadratic-bezier-curveto-argument-sequence
        // quadratic-bezier-curveto-argument-sequence:
        //     quadratic-bezier-curveto-argument
        //     | quadratic-bezier-curveto-argument comma-wsp?
        //         quadratic-bezier-curveto-argument-sequence
        // quadratic-bezier-curveto-argument:
        //     coordinate-pair comma-wsp? coordinate-pair
        return stream.transaction {
            let c = stream.next()
            guard c == "Q" || c == "q" else {
                return nil
            }
            let relative = c == "q"
            let _ = parseWsp()

            return parseArgumentSequence {
                guard let a = parseCoordinatePair() else {
                    return nil
                }
                let _ = parseCommaWsp()
                guard let b = parseCoordinatePair() else {
                    return nil
                }
                return PathCommand.QuadraticBezierCurveTo(relative: relative, a, b)
            }
        }
    }

    private func parseSmoothQuadraticBezierCurveTo() -> [PathCommand]? {
        // smooth-quadratic-bezier-curveto:
        //     ( "T" | "t" ) wsp* smooth-quadratic-bezier-curveto-argument-sequence
        // smooth-quadratic-bezier-curveto-argument-sequence:
        //     coordinate-pair
        //     | coordinate-pair comma-wsp? smooth-quadratic-bezier-curveto-argument-sequence
        return stream.transaction {
            let c = stream.next()
            guard c == "T" || c == "t" else {
                return nil
            }
            let relative = c == "t"
            let _ = parseWsp()

            return parseArgumentSequence {
                guard let coordinatePair = parseCoordinatePair() else {
                    return nil
                }
                return PathCommand.SmoothQuadraticBezierCurveTo(relative: relative, coordinatePair)
            }
        }
    }

    private func parseEllipticalArc() -> [PathCommand]? {
        // elliptical-arc:
        //     ( "A" | "a" ) wsp* elliptical-arc-argument-sequence
        // elliptical-arc-argument-sequence:
        //     elliptical-arc-argument
        //     | elliptical-arc-argument comma-wsp? elliptical-arc-argument-sequence
        // elliptical-arc-argument:
        //     nonnegative-number comma-wsp? nonnegative-number comma-wsp?
        //         number comma-wsp flag comma-wsp? flag comma-wsp? coordinate-pair
        return stream.transaction {
            let c = stream.next()
            guard c == "A" || c == "a" else {
                return nil
            }
            let relative = c == "a"
            let _ = parseWsp()

            return parseArgumentSequence {
                guard let rx = parseNonNegativeNumber() else {
                    return nil
                }
                let _ = parseCommaWsp()
                guard let ry = parseNonNegativeNumber() else {
                    return nil
                }
                let radius = CoordinatePair(x: rx, y: ry)
                let _ = parseCommaWsp()
                guard let angle = parseNumber() else {
                    return nil
                }
                let _ = parseCommaWsp()
                guard let largeArc = parseFlag() else {
                    return nil
                }
                let _ = parseCommaWsp()
                guard let sweep = parseFlag() else {
                    return nil
                }
                let _ = parseCommaWsp()
                guard let coordinatePair = parseCoordinatePair() else {
                    return nil
                }

                return PathCommand.EllipticalArc(relative: relative, radius: radius, xAxisRotation: angle, largeArc: largeArc, sweep: sweep, to: coordinatePair)
            }
        }
    }

    private func parseArgumentSequence(parseArgument: () -> (PathCommand?)) -> [PathCommand]? {
        // Non-spec helper. Almost all commands are defined with:
        // foo:
        //     "f" wsp* foo-argument-sequence
        // foo-argument-sequence:
        //     coordinate
        //     | coordinate comma-wsp? foo-argument-sequence
        // ...so, this wraps that behaviour up.
        return stream.transaction {
            var commands: [PathCommand] = []
            guard let first = parseArgument() else {
                return nil
            }
            commands.append(first)

            while true {
                let next = stream.transaction {
                    let _ = parseCommaWsp()
                    return parseArgument()
                }
                guard let next else {
                    break
                }
                commands.append(next)
            }

            return commands
        }
    }

    private func parseCoordinatePair() -> CoordinatePair? {
        // coordinate-pair:
        //     coordinate comma-wsp? coordinate
        return stream.transaction { () -> CoordinatePair? in
            guard let first = parseCoordinate() else {
                return nil
            }
            let _ = parseCommaWsp()
            guard let second = parseCoordinate() else {
                return nil
            }
            return CoordinatePair(x: first, y: second)
        }
    }

    private func parseCoordinate() -> Double? {
        // coordinate:
        //     number
        return parseNumber()
    }

    private func parseNonNegativeNumber() -> Double? {
        // number:
        //     integer-constant
        //     | floating-point-constant
        return stream.transaction {
            if let integerConstant = parseIntegerConstant() {
                return Double(integerConstant)
            }
            if let floatingPointConstant = parseFloatingPointConstant() {
                return Double(floatingPointConstant)
            }
            return nil
        }
    }

    private func parseNumber() -> Double? {
        // number:
        //     sign? integer-constant
        //     | sign? floating-point-constant
        return stream.transaction {
            let sign = parseSign()
            // floating-point-constant first, because it consumes a superset of integer-constant
            if let floatingPointConstant = parseFloatingPointConstant() {
                return Double("\(sign ?? "")\(floatingPointConstant)")
            }
            if let integerConstant = parseIntegerConstant() {
                return Double("\(sign ?? "")\(integerConstant)")
            }
            return nil
        }
    }

    private func parseFlag() -> Bool? {
        // flag:
        //     "0" | "1"
        return stream.transaction {
            return switch stream.next() {
            case "0": false
            case "1": true
            default: nil
            }
        }
    }

    // Returns whether it was parsed
    private func parseCommaWsp() -> Bool {
        // comma-wsp:
        //     (wsp+ comma? wsp*) | (comma wsp*)
        // comma:
        //     ","
        return stream.transaction {
            let parsedFrontWsp = parseWsp()
            let parsedComma = stream.peek() == ","
            if parsedComma {
                let _ = stream.next() // ","
            }

            guard parsedFrontWsp || parsedComma else {
                return nil
            }

            let _ = parseWsp()

            return true

        } ?? false
    }

    private func parseIntegerConstant() -> String? {
        // integer-constant:
        //     digit-sequence
        return parseDigitSequence()
    }

    private func parseFloatingPointConstant() -> String? {
        // floating-point-constant:
        //     fractional-constant exponent?
        //     | digit-sequence exponent
        return stream.transaction {
            if let fractionalConstant = parseFractionalConstant() {
                let exponent = parseExponent()
                return if let exponent {
                    "\(fractionalConstant)\(exponent)"
                } else {
                    fractionalConstant
                }
            }
            if let digitSequence = parseDigitSequence() {
                guard let exponent = parseExponent() else {
                    return nil
                }
                return "\(digitSequence)\(exponent)"
            }
            return nil
        }
    }

    private func parseFractionalConstant() -> String? {
        // fractional-constant:
        //     digit-sequence? "." digit-sequence
        //     | digit-sequence "."
        return stream.transaction {
            let prefixDigits = parseDigitSequence()
            guard stream.next() == "." else {
                return nil
            }
            let suffixDigits = parseDigitSequence()

            guard prefixDigits != nil || suffixDigits != nil else {
                return nil
            }

            return "\(prefixDigits ?? "").\(suffixDigits ?? "")"
        }
    }

    private func parseExponent() -> String? {
        // exponent:
        //     ( "e" | "E" ) sign? digit-sequence
        return stream.transaction { () -> String? in
            let e = stream.next()
            guard e == "e" || e == "E" else {
                return nil
            }
            let sign = parseSign()
            guard let digits = parseDigitSequence() else {
                return nil
            }

            return if let sign {
                sign + digits
            } else {
                digits
            }
        }
    }

    private func parseSign() -> String? {
        // sign:
        //     "+" | "-"
        return stream.transaction {
            return switch stream.next() {
            case "+": "+"
            case "-": "-"
            default: nil
            }
        }
    }

    private func parseDigitSequence() -> String? {
        // digit-sequence:
        //     digit
        //     | digit digit-sequence
        return stream.transaction {
            var digits = ""
            while let c = stream.peek() {
                guard ("0"..."9").contains(c) else {
                    break
                }
                digits.append(c)
                let _ = stream.next() // digit
            }

            guard !digits.isEmpty else {
                return nil
            }

            return digits
        }
    }

    // Returns whether it was parsed
    private func parseWsp() -> Bool {
        // wsp:
        //     (#x20 | #x9 | #xD | #xA)
        // NOTE: Grammar always allows multiple wsp's together, so that's what we parse here.

        var parsedWsp = false
        loop: while let c = stream.peek() {
            switch c.asciiValue {
            case 0x20, 0x9, 0xD, 0xA:
                let _ = stream.next()
                parsedWsp = true
            default:
                break loop
            }
        }

        return parsedWsp
    }
}
