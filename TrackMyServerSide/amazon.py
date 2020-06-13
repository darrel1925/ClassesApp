from time import sleep
from selenium import webdriver
from selenium.webdriver.support.ui import Select
from selenium.webdriver.chrome.options import Options

PAGE_TIMEOUT = 20
# CHROME_DRIVER_PATH = "/Users/darrelm/Desktop//chromedriver"
CHROME_DRIVER_PATH = "/home/ubuntu/desktop/chromedriver"
ITEM_URL = "https://www.amazon.com/gp/offer-listing/B00HRT863U/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=B00HRT863U&linkCode=am2&tag=chrisby20-20&linkId=cd1af38e475a3a692e9a683bdf23b2fb"
# ITEM_URL = "https://www.amazon.com/gp/offer-listing/B07K3FN5MR/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=B07K3FN5MR&linkCode=am2&tag=chrisby20-20&linkId=db2c0502d4d7515e34e134c3fd8d6aa4"
amzn_drivers = []


def load_inital_page():
    chrome_options = Options()
    chrome_options.add_argument("user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.97 Safari/537.36")
    chrome_options.add_argument("--incognito")    
    chrome_options.add_argument("--headless")  # <--------- change for aws

    driver = webdriver.Chrome(executable_path = CHROME_DRIVER_PATH, options=chrome_options)
    driver.implicitly_wait(3) # wait up to n sec to find an element
    driver.set_page_load_timeout(PAGE_TIMEOUT)
    driver.get(ITEM_URL)

    amzn_drivers.append(driver)

    return driver

def get_item_price(driver):
    item_price = driver.find_elements_by_class_name("olpOfferPrice")[0].text
    item_price = item_price.replace("$", "")
    item_price = float(item_price)
    
    return item_price

def get_shipping_price(driver):
    shipping_price = driver.find_elements_by_class_name("olpShippingInfo")[0].text

    if "free" in shipping_price.lower(): # & FREE Shipping
        return 0
    
    # + $16.61 shipping
    shipping_price = shipping_price.split("$")[1]
    shipping_price = shipping_price.split()[0]
    shipping_price = float(shipping_price)

    return shipping_price    

def check_price(driver, max_price):
    item_prices = driver.find_elements_by_class_name("olpShippingInfo")

    # Make sure there are items on the page
    assert len(item_prices) > 0, "Did not find any items in the provided link"

    # get price and check that its in range
    item_price     = get_item_price(driver)
    shipping_price = get_shipping_price(driver)
    
    print("item price:",item_price)
    print("shipping_price:", shipping_price)

    # Make sure price is within buying range 
    total = item_price + shipping_price
    assert total <= max_price, "Item price: " + str(total) + " is greater than your max price of: " + str(max_price)

def click_add_to_cart(driver):
    # click add cart
    add_to_cart_btns = driver.find_elements_by_name("submit.addToCart")[0].click()
    
    # click proceed to checkout
    proceed_to_checkout = driver.find_elements_by_class_name("a-button-inner")[1].click()


def sign_in(driver, email, pswd):
    # input credentials
    email_field = driver.find_element_by_name("email")
    email_field.send_keys(email)
    sleep(2)
    # continue to enter pswd
    continue_btn = driver.find_element_by_id("continue").click()
    sleep(2)
    pswd_field = driver.find_element_by_name('password')
    pswd_field.send_keys(pswd)

    sign_in_btn = driver.find_element_by_id("signInSubmit").click()
    sleep(2)

def enter_shipping_info(driver):
    print("signed in")
    # Full name
    full_name_field = driver.find_element_by_name('enterAddressFullName')
    full_name_field.send_keys("full name")

    # Address line 1
    address_line_1 = driver.find_element_by_name('enterAddressAddressLine1')
    address_line_1.send_keys("address line 1")

    # Address line 2
    address_line_1 = driver.find_element_by_name('enterAddressAddressLine2')
    address_line_1.send_keys("address line 2")

    # City
    city = driver.find_element_by_name('enterAddressCity')
    city.send_keys("city")

    # State/Province/Region
    state_province_region = driver.find_element_by_name('enterAddressStateOrRegion')
    state_province_region.send_keys("city")

    # Zip code
    state_province_region = driver.find_element_by_name('enterAddressPostalCode')
    state_province_region.send_keys("zip code")

    # Phone Number
    phone_number = driver.find_element_by_name('enterAddressPhoneNumber')
    phone_number.send_keys("phone number")

    # Add delivery instructions (optional)
    delivery_instructions = driver.find_element_by_name('AddressInstructions')
    delivery_instructions.send_keys("Delivery Instructions") 

    # Gate code (optional)
    gate_code = driver.find_element_by_name('GateCode')
    gate_code.send_keys("Delivery GateCode") 

    # Click Deliver to this address
    driver.find_element_by_name('shipToThisAddress').click()
    
def enter_card_info(driver):
    # Add Name on card
    name_on_card = driver.find_element_by_id('pp-j3iwU8-63')
    name_on_card.send_keys("Da Money")
    
    # Add Credit Card Number
    delivery_instructions = driver.find_element_by_name('addCreditCardNumber')
    delivery_instructions.send_keys("1234567898765")

    # Select card year dropdown
    delivery_instructions = driver.find_element_by_class_name('a-declarative')[1]
    delivery_instructions.click()

    # Select specific card year
    year_options = driver.find_element_by_class_name('a-declarative')[1]    
    items = year_options.find_elements_by_tag_name("li")
    for item in items:
        text = item.text
        print(text)


    # Select card year dropdown
    # delivery_instructions = driver.find_element_by_class_name('a-declarative')[1]
    # delivery_instructions.selectByIndex(5)

def main():

    driver = load_inital_page()
    check_price(driver, 600)
    click_add_to_cart(driver)
    sign_in(driver, "darrelmuonekwu@gmail.com", "Vision925")
    enter_shipping_info(driver)
    enter_card_info(driver)



if __name__ == "__main__":
    try:
        main()

    except Exception as error:
        print("Error:", error)

    finally:
        for driver in amzn_drivers:
            driver.quit()
    
