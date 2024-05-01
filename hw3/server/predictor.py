from ultralytics import YOLO

class ChessboardDetection:
    def __init__(self, model_path):
        self.model = YOLO(model_path)
    
    def check_model(self):
        metrics = self.model.val()
        print("\n\n")
        print("\n========metrics.box.map========\n", metrics.box.map)
        print("\n")
        print("\n========metrics.box.map50========\n", metrics.box.map50)
        print("\n")
        print("\n========metrics.box.map75========\n" ,metrics.box.map75)
        print("\n")
        print("\n========metrics.box.maps========\n", metrics.box.maps)
        print("\n")

    def predict(self, source_image_path):
        results = self.model(source_image_path)
        # results[0].show()
        return results[0]