import UIKit

struct Thumbnail: Identifiable, Hashable {
    static let size: CGSize = CGSize(width: 64, height: 64)
    
    let id: String
    let image: UIImage
}

class ThumnailRepositoryLive {
    
    public enum FetchError: Error {
        case badImage
        case badID
    }
    
    private let path = "https://picsum.photos/id/"
    private let ids = [1, 10, 100, 1000, 1002, 1003, 1004, 1005, 1006, 1009, 101].map { $0.description }
    
    public var randomId: String { ids.randomElement()! }
    
    public func fetchFewThumbnails() async throws -> [Thumbnail] {
        
        async let thumbnail1 = try fetchThumbnail(for: "100")
        
        async let thumbnail2 = try fetchThumbnail(for: "101")
        
        return try await [thumbnail1, thumbnail2]
    }
    
    public func fetchAllThumbnails() async throws -> [Thumbnail] {
        var result = [Thumbnail]()
        
        try await withThrowingTaskGroup(of: Thumbnail.self) { [weak self] group in
            guard let `self` = self else { return }
            
            for id in ids {
                group.addTask { return try await self.fetchThumbnail(for: id) }
            }
            
            for try await thumbnail in group {
                result.append(thumbnail)
            }
        }
        
        return result
    }
    
    public func fetchThumbnail(for id: String) async throws -> Thumbnail {
        print("start \(id)")
        let request = thumbnailURLRequest(for: id)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw FetchError.badID
        }
        
        guard let image = UIImage(data: data) else { throw FetchError.badImage }
        
        guard let thumbnail = await image.byPreparingThumbnail(ofSize: Thumbnail.size) else {
            throw FetchError.badImage
        }
        
        print("end \(id)")
        return Thumbnail(id: id, image: thumbnail)
    }
    
    public func fetchThumbnail(for id: String, completion: @escaping (Result<Thumbnail, Error>) -> Void) {
        let request = thumbnailURLRequest(for: id)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if (response as? HTTPURLResponse)?.statusCode != 200 {
                completion(.failure(FetchError.badID))
            } else {
                guard let image = UIImage(data: data!) else {
                    completion(.failure(FetchError.badImage))
                    return
                }
                
                image.prepareThumbnail(of: Thumbnail.size) { thumbnail in
                    guard let thumbnail = thumbnail else {
                        completion(.failure(FetchError.badImage))
                        return
                    }
                    completion(.success(Thumbnail(id: id, image: thumbnail)))
                }
            }
        }
        task.resume()
    }
    
    private func thumbnailURLRequest(for id: String) -> URLRequest {
        URLRequest(url: URL(string: "\(path)\(id)/200/300")!)
    }
}
