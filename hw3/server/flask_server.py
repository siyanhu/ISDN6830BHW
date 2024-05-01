from flask import Flask, request, send_file
import numpy as np
import cv2
import base64
import io
from PIL import Image

import time
from predictor import ChessboardDetection
import file_io as fio

app = Flask(__name__)
CBDEngine = ChessboardDetection('best.pt')

def current_timestamp(micro_second=False):
    t = time.time()
    if micro_second:
        return int(t * 1000 * 1000)
    else:
        return int(t * 1000)
    

@app.route('/cache', methods=['POST', 'GET'])
def saveImageCache():
    image_raw = request.get_data()
    image_obj = Image.open(io.BytesIO(image_raw))
    image_rgb = cv2.cvtColor(np.array(image_obj), cv2.COLOR_BGR2RGB)
    cache_image_path = fio.createPath(fio.sep, ['cache'], str(current_timestamp(False)) + '.jpg')
    cv2.imwrite(cache_image_path, image_rgb)
    if CBDEngine:
        pred = CBDEngine.predict([cache_image_path])
        box = pred.boxes
        if (box):
            print(box.xywh)
            return {"result": 1, "x1":float(box.xywh[0, 0]), 'y1':float(box.xywh[0, 1]), 'w':float(box.xywh[0, 2]), 'h':float(box.xywh[0, 3])}
    return {"result": 0 }

if __name__=='__main__':
    #Get host and port
    # host = "143.89.144.130" 
    host = "0.0.0.0"
    port = 2333

    app.run(host, debug=True, port=port)