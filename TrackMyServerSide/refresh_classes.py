import classes5, helpers

def get_all_classes():
    all_courses = helpers.get_classes_to_search_for()

    for course in all_courses:
        code, quarter, school, year, emails = course["code"], course["quarter"], course["school"], course["year"], course["emails"]
        # remove info added by client
        course.pop('emails', None)
        course.pop('school', None)
        course.pop('quarter', None)
        course.pop('year', None)

        if school == "UCI":
            web_address = helpers.get_class_url(code, quarter, year)
            new_dict = helpers.get_full_class_info_uci(web_address)
        
            # if course info has changed 
            if new_dict !=  course:
                # add back in removed info
                course["year"]    = year
                course["emails"]  = emails 
                course["school"]  = school
                course["quarter"] = quarter

                db = helpers.firestore.client()
                school_param = helpers.format_school(school)
                doc_ref = db.collection(school_param).document(code)
                if doc_ref.exists:
                    print("doc didnt exists")

                # add in the new info
                doc_ref.set({
                    # don't change the status 
                    "title": new_dict["title"],
                    "name": new_dict["name"],
                    "professor": new_dict["professor"],
                    "code": new_dict["code"],
                    "section": new_dict["section"],
                    "units": new_dict["units"],
                    "days": new_dict["days"],
                    "time": new_dict["time"],
                    "room": new_dict["room"],
                    "type": new_dict["type"],
                    "year": year,
                    "school": school,
                    "quarter": quarter,
                    
                }, merge=True)
    
                print("course", course, "replaced info", new_dict)

get_all_classes()