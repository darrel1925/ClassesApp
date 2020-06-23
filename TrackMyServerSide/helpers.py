from bs4 import BeautifulSoup
from datetime import datetime
from pytz import timezone
from constants import Constants
import pytz, urllib.request, requests
import datetime

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from firebase_admin import messaging

SERVER_IP = "http://34.209.136.1"
# ec2-34-209-136-1.us-west-2.compute.amazonaws.com
# Crashlytics script /Users/darrelmuonekwu/Desktop/classes/ClassesApp/Pods/FirebaseCrashlytics/upload-symbols -gsp /Users/darrelmuonekwu/Desktop/classes/ClassesApp/ClassesApp/GoogleService-Info.plist -p ios /Users/darrelmuonekwu/Desktop/appDsyms
# github personal access token: cc77f6c6e5ef5e228e1e8a8f714f6b72c1681653
class Quarter:
	fall          = "-92"
	winter        = "-03"
	spring        = "-14"
	summer1       = "-25"
	summer10      = "-39"
	summer2       = "-76"
	summerCom     = "-51" # <--- what is this?

class Status:
    OPEN  = "OPEN"
    FULL  = "FULL"
    Waitl = "Waitl"
    NewOnly = "NewOnly"


def get_class_status_for_ios(code, quarter, year, school):
    """
    Get class status with the input from ios device rather than from python script
    """
    # if school == UCI:
    web_address = get_class_url(code, quarter, year)
    return get_full_class_info_uci(web_address)

def get_full_class_info_uci(web_address):
    # get html for page
    response = urllib.request.urlopen(web_address)
    text = response.read()
    # make html parseable and find status
    soup = BeautifulSoup(text, 'lxml')
    status_row = soup.find_all("td")
    status = ""

    # dubugging below
    # print()
    # print(status_row)
    # print()
    # print(len(status_row))
    
    # for i, s in enumerate(status_row):
    #     print(i, "[" + s.text + "]")

    # staus is always in index 26 or 25
    for element in status_row:
        if element.text in ["OPEN", "FULL", "Waitl", "NewOnly"]:
            status = element.text
            break
    if status == "": # couldnt find the class info
        return "Error"

    # Ex. CompSci 161 DES&ANALYS OF ALGOR (Co-courses) (Prerequisites)
    # Ex. CompSci 290 RESEARCH SEMINAR
    course_header = status_row[11].text
    course_title = ""
    course_name = ""

    look_for_title = True
    _break = False

    # separate course name ex. CompSci 161 from course title ex. DES&ANALYS OF ALGOR
    for index, word in enumerate(course_header.split()):
        if look_for_title:
            # if word has a number
            for char in word:
                if char in {"1","2","3","4","5","6","7","8","9","0"}:
                    look_for_title = False
                    break
            course_name += word + " "
        else:
            for char in word:
                if char in {"(",")"}:
                    _break = True
                    break
            if _break:
                break
            course_title += word + " "


    # format professors name and only take 1st professor
    # separate the first professor
    professor_str = status_row[16].text.replace("STAFF", "").split(".")[0]
    # split the first and last name
    professor_arr = professor_str.replace(",", "").split()
    if len(professor_arr) == 0:
        professor = "STAFF"
    elif len(professor_arr) == 1: # Staff
        if professor_arr[0] == "":
            professor = "STAFF"
        else:
            professor = professor_arr[0].strip()
    else:
        professor = ""
        for name in professor_arr:
            professor += name.capitalize() + " "
        
        professor = professor.strip()
        # if professor has initial instead of last name
        if len(professor_arr[-1]) == 1:
            professor += "."

    # extract restrictions, always in index 24
    restrictions = []
    for restriction in status_row[24].text.split():
        if len(restriction) == 1:
            restrictions.append(restriction)

    code = status_row[12].text
    course_type = status_row[13].text
    section = status_row[14].text
    units = status_row[15].text
    days = status_row[17].text.split()[0]
    class_time = "".join(status_row[17].text.split()[1:])
    room = status_row[18].text

    if class_time == "":
        class_time = "TBA"

    json = {
        "status": status,
        "title": course_title.strip(),
        "name": course_name.strip(),
        "professor": professor,
        "code": code,
        "section": section,
        "units": units,
        "days": days,
        "time": class_time,
        "room": room,
        "type": course_type,
        "restrictions": restrictions,
        "website": "",
        "final": {
            "day": "",
            "date": "",
            "time": "",
            "locations": [],
        }
    }
    return json

def get_class_html(class_dict):
    """
    Takes in a course code and quarter and returns the status
    of that class
    """
    code = class_dict["code"]
    quarter = class_dict["quarter"]
    year = class_dict["year"]

    # get websoc url for class
    web_address = get_class_url(code, quarter, year)
    get_full_class_info_uci(web_address)
    # get html for page
    response = urllib.request.urlopen(web_address)
    text = response.read()

    # make html parseable and find status
    soup = BeautifulSoup(text, 'lxml')
    status_row = soup.find_all("td")

    return status_row

def get_class_status(status_row):
    """
    Takes in a status_row (html) returns the status 
    of that class. Ex. OPEN, FULL, or Waitl
    """ 
    try: 
        for element in status_row:
            if element.text in ["OPEN", "FULL", "Waitl", "NewOnly"]:
                return element.text
        return "Error" 
    except: # couldnt find the class info
        sbj = "Class likely removed"
        msg = "Error finding status. Class status is now error"
        send_email_error(sbj, msg)
        return "Error"


def get_class_url(code, quarter, year):
    """
    Takes in a course code and quarter and returns the URL for that specific
    class
    """
    urlFirstHalf  = "https://www.reg.uci.edu/perl/WebSoc?YearTerm="
    urlSecondHalf = "&ShowFinals=0&ShowComments=0&CourseCodes="
    quarter = quarter.lower()
    quarter_code = ""

    if quarter == "fall":
        quarter_code = Quarter.fall
    elif quarter == "winter":
        quarter_code = Quarter.winter    
    elif quarter == "spring":
        quarter_code = Quarter.spring    
    elif quarter == "summer1":
        quarter_code = Quarter.summer1    
    elif quarter == "summer10":
        quarter_code = Quarter.summer10
    elif quarter == "summer2":
        quarter_code = Quarter.summer2
    
    full_url = urlFirstHalf + year + quarter_code + urlSecondHalf + code  
    return full_url

def initialize_firebase():
    cred = credentials.Certificate("myclasses.json")
    firebase_admin.initialize_app(cred) # initialize app


def get_classes_to_search_for(): 
    """
    Returns all of the classes that are being tracked and 
    their associated info in a dictionary
    """
    db = firestore.client()

    uci_school_param = format_school("UCI")
    ucla_school_param = format_school("UCLA")

    uciDocs = list(db.collection(uci_school_param).stream())
    uclaDocs = list(db.collection(ucla_school_param).stream())
    
    docs = uciDocs + uclaDocs #+ classDocs

    # print("UCI", uci_school_param, uciDocs)
    # print("UCLA", ucla_school_param, uclaDocs)
    
    class_dict_arr = [] # [{status:status, quarter:quarter, school:school, ...}, ...]
    for doc in docs:
        class_dict_arr.append(doc.to_dict())

    # print(class_dict_arr)
    return class_dict_arr
    
def get_changed_restrictions(status_row, old_restrictions, class_dict):
    """
    Takes in a status_row (html) and an array of restrictions
    returns None if there is no change and an array of restrictions
    that were dropped if there is a change
    """
    try:
        # get restrictions from html
        new_restrictions = []
        for restriction in status_row[24].text.split():
            if len(restriction) == 1:
                new_restrictions.append(restriction)
    except:
        # Check html to see if class is availble still or not, 
        # if not, delete class, delete class from users who are tracking the class
        # send emails to all users notifying them of the delete
        new_restrictions = old_restrictions
        name = get_full_class_name(class_dict)
        sbj = "Class " + name + " likely removed"
        msg = "Error finding restrictions for " + name + " " + class_dict["code"]
        send_email_error(sbj, msg)

    if sorted(old_restrictions) != sorted(new_restrictions):
        print("restrictions changed from", old_restrictions, "-->", new_restrictions)
        return new_restrictions
    
    return None


def update_course_restrictions(class_dict): 
    restrictions = class_dict["restrictions"]
    school = class_dict["school"]
    code = class_dict["code"]
    status = class_dict["status"]

    db = firestore.client()
    school_param = format_school(school)
    doc_ref = db.collection(school_param).document(code)
    doc = doc_ref.get()
    
    # if user deletes the course while we are in the middle of tracking the latest list of courses the doc will not exist 
    if doc.exists:
        print("doc does exist, restr updated")
        doc_ref.set({
            "restrictions": restrictions,
        }, merge=True)
    else:
        print("doc does NOT exist, restr not updated")
        send_email_error("Doc doesnt Exists for Restr", "got doc " + code + " " + status + " " + "deostn exist")

def update_course_auto_enroll_emails(class_dict): 
    school = class_dict["school"]
    code = class_dict["code"]
    status = class_dict["status"]

    db = firestore.client()
    school_param = format_school(school)
    doc_ref = db.collection(school_param).document(code)
    doc = doc_ref.get()
    
    # if user deletes the course while we are in the middle of tracking the latest list of courses the doc will not exist 
    if doc.exists:
        print("doc does exist, auto_enroll_emails updated")
        doc_ref.set({
            "auto_enroll_emails": [],
        }, merge=True)
    else:
        print("doc does NOT exist, restr not updated")
        send_email_error("Doc doesnt Exists for Auto-Enroll", "got doc " + code + " " + status + " " + "deostn exist")


def update_course_status(class_dict):
    school = class_dict["school"]
    code = class_dict["code"]
    status = class_dict["status"]

    db = firestore.client()
    school_param = format_school(school)
    doc_ref = db.collection(school_param).document(code)
    doc = doc_ref.get()
    
    # if user deletes the course while we are in the middle of tracking the latest list of courses the doc will not exist 
    if doc.exists:
        # users are not nottified if a class goes from an Open state to a Full state
        print("doc does exist, status updated")
        doc_ref.set({
            "status": status,
        }, merge=True)
    else:
        send_email_error("Doc doesnt Exists for Status", "got doc " + code + " " + status + " " + "deostn exist")

def update_notifications_sent(num_push, num_email, reciever_email): 
    return 
    db = firestore.client()
    doc_ref = db.collection(Constants.Analytics).document(Constants.uci_analytics)
    doc = doc_ref.get()
    doc_dict = doc.to_dict()    
    notification_dict = doc_dict[Constants.notification_info]

    month = get_month()
    week = get_week()
    date = get_pst_day_and_date()
    
    if not doc.exists:
        print("Analytics Does not Exists!")
        send_email_error("Analytics Does not Exists!", "Analytics Does not Exists!")
        return 

    if month not in notification_dict.keys():
        notification_dict[month] = {            
            Constants.monthly_total: 0,
            Constants.monthly_push: 0,
            Constants.monthly_emails: 0,
            week: {
                Constants.weekly_total: 0,
                Constants.weekly_push: 0,
                Constants.weekly_emails: 0,
                date:{
                    Constants.daily_total: 0,
                    Constants.daily_push: 0,
                    Constants.daily_emails: 0,
                    }
                }
            }

    if week not in notification_dict[month].keys():
        notification_dict[month][week] =  {
                Constants.weekly_total: 0,
                Constants.weekly_push: 0,
                Constants.weekly_emails: 0,
                date:{
                    Constants.daily_total: 0,
                    Constants.daily_push: 0,
                    Constants.daily_emails: 0,
                    }
                }
                
    if date not in notification_dict[month][week].keys():
        notification_dict[month][week][date] = {
                    Constants.daily_total: 0,
                    Constants.daily_push: 0,
                    Constants.daily_emails: 0,
                    }
    # update monthly info
    notification_dict[month][Constants.monthly_total] += num_push + num_email
    notification_dict[month][Constants.monthly_push] += num_push
    notification_dict[month][Constants.monthly_emails] += num_email

    # update weekly info
    notification_dict[month][week][Constants.weekly_total] += num_push + num_email
    notification_dict[month][week][Constants.weekly_push] += num_push
    notification_dict[month][week][Constants.weekly_emails] += num_email

    # update daily info
    notification_dict[month][week][date][Constants.daily_total] += num_push + num_email
    notification_dict[month][week][date][Constants.daily_push] += num_push
    notification_dict[month][week][date][Constants.daily_emails] += num_email
    
    doc_ref.set({
        Constants.notification_info: notification_dict,
    }, merge=True)

def get_emails_tracking_this_class(class_dict): 
    """
    Returns the emails for all users that are tracking this class (Premium Users first, Free
    Users second) and an array of the user dicts of everyone with auto-enroll
    """
    school = class_dict["school"]
    code = class_dict["code"]
    
    # connect to db
    db = firestore.client()
    school_param = format_school(school)
    doc_ref = db.collection(school_param).document(code)
    doc = doc_ref.get()
    doc_dict = doc.to_dict()

    # get emails tracking this course
    emails_tracking_this_class = doc_dict["emails"]

    # get users with auto enroll
    user_emails_with_auto_enroll = doc_dict["auto_enroll_emails"]

    # get all user_docs tracking this course
    users_with_premium = []
    users_without_premium = []
    users_with_auto_enroll =[]

    for email in emails_tracking_this_class:
        # get user doc dict
        user_doc_ref = db.collection("User").document(email)
        user_doc = user_doc_ref.get()
        user_doc_dict = user_doc.to_dict()

        # split users into premium, no premium, and auto-enroll
        if user_doc_dict["has_premium"]:
            users_with_premium.append(user_doc_dict)
            if email in user_emails_with_auto_enroll:
                users_with_auto_enroll.append(user_doc_dict)
        else:
            users_without_premium.append(user_doc_dict)
    
    print("emails tracking course with    premium ", code, "are:", [user["email"] for user in users_with_premium])
    print("emails tracking course without premium ", code, "are:", [user["email"] for user in users_without_premium])
    print("emails tracking course with auto-enroll", code, "are:", [user["email"] for user in users_with_auto_enroll])

    # return emails_tracking_this_class # <-- comment out
    return users_with_premium + users_without_premium, users_with_auto_enroll 

def send_push_notification_to_user(user_dict, notif_info, notif_type):
    """
    Sends an iOS push notif to fcm in user's doc dict
    """
    # try:
    print(user_dict["email"])
    print("is_logged_in ==", user_dict["is_logged_in"])

    if (user_dict["is_logged_in"] == False) or (user_dict["notifications_enabled"] == False):
        return 

    # incase user has not updated phone to have badge count
    try:
        badge_count = user_dict["badge_count"] + 1
    except:
        print(user_dict["email"] + " does not have badge_count, setting now")
        badge_count = 1

    fcm_token = user_dict["fcm_token"]
    title, message = notif_info
    notif_data = {"notif_type": notif_type}

    # message
    notif = messaging.Message(
        notification = messaging.Notification(
            title = title,
            body = message,
        ),
        data = notif_data,
        token = fcm_token,

        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(badge=badge_count),
            ),
        ),
    )

    # send
    messaging.send(notif)
    update_notifications_sent(1, 0, user_dict["email"])
    update_badge_count(user_dict["email"])

    # except Exception as e:
    #     print("Could not send push notification")
    #     body = user_dict["email"] + " " + notif_info[0] + " Could not send push notification: " + str(e)
    #     send_email_error("Err sending notif", body)
    #     return

    # body = user_dict["email"] + " " + title + " " + message
    # send_email_error("Notif Sent:)", body)

def update_user_notification_list(email, old_status, class_dict, notif_info ,notif_type):
    code  = class_dict["code"]
    new_status  = class_dict["status"]    
    new_name = get_full_class_name(class_dict)

    db = firestore.client()
    doc_ref = db.collection("User").document(email)
    doc = doc_ref.get()
    doc_dict = doc.to_dict()    

    # if user with email does not exist
    if doc_dict == None:
        body =  "update_user_notification_list could not find doc for email: " + email
        send_email_error("Couldnt find doct_dict for " + email, body)
        return

    _, message = notif_info
    date = get_pst_time()
    print("date", date)

    data = {
        "date": date,
        "new_status": new_status,
        "old_status": old_status,
        "code": code,
        "name": new_name,
        "message": message,
        "notif_type": notif_type
    }
    
    notifications = doc_dict["notifications"]
    if notifications == [{}]:
        notifications = []
        
    notifications.append(data)

    doc_ref.set({
        "notifications": notifications,
    }, merge=True)

def update_badge_count(email):
    db = firestore.client()
    doc_ref = db.collection("User").document(email)
    doc = doc_ref.get()    
    doc_dict = doc.to_dict()    

    try:
        badge_count = doc_dict["badge_count"]
    except:
        badge_count = 0

    doc_ref.set({
        "badge_count": badge_count + 1,
    }, merge=True)


def send_email_error(subject, message):
    payload = {
    "subject": subject,
    "message": message,
    }
    requests.get(SERVER_IP + "/send_email_route", params=payload)

def get_full_class_name(class_dict):
    name = class_dict["name"]
    section = class_dict["section"]
    course_type = class_dict["type"]
    new_name = name + " " + course_type + " " + section
    return new_name

def get_pst_time():
    date_format="%Y-%m-%d %H:%M:%S"
    date = datetime.datetime.now(tz=pytz.utc)
    date = date.astimezone(timezone('US/Pacific'))
    pstDateTime=date.strftime(date_format)
    return pstDateTime

def should_slow_search():
    """
    Returns true if current time in between 2:00am - 6:59am
    """
    date_format="%H%p"
    date = datetime.datetime.now(tz=pytz.utc)
    date = date.astimezone(timezone('US/Pacific'))
    pstDateTime=date.strftime(date_format).lower()
    
    if pstDateTime in ["02am", "03am", "04am", "05am", "06am"]:
        return True
    
    return False

def get_month():
    date_format="%B"
    date = datetime.datetime.now(tz=pytz.utc)
    date = date.astimezone(timezone('US/Pacific'))
    month = date.strftime(date_format)
    return month

def get_pst_day_and_date():
    date_format="%a %m/%d"
    date = datetime.datetime.now(tz=pytz.utc)
    date = date.astimezone(timezone('US/Pacific'))
    pstDateTime=date.strftime(date_format)
    return pstDateTime

def get_week():
    date_format="%d"
    date = datetime.datetime.now(tz=pytz.utc)
    date = date.astimezone(timezone('US/Pacific'))
    day = int(date.strftime(date_format))
    
    if (day / 7) < 1: # 0 - 7
        return "week 1"
    elif (day / 7) < 2: # 8 
        return "week 2"
    elif (day / 7) < 3: # 15 - 21
        return "week 3"
    else: # 22 - 31
        return "week 4"  

def format_email(email):
    return email.split("@")[0]

def format_school(school):
    return school + "_Classes"



if __name__ == "__main__":
    print(get_pst_day_and_date())
    # print(get_full_class_info_uci("https://www.reg.uci.edu/perl/WebSoc?YearTerm=2020-92&ShowFinals=0&ShowComments=0&CourseCodes=34140"))
    # pass
    # formatted date = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
