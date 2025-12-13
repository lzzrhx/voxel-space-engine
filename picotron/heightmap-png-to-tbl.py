import png

# Read a PNG file
reader = png.Reader(filename='height.png')
width, height, pixels, metadata = reader.read()

# Access basic information
print(f"Image size: {width}x{height}")
print(f"Metadata: {metadata}")

# Convert pixels to list
#pixel_list = list(pixels)
#point = (2, 10)
#pixel_byte_width = 4 if metadata['alpha'] else 3
#pixel_position = point[0] + point[1] * width
#pixel = pixels[pixel_position * pixel_byte_width : (pixel_position + 1) * pixel_byte_width]
#print(pixel)

pixels = [list(row) for row in pixels]
#pixels=pixels[0]
#print(pixels[0])
#print(len(pixels[0]))
with open("height.txt","w") as f:
    f.write("{")
    for row in pixels:
        #f.write("{")
        for i in range(0,len(row)//3):
            #print(pixels[i*3])
            #if (i>0):
            f.write(",")
            f.write(str(row[i*3]))
        #f.write("},\n")
        f.write("\n")
    f.write("}")