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

from send_email import send_email, contruct_ios_message
import helpers, webreg
import time, sys, os, signal
helpers.initialize_firebase()

count = 0
classes_to_search_for = []


def class_is_open(class_dict):
    """
    Given a cousre code, returns a bool describing whether or not that class is open
    """
    school = class_dict["school"]
    code = class_dict["code"]
    quarter = class_dict["quarter"]
    year = class_dict["year"]

    old_status = class_dict["status"] 
    new_status = helpers.get_class_status(code, quarter, school, year)
    class_dict["status"] = new_status # <-- so you wont keep getting emails if class stays open

    if old_status in [helpers.Status.FULL, helpers.Status.NewOnly]:
        if new_status in [helpers.Status.OPEN, helpers.Status.Waitl]:
            print("Course", school , code, "status is " + new_status + "!!", end = " | ")
            helpers.update_course_status(code, quarter, new_status, school) 
            return True, old_status, new_status

    if old_status in [helpers.Status.Waitl]:
        if new_status in [helpers.Status.OPEN]:
            print("Course", school , code, "status is " + new_status + "!!", end = " | ")
            helpers.update_course_status(code, quarter, new_status, school) 
            return True, old_status, new_status

    # split bottom two if statments so Waitl -> Waitl and NewOnly -> NewOnly
        # do not execute update_course_status and watse my reads
    if old_status in [helpers.Status.OPEN, helpers.Status.Waitl]: 
        if new_status in [helpers.Status.FULL, helpers.Status.NewOnly]:
            helpers.update_course_status(code, quarter, new_status, school)

    if old_status in [helpers.Status.OPEN, helpers.Status.NewOnly]: 
        if new_status in [helpers.Status.FULL, helpers.Status.Waitl]:
            helpers.update_course_status(code, quarter, new_status, school) 
            
    print("Course", school, code, "status is " + new_status, end = " | ")
    return False, None, None


def check_for_course(class_dict):
    """
    Given a driver opened to the correct schedule of clases page, this func will sign you up
    for the lecture and discussion
    """
    school = class_dict["school"]
    code = class_dict["code"]
    quarter = class_dict["quarter"]
    name = class_dict["name"]

    is_open, old_status, new_status = class_is_open(class_dict)
    # if class is open
    if is_open:
        # list of people who have auto-enroll enabled
        will_auto_enroll = []
        # send emails to people
        email_class_pairs = {}
        emails = helpers.get_emails_tracking_this_class(code, quarter, school)

        for email in emails:
            print("might send to:", email)
            # sed push notif to user
            user_doc_dict = helpers.get_doc_dict_for_user(email)
            notif_info = contruct_ios_message(old_status, new_status, class_dict)
            helpers.send_push_notification_to_user(user_doc_dict, notif_info)
            helpers.update_user_notification_list(email, old_status, new_status, code, name)

            # get discussions/labs that this person wants to sign up for
            dis_and_labs = helpers.get_dis_and_labs_for_user(user_doc_dict, code)
            # add then to dictionary
            email_class_pairs.update({email: dis_and_labs})
            # send email to student who are tracking this class
            if user_doc_dict["receive_emails"]:
                helpers.send_email_for_notif(email, code, name ,old_status, new_status)
                # send_email(email, code, name ,old_status, new_status)
            if user_doc_dict["web_reg"]:
                print("auto-enroll_waiting")
                will_auto_enroll.append(user_doc_dict)

        for user_doc_dict in will_auto_enroll:
            webreg.enroll(user_doc_dict, code)
        
        print("emails", emails)
        
    else:
        global count
        print("# of searches", count)


def main():
    try:
        global count, classes_to_search_for

        if count % 1 == 0:
            print("Pulling updated info")
            classes_to_search_for = helpers.get_classes_to_search_for()

        for class_dict in classes_to_search_for:
            check_for_course(class_dict)
        count += 1            
    except Exception as e:
        status = "SERVER DOWN ERROR!!!"
        message = "Error message: " + str(e)
        helpers.send_email_error(status, message)
        time.sleep(20)
        main()
# resister signal handlers
# signal.signal(signal.SIGINT, signal_handler) # catch CTRL C
# signal.signal(signal.SIGTSTP, signal_handler) # stops CTRL Z from possibly being pressed z

# main()
