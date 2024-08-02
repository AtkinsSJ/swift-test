public struct CoordinatePair {
    let x: Double
    let y: Double
}

public enum PathCommand {
    case Move(relative: Bool, CoordinatePair)
    case ClosePath
    case LineTo(relative: Bool, CoordinatePair)
    case HorizontalLineTo(relative: Bool, Double)
    case VerticalLineTo(relative: Bool, Double)
    case CurveTo(relative: Bool, CoordinatePair, CoordinatePair, CoordinatePair)
    case SmoothCurveTo(relative: Bool, CoordinatePair, CoordinatePair)
    case QuadraticBezierCurveTo(relative: Bool, CoordinatePair, CoordinatePair)
    case SmoothQuadraticBezierCurveTo(relative: Bool, CoordinatePair)
    case EllipticalArc(relative: Bool, radius: CoordinatePair, xAxisRotation: Double, largeArc: Bool, sweep: Bool, to: CoordinatePair)

    func dump() -> String {
        switch self {
        case .Move(let relative, let pos):
            return if relative {
                "Move to (relative) \(pos.x), \(pos.y)"
            } else {
                "Move to \(pos.x), \(pos.y)"
            }
        case .ClosePath:
            return "Close path"
        case .LineTo(let relative, let pos):
            return if relative {
                "Line to (relative) \(pos.x), \(pos.y)"
            } else {
                "Line to \(pos.x), \(pos.y)"
            }
        case .HorizontalLineTo(let relative, let pos):
            return if relative {
                "Horizontal line to (relative) x \(pos)"
            } else {
                "Horizontal line to x \(pos)"
            }
        case .VerticalLineTo(let relative, let pos):
            return if relative {
                "Vertical line to (relative) y \(pos)"
            } else {
                "Vertical line to y \(pos)"
            }
        case .CurveTo(let relative, let a, let b, let c):
            return if relative {
                "Curve to (relative) \(a.x),\(a.y)   \(b.x),\(b.y)   \(c.x),\(c.y)"
            } else {
                "Curve to \(a.x),\(a.y)   \(b.x),\(b.y)   \(c.x),\(c.y)"
            }
        case .SmoothCurveTo(let relative, let a, let b):
            return if relative {
                "Smooth curve to (relative) \(a.x),\(a.y)   \(b.x),\(b.y)"
            } else {
                "Smooth curve to \(a.x),\(a.y)   \(b.x),\(b.y)"
            }
        case .QuadraticBezierCurveTo(let relative, let a, let b):
            return if relative {
                "Quadratic Bezier curve to (relative) \(a.x),\(a.y)   \(b.x),\(b.y)"
            } else {
                "Quadratic Bezier curve to \(a.x),\(a.y)   \(b.x),\(b.y)"
            }
        case .SmoothQuadraticBezierCurveTo(let relative, let a):
            return if relative {
                "Smooth quadratic Bezier curve to (relative) \(a.x),\(a.y)"
            } else {
                "Smooth quadratic Bezier curve to \(a.x),\(a.y)"
            }
        case .EllipticalArc(let relative, let radius, let xAxisRotation, let largeArc, let sweep, let to):
            return if relative {
                "Elliptical arc (relative) r=(\(radius.x),\(radius.y)) rotation=\(xAxisRotation) largeArc=\(largeArc) sweep=\(sweep) to \(to.x),\(to.y)"
            } else {
                "Elliptical arc r=(\(radius.x),\(radius.y)) rotation=\(xAxisRotation) largeArc=\(largeArc) sweep=\(sweep) to \(to.x),\(to.y)"
            }
        }
    }
}

public class Path {
    var commands: [PathCommand] = []
    var length: Int {
        get { return commands.count }
    }

    init(commands: [PathCommand]) {
        self.commands = commands
    }

    func dump() -> String {
        var result = ""
        for command in commands {
            result += command.dump() + "\n"
        }
        return result
    }
}
