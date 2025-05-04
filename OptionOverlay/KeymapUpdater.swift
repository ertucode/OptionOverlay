import Foundation

// Define the struct that matches the structure of the Karabiner JSON for the "Open apps with Option" rules
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


class KeymapUpdater {
    var keymap: [String: String] = [:] // Dictionary to store the key-to-shell-command mappings
    
    // Function to update keys from the Karabiner JSON file
    func updateKeys() -> [String: String] {
        let fileManager = FileManager.default
            let homeDir = fileManager.homeDirectoryForCurrentUser
            let karabinerPath = homeDir.appendingPathComponent(".config/karabiner/karabiner.json")

            do {
                let data = try Data(contentsOf: karabinerPath)
                let decoder = JSONDecoder()
                let config = try decoder.decode(KarabinerConfig.self, from: data)

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

            } catch {
                print("❌ Failed to read or parse Karabiner configuration: \(error)")
                return [:]
            }
    }
    
    func getCommand(_ command: String) -> String {
        if let match = command.range(of: #"open -a '([^']+)'"#, options: .regularExpression) {
                return String(command[match])
                    .replacingOccurrences(of: "open -a '", with: "")
                    .replacingOccurrences(of: "'", with: "")
            }
            
        return command
    }
}
