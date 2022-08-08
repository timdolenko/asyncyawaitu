import SwiftUI

actor BankAccount {
    private let iban = "FR7630006000011234567890189"
    
    private(set) var balance = 0
    
    func deposit() -> Int {
        balance = balance + 100
        return balance
    }
    
    nonisolated func bankDetails() -> String { iban }
}

@MainActor class DonationsViewModel: ObservableObject {
    @Published var balance: String = "0"
    
    /// Bank Details
    @Published var bankDetails: String = ""
    @Published var areBankDetailsShown = false
    
    /// Alert
    @Published var alertTitle = ""
    @Published var isAlertShown = false
    
    private var bankAccount = BankAccount()
    
    init() {
        bankDetails = bankAccount.bankDetails()
    }
    
    public func receiveDeposits() async {
        bankAccount = BankAccount()
        balance = await bankAccount.balance.description
        
        for _ in 1...1000 {
            
            /// 1. Global queue
            DispatchQueue.global().async {
                Task {
                    await self.depositAndDisplay()
                }
            }
            
            /// 2. Main Queue
            await depositAndDisplay()
        }
        
        try! await Task.sleep(nanoseconds: 1_000_000_000)

        await self.checkResults()
    }
    
    public func depositAndDisplay() async {
        let result = await bankAccount.deposit()
        
        self.balance = result.description
    }
    
    public func checkResults() async {
        let actualBalance = await bankAccount.balance
        let expectedBalance = 2 * 1000 * 100
        let difference = expectedBalance - actualBalance
        
        if difference > 0 {
            alertTitle = "Congrats! You just lost $\(difference)!"
        } else if difference < 0 {
            alertTitle = "Seems like you just created $\(difference) out of thin air! How's going to pay for this?"
        } else {
            alertTitle = "Okay, this time you got lucky."
        }
        
        print(actualBalance)
        
        isAlertShown = true
    }
    
    public func toggleDetails() {
        areBankDetailsShown = !areBankDetailsShown
    }
}
