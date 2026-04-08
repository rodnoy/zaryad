import Foundation

final class ThemeDirectoryWatcher {
    private let directoryURL: URL
    private let queue: DispatchQueue
    private let onChange: @Sendable () -> Void

    private var fileDescriptor: CInt = -1
    private var source: DispatchSourceFileSystemObject?
    private var debounceWorkItem: DispatchWorkItem?

    init(
        directoryURL: URL,
        queue: DispatchQueue = DispatchQueue(label: "com.chargermonitor.themewatcher", qos: .utility),
        onChange: @escaping @Sendable () -> Void
    ) {
        self.directoryURL = directoryURL
        self.queue = queue
        self.onChange = onChange
    }

    deinit {
        stop()
    }

    func start() {
        stop()

        fileDescriptor = open(directoryURL.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename, .attrib, .extend, .link, .revoke],
            queue: queue
        )

        source.setEventHandler { [weak self] in
            self?.scheduleDebouncedReload()
        }

        source.setCancelHandler { [weak self] in
            guard let self else { return }
            if self.fileDescriptor >= 0 {
                close(self.fileDescriptor)
                self.fileDescriptor = -1
            }
        }

        self.source = source
        source.resume()
    }

    func stop() {
        debounceWorkItem?.cancel()
        debounceWorkItem = nil

        source?.setEventHandler {}
        source?.cancel()
        source = nil

        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }

    private func scheduleDebouncedReload() {
        debounceWorkItem?.cancel()

        let workItem = DispatchWorkItem { [onChange] in
            onChange()
        }

        debounceWorkItem = workItem
        queue.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
}
