from send_email import send_email, contruct_ios_message
import helpers, webreg
import time, sys, os, signal

def main():
    all_courses = helpers.get_classes_to_search_for()


