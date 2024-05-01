# Credit to https://github.com/katmfoo/python-client-server for providing the network basecode

import socket
import threading
import cv2
import numpy as np

#Variables for holding information about connections
connections = []
total_connections = 0

#Client class, new instance created for each connected client
#Each instance has the socket and address that is associated with items
#Along with an assigned ID and a name chosen by the client
class Client(threading.Thread):
    def __init__(self, socket, address, id, name, signal):
        threading.Thread.__init__(self)
        self.socket = socket
        self.address = address
        self.id = id
        self.name = name
        self.signal = signal
    
    def __str__(self):
        return str(self.id) + " " + str(self.address)
    
    # Ensures that we pull the entire expected length of data
    # Normally, for small chunks of data, it should be fine, but larger chunks may need to be pulled in several batches
    def getdataofsize(self,size):
        total_data =[]
        receivedlength=0
        while receivedlength<size:
            data = self.socket.recv(min(size,32000))
            if len(data)==0:
                raise Exception("Socket Closed")
            receivedlength+=len(data)
            # Debug message, uncomment if something goes wrong and the data is not properly received
            #print("Received "+str(len(data))+", Remaining "+str(length-receivedlength))
            total_data.append(data)
        message = b"".join(total_data)
        return message

    # Where you should do your data processing. 
    # Here, I just convert the raw byte array to an RGB image that numpy understands and display it.
    def processimage(self, message, width, height):
        image=np.asarray(bytearray(message), dtype=np.uint8 ).reshape( height,width, 3 )
        image_rgb=np.flip(image, axis=-1) 
        image_rgb_rotated = cv2.rotate(image_rgb, cv2.ROTATE_90_COUNTERCLOCKWISE)
        cv2.imshow("image", image_rgb_rotated)
        cv2.waitKey(0)
        cv2.destroyWindow("image") 


    #Attempt to get data from client
    #If unable to, assume client has disconnected and remove him from server data
    #If able to and we get data back, print it in the server and send it back to every
    #client aside from the client that has sent it
    #.decode is used to convert the byte data into a printable string
    def run(self):
        while self.signal:
            try:
                print("listening")
                # Get all the data from the simple protocol we defined
                datamessagetype = self.getdataofsize(4)
                messagetype = int.from_bytes(datamessagetype, "little")
                if messagetype==0:
                    datalength = self.getdataofsize(4)
                    length = int.from_bytes(datalength, "little")
                    # Debug message, uncomment if something goes wrong and the data is not properly received
                    #print("Got "+str(length)+"B from "  + str(self.id))

                    datawidth = self.getdataofsize(4)
                    width = int.from_bytes(datawidth, "little")
                    dataheight = self.getdataofsize(4)
                    height = int.from_bytes(dataheight, "little")
                    # Debug message, uncomment if something goes wrong and the data is not properly received
                    #print("Received a "+str(width)+"x"+str(height)+" image")

                    message = self.getdataofsize(length)
                    # Debug message, uncomment if something goes wrong and the data is not properly received
                    #print("Data received: "+str(len(message))+"B")
                    self.processimage(message, width, height)
                    
                    replytype = 1
                    datareplytype = replytype.to_bytes(4,'little')
                    print("replytype")

                    replymessage = "Well Received" 
                    replylength = len(replymessage.encode())
                    datareplylength = replylength.to_bytes(4, 'little')

                    self.socket.sendall(datareplytype)
                    self.socket.sendall(datareplylength)
                    self.socket.sendall(replymessage.encode())

            except Exception as e:
                print(e)
                print("Client " + str(self.address) + " has disconnected")
                self.signal = False
                connections.remove(self)
                break

#Wait for new connections
def newConnections(socket):
    while True:
        sock, address = socket.accept()
        global total_connections
        connections.append(Client(sock, address, total_connections, "Name", True))
        connections[len(connections) - 1].start()
        print("New connection at ID " + str(connections[len(connections) - 1]))
        total_connections += 1

def main():
    #Get host and port
    host = "0.0.0.0" 
    port = 12345

    #Create new server socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.bind((host, port))
    sock.listen(5)

    print("Server Started")

    #Create new thread to wait for connections
    newConnectionsThread = threading.Thread(target = newConnections, args = (sock,))
    newConnectionsThread.start()
    
main()