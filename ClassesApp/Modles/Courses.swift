//
//  MyCourses.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/27/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import Foundation

class Courses {
    var courses: [Course]
    
    init(courses: [Course]){
        self.courses = courses
    }
    
    static func modelToData(myCourses: Courses) -> [String: Any] {
        let data : [String: Any] = [
            DataBase.courses : myCourses.courses,
        ]
        
        return data
    }

}


