import subprocess
import sys

# Set up to run flutter analyze and capture output
try:
    result = subprocess.run(['flutter', 'analyze'], capture_output=True, text=True, cwd=r'c:\Users\athma\OneDrive\Desktop\Mini Project\gowayanad')
    print(result.stdout)
    print(result.stderr)
except Exception as e:
    print(f"Error running flutter analyze: {e}")
