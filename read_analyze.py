import os

file_path = "c:\\Users\\athma\\OneDrive\\Desktop\\Mini Project\\gowayanad\\analyze_results.txt"
if os.path.exists(file_path):
    with open(file_path, "r", encoding="utf-16") as f:
        print(f.read())
else:
    print("File not found")
