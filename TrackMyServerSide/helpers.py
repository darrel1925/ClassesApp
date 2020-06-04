from bs4 import BeautifulSoup
from datetime import datetime
from pytz import timezone
import pytz, urllib.request, requests
import datetime

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from firebase_admin import  messaging

SERVER_IP = "http://34.209.136.1"


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
        "restrictions": restrictions
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
    
# def get_users_tracking_this_class(code, quarter, school): 
#     """
#     Returns the emails and passwords for all users that
#     are tracking this class
#     """
#     db = firestore.client()
#     school_param = format_school(school)
#     doc_ref = db.collection(school_param).document(code)
#     doc = doc_ref.get()
#     doc_dict = doc.to_dict()

#     users_tracking_this_class = doc_dict["emails"]
#     users_info = []

#     for email in users_tracking_this_class:
#         formated_email = format_email(email)
#         pwd = get_pw(email)

#         users_info.append([formated_email, pwd])

#     return users_info

def get_changed_restrictions(status_row, old_restrictions):
    """
    Takes in a status_row (html) and an array of restrictions
    returns None if there is no change and an array of restrictions
    that were dropped if there is a change
    """
    # get restrictions from html
    new_restrictions = []
    for restriction in status_row[24].text.split():
        if len(restriction) == 1:
            new_restrictions.append(restriction)
    # print("Restriction -->", new_restrictions)

    if sorted(old_restrictions) != sorted(new_restrictions):
        print("restrictions changed from", old_restrictions, "-->", new_restrictions)
        return new_restrictions
    
    return None


def update_course_restrictions(class_dict): 
    restrictions = class_dict["restrictions"]
    school = class_dict["school"]
    code = class_dict["code"]

    db = firestore.client()
    school_param = format_school(school)
    doc_ref = db.collection(school_param).document(code)
    doc = doc_ref.get()
    
    # if user deletes the course while we are in the middle of tracking the latest list of
    # courses the doc will not exist 
    
    if doc.exists:
        print("doc does exist")
        doc_ref.set({
            "restrictions": restrictions,
        }, merge=True)
    else:
        send_email_error("Doc doesnt Exists Restrictions", "got doc " + code + " " + restrictions + " " + "deostn exist")
        doc_ref.set({
            "restrictions": restrictions,
        }, merge=True)

def update_course_status(class_dict): 
    school = class_dict["school"]
    code = class_dict["code"]
    status = class_dict["status"]

    db = firestore.client()
    school_param = format_school(school)
    doc_ref = db.collection(school_param).document(code)
    doc = doc_ref.get()
    
    # if user deletes the course while we are in the middle of tracking the latest list of
    # courses the doc will not exist 
    
    if doc.exists:
        print("doc does exist")
        doc_ref.set({
            "status": status,
        }, merge=True)
    else:
        send_email_error("Doc doesnt Exists", "got doc " + code + " " + status + " " + "deostn exist")
        doc_ref.set({
            "status": status,
        }, merge=True)

def get_emails_tracking_this_class(class_dict): 
    """
    Returns only the emails for all users that
    are tracking this class
    """
    school = class_dict["school"]
    code = class_dict["code"]
    
    db = firestore.client()
    school_param = format_school(school)
    doc_ref = db.collection(school_param).document(code)
    doc = doc_ref.get()
    doc_dict = doc.to_dict()

    emails_tracking_this_class = doc_dict["emails"]

    print("emails tracking course", code, "are:", emails_tracking_this_class)
    return emails_tracking_this_class

def get_doc_dict_for_user(email):
    """
    Returns a document dictionary for a specific user
    """
    db = firestore.client()
    doc_ref = db.collection("User").document(email)
    doc = doc_ref.get()
    doc_dict = doc.to_dict()    
    return doc_dict

# def get_dis_and_labs_for_user(doc_dict, code): # <-- depricated
#     """
#     Returns all of the labs and discussions that the users wants to sign up for
#     relating to this code
#     """
#     dis_and_labs = doc_dict["classes"][code]
#     return dis_and_labs

def send_push_notification_to_user(doc_dict, notif_info, notif_type):
    """
    Sends an iOS push notif to fcm in user's doc dict
    """
    try:
        print(doc_dict["email"])
        print("is_logged_in ==", doc_dict["is_logged_in"])
        if (doc_dict["is_logged_in"] == False) or (doc_dict["notifications_enabled"] == False):
            return 

        fcm_token = doc_dict["fcm_token"]
        title, message = notif_info
        notif_data = {"notif_type": notif_type}

        # message
        notif = messaging.Message(
            notification = messaging.Notification(
                title = title,
                body = message
            ),
            data = notif_data,
            token = fcm_token,
        )

        # send
        messaging.send(notif)

    except Exception as e:
        print("Could not send push notification")
        body = "Could not send push notification: " + str(e)
        send_email_error("ERR SENDING NOTIF", body)
        return

    body = doc_dict["email"] + " " + title + " " + message
    send_email_error("Notif Sent:)", body)

def update_user_notification_list(email, old_status, new_status, code, name, notif_info ,notif_type):
    db = firestore.client()
    doc_ref = db.collection("User").document(email)
    doc = doc_ref.get()
    doc_dict = doc.to_dict()    

    # date_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    _, message = notif_info
    date = get_pst_time()
    print("date", date)

    data = {
        "date": date,
        "new_status": new_status,
        "old_status": old_status,
        "code": code,
        "name": name,
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

def send_email_error(subject, message):
    payload = {
    "subject": subject,
    "message": message,
    }
    r = requests.get(SERVER_IP + "/send_email_route", params=payload)
    print(r.text, "sent err")

def send_email_for_notif(reciever_email, code, name ,old_status, new_status):
    payload = {
    "reciever_email": reciever_email,
    "code": code,
    "name": name,
    "old_status": old_status,
    "new_status": new_status,
    }
    r = requests.get(SERVER_IP + "/send_notification_email", params=payload)
    print(r.text, "sent notif")


# def user_has_webreg_enabled(email): # <-- depricated
#     """
#     Returns a bool indicating if a user has webreg enabled  
#     """
#     db = firestore.client()
#     doc_ref = db.collection("User").document(email)
#     doc = doc_ref.get()
#     doc_dict = doc.to_dict()    

#     try:
#         return doc_dict["web_reg"]
#     except:
#         return False

# def get_pw(email): # <-- depricated
#     db = firestore.client()
#     doc_ref = db.collection("User").document(email)
#     doc = doc_ref.get()
#     doc_dict = doc.to_dict()

#     return doc_dict["web_reg_pswd"]


def get_pst_time():
    date_format="%Y-%m-%d %H:%M:%S"
    date = datetime.datetime.now(tz=pytz.utc)
    date = date.astimezone(timezone('US/Pacific'))
    pstDateTime=date.strftime(date_format)
    return pstDateTime

def format_email(email):
    return email.split("@")[0]

# def format_doc_id(code, quarter):
#     return code + " " + quarter

def format_school(school):
    return school + "_Classes"



# initialize_firebase() 
# get_pw("a@uci.edu")
# get_class_status("34250", "fall", "2019")
# print(get_pw("dmuonekw@uci.edu"))
# print(format_email("dmuonekw@uci.edu"))
# print(get_users_tracking_this_class("34250"))
# print(get_users_tracking_this_class("34250"))
# update_class()
# get_classes_to_search_for()
# update_course_status(1,2)

# formatted date = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

# print(get_full_class_info_uci("https://www.reg.uci.edu/perl/WebSoc?YearTerm=2020-92&ShowFinals=0&ShowComments=0&CourseCodes=34140"))
# 68210