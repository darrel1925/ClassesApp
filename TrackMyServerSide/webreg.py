
from selenium import webdriver
from selenium.webdriver.support.ui import Select
from selenium.webdriver.chrome.options import Options
from collections import defaultdict

from time import sleep
import time
start_time = time.time()

CHROME_DRIVER_PATH = "/home/ubuntu/desktop/chromedriver"
# CHROME_DRIVER_PATH = "/Users/darrelm/Desktop/classes/chromedriver"
PAGE_TIMEOUT = 20

active_drivers = []

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
            return False
        if "Sorry, your student record is currently" in webreg_err.text:
            return False
        if "Your enrollment window opens on" in webreg_err.text:
            return False
        
        # if there is no error
        return True

    # if you cannot find DivLogoutMsg there was not error
    except:
        return True

def no_div_logout_msg(driver):
    # if you can find DivLogoutMsg there might be an error
    try:
        logout_err = driver.find_element_by_class_name("DivLogoutMsg") # if you try to sign up before 7pm
        print(logout_err.text)
        # if we find an error
        if logout_err.text == "You are logged out.": # cannot log in
            return False
        
        # if there is no error
        return True

    # if you cannot find DivLogoutMsg there was not error
    except:
        return True

def log_into_web_reg(email, pswd):
    """
    Logs into web reg, navigates to enrollment menu and returns the driver
    """
    print("entered")
    # this is our error or success message to return to user
    message = ""
    # set options for window size
    chrome_options = Options()
    chrome_options.add_argument("--headless")  # <--------- change for aws

    # open chrome
    driver = webdriver.Chrome(executable_path = CHROME_DRIVER_PATH, options=chrome_options)
    driver.set_page_load_timeout(PAGE_TIMEOUT)
    driver.get("https://www.reg.uci.edu/cgi-bin/webreg-redirect.sh")
    net_id = email.split("@")[0]
    

    ### try to find username and password input field ###
    try:
        # input credentials
        net_id_btn = driver.find_element_by_id("ucinetid")
        net_id_btn.send_keys(net_id)
        
        p_word_btn = driver.find_element_by_id("password")
        p_word_btn.send_keys(pswd)

        get_login_message(driver)
        driver.find_element_by_name("login_button").click()
    except Exception as e:
        # couldnt find username and password field
        print("err 1:", str(e))
        message = "Unable to login. Double check that your username and password are entered correctly."
        driver.quit()
        return None, message

    ### try to get passed the user name and password login ###
    try:
        assert(no_webreg_err_msg(driver))
    except Exception as e:  
        print("error after clicking log in:", str(e))
        message = "Unable to login. Likly becasue your registration window is not open at this time."
        return None, message

    ### loading the front page of portal correctly ###
    try:
        assert(no_div_logout_msg(driver))
    except Exception as e:  
        print("error after getting into web reg:", str(e))
        logout_of_webreg(driver)


    ### We got into we reg ###
    return driver, "message"

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

def add_class(driver, code):
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

            
    try:
        classes_added_elem = driver.find_element_by_class_name("studyList") 
        print(classes_added_elem.text)
        return
    except:
        print('class not added')


    try:
        webreg_err = driver.find_element_by_class_name("WebRegErrorMsg") 
        print(webreg_err.text)
    except:
        print('no web reg error')


def click_enroll_btn(driver):
    print("entered click enroll")
    # try to get to page to add and drop classes
    try:
        assert(no_webreg_err_msg(driver))
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


    except Exception as e:
        print("Error: login error", str(e))
        logout_of_webreg(driver)
        return None

    return driver 
    
def enroll(user_doc_dict, code):
    email = user_doc_dict["email"]
    pswd = user_doc_dict["web_reg_pswd"]
    discussion_and_labs = user_doc_dict["classes"][code]
    print("in enroll")
    driver, message = log_into_web_reg(email, pswd)

    if not driver:
        return 
    click_enroll_btn(driver)
    time.sleep(1) # wait for page to load

    for code in discussion_and_labs:
        sleep(0.5)
        add_class(driver, code)
    
    logout_of_webreg(driver)

def main():
    code = "12345"
    email = "dmuonekw@uci.edu"
    pswd = "Vision925"
    discussion_and_labs = []
    print("in enroll")
    driver, message = log_into_web_reg(email, pswd)

    if not driver:
        return 
    click_enroll_btn(driver)
    time.sleep(1) # wait for page to load


    add_class(driver, code)
    for code in discussion_and_labs:
        sleep(1)
        add_class(driver, code)
    
    logout_of_webreg(driver)
    


# main()
