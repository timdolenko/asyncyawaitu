import SwiftUI

struct PictureThumbnailsView: View {
    
    @ObservedObject var viewModel = PictureThumbnailsViewModel()
    
    let columns = Array(repeating: GridItem(.flexible()), count: 4)
        
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(viewModel.images, id: \.self) { thumbnail in
                    
                    let size = Thumbnail.size
                    
                    ZStack {
                        Image(uiImage: thumbnail.image)
                            .frame(width: size.width, height: size.height)
                            .clipped()
                           
                        Text(thumbnail.id)
                            .foregroundColor(.white)
                            .bold()
                    }
                    .frame(width: size.width, height: size.height)
                }
            }
        }
        .padding()
        .onAppear { viewModel.onAppear() }
    }
}
