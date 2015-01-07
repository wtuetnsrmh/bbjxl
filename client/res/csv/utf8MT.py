import os
files = os.listdir(".")      
for filename in files:
    portion = os.path.splitext(filename)
    if portion[1] == ".utf8":   
        newname = portion[0] + " "   
        os.rename(filename,newname)