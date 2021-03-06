import Foundation
import Runes

class CascadeController {
    private let imageFetcher: ImageFetcher
    private let observer: ManagedObjectContextObserver
    private let imageStore: ImageStore
    private let syncEngine: SyncEngine
    var viewModel: CascadeViewModel

    init(syncClient: SyncClient) {
        let dataStore = Store()
        imageStore = ImageStore(store: dataStore)
        observer = dataStore.managedObjectContextObserver
        imageFetcher = ImageFetcher()
        syncEngine = SyncEngine(imageStore: imageStore, syncClient: syncClient)
        viewModel = CascadeViewModel(images: [])
    }

    var hasPasteboardImage: Bool {
        return Pasteboard.hasImageData
    }

    func syncWithTHECLOUD() {
        syncEngine.runSync()
    }

    func fetchImages() {
        viewModel = CascadeViewModel(images: imageStore.cachedImages() ?? [])
    }

    func registerForChanges(callback: ([NSIndexPath], [NSIndexPath], [NSIndexPath]) -> ()) {
        observer.callback = { inserted, updated, deleted in
            let d = deleted.map(self.createIndexPathFromImage)
            let u = updated.map(self.createIndexPathFromImage)
            self.fetchImages()
            let i = inserted.map(self.createIndexPathFromImage)
            callback(compact(i), compact(u), compact(d))
        }
    }

    private func createIndexPathFromImage(image: CachedImage) -> NSIndexPath? {
        return find(viewModel.images.map { $0.path }, image.path) >>- { NSIndexPath(forRow: $0, inSection: 0) }
    }

    func cellControllerForIndexPath(indexPath: NSIndexPath) -> PoppinsCellController? {
        let path = viewModel.imagePathForIndexPath(indexPath)
        return PoppinsCellController(imageFetcher: imageFetcher, path: path ?? "")
    }

    func importController() -> ImportController? {
        return Pasteboard.fetchImageData().map { ImportController(imageData: $0.data, imageType: $0.type, store: imageStore, client: syncEngine.client) }
    }
}
