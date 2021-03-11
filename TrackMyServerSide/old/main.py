
import time, schedule
import classes5
from helpers import should_slow_search

def print_space():
    print()

def main():
    schedule.every(5).seconds.do(classes5.main)
    schedule.every(5).seconds.do(print_space)

    classes5.main()
    time.sleep(5)
    print()
    while True:
        schedule.run_pending()
        time.sleep(1)

        if should_slow_search():
            print("slow")
            time.sleep(300)

if __name__ == "__main__":
    main()




