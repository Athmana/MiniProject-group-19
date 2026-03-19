import sys

with open(r'c:\Users\athma\OneDrive\Desktop\Mini Project\gowayanad\analysis_errors.txt', 'rb') as f:
    content = f.read()
    # Handle UTF-16 LE with BOM
    if content.startswith(b'\xff\xfe'):
        text = content.decode('utf-16-le')
    else:
        text = content.decode('utf-8', errors='ignore')
    print(text)
