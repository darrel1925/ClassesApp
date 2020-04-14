//
//  Extensions.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 3/25/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

extension UIViewController {
    
    func displayError(error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func displayError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func displayError(title: String, message: String, completion: ((UIAlertAction) -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .default, handler: completion)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
}


extension String {
    var isAlphanumeric: Bool {
        return !isEmpty && range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }
    
    var isOnlyNumeric: Bool {
        return !isEmpty && range(of: "[0-9]", options: .regularExpression) == nil
    }
    
    var hasLettersOnly: Bool {
        return !isEmpty && range(of: "[^a-zA-Z]", options: .regularExpression) == nil
    }
    
    var containsWhitespace : Bool {
        return(self.rangeOfCharacter(from: .whitespacesAndNewlines) != nil)
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + self.lowercased().dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
    var isValidUCIEmail: Bool {
        let trimmedEmail = self.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailArray = trimmedEmail.components(separatedBy: "@")
        
        if emailArray.count < 2 { return false }
        print("email1 \(emailArray[0]) email2 \(emailArray[1])")
        
        if emailArray[1] != "uci.edu" { return false }
        
        return true
    }
    
    var isValidName: Bool {
        let trimmedString = self.trimmingCharacters(in: .whitespacesAndNewlines)
        let fullName = trimmedString.components(separatedBy: " ")
        
        if fullName.count != 2 { return false }
        
        let firstName = fullName[0]
        let lastName = fullName[1]
        
        if !firstName.hasLettersOnly { return false }
        
        if !lastName.hasLettersOnly { return false }
        
        print("Full Name: \(fullName)")
        
        return true
    }
    
    
    func separateAndFormatName() -> [String] {
        let name =  self
        let nameFormatter = PersonNameComponentsFormatter()
        if let nameComps  = nameFormatter.personNameComponents(from: name),
            let firstLetter = nameComps.givenName?.first?.uppercased(),
            let lastLetter = nameComps.familyName?.first?.uppercased(),
            let firstName = nameComps.givenName?.lowercased(),
            let lastName = nameComps.familyName?.lowercased() {
            
            let sortedName = ["\(firstLetter)\(firstName[1 ..< lastName.count])", "\(lastLetter)\(lastName[1 ..< lastName.count])"]  // J. Singh
            return sortedName
        }
        return self.components(separatedBy: " ")
    }
    
    func toDate() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "PST")
        
        
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.date(from: self)!
    }
    
}


extension Date {
    
    func toString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "PST")
        
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: self)
    }
    
    func toStringInWords() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "PST")
        
        dateFormatter.dateStyle = .full
        
        let dateStr = dateFormatter.string(from: self)
        
        return formatMyDate(dateStr: dateStr)
    }
    
    private func formatMyDate(dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mma" // "4:44 pm
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        
        let dateStr2 = formatter.string(from: self) // "4:44pm on June 23, 2016\n"
        
        let dateArr = dateStr.components(separatedBy: ", ") // Wednesday, January 10, 2018
        
        return "\(dateArr[0]) • \(dateStr2)" // Wednesday • 4:44pm
    }
    
    var recivedUnderFiveMinutesAgo: Bool  {
        let inputDate = self.toString()
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let aDate = dateFormatter.date(from: inputDate) {
            
            let timeInterval = aDate.timeIntervalSinceNow
            
            let dateComponentsFormatter = DateComponentsFormatter()
            
            if var dateString = dateComponentsFormatter.string(from: abs(timeInterval)) {
                print ("Elapsed time= \(dateString)") // 4:04
                if (!dateString.contains(":")) { // 32   <-- seconds
                    return true
                }
                else {
                    if (dateString.count > 4) { return false } // 12:22, 13:32, 1:23:23
                    
                }
                dateString = dateString.replacingOccurrences(of: ":", with: ".") //  4.04
                let minutesPassed = Double(dateString) ?? 5
                
                if (minutesPassed <= 5.0) {
                    return true
                }
            }
        }
        return false
    }
}
extension DispatchGroup {
    var count: Int {
        let count = self.debugDescription.components(separatedBy: ",").filter({$0.contains("count")}).first?.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap{Int($0)}.first
        return count!
    }
    
    func customLeave(){
        if count > 0 {
            self.leave()
        }
    }
}


//let str = "abcdef"
//str[1 ..< 3] // returns "bc"
//str[5] // returns "f"
//str[80] // returns ""
//str.substring(fromIndex: 3) // returns "def"
//str.substring(toIndex: str.length - 2) // returns "abcd"
extension String {
    
    var length: Int {
        return count
    }
    
    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }
    
    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }
    
    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}

extension Int {
    func penniesToFormattedDollars() -> String {
        
        let dollars = Double(self) / 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        if let dollarString = formatter.string(from: dollars as NSNumber) {
            return dollarString
        }
        
        return "$0.00"
    }
    
}

extension UIPanGestureRecognizer {
    
    enum GestureDirection {
        case Up
        case Down
        case Left
        case Right
    }
    
    /// Get current vertical direction
    ///
    /// - Parameter target: view target
    /// - Returns: current direction
    func verticalDirection(target: UIView) -> GestureDirection {
        return self.velocity(in: target).y > 600 ? .Down : .Up
    }
    
    /// Get current horizontal direction
    ///
    /// - Parameter target: view target
    /// - Returns: current direction
    func horizontalDirection(target: UIView) -> GestureDirection {
        print(self.velocity(in: target).x)
        if self.velocity(in: target).x < -1000 {
            return .Left
        }
        if self.velocity(in: target).x > 1000 {
            return .Right
        }
        return .Down
        //          return self.velocity(in: target).x > 600 ? .Right : .Left
    }
    
    /// Get a tuple for current horizontal/vertical direction
    ///
    /// - Parameter target: view target
    /// - Returns: current direction
    func versus(target target: UIView) -> (horizontal: GestureDirection, vertical: GestureDirection) {
        return (self.horizontalDirection(target: target), self.verticalDirection(target: target))
    }
}

extension AuthErrorCode {
    var errorMessage: String {
        switch self {
        case .emailAlreadyInUse:
            return "This email is already in use with another account. Pick another email!"
        case .userNotFound:
            return "Account not found for this email address. Please check and try again!"
        case .userDisabled:
            return "Your account has been disabled. Please contact support."
        case .networkError:
            return "Network error. Please try again."
        case .wrongPassword:
            return "Your password or email in incorrect."
        default:
            return "Sorry, looks like something went wrong. Please try again later."
        }
    }
}
