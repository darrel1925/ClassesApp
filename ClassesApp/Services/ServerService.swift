//
//  ServerService.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/10/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//  python3 -m pip install firebase-admin
// #!/System/Library/Frameworks/Python.framework/Versions/2.7/Resources/Python.app/Contents/MacOS/Python

import Foundation
import FirebaseFirestore
import FirebaseFunctions

let ServerService = _ServerService()

final class _ServerService {
    
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
    
    func getClassStatus(withGroup dispatchGroup: DispatchGroup, homeVC: HomePageController) {
        let db = Firestore.firestore()
        homeVC.courses.removeAll()
        for cls in UserService.user.courseCodes {
            dispatchGroup.enter()
            let docRef = db.collection(ServerService.schoolParam).document(cls)
            
            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    guard let data = document.data() else { print("couldn't do it"); return }
                    
//                    print(data)
                    let course = Course(courseDict: data)
                    homeVC.courses.append(course)
                    
//                    print("Found course: \(cls) status: \(course.status)")
                    dispatchGroup.leave()
                    
                } else {
                    print("Document does not exist")
                    dispatchGroup.leave()
                }
            }
        }
    }
    
    func addClassToFirebase(withCourse course: Course, viewController controller: UIViewController, withDiscussions discussions: [String] = [], withLabs labs: [String] = []) -> Bool {
        dispatchGroup.enter()
        let db = Firestore.firestore()
        var returnValue = true // <-- indicates success or failure
        
        // Find course in db
        let _ = db.collection(ServerService.schoolParam).whereField(DataBase.code, isEqualTo: course.code)
            .getDocuments() { (querySnapshot, err) in
                if let _ = err {
                    let message = "There was a problem tracking your class, please try again later."
                    controller.displayError(title: "Error", message: message)
                    returnValue = false
                    self.dispatchGroup.customLeave()
                    return
                }
                else {
                    let docs = querySnapshot!.documents
                    
                    // If class is not being tracked by anyone
                    if docs.count == 0 {
                        // Create a new class
                        let docRef = db.collection(ServerService.schoolParam).document(course.code)
                        var data = course.modelToData()
                        data[DataBase.emails] = [UserService.user.email]
                        
                        docRef.setData(data, merge: true) { (err) in
                            if let _ = err {
                                let message = "There was a problem tracking your class, please try again later."
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
                let message = "There was a problem tracking your class, please try again later."
                controller.displayError(title: "Error", message: message)
                self.dispatchGroup.customLeave()
                returnValue = false
                return
            }
            var classDict = doc?.data()![DataBase.classes]  as! [String: Any]
            classDict.updateValue(discussions + labs, forKey: course.code)
            docRef.setData([DataBase.classes: classDict], merge: true)
        }
        print("add classes finished")
        self.dispatchGroup.customLeave()
        return returnValue
    }
    
    func removeClassesFromFirebase(withCourseCodes codes: [String], completion: @escaping () -> ()) {
        let db = Firestore.firestore()
        
        // remove class from user
        let docRef = db.collection(DataBase.User).document(UserService.user.email)
        docRef.getDocument { (doc, error) in
            if error != nil{
                print("FATAAL ERROR DUBUG ASSSASPPP: in ServerService\n\n\n\n")
                completion()
                return
            }
            
            guard var classes = doc?[DataBase.classes] as? [String : [Any]] else { completion(); return }
            
            for code in codes {
                // If class is in user's classes dict
                if classes.keys.contains(code) {
                    // Remove email address
                    classes.removeValue(forKey: code)
                }
            }
            docRef.updateData([DataBase.classes : classes]) { (err) in
                if let err = err{
                    print("ERRRRR", err.localizedDescription)
                    completion()
                    return
                }
            }
            
            
            // remove email from classes
            for code in codes {
                
                let _ = db.collection(ServerService.schoolParam).whereField(DataBase.code, isEqualTo: code).getDocuments { (querySnapshot, error) in
                    if querySnapshot?.documents.count ?? 0 > 0 { // on success | if query doesnt exist, default to 0
//                        print("doc1: \(querySnapshot!.documents)\n\n")
//                        print("doc2: \(querySnapshot!.documents[0].data())\n\n")
                        let doc = querySnapshot!.documents[0]
                        var emails = doc.data()[DataBase.emails] as! [String]
                        let classRef = doc.reference
                        
                        // If user's email is under class email list
                        if emails.contains(UserService.user.email) {
                            // Remove email from array
                            emails = emails.filter { $0 != UserService.user.email }
                            
//                            print("course \(code) emails \(emails))")
                            // If no one else is tracking this class
                            if emails.count == 0 {
                                classRef.delete()
                            }
                            else {
                                // update classes email array in db
                                classRef.updateData([DataBase.emails : emails])
                            }
                        }
                        
                        // if this class has an auto_enroll param (old versions might not create it)
                        if var auto_enroll_emails = doc.data()[DataBase.auto_enroll_emails] as? [String] {
                            // if user is registered in auto_enroll, remove them
                            auto_enroll_emails = auto_enroll_emails.filter { $0 != UserService.user.email }
                            classRef.updateData([DataBase.auto_enroll_emails : auto_enroll_emails])
                        }
                        print("completion 1")
                        completion()
                        return
                    }
                    else {
                        print("completion 2")
                        completion()
                        return
                    }
                }
                return
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
    
    // parameters are the types of data that you want back from this function
    func getClassInfo(course_code: String, completionHandler: @escaping ([String: Any]?, Bool, Error?) -> Void) {
        // Create url that will get parsed and give you the parameters
        print("entered get info")
        var components = URLComponents()
        components.scheme = Routes.scheme
        components.host = AppConstants.server_ip
        components.path = "/\(UserService.user.school)/\(Routes.class_info ?? "")"
        
        let schoolQueryItem = URLQueryItem(name: DataBase.school, value: UserService.user.school)
        let quarterQueryItem = URLQueryItem(name: DataBase.quarter, value: AppConstants.quarter)
        let courseCodeQueryItem = URLQueryItem(name: DataBase.code, value: course_code)
        let yearCodeQueryItem = URLQueryItem(name: DataBase.year, value: AppConstants.year)
        //        let emailCodeQueryItem = URLQueryItem(name: DataBase.email, value: UserService.user.email)
        components.queryItems = [ schoolQueryItem, quarterQueryItem, courseCodeQueryItem,yearCodeQueryItem]
        
        // Full url with all parameters included
        guard let url = components.url else { return }
        print("url is ", url)
        
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            if let error = error {
                print("WE HAVE ERROR", error.localizedDescription)
                completionHandler(nil, false, error)
            }
            
            print("no error")
            guard let data = data else { return }
//            print(data)
            do {
                let json =  try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                completionHandler(json, false, nil)
            }
            catch {
                completionHandler(nil, true, error)
            }
        }
        task.resume()
    }
    
    func updateUser(atKey key: String, withValue value: Any) {
        let db = Firestore.firestore()
        let docRef = db.collection(DataBase.User).document(UserService.user.email)
        docRef.setData([key : value], merge: true)
    }
    
    func sendSupportEmail(subject: String, message: String, completionHandler: @escaping ([String: Any]?, Error?) -> Void) {
        
        var components = URLComponents()
        components.scheme = Routes.scheme
        components.host = AppConstants.server_ip
        components.path = "/\(Routes.send_email_route ?? "")"
        
        let subjectQueryItem = URLQueryItem(name: DataBase.subject, value: subject)
        let messageQueryItem = URLQueryItem(name: DataBase.message, value: message)
        
        components.queryItems = [subjectQueryItem, messageQueryItem]
        
        guard let url = components.url else { return }
        
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            if let error = error {
                print("WE HAVE ERROR", error.localizedDescription)
                completionHandler(nil, error)
            }
            
            print("no error")
            guard let data = data else { return }
            print(data)
            do {
                let json =  try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                completionHandler(json, nil)
            }
            catch {
                completionHandler(nil, error)
            }
        }
        task.resume()
    }
    
    // UNUSED
    func addClassToDb(course: Course, completion: @escaping ([String: Any]?, Error?) -> Void ){
        
        // construct url
        var components = URLComponents()
        components.scheme = Routes.scheme
        components.host = AppConstants.server_ip
        components.path = "/\(Routes.send_email_route ?? "")"
        
        // get constructed url
        guard let url = components.url else { return }
        
        // add all key,vals from course to th query
        let courseDict = course.modelToData()
        var queryItems: [URLQueryItem] = []
        for key in courseDict.keys {
            queryItems.append(URLQueryItem(name: key, value: courseDict[key] as? String ?? "not a string"))
        }
        
        // get query
        components.queryItems = queryItems
        let query = components.url!.query
        
        // construct request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data(query!.utf8)
        
        // send request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("WE HAVE ERROR", error.localizedDescription)
                completion(nil, error)
            }
            
            print("no error")
            guard let data = data else { return }
            print(data)
            do {
                let json =  try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                completion(json, nil)
            }
            catch {
                completion(nil, error)
            }
            
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
        }
        task.resume()
    }
    
    // UNUSED
    func updatePurchaseMade() {
        Stats.logPurchase()
        getToken(forEmail: AppConstants.my_email) { (token) in
            guard let token = token else { print("no token"); return }
        
            let data: [String : Any] = [
                DataBase.email: UserService.user.email,
                DataBase.school: UserService.user.school,
                DataBase.date: Date().toString(),
            ]
            self.sendToPhone(withToken: token, withData: data)
            self.updatePurchaseAnalytics(data: data)
        }
    }
    
    fileprivate func getToken(forEmail email: String, completion: @escaping (String?) -> Void ) {
        let db = Firestore.firestore()
        let docRef = db.collection(DataBase.User).document(email)

        docRef.getDocument { (doc, error) in
            if error != nil {
                completion(nil)
                return
            }
            guard let token = doc?[DataBase.fcm_token] as? String else { return }
            completion(token)
        }
    }
    
    fileprivate func sendToPhone(withToken token: String, withData data: [String: Any]) {
        print("send to token: \(token)")
        let message: [String : Any] = [
            "notification": [
                "title": "New Purchase!!",
                "body": "Shmoney :D"
            ],
            "data": data,
            "token": token
        ]

        // sends notification to phone
        Functions.functions().httpsCallable("sendNotification").call(message) { (result, error) in
            if let error = error {
                debugPrint(error.localizedDescription)
                return
            }
        }
    }
        
    fileprivate func updatePurchaseAnalytics(data: [String: Any]) {
        let db = Firestore.firestore()
        let docRef = db.collection(DataBase.Analytics).document(DataBase.purchases)

        docRef.getDocument { (doc, error) in
            if error != nil {
                return
            }

            guard var premiumArr = doc?[DataBase.premium] as? [[String: Any]] else { return }
            premiumArr.append(data)
            docRef.setData([DataBase.premium: premiumArr], merge: true)
        }
    }

    enum VersionError: Error {
        case invalidResponse, invalidBundleInfo
    }
    
    func isUpdateAvailable(completion: @escaping (Bool?, Error?) -> Void) throws -> URLSessionDataTask {
        guard let info = Bundle.main.infoDictionary,
            let currentVersion = info["CFBundleShortVersionString"] as? String,
            let identifier = info["CFBundleIdentifier"] as? String,
            let url = URL(string: "http://itunes.apple.com/lookup?bundleId=\(identifier)") else {
                throw VersionError.invalidBundleInfo
        }
        print("my versions is:", currentVersion)
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let error = error { throw error }
                guard let data = data else { throw VersionError.invalidResponse }
                let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]
                guard let result = (json?["results"] as? [Any])?.first as? [String: Any], let version = result["version"] as? String else {
                    throw VersionError.invalidResponse
                }
                print("app store version is")
                completion(version != currentVersion, nil)
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
        return task
    }

    func getCurrentAppStoreVersion(completion: @escaping (String?, Bool) -> Void) {
        guard let info = Bundle.main.infoDictionary,
            let identifier = info["CFBundleIdentifier"] as? String,
            let url = URL(string: "http://itunes.apple.com/lookup?bundleId=\(identifier)")
            else { completion(nil, false); return }
        
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let _ = error { completion(nil, false) }
                guard let data = data else { completion(nil, false); return }
                let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]
                guard let result = (json?["results"] as? [Any])?.first as? [String: Any], let version = result["version"] as? String else { completion(nil, false); return }
                print("app store version is")
                completion(version, true)
            } catch {
                completion(nil, false)
            }
        }
        task.resume()
    }
}

