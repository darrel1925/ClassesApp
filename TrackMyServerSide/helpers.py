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
    # email, quarter, year, code, school, dis_sections, lab_sections =  parse_input(server_input)
    web_address = get_class_url(code, quarter, year)
    if school:
        return get_full_class_info_uci(web_address)
    return get_class_status(code, quarter, school, year)

def get_full_class_info_uci(web_address):
    # get html for page
    response = urllib.request.urlopen(web_address)
    text = response.read()
    # make html parseable and find status
    soup = BeautifulSoup(text, 'lxml')
    status_row = soup.find_all("td")
    status = ""
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


    # CompSci 161 DES&ANALYS OF ALGOR (Co-courses) (Prerequisites)
    # CompSci 290 RESEARCH SEMINAR
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

    # print("Prof", professor)

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
    }
    return json

def get_class_status(code, quarter, school, year):
    """
    Takes in a course code and quarter and returns the status 
    of that class. Ex. OPEN, FULL, or Waitl
    """ 
    # get websoc url for class
    web_address = get_class_url(code, quarter, year)
    get_full_class_info_uci(web_address)
    # get html for page
    response = urllib.request.urlopen(web_address)
    text = response.read()

    # make html parseable and find status
    soup = BeautifulSoup(text, 'lxml')
    status_row = soup.find_all("td")

    #####TODO: IF THIS CAUSES AN ERROR, CHANGE STATUS IN DB TO ERROR #####
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

def parse_input(input_str):
    input_str = input_str.split(",")

    email = input_str[0]
    quarter = input_str[1]
    year = input_str[2]
    code = input_str[3]
    school = input_str[4]
    dis_sections = input_str[5].split()
    lab_sections = input_str[6].split()

    return email, quarter, year, code, school, dis_sections, lab_sections

def add_class_to_fb(server_input):
    emails = []
    email, quarter, year, code, school, dis_sections, lab_sections =  parse_input(server_input)

    db = firestore.client()
    school_param = format_school(school)
    doc_list = list(db.collection(school_param).where('code', '==', code).where('quarter', '==', quarter).stream())

    # doc is in the db
    if len(doc_list) > 0: 
        print("Class is already in db")
        
        doc = doc_list[0]
        emails = doc.to_dict()["emails"]
        if email not in emails:
            emails.append(email)

        doc.reference.set({ "emails": emails, }, merge=True)
    
    else:
        # Old, need to update to use again
        print('Class does not already exist in db!')
        doc_id = format_doc_id(code, quarter)
        school_param = format_school(school)
        doc_ref = db.collection(school_param).document(doc_id) # create new doc ref
        doc_ref.set({
            "status": "FULL", # needs to ALWAYS start out is FULL to send first email!
            "code": code,
            "quarter": quarter,
            "emails": emails,
            "year": year
        }, merge=True)

    print("found emails for", format_doc_id(code, quarter), "=", emails)
    # add user to class document
    if email not in emails:
        emails.append(email)

        doc_ref.set({
            "status": "FULL", # <-- needs to ALWAYS start out is FULL to send first email!
            "code": code,
            "quarter": quarter,
            "emails": emails,
            "year": year
        }, merge=True)


    # add class/discussions/labs to users document
    doc_ref = db.collection("User").document(email)
    try:
        doc = doc_ref.get()
        classes = doc.to_dict()["classes"]
        print(u'emails: {}'.format(emails))
        classes.update({code: dis_sections + lab_sections})
        doc_ref.update({"classes": classes}) # if user is in data base
    except Exception as e:
        print(str(e))
        print(u'User not found in db!')
        classes.update({code: dis_sections + lab_sections})
        doc_ref.set({"classes": classes}, merge=True) # if user is not in data base

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
    
def get_users_tracking_this_class(code, quarter, school): 
    """
    Returns the emails and passwords for all users that
    are tracking this class
    """
    db = firestore.client()
    school_param = format_school(school)
    doc_ref = db.collection(school_param).document(code)
    doc = doc_ref.get()
    doc_dict = doc.to_dict()

    users_tracking_this_class = doc_dict["emails"]
    users_info = []

    for email in users_tracking_this_class:
        formated_email = format_email(email)
        pwd = get_pw(email)

        users_info.append([formated_email, pwd])

    return users_info

def update_course_status(code, quarter, new_status, school): 
    db = firestore.client()
    school_param = format_school(school)
    doc_ref = db.collection(school_param).document(code)
    doc = doc_ref.get()
    
    # if user deletes the course while we are in the middle of tracking the latest list of
    # courses the doc will not exist 
    
    if doc.exists:
        doc_ref.set({
            "status": new_status,
        }, merge=True)

def get_emails_tracking_this_class(code, quarter, school): 
    """
    Returns only the emails for all users that
    are tracking this class
    """
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

def get_dis_and_labs_for_user(doc_dict, code):
    """
    Returns all of the labs and discussions that the users wants to sign up for
    relating to this code
    """
    dis_and_labs = doc_dict["classes"][code]
    return dis_and_labs

def send_push_notification_to_user(doc_dict, notif_info):
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
        notif_data = {"key": "value"}

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
    except:
        print("Could not send push notification")

def update_user_notification_list(email, old_status, new_status, code, name):
    db = firestore.client()
    doc_ref = db.collection("User").document(email)
    doc = doc_ref.get()
    doc_dict = doc.to_dict()    

    # date_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    date = get_pst_time()
    print("date", date)

    data = {
        "date": date,
        "new_status": new_status,
        "old_status": old_status,
        "code": code,
        "name": name
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
    print(r.text, "sent")

def send_email_for_notif(reciever_email, code, name ,old_status, new_status):
    payload = {
    "reciever_email": reciever_email,
    "code": code,
    "name": name,
    "old_status": old_status,
    "new_status": new_status,
    }
    r = requests.get(SERVER_IP + "/send_notification_email", params=payload)
    print(r.text, "sent")


def user_has_webreg_enabled(email):
    """
    Returns a bool indicating if a user has webreg enabled  
    """
    db = firestore.client()
    doc_ref = db.collection("User").document(email)
    doc = doc_ref.get()
    doc_dict = doc.to_dict()    

    try:
        return doc_dict["web_reg"]
    except:
        return False

def get_pw(email):
    db = firestore.client()
    doc_ref = db.collection("User").document(email)
    doc = doc_ref.get()
    doc_dict = doc.to_dict()

    return doc_dict["web_reg_pswd"]


def get_pst_time():
    date_format="%Y-%m-%d %H:%M:%S"
    date = datetime.datetime.now(tz=pytz.utc)
    date = date.astimezone(timezone('US/Pacific'))
    pstDateTime=date.strftime(date_format)
    return pstDateTime

def format_email(email):
    return email.split("@")[0]

def format_doc_id(code, quarter):
    return code + " " + quarter

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

# print(get_full_class_info_uci("https://www.reg.uci.edu/perl/WebSoc?YearTerm=2020-92&ShowFinals=0&ShowComments=0&CourseCodes=05551"))
# 68210