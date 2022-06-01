import SwiftUI

class PictureThumbnailsViewModel: ObservableObject {
    
    @Published var images: [Thumbnail] = []
    
    private let repository = ThumnailRepositoryLive()
    
    init() {}
    
    public func onAppear() {
        repository.fetchThumbnail(for: repository.randomId) { [weak self] result in
            switch result {
            case .success(let thumbnail):
                DispatchQueue.main.async { [weak self] in
                    self?.images = [thumbnail]
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}
