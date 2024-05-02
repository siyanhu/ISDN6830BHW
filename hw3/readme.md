# ISDN6380B_Homework Assignment3 Directions

## Server setup

1. [flask_server.py](server/flask_server.py) is very well setup for Linux/MacOS/Windows. It is recommended to run in conda environemnt (python=3.9). And pip install flask, numpy, opencv-python and Pillow.
   
2. Flask server does not require specifically set up IP in the script. Leaving it with 0.0.0.0 will allow connection via the IP of current device. Check your IP in terminal by typing command ifconfig.
   
3. Uploaded image will be saved in [../cache](server/cache) folder.

## Client setup
   
1. [CBClient App](client/CBOnlineSocket/CBOnlineSocket.xcodeproj) is an app to collect data based on iPhone/iPad and send the scene info to server. It requries to run on iPhone/iPad (with iOS 10.0 above) only with depth enabled camera. As it is written in swift 4.0, Xcode 9.0 or newer, as well as the devices with macOS 10.12, is required to compile the source code. 
   
2. [CBClient App](client/CBOnlineSocket/CBOnlineSocket.xcodeproj) collects RGB and Depth information from specific frame of ARSession. The event is triggered by tapping the "▶️" button on left lower corner. RGB information is sent to server to do Chessboard detection and segmentation. Response data include bounding box of detected chessboard area (center_x, center_y, boundingbox_width, boundingbox_height). Here to make it more saving of system resources for older generations iPhone/iPad, we only use the center_x and center_y to display the 3D object. 

3. After we receive the response data from server, and we get enough depth information, we calculate the scene position by transferring [center_x, center_y] from frame (CIImage) coordinate to screen location, and screen location to scene coordinate [scene_x, scene_y]. Scene_z will be replaced by depth data. With scene position ready, we put a 3D [vase](client/CBOnlineSocket/CBOnlineSocket/Models.scnassets/vase/vase.scn) onto it. Demo video of this process locates at [hw3.mp4](https://drive.google.com/file/d/1dsoTEUjtjbgBcEmRNqV0lgCa4FkDeLV-/view?usp=share_link).

4. We also have a testing function to just put a 3D model onto wherever you tap the screen. New vase added will remove the previous one.

## Known issues

1. Since the object detection is done on server, there will be a notable delay between the time Capture button clicked and the time vase is put onto chessboard.

2. Center data is calculated based on boundingbox. So there will be a displacement between the real center of the chessboard and the position vase is put.

3. Depth data is generated from ARSession and it is not applicable for iPhone/iPad without depth camera or LiDAR in the back.