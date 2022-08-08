import SwiftUI

struct DonationsView: View {
    
    @ObservedObject var viewModel = DonationsViewModel()

    var body: some View {
        VStack {
            Text("Free Ed - Donate $100")
            
            Text("Total Balance:")
                .font(.title)
                .padding()
            Text(viewModel.balance)
                .font(.largeTitle)
                .padding()
            
            Button {
                Task { await viewModel.receiveDeposits() }
            } label: {
                Text("Launch the donation event! 🚀")
            }
            .padding()
            
            if viewModel.areBankDetailsShown {
                Text(viewModel.bankDetails)
                    .font(.caption)
                    .padding()
            }
            
            Button {
                viewModel.toggleDetails()
            } label: {
                Text("Bank Details")
            }
            .padding()
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.isAlertShown) {}
    }
}

struct DonationsView_Previews: PreviewProvider {
    static var previews: some View {
        DonationsView()
    }
}
