
import time, schedule
import classes5

def print_space():
    print()

def main():
    schedule.every(60).seconds.do(classes5.main)
    schedule.every(60).seconds.do(print_space)

    classes5.main()
    print()
    while True:
        schedule.run_pending()
        time.sleep(1)

main()




