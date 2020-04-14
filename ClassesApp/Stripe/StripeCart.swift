//
//  StripeCart.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/3/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit


let StripeCart = _StripeCart()

final class _StripeCart {
    var cartItems = [String]()
    private let stripeCreditCardCut = 0.029 // 0.29%
    private let stripeFlatFee = 30 // 30 cents
    let pricePerClass = AppConstants.price_per_class // $1.49 per class
    
    var discount = 0
    
    var subtotal: Int {
        return cartItems.count * pricePerClass
    }
    
    var total: Int {
        let freeClassDiscount = pricePerClass * UserService.user.freeClasses
        let totalAmt = subtotal - freeClassDiscount - discount
        
        if totalAmt < 0{
            return 0
        }
        return totalAmt
    }
    
    func addItemToCart(item: String) {
        cartItems.append(item)
    }
    
    func removeItemFromCart(item: String) {
        if let index = cartItems.firstIndex(of: item) {
            cartItems.remove(at: index)
        }
    }
    
    func clearCart() {
        cartItems.removeAll()
    }
}
