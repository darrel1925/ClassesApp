from flask import Flask, request, render_template
import helpers
from send_email import send_support_email, send_email_with_msg, contruct_email_message
# intanciate instance of Flask
app = Flask(__name__)

# the function index is getting called anytime somone accesses this path
@app.route("/")
def index():
    return "Yo I'm D"

@app.route("/UCI/class_info")
def  uci_class_info():
    # get the value paried with the school arg passed into the url
    school = request.args.get("school")
    code = request.args.get('code')
    year = request.args.get('year')
    quarter = request.args.get('quarter')

    return helpers.get_class_status_for_ios(code, quarter, year, school)

@app.route("/send_email_route")
def send_email_route():
    subject = str(request.args.get("subject"))
    subject = subject.encode('ascii', 'ignore').decode('ascii')
    message = str(request.args.get("message"))
    message = message.encode('ascii', 'ignore').decode('ascii')
    print(message)
    did_send_email = send_support_email(subject, message)
    json = {"did_send_email": did_send_email}
    return json

@app.route("/send_notification_email")
def send_notification_email():
    code           = str(request.args.get("code")).encode('ascii', 'ignore').decode('ascii')
    name           = str(request.args.get("name")).encode('ascii', 'ignore').decode('ascii')
    old_status     = str(request.args.get("old_status")).encode('ascii', 'ignore').decode('ascii')
    new_status     = str(request.args.get("new_status")).encode('ascii', 'ignore').decode('ascii')
    reciever_email = str(request.args.get("reciever_email")).encode('ascii', 'ignore').decode('ascii')
    
    message = contruct_email_message(old_status, new_status, code, name)
    did_send_email = send_email_with_msg(reciever_email, message)
    json = {"did_send_email": did_send_email}
    return json

@app.route("/display_terms")
def display_terms():
    return render_template("terms.html")


@app.route("/display_privacy")
def display_privacy():
    return render_template("privacy.html")

@app.route("/classes")
def getClasses():
    return "This is your class!"

if __name__ == "__main__":
    app.run(debug=True, port = 5000)