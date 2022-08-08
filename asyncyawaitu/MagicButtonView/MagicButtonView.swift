import SwiftUI

struct MagicButtonView: View {
    
    @ObservedObject var viewModel = MagicButtonViewModel()

    var body: some View {
        VStack {
            Text(viewModel.output)
                .font(.title)
                .padding()
            
            Button {
                viewModel.cancel()
            } label: {
                Text("🗑 Unsubscribe")
            }
            .padding()
        }
    }
}
