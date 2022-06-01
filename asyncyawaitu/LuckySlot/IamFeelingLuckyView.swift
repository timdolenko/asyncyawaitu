import SwiftUI

struct IamFeelingLuckyView: View {
    
    @ObservedObject var viewModel = IamFeelingLuckyViewModel()
    
    var body: some View {
        Text(viewModel.lastResult)
            .font(.title)
            .padding()

        Button {
            Task { viewModel.playSlot() }
        } label: {
            Text("Play Slot")
        }
        .padding()
        Button {
            Task { viewModel.playGenerator() }
        } label: {
            Text("I am feeling lucky!")
        }
        .padding()
        
        .alert("We got an error", isPresented: $viewModel.isDisplayingError) {
            Button("OK", role: .cancel) {}
        }
        .alert("You got lucky!", isPresented: $viewModel.isDisplayingJackpot) {
            Button("OK", role: .cancel) {}
        }
    }
}
