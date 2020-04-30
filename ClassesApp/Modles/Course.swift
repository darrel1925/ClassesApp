//
//  Course.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/27/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import Foundation


class Course{
    
    var course_code: String = ""
    var course_title: String = ""
    var course_name: String = ""
    var course_type: String = ""
    var section: String = ""
    var units: String = ""
    var professor: String = ""
    var days: String = ""
    var class_time: String = ""
    var status: String = ""
    var room: String = ""
    var school: String = UserService.user.school
    var year: String = AppConstants.year
    var quarter: String = AppConstants.quarter
    
    init(serverInput: String){
        let inputArr = serverInput.components(separatedBy: ",")
        if inputArr.count < 11 {
            self.status = Status.Error
            return
        }
        
        self.course_code = inputArr[0]
        self.course_name = inputArr[1]
        self.course_title = inputArr[2]
        self.course_type = inputArr[3]
        self.section = inputArr[4]
        self.units = inputArr[5]
        self.professor = inputArr[6]
        self.days = inputArr[7]
        self.class_time = inputArr[8]
        self.status = inputArr[9]
        self.room = inputArr[10]
    }
    
    init(courseDict: [String: String]) {
        
        self.course_code = courseDict[DataBase.course_code] ?? ""
        self.course_title = courseDict[DataBase.course_title] ?? ""
        self.course_name = courseDict[DataBase.course_name] ?? ""
        self.course_type = courseDict[DataBase.course_type] ?? ""
        self.section = courseDict[DataBase.section] ?? ""
        self.units = courseDict[DataBase.units] ?? ""
        self.professor = courseDict[DataBase.professor] ?? ""
        self.days = courseDict[DataBase.days] ?? ""
        self.class_time = courseDict[DataBase.class_time] ?? ""
        self.status = courseDict[DataBase.curr_status] ?? ""
        self.room = courseDict[DataBase.room] ?? ""
        
    }
    
    
    func modelToData() -> [String: Any] {
        let data: [String: Any] = [
            DataBase.course_code: self.course_code,
            DataBase.course_title: self.course_title,
            DataBase.course_name: self.course_name,
            DataBase.course_type: self.course_type,
            DataBase.section: self.section,
            DataBase.units: self.units,
            DataBase.professor: self.professor,
            DataBase.days: self.days,
            DataBase.class_time: self.class_time,
            DataBase.curr_status: self.status,
            DataBase.room: self.room,
        ]
        return data
    }
    
    static func getCodes(courses: [Course]) -> [String] {
        // Given a list of Courses, return a list of all course codes
        var courseCodeArr: [String] = []
        for course in courses{
            courseCodeArr.append(course.course_code)
        }
        return courseCodeArr
    }
    
    
}
