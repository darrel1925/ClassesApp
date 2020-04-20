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
    let dispatchGroup = DispatchGroup()
    
    var schoolParam : String {
        switch UserService.user.school {
        case Schools.UCI:
            return "\(Schools.UCI)_Classes"
        case Schools.UCLA:
            return "\(Schools.UCLA)_Classes"
        default:
            return "Error"
        }
    }
    
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
        
        return "\(action)\(email),\(quarter),\(year),\(course_code),\(school),,,"
    }
    
    func getClassStatus(withGroup dispatchGroup: DispatchGroup, homeVC: HomePageController){
        let db = Firestore.firestore()
        for cls in UserService.user.classArr {
            dispatchGroup.enter()
            let docRef = db.collection(ServerService.schoolParam).document(cls)
            
            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    guard let data = document.data() else { print("couldn't do it"); return }
                    let status = data[DataBase.curr_status] as! String
                    homeVC.courseCodes.append(cls)
                    homeVC.courseStatus.append(status)
                    
                    print("Found course: \(cls) status: \(data[DataBase.curr_status])")
                    dispatchGroup.leave()
                    
                } else {
                    print("Document does not exist")
                    dispatchGroup.leave()
                }
            }
        }
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
        dispatchGroup.enter()
        let db = Firestore.firestore()
        var returnValue = true // <-- indicates success or failure
        
        let _ = db.collection(ServerService.schoolParam).whereField(DataBase.course_code, isEqualTo: course_code)
            .getDocuments() { (querySnapshot, err) in
                if let _ = err {
                    let message = "There was a problem tracking your class, please try again later. Your card has NOT been charged."
                    controller.displayError(title: "Error", message: message)
                    returnValue = false
                    self.dispatchGroup.customLeave()
                    return
                }
                else {
                    let docs = querySnapshot!.documents
                    
                    // If class is not being tracked by anyone
                    if docs.count == 0 {
                        let docRef = db.collection(ServerService.schoolParam).document(course_code)
                        let data: [String: Any] = [
                            DataBase.curr_status: status,
                            DataBase.course_code: course_code,
                            DataBase.quarter: AppConstants.quarter,
                            DataBase.school: UserService.user.school,
                            DataBase.emails: [UserService.user.email],
                            DataBase.year: AppConstants.year
                        ]
                        
                        docRef.setData(data, merge: true) { (err) in
                            if let _ = err {
                                let message = "There was a problem tracking your class, please try again later. Your card has NOT been charged."
                                controller.displayError(title: "Error", message: message)
                                returnValue = false
                                self.dispatchGroup.customLeave()
                                return
                            }
                        }
                    }
                    // If class is already being tracked
                    else {
                        let doc = querySnapshot!.documents[0]
                        var emails = doc.data()[DataBase.emails] as! [String]
                        let docRef = doc.reference
                        
                        if !emails.contains(UserService.user.email) { // user's email is not under class
                            emails.append(UserService.user.email)
                        }
                        // update classes email array
                        docRef.updateData([DataBase.emails : emails])
                    }
                }
        }
        
        // add email to user's classes dict
        let docRef = db.collection(DataBase.User).document(UserService.user.email)
        docRef.getDocument { (doc, err) in
            if let _ = err {
                let message = "There was a problem tracking your class, please try again later. Your card has NOT been charged."
                controller.displayError(title: "Error", message: message)
                self.dispatchGroup.customLeave()
                returnValue = false
                return
            }
            var classDict = doc?.data()![DataBase.classes]  as! [String: Any]
            classDict.updateValue(discussions + labs, forKey: course_code)
            docRef.setData([DataBase.classes: classDict], merge: true)
        }
        print("add classes finished")
        self.dispatchGroup.customLeave()
        return returnValue
    }
    
    func removeClassesFromFirebase(withClasses codes: [String]) {
        let db = Firestore.firestore()
        
        // remove class from user
        let docRef = db.collection(DataBase.User).document(UserService.user.email)
        docRef.getDocument { (doc, error) in
            if error != nil{
                print("FATAAL ERROR DUBUG ASSSASPPP: in ServerService\n\n\n\n")
                return
            }
            
            guard var classes = doc?[DataBase.classes] as? [String : [Any]] else { return }
            print("classes: \(classes)\n\n")
            print("codes: \(codes)\n\n")
            
            for course_code in codes {
                // If class is in user's classes dict
                if classes.keys.contains(course_code) {
                    // Remove email address
                    classes.removeValue(forKey: course_code)
                }
            }
            docRef.updateData([DataBase.classes : classes]) { (err) in
                if let err = err{
                    print(err.localizedDescription)
                    return
                }
            }
            
            
            print("codes2: \(codes)\n\n")
            // remove email from classes
            for course_code in codes {

                let _ = db.collection(ServerService.schoolParam).whereField(DataBase.course_code, isEqualTo: course_code).getDocuments { (querySnapshot, error) in
                    if querySnapshot?.documents.count ?? 0 > 0 { // on success | if query doesnt exist, default to 0
                        print("doc1: \(querySnapshot!.documents)\n\n")
                        print("doc2: \(querySnapshot!.documents[0].data())\n\n")
                        let doc = querySnapshot!.documents[0]
                        var emails = doc.data()[DataBase.emails] as! [String]
                        let classRef = doc.reference
                        
                        // If user's email is under class email list
                        if emails.contains(UserService.user.email) {
                            // Remove email from array
                            emails = emails.filter { $0 != UserService.user.email }
                            
                            print("course \(course_code) emails \(emails))")
                            // If no one else is tracking this class
                            if emails.count == 0 {
                                classRef.delete()
                            }
                            else {
                                // update classes email array in db
                                classRef.updateData([DataBase.emails : emails])
                            }
                        }
                    }
                }
            }
        }
    }
    
    func updatePurchaseHistory(numCreditsBought numCredits: Int, totalPrice total: Int) {
        var purchaseHistory = UserService.user.purchaseHistory
        
        if purchaseHistory.count > 0 {
            if purchaseHistory[0] == [:] {
                purchaseHistory = []
            }
        }
        
        let data: [String: String] = [
            DataBase.num_credits: "\(numCredits)",
            DataBase.date: Date().toString(),
            DataBase.price: "\(total)"
        ]
            purchaseHistory.append(data)
        
        let db = Firestore.firestore()
        let docRef = db.collection(DataBase.User).document(UserService.user.email)
        
        docRef.setData([DataBase.purchase_history : purchaseHistory], merge: true)
    }
    
    func addToTrackedClasses(classes: [String]) {
        let db = Firestore.firestore()
        let docRef = db.collection(DataBase.User).document(UserService.user.email)
        
        var updatedTrackedClasses = UserService.user.trackedClasses
        
        for course in classes {
            if !updatedTrackedClasses.contains(course) {
                updatedTrackedClasses.append(course)
            }
        }
        
        docRef.updateData([DataBase.tracked_classes: updatedTrackedClasses]) { (err) in
            if let err = err {
                print("Error updatign tracked classes", err.localizedDescription)
                return
            }
            print("Success updating trackedClasses")
        }
    }
}
