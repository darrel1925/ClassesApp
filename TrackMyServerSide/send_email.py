import smtplib
from constants import Restrictions
# from helpers import get_full_class_name

WEB_REG_URL = "https://www.reg.uci.edu/cgi-bin/webreg-redirect.sh"

def send_email_with_msg(reciever_email, message):
    try:
        server = smtplib.SMTP('smtp.gmail.com:587')
        server.ehlo()
        server.starttls()
        server.login("classnotify1@gmail.com", "class123!")
        server.sendmail("classnotify1@gmail.com", reciever_email, message)
        server.quit()
        print("Success: Email sent!")
        return True
    except Exception as e:
        print("Email failed to send.")
        print("Error:", str(e))
        return False


def contruct_email_message(old_status, class_dict):
    code  = class_dict["code"]
    new_status  = class_dict["status"]
    
    new_name = get_full_class_name(class_dict)
    old_status, new_status = _format_status(old_status, new_status)

    old_status, new_status = _format_status(old_status, new_status)    
    opt_out_info = "\n\nNote: To opt-out of email notifications, change your preferences in your app Settings."

    if new_status == "Open":
        subject = new_name + " is Open!"
        body = "Your class" + " (" + code + ") " + "has changed from " + old_status + " to " + new_status + "! Head to Web Reg to sign up! \n\n" + WEB_REG_URL + opt_out_info
        full_msg = 'Subject: {}\n\n{}'.format(subject, body)
        return full_msg

    elif new_status == "Waitlist":
        subject = "Waitlist is open for" + new_name +  "(" + code + ")!"
        body = "Your class" + " (" + code + ") " + "has changed from " + old_status + " to " + new_status + "!  \n\nHead over to web reg to sign up! \n\n" + WEB_REG_URL + opt_out_info
        full_msg = 'Subject: {}\n\n{}'.format(subject, body)
        return full_msg        

    else:
        subject = "Error"
        body = "Something went wrong. Reply to this email to report this issue." + opt_out_info
        full_msg = 'Subject: {}\n\n{}'.format(subject, body)
        return full_msg


def contruct_ios_message(old_status, new_status, class_dict):
    new_name = get_full_class_name(class_dict)
    old_status, new_status = _format_status(old_status, new_status)

    if new_status == "Open": # status is Open
        title = new_name + " is now " +  new_status + "!"
    else: # status is Waitlist
        title = new_name + " is now on" +  new_status + "!"
    message = "Status has changed from " + old_status + " to " + new_status + "! Head to Web Reg to sign up!"
    return title, message

def send_support_email(subject, message):
    try:
        server = smtplib.SMTP('smtp.gmail.com:587')
        server.ehlo()
        server.starttls()
        server.login("classnotify1@gmail.com", "class123!")
        print(message)
        full_msg = 'Subject: {}\n\n{}'.format(subject, message)
        print(message)
        
        server.sendmail("classnotify1@gmail.com", "classnotify1@gmail.com",  full_msg)
        server.quit()
        print("Success: Email sent!")
        return True
        
    except Exception as e:
        print("Email failed to send.")
        print("Error:", str(e))
        return False

def _format_status(old_status, new_status):
    if old_status == "OPEN":
        old_status = "Open"
    elif old_status == "FULL": 
        old_status = "Full"
    elif old_status == "Waitl":
        old_status = "Waitlist"
    elif old_status == "NewOnly":
        old_status = "NewOnly"

    if new_status == "OPEN":
        new_status = "Open"
    elif new_status == "FULL":
        new_status = "Full"
    elif new_status == "Waitl":
        new_status = "Waitlist"
    elif new_status == "NewOnly":
        new_status = "NewOnly"

    return old_status, new_status


def construct_restrictions_email(old_restrictions, new_restrictions, class_dict):
    old = ""
    new = ""
    new_name = get_full_class_name(class_dict)

    for restriction in old_restrictions:
        old += Restrictions.dictionary[restriction] + "\n"

    for restriction in new_restrictions:
        new += Restrictions.dictionary[restriction] + "\n"

    subject = new_name + " restrictions have changed!"
    body =  "Restrictions have changed\n\nFrom:\n" + old  + "\nTo:\n" + new 

    return subject, body


def construct_restrictions_message(old_restrictions, new_restrictions, class_dict):
    old = ", ".join(old_restrictions)
    new = ", ".join(new_restrictions)

    new_name = get_full_class_name(class_dict)

    title = new_name + " restrictions have changed!"
    message = "Restrictions have changed from " + old + " to " + new
    
    return title, message

def construct_enrollment_notification(user_doc_dict, class_dict):
    new_name = get_full_class_name(class_dict)

    title = "You are enrolled in " + new_name + "!"
    message = "Check web reg to confirm your registration!\n\nLet us know how we did! If you've experienced any issues or have questions we're happy to help."

    return title, message

def construct_enrollment_success_email(user_doc_dict, class_dict, message):
    new_name = get_full_class_name(class_dict)

    subject = "You are enrolled in " + new_name + "!"
    body = "Check WebReg to confirm your registration!\n\nWe're not perfect yet, let us know how we did! If you've experienced any issues or have questions we're happy to help."

    return subject, body

def construct_enrollment_failure_email(user_doc_dict, class_dict, message):
    new_name = get_full_class_name(class_dict)

    subject = "Could not enrolled in " + new_name
    body = "Reason from Web Reg:\n" + message + "\nWe're not perfect yet, let us know how we did. If you've experienced any issues or have questions we're happy to help."

    return subject, body