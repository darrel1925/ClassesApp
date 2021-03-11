import classes5, helpers
from time import sleep
from datetime import datetime

def get_all_classes():
    try:
        db = helpers.firestore.client()
        docs = list(db.collection('User').stream())
        # print(len(docs))

        count = 0
        for doc in docs:
            doc_ref = doc.reference
            doc_ref.set({
            "notifications": [],
            "has_premium": False,
            "badgeCount": 0,
            "classes": dict(),
            "num_referrals": 0,

            }, merge=True)

            count +=1
            print(len(docs) - count)
    except Exception as e:
        print(e)

# def get_all_classes():
#     try:
#         all_courses = helpers.get_classes_to_search_for()
#         count = 0
#         for course in all_courses:
#             count += 1
#             print("Checked class #", count)
#             code, quarter, school, year, emails = course["code"], course["quarter"], course["school"], course["year"], course["emails"]
#             # remove info added by client
#             course.pop('emails', None)
#             course.pop('school', None)
#             course.pop('quarter', None)
#             course.pop('year', None)    

#             sleep(3)
#             if school == "UCI":
#                 web_address = helpers.get_class_url(code, quarter, year)
#                 updated_dict = helpers.get_full_class_info_uci(web_address)

#                 # if course info has changed 
#                 if updated_dict !=  course:
#                     print("old", course)
#                     print("!=")
#                     print("new", updated_dict)
#                     course["year"]    = year
#                     course["emails"]  = emails 
#                     course["school"]  = school
#                     course["quarter"] = quarter

#                     db = helpers.firestore.client()
#                     school_param = helpers.format_school(school)
#                     doc_ref = db.collection(school_param).document(code)
#                     doc = doc_ref.get() 

#                     # if the last person tracking this class deletes it from db after we pulled our info
#                     # and before we have checked it, it will not exist
#                     if not doc.exists:
#                         print("doc didnt exists")
#                         continue

#                     # add in the new info
#                     doc_ref.set({
#                         # do NOT change the status 
#                         "title": updated_dict["title"],
#                         "name": updated_dict["name"],
#                         "professor": updated_dict["professor"],
#                         "code": updated_dict["code"],
#                         "section": updated_dict["section"],
#                         "units": updated_dict["units"],
#                         "days": updated_dict["days"],
#                         "time": updated_dict["time"],
#                         "room": updated_dict["room"],
#                         "type": updated_dict["type"],
#                         "restrictions": updated_dict["restrictions"],
#                         "year": year,
#                         "school": school,
#                         "quarter": quarter,
                        
#                     }, merge=True)

#     except Exception as e:
#         status = "Refresh Error!!!"
#         message = "Error message: " + str(e)
#         helpers.send_email_error(status, message)
#         get_all_classes()
#         sleep(20)


# def practice():
#     db = helpers.firestore.client()
#     docs = db.collection('User').where(u'fcm_token', u'==', "").stream()
#     docs1 = db.collection('User').stream()
#     docs2 = db.collection('User').stream()
#     docs3 = db.collection('User').stream()
#     all_classes = list(db.collection('UCI_Classes').stream())
#     dnt_have = len(list(docs)) 
#     total = len(list(docs1))
#     do_have = total - dnt_have
#     do_have_percent = do_have / total
#     num_tracked_classes = 0
#     tracking_0 = 0
#     tracking_1 = 0
#     tracking_2 = 0
#     tracking_3_plus = 0
#     num_premium_users = 0
#     unverified_emails = 0

#     for user in docs3:
#         if not user.to_dict()["is_email_verified"]:
#             unverified_emails += 1

#     for course in all_classes:
#         num_tracked_classes += len(course.to_dict()["emails"])

#     for user in list(docs2):
#         numer_tracked = len(user.to_dict()["classes"])

#         if numer_tracked == 0:
#             tracking_0 += 1
#         elif numer_tracked == 1:
#             tracking_1 += 1
#         elif numer_tracked == 2:
#             tracking_2 += 1
#         else:
#             tracking_3_plus += 1

        

#     print(dnt_have, "do not have fcm tokens")
#     print(total, "of total users")
#     print(do_have, "do have fcm tokens")
#     print(str(round(do_have_percent,4) * 100) + "% do have fcm tokens")
#     print(len(all_classes), "Num classes being tracked" )
#     print(num_tracked_classes, "Num total tracked classes")
#     print()
#     print(tracking_0, "Tracking 0 classes")
#     print(tracking_1, "Tracking 1 class")
#     print(tracking_2, "Tracking 2 classes")
#     print(tracking_3_plus, "Tracking 3+ class")
#     print(unverified_emails, "users with unverified emails")
#     # 198 do not have fcm tokens
#     # 340 of total users
#     # 142 do have fcm tokens
#     print()
#     print()



if __name__ == "__main__":
    get_all_classes()


