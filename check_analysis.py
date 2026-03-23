import subprocess
import os

def run_analysis():
    project_path = r"c:\Users\athma\OneDrive\Desktop\Mini Project\gowayanad"
    try:
        # Run flutter analyze
        process = subprocess.Popen(
            ['flutter', 'analyze', '--no-pub'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=project_path,
            shell=True,
            text=True
        )
        stdout, stderr = process.communicate()
        
        print("Analysis Output:")
        print(stdout)
        if stderr:
            print("Errors:")
            print(stderr)
            
    except Exception as e:
        print(f"Failed to run analysis: {e}")

if __name__ == "__main__":
    run_analysis()
