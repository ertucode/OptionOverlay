import Cocoa
import Foundation

class ConfigLoader: NSObject {

    // Callback type for when the config is loaded
    typealias ConfigLoadCompletion = (Result<KarabinerConfig, Error>) -> Void

    private let bookmarkDefaultsKey = "karabinerConfigFolderBookmark"
    private var completionHandler: ConfigLoadCompletion?

    func loadConfig(completion: @escaping ConfigLoadCompletion) {
        self.completionHandler = completion

        // Attempt to load a previously saved bookmark
        if let bookmarkData = UserDefaults.standard.data(forKey: bookmarkDefaultsKey) {
            resolveBookmarkAndLoadConfig(bookmarkData: bookmarkData)
        } else {
            // No bookmark found, ask the user to select the folder
            presentOpenPanel()
        }
    }

    private func resolveBookmarkAndLoadConfig(bookmarkData: Data) {
        do {
            var isStale = false
            // Resolve the bookmark with security scope
            let bookmarkURL = try URL(resolvingBookmarkData: bookmarkData,
                                      options: .withSecurityScope,
                                      relativeTo: nil,
                                      bookmarkDataIsStale: &isStale)

            if isStale {
                print("Bookmark is stale. Asking user to re-select the folder.")
                // Bookmark is stale, ask the user to re-select
                presentOpenPanel()
                return
            }

            // Start accessing the resource with security scope
            if bookmarkURL.startAccessingSecurityScopedResource() {
                print("Successfully accessed bookmarked URL via existing bookmark: \(bookmarkURL.path)")

                // Load and parse the config file
                loadAndParseConfig(from: bookmarkURL)

                // **Important:** Stop accessing the resource when done loading
                bookmarkURL.stopAccessingSecurityScopedResource()
                print("Stopped accessing security-scoped resource after loading.")

            } else {
                print("Failed to start accessing security-scoped resource with existing bookmark.")
                // Failed to access with bookmark, ask user to re-select
                presentOpenPanel()
            }

        } catch {
            print("Error resolving bookmark: \(error)")
            // Error resolving bookmark, ask user to re-select
            presentOpenPanel()
        }
    }

    private func presentOpenPanel() {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            let openPanel = NSOpenPanel()
            openPanel.message = "Select your .config folder to allow the application to read Karabiner-Elements configuration."
            openPanel.prompt = "I have selected .config"
            openPanel.canChooseFiles = false
            openPanel.canChooseDirectories = true
            openPanel.allowsMultipleSelection = false
            openPanel.canCreateDirectories = false
            openPanel.showsHiddenFiles = true
            
            // Attempt to set the user's home directory as the initial location
            if let homeURL = URL(string: NSHomeDirectory()) {
                // Hide hidden files by default, but the user can reveal them
                openPanel.isExtensionHidden = true // Affects displayed filenames
                openPanel.directoryURL = homeURL
            }
            
            openPanel.begin { [weak self] response in
                guard let self = self else { return }
                
                if response == .OK, let selectedURL = openPanel.url {
                    // Store the security-scoped bookmark data for future use
                    self.storeConfigFolderBookmark(for: selectedURL)
                    
                    // Start accessing the resource with security scope
                    if selectedURL.startAccessingSecurityScopedResource() {
                        print("Successfully accessed bookmarked URL after user selection: \(selectedURL.path)")
                        
                        // Load and parse the config file
                        self.loadAndParseConfig(from: selectedURL)
                        
                        // **Important:** Stop accessing the resource when done loading
                        selectedURL.stopAccessingSecurityScopedResource()
                        print("Stopped accessing security-scoped resource after user selection.")
                        
                    } else {
                        print("Failed to start accessing security-scoped resource after user selection.")
                        // Call completion with an error if we can't access even after selection
                        self.completionHandler?(.failure(ConfigLoaderError.failedToAccessFolderAfterSelection))
                    }
                } else {
                    print("Folder selection cancelled or failed.")
                    // Call completion with a cancellation error
                    self.completionHandler?(.failure(ConfigLoaderError.selectionCancelled))
                }
            }
        }
    }

    private func storeConfigFolderBookmark(for url: URL) {
        do {
            // Create a security-scoped bookmark
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope,
                                                    includingResourceValuesForKeys: nil,
                                                    relativeTo: nil)

            // Store the bookmark data
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkDefaultsKey)
            print("Bookmark data stored for: \(url.path)")

        } catch {
            print("Error creating bookmark: \(error)")
            // You might want to inform the user that the permission won't be persistent
        }
    }

    private func loadAndParseConfig(from configFolderURL: URL) {
        let fileManager = FileManager.default
        let karabinerConfigURL = configFolderURL.appendingPathComponent("karabiner/karabiner.json")

        guard fileManager.fileExists(atPath: karabinerConfigURL.path) else {
            print("karabiner.json not found at: \(karabinerConfigURL.path)")
            // Call completion with a file not found error
            self.completionHandler?(.failure(ConfigLoaderError.karabinerConfigNotFound))
            return
        }

        do {
            let jsonData = try Data(contentsOf: karabinerConfigURL)

            // Parse the JSON data into your KarabinerConfig struct
            let decoder = JSONDecoder()
            let karabinerConfig = try decoder.decode(KarabinerConfig.self, from: jsonData)

            // Call the completion handler with the parsed data
            self.completionHandler?(.success(karabinerConfig))

        } catch {
            print("Error reading or parsing karabiner.json: \(error)")
            // Call completion with the reading/parsing error
            self.completionHandler?(.failure(error))
        }
    }
}

// MARK: - Custom Errors

enum ConfigLoaderError: Error, LocalizedError {
    case selectionCancelled
    case failedToAccessFolderAfterSelection
    case karabinerConfigNotFound

    var errorDescription: String? {
        switch self {
            case .selectionCancelled:
                return NSLocalizedString("The folder selection was cancelled.", comment: "")
            case .failedToAccessFolderAfterSelection:
                return NSLocalizedString("Failed to gain access to the selected .config folder.", comment: "")
            case .karabinerConfigNotFound:
                return NSLocalizedString("Could not find the karabiner.json file in the selected folder.", comment: "")
        }
    }
}
