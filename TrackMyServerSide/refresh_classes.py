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
            updated_dict = helpers.get_full_class_info_uci(web_address)
        
            # if course info has changed 
            if updated_dict !=  course:
                # add back in removed info
                # print(updated_dict)
                # print()
                # print(course)
                # print(updated_dict["code"])
                # print(course["code"])
                # return
                course["year"]    = year
                course["emails"]  = emails 
                course["school"]  = school
                course["quarter"] = quarter

                db = helpers.firestore.client()
                school_param = helpers.format_school(school)
                doc_ref = db.collection(school_param).document(code)
                doc = doc_ref.get() 

                # if the last person tracking this class deletes it from db after we pulled our info
                # and before we have checked it, it will not exsist
                if not doc.exists:
                    print("doc didnt exists")
                    continue

                # add in the new info
                doc_ref.set({
                    # don't change the status 
                    "title": updated_dict["title"],
                    "name": updated_dict["name"],
                    "professor": updated_dict["professor"],
                    "code": updated_dict["code"],
                    "section": updated_dict["section"],
                    "units": updated_dict["units"],
                    "days": updated_dict["days"],
                    "time": updated_dict["time"],
                    "room": updated_dict["room"],
                    "type": updated_dict["type"],
                    "restrictions": updated_dict["restrictions"],
                    "year": year,
                    "school": school,
                    "quarter": quarter,
                    
                }, merge=True)
                print("false")


            print("true")

                # print("course", course, "replaced info", updated_dict)

get_all_classes()