import socket
import cv2
import numpy as np

def send_image(image_path, host, port):
    # Create a socket object
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client_socket.connect((host, port))

    # Load the image
    image = cv2.imread(image_path)

    image = cv2.rotate(image, cv2.ROTATE_90_CLOCKWISE)
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    image = cv2.flip(image, 0)

    height, width, _ = image.shape

    # Convert the image to a byte array
    image_bytes = image.tobytes()

    # Send the image type (0 for now)
    zero = 0
    client_socket.sendall(zero.to_bytes(4, 'little'))
    client_socket.sendall(len(image_bytes).to_bytes(4, 'little'))
    client_socket.sendall(width.to_bytes(4, 'little'))
    client_socket.sendall(height.to_bytes(4, 'little'))
    client_socket.sendall(image_bytes)

    # Receive the reply from the server
    reply_type = int.from_bytes(client_socket.recv(4), 'little')
    reply_length = int.from_bytes(client_socket.recv(4), 'little')
    reply_message = client_socket.recv(reply_length).decode()

    print(f"Reply type: {reply_type}, reply length: {reply_length}, reply message: {reply_message}")

    # Close the socket
    client_socket.close()

# Example usage
send_image("lena.jpg", "127.0.0.1", 12345)