public struct CoordinatePair {
    let x: Double
    let y: Double
}

public enum PathCommand {
    case Move(relative: Bool, CoordinatePair)

    func dump() -> String {
        switch self {
        case .Move(let relative, let pos):
            return if relative {
                "Move by \(pos.x), \(pos.y)"
            } else {
                "Move to \(pos.x), \(pos.y)"
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
