"""
cls_ntf_eml = classnotify1@gmail.com
cls_ntf_psw = classnotify1
to add ->     "class_to_add": ["add", ["discussions and/or labs to add in one list]]
to replace -> "class_to_drop": ["replace", ["discussions and/or labs to replace with if one opens up"]]

Ex.
classes_to_look_for = {
    "34250": ["add", ["34251", "34252"]], # add COMP SCI 161 if it opens up
    "34044": ["replace", ["34043"]] # replace 34044 with 34043 if 34043 opens up
}

From User I Need:
dept_name       Ex. COMPSCI, ECON, AFAM
lectue_code     Ex. "64250"
uci_email       Ex. peterant@uci.edu
web_reg_pw      Ex. Password123!                <-- optional
dis_codes       Ex. ["64250", "64251", "64252"] <-- optional
lab_codes       Ex. ["64250", "64251", "64252"] <-- optional


Firbase Firestore:

User _
      | 
      L - ->  user_1
      |               str             uci_email:
      |               str             web_reg_pwd:     # <-- optional
      |               str             first_name:
      |               str             last_name:
      |               [str1: [str2]]  classes_to_add: # str1 = class to add | str2 = disc/labs to add as well
      |
      L - ->  user_2  
                      str              uci_email:
                      str              web_reg_pwd:     # <-- optional      
                      str              first_name:
                      str              last_name:
                      [str1: [str2]]   classes_to_add: # str1 = class to add | str2 = disc/labs to add as well

Class -
      | 
      L - ->  34250 
      |               str   lectue_code:
      |               [str] uci_email:
      |
      L - ->  34873  
                      str   lectue_code:
                      [str] uci_email:
"""

from send_email import contruct_ios_message, construct_restrictions_message, send_email_with_msg, contruct_email_message, construct_restrictions_email
from constants import Constants
import helpers, webreg
import time, sys, os, signal
helpers.initialize_firebase()

count = 0
classes_to_search_for = []


def get_course_html(class_dict):
    """
    Given a class, returns the html containing it's most current
    information
    """

    # if school == UCI:    
    status_row = helpers.get_class_html(class_dict)
    return status_row

def class_is_open(class_dict, status_row):
    """
    Given a course dict and html of the course on school's website, 
    returns a tuple describing whether or not that class is open, and
    the new and old status' if a class status has changed
    """
    school = class_dict["school"]
    code = class_dict["code"]
    old_status = class_dict["status"] 
    
    new_status = helpers.get_class_status(status_row)
    class_dict["status"] = new_status # <-- so you wont keep getting emails if class stays open

    if old_status in [helpers.Status.FULL, helpers.Status.NewOnly]:
        if new_status in [helpers.Status.OPEN, helpers.Status.Waitl]:
            print("Course", school , code, "status is " + new_status + "!!", end = " | ")
            helpers.update_course_status(class_dict) 
            return True, old_status, new_status

    if old_status in [helpers.Status.Waitl]:
        if new_status in [helpers.Status.OPEN]:
            print("Course", school , code, "status is " + new_status + "!!", end = " | ")
            helpers.update_course_status(class_dict) 
            return True, old_status, new_status

    # split bottom two if statments so Waitl -> Waitl and NewOnly -> NewOnly
        # do not execute update_course_status and watse my reads
    if old_status in [helpers.Status.OPEN, helpers.Status.Waitl]: 
        if new_status in [helpers.Status.FULL, helpers.Status.NewOnly]:
            helpers.update_course_status(class_dict)

    if old_status in [helpers.Status.OPEN, helpers.Status.NewOnly]: 
        if new_status in [helpers.Status.FULL, helpers.Status.Waitl]:
            helpers.update_course_status(class_dict) 
            
    print("Course", school, code, "status is " + new_status, end = " | ")
    return False, None, None

def check_for_restriction_change(class_dict, status_row):
    """
    Takes in dictionary of class and html of from schools website, checks for change in a
    the restrictions bewtween db and website, updates db if there is a change, and
    notifies every who is tracking this class
    """
    # incase user has not updated phone and added class to db without adding auto_enroll_emails
    if "auto_enroll_emails" not in class_dict.keys():
        class_dict["auto_enroll_emails"] = []
        helpers.update_course_auto_enroll_emails(class_dict)

    # incase user has not updated phone and added class to db without adding restrictions
    try:
        old_restrictions = class_dict["restrictions"]
    except:
        # if restrictions we'e not to db, find the restrictions and add them to db 
        old_restrictions = helpers.get_changed_restrictions(status_row, [], class_dict)
        old_restrictions           = [] if old_restrictions == None else old_restrictions
        class_dict["restrictions"] = [] if old_restrictions == None else old_restrictions

        helpers.update_course_restrictions(class_dict)

    new_restrictions = helpers.get_changed_restrictions(status_row, old_restrictions, class_dict)
    class_dict["restrictions"] = new_restrictions

    # the restrictions have changed
    if new_restrictions != None: # new_restrictions can also == []
        users, users_with_auto_enroll = helpers.get_emails_tracking_this_class(class_dict)

        # update class's restrictions in data base
        helpers.update_course_restrictions(class_dict)

        for user_doc_dict in users:
            email = user_doc_dict["email"]
            # construct the full subject and body describing which restrictions changed in detail
            subject, body = construct_restrictions_email(old_restrictions, new_restrictions, class_dict)

            # construct message to send to user's phone
            notif_info = construct_restrictions_message(old_restrictions, new_restrictions, class_dict)
            
            # only continue if user has premium
            if not user_doc_dict["has_premium"]:
                continue

            # use the detailed body to update user's notification dictionary
            new_notif_info = (subject, body)

            # send push notificatoin to user's cell phone
            helpers.send_push_notification_to_user(user_doc_dict, notif_info, Constants.restriction_changed)
            
            # updates user's notification list
            helpers.update_user_notification_list(email, "", class_dict, new_notif_info, Constants.restriction_changed)
           
            # send email to student who are tracking this class
            if user_doc_dict["receive_emails"]:
                print("sending restriction email to", email)
                full_msg = 'Subject: {}\n\n{}'.format(subject, body)
                helpers.update_notifications_sent(0, 1, email)
                send_email_with_msg(email, full_msg)
                    
        # sign users up who have paid for webreg
        for user_doc_dict in users_with_auto_enroll:
            webreg.main(user_doc_dict, class_dict)


def check_for_status_change(class_dict, status_row):
    """
    Takes in dictionary of class and html of from schools website, checks for changes in a
    the class staus bewtween db and website, updates db if there is a change, and 
    notifies every who is tracking this class
    """

    # incase user has not updated phone and added class to db without adding auto_enroll_emails
    if "auto_enroll_emails" not in class_dict.keys():
        class_dict["auto_enroll_emails"] = []
        helpers.update_course_auto_enroll_emails(class_dict)

    is_open, old_status, new_status = class_is_open(class_dict, status_row)
    # if class is open
    if is_open:
        # will_auto_enroll = [] # list of people who have auto-enroll enabled
        users, users_with_auto_enroll = helpers.get_emails_tracking_this_class(class_dict)
        
        for user_doc_dict in users:
            email = user_doc_dict["email"]

            # construct message to send to user's phone           
            notif_info = contruct_ios_message(old_status, new_status, class_dict)

            # send notif to user's cell phone
            helpers.send_push_notification_to_user(user_doc_dict, notif_info, Constants.status_changed)
            
            # update user's notification list in data base
            helpers.update_user_notification_list(email, old_status, class_dict, notif_info, Constants.status_changed)
           
            # send email to student who are tracking this class
            if user_doc_dict["receive_emails"]:
                full_msg = contruct_email_message(old_status, class_dict)
                send_email_with_msg(email, full_msg)
                helpers.update_notifications_sent(0, 1, email)

        # sign users up who have paid for webreg
        for user_doc_dict in users_with_auto_enroll:
            webreg.main(user_doc_dict, class_dict)
        
        print("emails", [user["email"] for user in users])
        
    else:
        global count
        print("# of searches", count)

def main():
    # try:
    global count, classes_to_search_for

    if count % 1 == 0:
        print("Pulling updated info")
        classes_to_search_for = helpers.get_classes_to_search_for()

    for class_dict in classes_to_search_for:
        if count < 110:
            count += 1
            continue
        time.sleep(0.25)
        # get html
        status_row = get_course_html(class_dict)
        # use html to check if class is open
        check_for_status_change(class_dict, status_row)
        # use html to check if restrictions have changed
        check_for_restriction_change(class_dict, status_row)
    count += 1            

    # except Exception as e:
    #     status = "SERVER DOWN ERROR!!!"
    #     message = "Error message: " + str(e)
    #     helpers.send_email_error(status, message)
    #     time.sleep(20)
    #     main()

# resister signal handlers
# signal.signal(signal.SIGINT, signal_handler) # catch CTRL C
# signal.signal(signal.SIGTSTP, signal_handler) # stops CTRL Z from possibly being pressed z

# main()
