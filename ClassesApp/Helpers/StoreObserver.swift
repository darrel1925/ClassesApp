//
//  StoreObserver.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 5/17/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import Foundation
import StoreKit
import PassKit


class StoreObserver: NSObject {
    
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
            storeVC.presentPaymentErrorAlert()
            return
        }
        
        let productToPurchase = products[0]
        let payment = SKPayment(product: productToPurchase)
        paymentQueue.add(payment)
        
    }
    
    func purchasePremiumWithApplePay() {
        // We could not find products ids in app store connect
        if products.count == 0 {
            storeVC.presentPaymentErrorAlert()
            return
        }
        
        let productToPurchase = products[0]
        let payment = SKPayment(product: productToPurchase)
        paymentQueue.add(payment)
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
        for transaction in queue.transactions {
            print("-->",transaction.transactionState.status(), transaction.payment.productIdentifier)
            switch transaction.transactionState {
            case .purchasing:
                print("finishing4", transaction.transactionState.status(), transaction.payment.productIdentifier)
                continue
                
            case .purchased:
                print("finishing5", transaction.transactionState.status(), transaction.payment.productIdentifier)
                queue.finishTransaction(transaction)
                storeVC.updatePremium()
                
            case .failed:
                let errString = transaction.error?.localizedDescription
                print(errString ?? "no err")
                if errString ?? "" == "Cannot connect to iTunes Store" {
                    print("user canceled")
                    print("finishing3", transaction.transactionState.status(), transaction.payment.productIdentifier)
                }
                else {
                    queue.finishTransaction(transaction)
                    print("finishing1", transaction.transactionState.status(),  transaction.payment.productIdentifier)

                    storeVC.presentPaymentErrorAlert()
                }
                queue.finishTransaction(transaction)

                
            default:
                print(transaction.transactionState.status())
                queue.finishTransaction(transaction)
                print("finishing2", transaction.transactionState.status(), transaction.payment.productIdentifier)
            }
        }
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
