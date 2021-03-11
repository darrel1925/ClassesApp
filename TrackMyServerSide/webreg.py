from selenium import webdriver
from selenium.webdriver.support.ui import Select
from selenium.webdriver.chrome.options import Options
from collections import defaultdict
from constants import Constants
from time import sleep
import time, send_email
# import helpers
start_time = time.time()

# CHROME_DRIVER_PATH = "/home/ubuntu/desktop/chromedriver"
CHROME_DRIVER_PATH = "./chromedriver"
PAGE_TIMEOUT = 12 # how long to wait for a page to load
NUM_RETRIES = 1 # how many time to retry logging in 
IMPLICIT_WAIT = 0 # how long to wait for element to load onto a page

active_drivers = []

def password_is_valid(driver):
    try:
        log_in_message = driver.find_element_by_class_name("webauth-alert").text
        print(log_in_message)
        return False, log_in_message
    except:
        return True, ""


def get_login_message(driver):
    try:
        log_in_message = driver.find_element_by_id("staus").text
        print(log_in_message)
    except:
        print("no log in message")

def no_webreg_err_msg(driver):
    try:
        webreg_err = driver.find_element_by_class_name("WebRegErrorMsg") 
        print(webreg_err.text)
        
        # if we find an error
        if webreg_err.text == "Login Authorization has expired": # cannot log in
            return False, webreg_err.text
        if "Sorry, your student record is currently" in webreg_err.text:
            return False, webreg_err.text
        if "Your enrollment window opens on" in webreg_err.text:
            return False, webreg_err.text
        
        # if there is no error
        return True, webreg_err.text

    # if you cannot find DivLogoutMsg there was not error
    except:
        return True, ""

def no_div_logout_msg(driver):
    # if you can find DivLogoutMsg there might be an error
    try:
        logout_err = driver.find_element_by_class_name("DivLogoutMsg") # if you try to sign up before 7pm
        print(logout_err.text)
        # if we find an error
        if logout_err.text == "You are logged out.": # cannot log in
            return False, logout_err.text
        
        # if there is no error
        return True, logout_err.text

    # if you cannot find DivLogoutMsg there was not error
    except:
        return True, ""

def log_into_web_reg(email, pswd):
    """
    Logs into web reg, navigates to enrollment menu and returns the driver
    """
    print("entered")
    # this is our error or success message to return to user
    message = ""
    # set options for window size
    chrome_options = Options()
    chrome_options.add_argument("user-agent=Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:15.0) Gecko/20100101 Firefox/15.0.1")
    # chrome_options.add_argument("--headless")  # <--------- change for aws

    # open chrome
    driver = webdriver.Chrome(executable_path = CHROME_DRIVER_PATH, options=chrome_options)
    driver.set_page_load_timeout(PAGE_TIMEOUT)
    driver.implicitly_wait(IMPLICIT_WAIT) # wait up to n sec to find an element
    driver.get("https://www.reg.uci.edu/cgi-bin/webreg-redirect.sh")
    net_id = email.split("@")[0]
    ### try to find username and password input field ###
    try:
        # input credentials
        net_id_btn = driver.find_element_by_id("ucinetid")
        net_id_btn.send_keys(net_id)
        
        p_word_btn = driver.find_element_by_id("password")
        p_word_btn.send_keys(pswd)
        # sleep(50)
        get_login_message(driver)
        driver.find_element_by_name("login_button").click()
    except Exception as e:
        # couldnt find username and password field
        print("err 1:", str(e))
        message = "Unable to login. Double check that your username and password are entered correctly."
        return driver, message, False

    ### check for invalid password error ###
    try:
        success, message = password_is_valid(driver)
        assert success, message
    except Exception as e:
        # username and password are incorrect  
        print("error after clicking log in:", str(e))
        message = "Unable to login: " + str(e) 
        return driver, message, False

    ### try to get passed the user name and password login ###
    try:
        success, message = no_webreg_err_msg(driver)
        assert success

    except Exception as e:  
        print("error after clicking log in:", str(e))
        message = "Unable to login.\nLikly becasue you are not authorized to enroll at this time."
        return driver, message, False

    ### loading the front page of portal correctly ###
    try:
        success, message = no_div_logout_msg(driver)
        assert success

    except Exception as e:  
        print("error after getting into web reg:", str(e))
        message = "Unable access webreg.\nLikly becasue you are not authorized to enroll at this time."
        return driver, message, False


    ### We got into we reg ###
    return driver, "", True

def logout_of_webreg(driver):
    """
    Takes in a WebReg driver. If user is logged in, it'll log out. Then quit the driver reguardless.
    """
    if not driver:
        return

    # if you can find log in button
    try:
        submit_btns = driver.find_elements_by_name("submit")
        for btn in submit_btns:
            btn_value = btn.get_attribute('value')

            if btn_value == "Logout":
                btn.click()
                print("Logged Out Successful!")
                break
    except:
        print("Could not find log in button, quitting now")        
    
    # active_drivers[threading.current_thread()].remove(driver)
    # print("driver removed, AD len =", len(active_drivers))
    print("My program took", time.time() - start_time, "to run")
    print("My program took", time.time() - start_time, "to run")
    driver.quit()

def click_enroll_btn(driver):
    print("entered click enroll")
    # try to get to page to add and drop classes
    try:
        success, message = no_webreg_err_msg(driver)
        assert success
        print("looking for enroll")

        # try to click the enrollment menu button
        front_pg_buttons = driver.find_elements_by_class_name("WebRegButton")

        # get initial enroll button
        for btn in front_pg_buttons:
            btn_value = btn.get_attribute('value')
            print(btn_value)

            if btn_value == "Enrollment Menu":
                btn.click()
                break
        
        return driver, "", True

    except Exception as e:
        print("Error: login error", str(e))
        logout_of_webreg(driver)
        message = "Unable access webreg. \nLikely becasue you are not authorized to enroll at this time."
        return None, message, False

def click_waitlist_btn(driver):
    print("entered click enroll")
    # try to get to page to add and drop classes
    try:
        success, message = no_webreg_err_msg(driver)
        assert success
        print("looking for enroll")

        # try to click the enrollment menu button
        front_pg_buttons = driver.find_elements_by_class_name("WebRegButton")

        # get initial enroll button
        for btn in front_pg_buttons:
            btn_value = btn.get_attribute('value')
            print(btn_value)

            if btn_value == "Wait list Menu":
                btn.click()
                break
        
        return driver, "", True

    except Exception as e:
        print("Error: login error", str(e))
        logout_of_webreg(driver)
        message = "Unable access webreg. \nLikely becasue you are not authorized to enroll at this time."
        return None, message, False

 # *set retry_used = False to have each filed attmept to add class retried at 1 time
def add_class(driver, code, retry_used = True): 
    """
    Takes in a WebReg driver and cousrse code then adds that course
    """
    # get add button
    driver.find_element_by_id("add").click()
    print("registering for class [" + code + "]")

    # type in course code
    driver.find_element_by_name("courseCode").send_keys(code)    

    # get and click submit button
    submit_btns = driver.find_elements_by_name("button")
    for btn in submit_btns:
        btn_value = btn.get_attribute('value')
        
        if btn_value == "Send Request":
            btn.click()
            print("Request was went")
            break

    # if adding class is successful
    try:
        classes_added_elem = driver.find_element_by_class_name("studyList") 
        formated_text = code + classes_added_elem.text.split(code)[1]
        print(formated_text)
        return "Course " + code + " Added:\n" + formated_text + "\n"
    # if adding class is NOT successful
    except:
        print('class not added')
        webreg_err = driver.find_element_by_class_name("WebRegErrorMsg") 
        print(webreg_err.text)
        # retry each class at leasae once
        if retry_used == False:
            return add_class(driver, code, retry_used = True)
        
        return "Course " + code + " Not Added:\n" + webreg_err.text + "\n"

def should_retry_main(num_retries):
     # give program 3 tries
    return True if num_retries < (NUM_RETRIES - 1) else False

def send_success_notifications(user_doc_dict, class_dict, message):
    # TODO: Remove them from auto-enroll
    email = user_doc_dict["email"]
    
    # send notification to phone
    if "not" in message.lower():
        # send failure
        notif_info = send_email.construct_enrollment_failure_email(user_doc_dict, class_dict, message)
    else:
        #send success
        notif_info = send_email.construct_enrollment_success_email(user_doc_dict, class_dict, message)
    
    # helpers.send_push_notification_to_user(user_doc_dict, notif_info, Constants.enroll)
    
    # send email
    if user_doc_dict["receive_emails"]:
        full_msg = 'Subject: {}\n\n{}'.format(notif_info[0], notif_info[1])
        send_email.send_email_with_msg(email, full_msg)

    # update users notification list
    # helpers.update_user_notification_list(email, "", class_dict, notif_info, Constants.enroll)

def send_error_notifications(user_doc_dict, class_dict, message):
    email = user_doc_dict["email"]
    # new_name = helpers.get_full_class_name(class_dict)

    # send notification to phone
    title = "Could not register for " + new_name 
    body = "Error message: \n\n" + message + "\n\nLet us know how we did! While working to perfect this product, the more feedback the better - good or bad."
    notif_info = (title, body)
    # helpers.send_push_notification_to_user(user_doc_dict, notif_info, Constants.enroll)
    
    # send email
    email_title = "Could not register for " + new_name 
    email_body = "Error message: \n\n" + message + "\n\nLet us know how we did by replying to this email! While working to perfect this product, the more feedback the better - good or bad."
    if user_doc_dict["receive_emails"]:
        full_msg = 'Subject: {}\n\n{}'.format(email_title, email_body)
        send_email.send_email_with_msg(email, full_msg)

    # update users notification list
    # helpers.update_user_notification_list(email, "", class_dict, notif_info, Constants.enroll)

def handle_retry(driver, user_doc_dict, class_dict, num_retries, message):
    logout_of_webreg(driver)
    if should_retry_main(num_retries):
        main(user_doc_dict, class_dict, num_retries = num_retries + 1)
    else:
        # send failure notification
        send_error_notifications(user_doc_dict, class_dict, message)

def main(user_doc_dict, class_dict, num_retries = 0):
    global start_time
    start_time = time.time()

    try:
        # get info from user and class
        code = class_dict["code"]
        email = user_doc_dict["email"]
        pswd = user_doc_dict["web_reg_pswd"]
        discussion_and_labs = [code] + user_doc_dict["classes"][code]
        print("in webreg main")

        # log into web reg
        driver, message, success = log_into_web_reg(email, pswd)
        if not success:
            handle_retry(driver, user_doc_dict, class_dict, num_retries, message)
            return

        #  --> Go to Enrollment Menu <--
        # print("class_dict[status] ==", helpers.Status.OPEN, "is", class_dict["status"] == helpers.Status.OPEN)
        if class_dict["status"] == "OPEN":#helpers.Status.OPEN:
            
            # click on enrollment button
            driver, message, success = click_enroll_btn(driver)
            
            if not success:
                print("failed logging in: -->", num_retries)
                handle_retry(driver, user_doc_dict, class_dict, num_retries, message)
                return

        # --> Go to Waitlist Menu <-- 
        else:
            print("--> enter waitl!")
            # click on wait list button
            driver, message, success = click_waitlist_btn(driver)
            
            if not success:
                print("failed logging in: -->", num_retries)
                handle_retry(driver, user_doc_dict, class_dict, num_retries, message)
                return

        message = ""
        # enroll in class or add classes to waitlist 
        for code in discussion_and_labs:
            # sleep(0.1) # wait for page to load
            message_fragment = add_class(driver, code)
            message += message_fragment + "\n"


        print("PRESENT SUCCESS")
        logout_of_webreg(driver)
        # send a success notification
        send_success_notifications(user_doc_dict, class_dict, message)
    
    except Exception as e:
        print("Error occured ->", e)
        subject = "ERR with auto-enroll!!!"
        message = "error: " + str(e) 
        # helpers.send_email_error(subject, message)
    


user_doc_dict = {
    "email": "dmuonekw@uci.edu",
    "web_reg_pswd": "Vision925",
    "classes": {
        "34180": ["34181","34182"]
        },
    "notifications": [],
    "is_logged_in": True,
    "notifications_enabled": True,
    "receive_emails": False,
    "fcm_token": "cqYJ8H7zEEl6sKMQrxcGPD:APA91bHjsIynTuGbqfv6_u4ea7KHR8QTd--OUzWav5SO91qcyYe-j3rtyTTGkUie-HH5I6l-cCcBi_WuwHtZafTLliNvB7VMKl6y2ygEy_VtSxWjdyLr1974mJ1JwzzTpZqb8acExnTf"
    }

class_dict = {
    "status": "OPEN",
    "code": "34180",
    "name": "Comp Sci 143a",
    "section": "A",
    "type": "Lec"
}
if __name__ == "__main__":
    # helpers.initialize_firebase()
    main(user_doc_dict, class_dict, num_retries = 0)