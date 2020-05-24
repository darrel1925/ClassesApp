//
//  StoreObserver.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 5/17/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import Foundation
import StoreKit

class StoreObserver: NSObject {
    
    var didTapMenuType: ((Bool) -> Void)?
    var products = [SKProduct]()
    var storeVC: StoreController!
    let paymentQueue = SKPaymentQueue.default()
    let premiumProductId: String = AppConstants.premium_product_id
    static let shared = StoreObserver()
    
    //Initialize the store observer.
    override init() {
        super.init()
    }
    
    func getProducts() {
        let products: Set = [premiumProductId] // <- set of all products
        let requests = SKProductsRequest(productIdentifiers: products)
        requests.delegate = self
        requests.start() // get the products from apple, adds each product to products array in delegate
        paymentQueue.add(self)
    }
    
    func purchasePremium() {
        // We could not find products ids in app store connect
        if products.count == 0 {
            print("no items found")
            storeVC.presentPaymentErrorAlert()
            storeVC.activityIndicator.stopAnimating()
            return
        }
        
        let productToPurchase = products[0]
        let payment = SKPayment(product: productToPurchase)
        paymentQueue.add(payment)
    }
    
    var isAuthorizedForPayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
}


extension StoreObserver: SKProductsRequestDelegate {
    // this is call once we get products back after calling requests.start
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.products = response.products
    }
}

//Observe transaction updates.
extension StoreObserver: SKPaymentTransactionObserver {
    // called each time something is add to transaction queue
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("updated called")
        for transaction in queue.transactions {
            switch transaction.transactionState {
            case .purchasing:
                handlePurchasing(transaction: transaction, queue: queue)
            case .purchased:
                handlePurchased(transaction: transaction, queue: queue)
            case .failed:
                handleFailed(transaction: transaction, queue: queue)
            default:
                handleDefault(transaction: transaction, queue: queue)
            }
        }
    }
    
    func handlePurchasing(transaction: SKPaymentTransaction, queue: SKPaymentQueue){
        print("4", transaction.transactionState.status(), transaction.payment.productIdentifier)
    }
    
    func handlePurchased(transaction: SKPaymentTransaction, queue: SKPaymentQueue){
        print("5", transaction.transactionState.status(), transaction.payment.productIdentifier)
        storeVC.activityIndicator.stopAnimating()
        queue.finishTransaction(transaction)
        storeVC.updatePremium()
    }
    
    func handleFailed(transaction: SKPaymentTransaction, queue: SKPaymentQueue){
        storeVC.activityIndicator.stopAnimating()

        // there was an actual error
        if (transaction.error as? SKError)?.code != .paymentCancelled {
            DispatchQueue.main.async {
                print("pay error")
                self.storeVC.displayError(title: "Payment Error", message: "There was an issue processing your purchase. Plase contact support if this continues.")
                self.storeVC.activityIndicator.stopAnimating()
                queue.finishTransaction(transaction)
                //storeVC.presentPaymentErrorAlert()
            }
            return
        }
        print("User cancelled purchase")
        queue.finishTransaction(transaction)
    }
    
    func handleDefault (transaction: SKPaymentTransaction, queue: SKPaymentQueue){
        storeVC.activityIndicator.stopAnimating()
        queue.finishTransaction(transaction)
        print(1, transaction.transactionState.status())
    }
    
    func handleRestored(queue: SKPaymentQueue) {
        print("restore...")
        if queue.transactions.count == 0 {
            self.didTapMenuType?(false)
            return
        }
    
        print("restore... ", queue.transactions.count)
        self.didTapMenuType?(true)
     }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        handleRestored(queue: queue)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        handleRestored(queue: queue)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions{
            print(transaction.payment.productIdentifier, "has been removed")
        }
    }
}

extension SKPaymentTransactionState {
    func status() -> String {
        switch self {
        case .deferred:
            return "deferred"
        case .purchasing:
            return "purchasing"
        case .purchased:
            return "purchased"
        case .failed:
            return "failed"
        case .restored:
            return "restored"
        @unknown default:
            return "unknown"
        }
    }
}
