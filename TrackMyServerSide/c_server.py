import socket, time
import helpers
from helpers import parse_input
"""
Request prefix

add = Add a class to search for to the data base
get = get the current status of a class
lod = load in all classes that are being tracked by user

"""

PORT = 17821
CONNECT_PSWD = "Mes4#3=+f1F22KF2@34%&3ad"

def inputIsValid(input_str):
    try:
        return input_str.split()[0] == CONNECT_PSWD
    except: 
        return False

def set_up_server():
    # try:
    s = socket.socket()
    print("Socket successfully created")

    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    # empty str make server listen to connections from other netwroks
    s.bind(('0.0.0.0', PORT))
    print("socket binded to", (PORT))

    # put the socket into listening mode | max queue size = 5
    s.listen(500)      
    print("socket is listening")

    while(True):
        # Establish connection with client. 
        c, addr = s.accept()
        print('Got connection from', addr)
        
        # wait to reveive a max of 4096 bytes from client
        server_input = c.recv(4096).decode()

        if not inputIsValid(server_input):
            print("\n!!!received INVALID INPUT data!!! -> " + server_input + "\n")
            c.close()
            continue
        
        server_input = server_input.split()[1]
        print("\nVerified received data -> " + server_input + "\n")

        

        if server_input[:3] == "add":
            print("add")
            print(parse_input(server_input[3:]))
            helpers.add_class_to_fb(server_input[3:])
            print(parse_input(server_input[3:]))
            c.close()

        elif server_input[:3] == "get":
            print("get")
            print(parse_input(server_input[3:]))
            status = helpers.get_class_status_for_ios(server_input[3:])
            my_str_as_bytes = str.encode(status)
            print("sending back", status)
            c.send(my_str_as_bytes)
            c.close()
        
        else:
            c.close()

    # except Exception as e:
    #     print("Error!! ->", str(e), "\n\n")
    #     print("--> Restarting server... <--\n\n")

    #     c.close()
    #     s.shutdown(socket.SHUT_RDWR)
    #     s.close()

    #     for num in [3,2,1]:
    #         time.sleep(1)
    #         print("Restarting in...", num)
    #     print()
    #     set_up_server()

def getInput():
    port = input("Select Port:\n\n0: Port 1 \n1: Port 1 \n 2:Port 2")
# set_up_server()




