import Foundation

enum DataMigration {
    private struct Summary: Encodable {
        var migrated_dirs: [String] = []
        var migrated_files: [String] = []
        var errors: [String] = []
        var moved: Bool = false
    }

    static func migrateIfNeeded() {
        let fileManager = FileManager.default
        var summary = Summary()

        let home = fileManager.homeDirectoryForCurrentUser
        let homeLegacy = home.appendingPathComponent(".chargermonitor", isDirectory: true)
        let homeNew = home.appendingPathComponent(".zaryad", isDirectory: true)

        if migrateDirectoryIfNeeded(from: homeLegacy, to: homeNew, fileManager: fileManager, summary: &summary) {
            summary.moved = true
        }

        if let appSupport = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) {
            let supportLegacy = appSupport.appendingPathComponent("ChargerMonitor", isDirectory: true)
            let supportNew = appSupport.appendingPathComponent("Zaryad", isDirectory: true)
            if migrateDirectoryIfNeeded(from: supportLegacy, to: supportNew, fileManager: fileManager, summary: &summary) {
                summary.moved = true
            }
        } else {
            summary.errors.append("Failed to resolve Application Support directory")
        }

        if let data = try? JSONEncoder().encode(summary), let json = String(data: data, encoding: .utf8) {
            print(json)
        } else {
            print("{\"migrated_dirs\":[],\"migrated_files\":[],\"errors\":[\"Failed to encode migration summary\"],\"moved\":false}")
        }
    }

    @discardableResult
    private static func migrateDirectoryIfNeeded(
        from source: URL,
        to destination: URL,
        fileManager: FileManager,
        summary: inout Summary
    ) -> Bool {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: source.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return false
        }

        guard !fileManager.fileExists(atPath: destination.path) else {
            summary.errors.append("Destination already exists, skipping: \(destination.path)")
            return false
        }

        do {
            try fileManager.moveItem(at: source, to: destination)
            summary.migrated_dirs.append("\(source.path) -> \(destination.path)")
            migrateSwiftDataSQLiteFilesIfNeeded(in: destination, fileManager: fileManager, summary: &summary)
            return true
        } catch {
            do {
                try copyDirectoryRecursively(from: source, to: destination, fileManager: fileManager)
                try fileManager.removeItem(at: source)
                summary.migrated_dirs.append("\(source.path) -> \(destination.path) (copy-delete)")
                migrateSwiftDataSQLiteFilesIfNeeded(in: destination, fileManager: fileManager, summary: &summary)
                return true
            } catch {
                summary.errors.append("Failed to migrate \(source.path): \(error.localizedDescription)")
                return false
            }
        }
    }

    private static func copyDirectoryRecursively(from source: URL, to destination: URL, fileManager: FileManager) throws {
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)

        guard let enumerator = fileManager.enumerator(
            at: source,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        ) else {
            throw NSError(domain: "DataMigration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to enumerate source directory"])
        }

        for case let fileURL as URL in enumerator {
            let relativePath = fileURL.path.replacingOccurrences(of: source.path + "/", with: "")
            let destinationURL = destination.appendingPathComponent(relativePath)
            let values = try fileURL.resourceValues(forKeys: [.isDirectoryKey])

            if values.isDirectory == true {
                try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
            } else {
                let parent = destinationURL.deletingLastPathComponent()
                if !fileManager.fileExists(atPath: parent.path) {
                    try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
                }
                try fileManager.copyItem(at: fileURL, to: destinationURL)
            }
        }
    }

    private static func migrateSwiftDataSQLiteFilesIfNeeded(
        in directory: URL,
        fileManager: FileManager,
        summary: inout Summary
    ) {
        guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey]) else {
            summary.errors.append("Failed to enumerate migrated directory: \(directory.path)")
            return
        }

        for case let fileURL as URL in enumerator {
            let fileName = fileURL.lastPathComponent
            guard fileName.contains("ChargerMonitor") else { continue }
            guard fileName.hasSuffix(".sqlite") || fileName.hasSuffix(".sqlite-shm") || fileName.hasSuffix(".sqlite-wal") else {
                continue
            }

            let newFileName = fileName.replacingOccurrences(of: "ChargerMonitor", with: "Zaryad")
            let newURL = fileURL.deletingLastPathComponent().appendingPathComponent(newFileName)

            if fileManager.fileExists(atPath: newURL.path) {
                summary.errors.append("Target sqlite file already exists, skipping: \(newURL.path)")
                continue
            }

            do {
                // Copy first, then remove old file to keep migration safe.
                try fileManager.copyItem(at: fileURL, to: newURL)
                try fileManager.removeItem(at: fileURL)
                summary.migrated_files.append("\(fileURL.path) -> \(newURL.path)")
            } catch {
                summary.errors.append("Failed to migrate sqlite file \(fileURL.path): \(error.localizedDescription)")
            }
        }
    }
}
