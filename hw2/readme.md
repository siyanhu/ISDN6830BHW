# ISDN6380B_Homework Assignment2 Directions

1. [hw2.ipynb](hw2.ipynb) is the main training and testing notebook. It is built and tested in the following environment:
   
   > Python-3.9.19, torch-2.2.1, NVIDIA GeForce RTX 4090, 24209MiB, Ubuntu 22.04.

   > [YOLOv8.1.34](https://docs.ultralytics.com/quickstart/)

2. Please refer to [html version](hw2.html) to preview [notebook](hw2.ipynb) without compilation.
   
3. Custom training dataset could be found via [Google Drive](https://drive.google.com/file/d/1GZWLdSm_hzEToYYhK68X5_Njj64yWlOs/view?usp=sharing). Prediction images with result marked could be found at [predictions](predictions).
   
4. Trained models and their statistical results could be found at [here](models/train5).
   
5. To test the model in real-time, there is an iPhone app based on [CoreML](https://developer.apple.com/documentation/coreml). To transfer from Pytorch based YOLO model to mlpackage or mlmodel, please refer to [official document](https://docs.ultralytics.com/modes/export/) and the [notebook](hw2.ipynb).

6. The iPhone App [ChessboardDetection](ChessboardDetection/ISDN6380B_Homework) is coded and tested via XCode Version 15.3, and iPhone 15 pro with iOS 17.4. A screen capture video for the performance is also attached [here](AppScreenCapture.MP4)

## References
[1] YOLOv8: [Github](https://github.com/ultralytics/ultralytics)

[2] Parse YOLOv8 in ios project: [Github](https://github.com/hollance/Forge/tree/master/Examples/YOLO)

[3] YOLOv8 in CoreML: [Blog](https://machinethink.net/blog/yolo-coreml-versus-mps-graph/)

[4] What is MLMultiArray: [Apple Developer Website](https://developer.apple.com/documentation/coreml/mlmultiarray)

[5] CoreML: [CoreML Toos](https://apple.github.io/coremltools/docs-guides/)