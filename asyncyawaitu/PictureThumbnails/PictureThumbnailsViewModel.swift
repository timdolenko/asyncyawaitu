import SwiftUI

class PictureThumbnailsViewModel: ObservableObject {
    
    @Published var images: [Thumbnail] = []
    
    private let repository = ThumnailRepositoryLive()
    
    init() {}
    
    public func onAppear() async {
        do {
            let result = try await repository.fetchAllThumbnails()
            
            DispatchQueue.main.async { [weak self] in
                self?.images = result
            }
        } catch {
            print(error)
        }
    }
}
