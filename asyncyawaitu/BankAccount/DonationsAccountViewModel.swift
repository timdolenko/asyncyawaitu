import SwiftUI

class BankAccount {
    private let iban = "FR7630006000011234567890189"
    
    private(set) var balance = 0
    
    func deposit() -> Int {
        balance = balance + 100
        return balance
    }
    
    func bankDetails() -> String { iban }
}

class DonationsViewModel: ObservableObject {
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
    
    public func receiveDeposits() {
        bankAccount = BankAccount()
        balance = bankAccount.balance.description
        
        for _ in 1...1000 {
            
            /// 1. Global queue
            DispatchQueue.global().async {
                self.depositAndDisplay()
            }
            
            /// 2. Main Queue
            depositAndDisplay()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.checkResults()
        }
    }
    
    public func depositAndDisplay() {
        let result = bankAccount.deposit()
        
        DispatchQueue.main.async {
            self.balance = result.description
        }
    }
    
    public func checkResults() {
        let actualBalance = bankAccount.balance
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
