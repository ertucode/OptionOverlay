import Foundation
import Cocoa

class ConfigParser {
    static func parse(config: KarabinerConfig) -> [String: String] {
        var keyMap: [String: String] = [:]

        for profile in config.profiles {
            for rule in profile.complex_modifications.rules {
                if rule.description.contains("Open apps with Option") {
                    for manipulator in rule.manipulators {
                        if manipulator.from.modifiers?.mandatory?.contains("option") == true,
                           let command = manipulator.to?.first?.shell_command {
                            let key = manipulator.from.key_code
                            keyMap[key] = getCommand(command)
                        }
                    }
                }
            }
        }
        return keyMap
    }
    
    static func getCommand(_ command: String) -> String {
        if let match = command.range(of: #"open -a '([^']+)'"#, options: .regularExpression) {
                return String(command[match])
                    .replacingOccurrences(of: "open -a '", with: "")
                    .replacingOccurrences(of: "'", with: "")
            }
            
        return command
    }
}

struct KarabinerConfig: Codable {
    let profiles: [Profile]
}

struct Profile: Codable {
    let complex_modifications: ComplexModifications
}

struct ComplexModifications: Codable {
    let rules: [Rule]
}

struct Rule: Codable {
    let description: String
    let manipulators: [Manipulator]
}

struct Manipulator: Codable {
    let from: From
    let to: [To]?
    let type: String
}

struct From: Codable {
    let key_code: String
    let modifiers: Modifiers?
}

struct Modifiers: Codable {
    let mandatory: [String]?
}

struct To: Codable {
    let shell_command: String?
}
