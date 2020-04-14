//
//  ServerService.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/10/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import Foundation
import FirebaseFirestore
import Socket

let ServerService = _ServerService()

final class _ServerService {
    /*
     response
     ""
     ConnectionError1
     ConnectionError2
     NetworkError1
     NetworkError2
     */
    
    enum ReturnType: String {
        case ConnectionError1 // could not read what was returned from server
        case ConnectionError2 // problem with code writing data back
        case NetworkError1    // server is not up and runnung
        case NetworkError2    // problem with users internet connection
        case AddComplete      // add operation complete
    }
    
    func constuctInput(withAction action: String, withCode course_code: String) -> String {
        
        let email = UserService.user.email
        let quarter = AppConstants.quarter
        let year = AppConstants.year
        let school = UserService.user.school
        
        return "\(action)\(email),\(quarter),\(year),\(course_code),\(school),"
    }
    
    func makeConnection(withAction action: String, withInput input: String) -> String {
        var mySocket: Socket
        
        do {
            print("will create")
            mySocket = try Socket.create()
            mySocket.readBufferSize = 32768
            print("created")
            do {
                let server_ip = AppConstants.server_ip
                let server_port = AppConstants.server_port
                try mySocket.connect(to: server_ip, port: Int32(server_port))
                
                do {
                    try mySocket.write(from: input)
                    
                    if action == "get"{
                        do {
                            var data: Data = Data()
                            _ = try mySocket.read(into: &data)
                            let response = String(data: data, encoding: .utf8)
                            return response ?? ""}
                        catch { // could not read what was returned from server
                            mySocket.close()
                            return ReturnType.ConnectionError1.rawValue}
                    }
                    
                    if action == "add" {
                        return ReturnType.AddComplete.rawValue
                    }
                    
                }
                catch { // problem with code writing data back
                    mySocket.close()
                    return ReturnType.ConnectionError2.rawValue}
            }
            catch { // server is not up and runnung
                mySocket.close()
                return ReturnType.NetworkError1.rawValue}
        }
        catch { // problem with users internet connection
            return ReturnType.NetworkError2.rawValue}
        
        return ""
    }
    
    func addClassToFirebase(withCode course_code: String, withStatus status: String, viewController controller: UIViewController, withDiscussions discussions: [String] = [], withLabs labs: [String] = []) -> Bool {
        let db = Firestore.firestore()
        var returnValue = true // <-- indicates success or failure
        
        let _ = db.collection("Class").whereField("course_code", isEqualTo: course_code)
            .getDocuments() { (querySnapshot, err) in
                if let _ = err {
                    let message = "There was a problem tracking your class, please try again later. Your card has NOT been charged."
                    controller.displayError(title: "Error", message: message)
                    returnValue = false
                    return
                }
                else {
                    let docs = querySnapshot!.documents
                    
                    if docs.count == 0 {
                        let docRef = db.collection("Class").document("\(course_code) \(AppConstants.quarter)")
                        let data: [String: Any] = [
                            "curr_status": status,
                            "course_code": course_code,
                            "quarter": AppConstants.quarter,
                            "emails": [UserService.user.email],
                            "year": AppConstants.year
                        ]
                        
                        docRef.setData(data, merge: true) { (err) in
                            if let _ = err {
                                let message = "There was a problem tracking your class, please try again later. Your card has NOT been charged."
                                controller.displayError(title: "Error", message: message)
                                returnValue = false
                                return
                            }
                        }
                    }
                    else {
                        
                        let doc = querySnapshot!.documents[0]
                        var emails = doc.data()["emails"] as! [String]
                        let docRef = doc.reference
                        
                        if !emails.contains(UserService.user.email) { // user's email is not under class
                            emails.append(UserService.user.email)
                        }
                        // update classes email array
                        docRef.updateData(["emails" : emails])
                        
                    }
                }
        }
        
        // add email to user's classes dict
        let docRef = db.collection("User").document(UserService.user.email)
        docRef.getDocument { (doc, err) in
            if let _ = err {
                let message = "There was a problem tracking your class, please try again later. Your card has NOT been charged."
                controller.displayError(title: "Error", message: message)
                returnValue = false
                return
            }
            var classDict = doc?.data()!["classes"]  as! [String: Any]
            classDict.updateValue(discussions + labs, forKey: course_code)
            docRef.setData(["classes": classDict], merge: true)
        }
        return returnValue
    }
    
    func removeClassesFromFirebase(withClasses codes: [String]) {
        let db = Firestore.firestore()
        
        // remove class from user
        let docRef = db.collection("User").document(UserService.user.email)
        docRef.getDocument { (doc, error) in
            if error != nil{
                print("FATAAL ERROR DUBUG ASSSASPPP: in ServerService\n\n\n\n")
                return
            }
            
            guard var classes = doc?["classes"] as? [String : [Any]] else { return }
            
            for course_code in codes {
                // If class is in user's classes dict
                if classes.keys.contains(course_code) {
                    // Remove email address
                    classes.removeValue(forKey: course_code)
                }
            }
            docRef.updateData(["classes" : classes]) { (err) in
                if let err = err{
                    print(err.localizedDescription)
                    return
                }
            }
            
            
            // remove email from classes
            for course_code in codes {
                let _ = db.collection("Class").whereField("course_code", isEqualTo: course_code).getDocuments { (querySnapshot, error) in
                    if querySnapshot != nil { // on success
                        let doc = querySnapshot!.documents[0]
                        var emails = doc.data()["emails"] as! [String]
                        let classRef = doc.reference
                        
                        // If user's email is under class email list
                        if emails.contains(UserService.user.email) {
                            // Remove email from array
                            emails = emails.filter { $0 != UserService.user.email }
                            
                            // If no one else is tracking this class
                            if emails.count == 0 {
                                classRef.delete()
                            }
                            else {
                                // update classes email array in db
                                classRef.updateData(["emails" : emails])
                            }
                        }
                    }
                }
            }
        }
    }
    
    func updatePurchaseHistory(withClasses classes: [String]) {
        var free_classes = UserService.user.freeClasses
        var purchaseHistory = UserService.user.purchaseHistory
        
        if purchaseHistory.count > 0 {
            if purchaseHistory[0] == [:] {
                purchaseHistory = []
            }
        }
        
        for code in classes {
            var pricePerClass = StripeCart.pricePerClass
            
            // update amt of free classes left only on purchase success
            if free_classes > 0 {
                pricePerClass = 0
                free_classes -= 1
            }
            
            let data: [String: String] = [
                "course_code": code,
                "date": Date().toString(),
                "price": "\(pricePerClass)"
            ]
            purchaseHistory.append(data)
        }
        
        let db = Firestore.firestore()
        let docRef = db.collection("User").document(UserService.user.email)
        
        docRef.setData(["purchase_history" : purchaseHistory], merge: true)
    }
}
